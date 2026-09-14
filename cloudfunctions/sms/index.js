'use strict';
/**
 * 摸鱼圈 · 短信验证码「HTTP 云函数」(Web 函数)
 *
 * 运行形态：监听 9000 端口的常驻 HTTP 服务（CloudBase HTTP 云函数硬性要求）。
 * 入口：scf_bootstrap → node index.js
 *
 * 访问地址（HTTP 型按函数必须在带 APPID 的默认域名下）：
 *   https://{envId}-{appid}.{region}.app.tcloudbase.com/sms
 *   ⚠️ 不带 APPID 的 `{envId}.service.tcloudbase.com` 对 HTTP 型函数会返回
 *      FUNCTIONS_PARAM_INVALID（FunctionType parameter is invalid），不可用。
 *
 * 路由（单一入口，靠 body.action 区分）：
 *   POST /  {action:"send",   phone}        → 限流 + 生成 6 位码 + 存 HMAC + 腾讯云 SendSms
 *   POST /  {action:"verify", phone, code}  → 比对 HMAC 并置 used（防重放 + 错误次数锁定）
 *   GET  /?action=ping                      → 健康检查
 *
 * 安全要点：
 *   1. 腾讯云 SecretId/SecretKey/SmsSdkAppId/TemplateId 只存在于本函数环境变量，
 *      绝不下发客户端（App 直连腾讯云 API 会被反编译提取密钥 → 盗刷短信费）。
 *   2. 验证码不落明文：库里只存 HMAC-SHA256(CODE_PEPPER, phone|code)。
 *      短信验证码表对 anon 角色是「可读写」（云函数用 Publishable Key 访问），
 *      若不哈希，攻击者用公开的 Publishable Key 就能 SELECT 出所有人的待验证码 → 批量登录。
 *      加了 pepper（仅存在于云函数环境变量）后，读到哈希也算不出 6 位码。
 *   3. 单条码最多错 5 次即作废（需重新发送），配合 60 秒重发间隔防在线爆破。
 *
 * 零第三方依赖（仅 Node 内置 http / https / crypto）。
 *
 * 环境变量：
 *   TC_SECRET_ID / TC_SECRET_KEY          腾讯云 API 密钥
 *   TC_SMS_SDK_APP_ID                     短信应用 SdkAppId（1401192900）
 *   TC_SMS_SIGN_NAME                      短信签名（摸鱼圈）
 *   TC_SMS_TEMPLATE_ID                    验证码模板 ID
 *   TC_SMS_REGION                         默认 ap-guangzhou
 *   RDB_BASE / RDB_KEY                    云开发 PG(PostgREST) 端点 + Publishable Key
 *   CODE_PEPPER                           验证码哈希用的服务端盐（务必设随机值，勿留默认）
 */

const http = require('http');
const crypto = require('crypto');
const https = require('https');

// ─────────────────────────────────────────────
// 配置
// ─────────────────────────────────────────────
const TC_SECRET_ID = process.env.TC_SECRET_ID || '';
const TC_SECRET_KEY = process.env.TC_SECRET_KEY || '';
const TC_SDK_APP_ID = process.env.TC_SMS_SDK_APP_ID || '';
const TC_SIGN_NAME = process.env.TC_SMS_SIGN_NAME || '摸鱼圈';
const TC_TEMPLATE_ID = process.env.TC_SMS_TEMPLATE_ID || '';
const TC_REGION = process.env.TC_SMS_REGION || 'ap-guangzhou';

const RDB_BASE = (process.env.RDB_BASE || '').replace(/\/+$/, '');
const RDB_KEY = process.env.RDB_KEY || '';
const CODE_PEPPER = process.env.CODE_PEPPER || '';

const CODE_TTL_MIN = 10; // 验证码有效期（分钟）
const RESEND_SECONDS = 60; // 同号重发最小间隔（秒）
const MAX_PER_DAY = 5; // 单号每日发送上限
const MAX_VERIFY_FAILS = 5; // 单条码最大错误次数
const TABLE = 'sms_verify_codes';
const PORT = process.env.PORT || 9000;

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

// ─────────────────────────────────────────────
// 基础工具
// ─────────────────────────────────────────────
function ok(body) {
  return { statusCode: 200, body: body };
}
function fail(statusCode, body) {
  return { statusCode: statusCode, body: body };
}

function isValidPhone(p) {
  return /^1[3-9]\d{9}$/.test(String(p || ''));
}

function genCode() {
  return String(crypto.randomInt(0, 1000000)).padStart(6, '0');
}

/** 验证码入库哈希：只有服务端知道 pepper，读到哈希也无法还原 6 位码 */
function hashCode(phone, code) {
  return crypto
    .createHash('sha256')
    .update(CODE_PEPPER + '|' + phone + '|' + code, 'utf8')
    .digest('hex');
}

function sha256hex(s) {
  return crypto.createHash('sha256').update(s, 'utf8').digest('hex');
}

function hmacSha256(key, s) {
  return crypto.createHmac('sha256', key).update(s, 'utf8').digest();
}

/** 低层 HTTPS 请求（返回 {statusCode, body}），零依赖 */
function httpsRequest(method, url, headers, rawBody) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const h = Object.assign({}, headers);
    if (rawBody != null) h['Content-Length'] = Buffer.byteLength(rawBody);
    const req = https.request(
      {
        method: method,
        hostname: u.hostname,
        port: u.port || 443,
        path: u.pathname + u.search,
        headers: h,
        timeout: 9000,
      },
      (res) => {
        let data = '';
        res.setEncoding('utf8');
        res.on('data', (c) => (data += c));
        res.on('end', () => resolve({ statusCode: res.statusCode, body: data }));
      },
    );
    req.on('timeout', () => req.destroy(new Error('request timeout')));
    req.on('error', reject);
    if (rawBody != null) req.write(rawBody);
    req.end();
  });
}

// ─────────────────────────────────────────────
// 云开发 PG(PostgREST) 读写
// ─────────────────────────────────────────────
function rdbUrl(query) {
  return RDB_BASE + '/' + TABLE + (query ? '?' + query : '');
}

function rdbHeaders(extra) {
  return Object.assign(
    {
      Authorization: 'Bearer ' + RDB_KEY,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    extra || {},
  );
}

async function rdbGet(query) {
  const r = await httpsRequest('GET', rdbUrl(query), rdbHeaders(), null);
  if (r.statusCode < 200 || r.statusCode >= 300) {
    throw new Error('RDB_GET_' + r.statusCode + ': ' + r.body.slice(0, 200));
  }
  return JSON.parse(r.body || '[]');
}

async function rdbInsert(row) {
  const r = await httpsRequest(
    'POST',
    rdbUrl(''),
    rdbHeaders({ Prefer: 'return=minimal' }),
    JSON.stringify(row),
  );
  if (r.statusCode < 200 || r.statusCode >= 300) {
    throw new Error('RDB_INSERT_' + r.statusCode + ': ' + r.body.slice(0, 200));
  }
}

async function rdbPatch(id, patch) {
  const r = await httpsRequest(
    'PATCH',
    rdbUrl('id=eq.' + encodeURIComponent(id)),
    rdbHeaders({ Prefer: 'return=minimal' }),
    JSON.stringify(patch),
  );
  if (r.statusCode < 200 || r.statusCode >= 300) {
    throw new Error('RDB_PATCH_' + r.statusCode + ': ' + r.body.slice(0, 200));
  }
}

// ─────────────────────────────────────────────
// 腾讯云短信 SendSms（TC3-HMAC-SHA256 手写签名，零依赖）
// ─────────────────────────────────────────────
async function callSendSms(phone, code) {
  const host = 'sms.tencentcloudapi.com';
  const service = 'sms';
  const action = 'SendSms';
  const version = '2021-01-11';
  const ct = 'application/json; charset=utf-8';

  const payload = JSON.stringify({
    PhoneNumberSet: ['+86' + phone],
    SmsSdkAppId: TC_SDK_APP_ID,
    SignName: TC_SIGN_NAME,
    TemplateId: TC_TEMPLATE_ID,
    TemplateParamSet: [code, String(CODE_TTL_MIN)],
  });

  const timestamp = Math.floor(Date.now() / 1000);
  const date = new Date(timestamp * 1000).toISOString().slice(0, 10);
  const canonicalHeaders = 'content-type:' + ct + '\n' + 'host:' + host + '\n';
  const signedHeaders = 'content-type;host';
  const canonicalRequest = [
    'POST',
    '/',
    '',
    canonicalHeaders,
    signedHeaders,
    sha256hex(payload),
  ].join('\n');

  const credentialScope = date + '/' + service + '/tc3_request';
  const stringToSign = [
    'TC3-HMAC-SHA256',
    String(timestamp),
    credentialScope,
    sha256hex(canonicalRequest),
  ].join('\n');

  const secretDate = hmacSha256('TC3' + TC_SECRET_KEY, date);
  const secretService = hmacSha256(secretDate, service);
  const secretSigning = hmacSha256(secretService, 'tc3_request');
  const signature = crypto
    .createHmac('sha256', secretSigning)
    .update(stringToSign, 'utf8')
    .digest('hex');

  const authorization =
    'TC3-HMAC-SHA256 Credential=' +
    TC_SECRET_ID +
    '/' +
    credentialScope +
    ', SignedHeaders=' +
    signedHeaders +
    ', Signature=' +
    signature;

  const r = await httpsRequest(
    'POST',
    'https://' + host + '/',
    {
      Authorization: authorization,
      'Content-Type': ct,
      'X-TC-Action': action,
      'X-TC-Version': version,
      'X-TC-Timestamp': String(timestamp),
      'X-TC-Region': TC_REGION,
    },
    payload,
  );

  let data;
  try {
    data = JSON.parse(r.body || '{}');
  } catch (e) {
    throw new Error('SMS_BAD_RESPONSE: ' + r.body.slice(0, 200));
  }
  const body = data.Response || {};
  if (body.Error) {
    const err = new Error(body.Error.Message || 'SMS API error');
    err.tcCode = body.Error.Code || '';
    throw err;
  }
  return body;
}

// ─────────────────────────────────────────────
// 业务处理
// ─────────────────────────────────────────────
function notConfigured() {
  return fail(503, {
    ok: false,
    error: 'SMS_NOT_CONFIGURED',
    message: '短信凭证未配置（等待签名/模板审核通过后填云函数环境变量）',
  });
}

async function handleSend(phone) {
  if (!isValidPhone(phone)) return fail(400, { ok: false, error: 'INVALID_PHONE' });

  if (
    !TC_SECRET_ID ||
    !TC_SECRET_KEY ||
    !TC_SDK_APP_ID ||
    !TC_TEMPLATE_ID ||
    !CODE_PEPPER ||
    !RDB_BASE ||
    !RDB_KEY
  ) {
    return notConfigured();
  }

  const rows = await rdbGet(
    'select=id,created_at&phone=eq.' +
      encodeURIComponent(phone) +
      '&order=created_at.desc&limit=20',
  );
  const now = Date.now();
  if (rows.length) {
    const lastTs = new Date(rows[0].created_at).getTime();
    if (now - lastTs < RESEND_SECONDS * 1000) {
      return fail(429, { ok: false, error: 'TOO_FREQUENT', message: '发送过于频繁，请稍后再试' });
    }
  }
  const dayAgo = now - 24 * 3600 * 1000;
  const todayCount = rows.filter((r) => new Date(r.created_at).getTime() > dayAgo).length;
  if (todayCount >= MAX_PER_DAY) {
    return fail(429, { ok: false, error: 'DAILY_LIMIT', message: '今日发送次数已达上限' });
  }

  const code = genCode();
  // 只存哈希，不落明文
  await rdbInsert({ phone: phone, code: hashCode(phone, code), used: false, attempts: 0 });

  try {
    await callSendSms(phone, code);
  } catch (e) {
    return fail(502, {
      ok: false,
      error: 'SMS_API_ERROR',
      tcCode: e.tcCode || '',
      message: e.message,
    });
  }
  return ok({ ok: true });
}

async function handleVerify(phone, code) {
  if (!isValidPhone(phone) || !/^\d{6}$/.test(String(code || ''))) {
    return fail(400, { ok: false, error: 'INVALID_INPUT' });
  }
  if (!CODE_PEPPER || !RDB_BASE || !RDB_KEY) return notConfigured();

  // 取最近若干条未用码：不用 limit 1，避免他人插入垃圾行把真实那条挤掉
  const rows = await rdbGet(
    'select=id,code,created_at,attempts&phone=eq.' +
      encodeURIComponent(phone) +
      '&used=eq.false&order=created_at.desc&limit=10',
  );
  if (!rows.length) return ok({ ok: false, error: 'NO_CODE' });

  const now = Date.now();
  const want = hashCode(phone, code);

  // 任一未过期行命中即通过
  let matched = null;
  for (const row of rows) {
    const ageMs = now - new Date(row.created_at).getTime();
    if (ageMs > CODE_TTL_MIN * 60 * 1000) continue;
    if (String(row.code) === want) {
      matched = row;
      break;
    }
  }

  if (matched) {
    // 该手机号所有未用码一并作废（防重放）
    for (const row of rows) {
      try {
        await rdbPatch(row.id, { used: true });
      } catch (e) {
        /* 单条失败不影响整体结果 */
      }
    }
    return ok({ ok: true });
  }

  // 未命中：最新那条累加错误次数，超过阈值直接作废
  const latest = rows[0];
  const ageOk = now - new Date(latest.created_at).getTime() <= CODE_TTL_MIN * 60 * 1000;
  if (!ageOk) return ok({ ok: false, error: 'EXPIRED' });

  const fails = Number(latest.attempts || 0) + 1;
  try {
    await rdbPatch(latest.id, fails >= MAX_VERIFY_FAILS ? { attempts: fails, used: true } : { attempts: fails });
  } catch (e) {
    /* 忽略 */
  }
  if (fails >= MAX_VERIFY_FAILS) {
    return ok({ ok: false, error: 'TOO_MANY_ATTEMPTS' });
  }
  return ok({ ok: false, error: 'WRONG_CODE' });
}

/**
 * 读取请求体（Web 函数里 event/body 概念由我们自己解析）
 */
function readBody(req) {
  return new Promise((resolve) => {
    let raw = '';
    req.on('data', (c) => {
      raw += c;
      if (raw.length > 64 * 1024) raw = raw.slice(0, 64 * 1024);
    });
    req.on('end', () => {
      try {
        resolve(raw ? JSON.parse(raw) : {});
      } catch (e) {
        resolve({});
      }
    });
    req.on('error', () => resolve({}));
  });
}

function sendJson(res, out) {
  res.writeHead(
    out.statusCode,
    Object.assign({ 'Content-Type': 'application/json; charset=utf-8' }, CORS),
  );
  res.end(JSON.stringify(out.body));
}

// ─────────────────────────────────────────────
// HTTP 服务（HTTP 云函数入口，必须监听 9000）
// ─────────────────────────────────────────────
const server = http.createServer(async (req, res) => {
  if (String(req.method).toUpperCase() === 'OPTIONS') {
    res.writeHead(204, CORS);
    res.end();
    return;
  }

  const u = new URL(req.url || '/', 'http://localhost');
  const body = await readBody(req);
  const pick = (k) => (body[k] != null ? body[k] : u.searchParams.get(k));
  const action = String(pick('action') || '').toLowerCase();
  const phone = String(pick('phone') || '');
  const code = String(pick('code') || '');

  try {
    let out;
    if (action === 'ping') {
      out = ok({ ok: true, pong: true, ts: Date.now() });
    } else if (action === 'send') {
      out = await handleSend(phone);
    } else if (action === 'verify') {
      out = await handleVerify(phone, code);
    } else {
      out = fail(400, {
        ok: false,
        error: 'BAD_ACTION',
        message: 'action 需为 send / verify / ping',
      });
    }
    sendJson(res, out);
  } catch (e) {
    sendJson(
      res,
      fail(500, {
        ok: false,
        error: 'INTERNAL',
        message: e && e.message ? e.message : String(e),
      }),
    );
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('[moyuquan-sms] HTTP cloud function listening on ' + PORT);
});
