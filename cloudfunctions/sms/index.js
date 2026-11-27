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
 * ⚠️ 双通道设计（2026-10-27）：账号无营业执照，腾讯云国内短信【个人认证已无法申请签名】
 *    （2025-09-18 新规：不再支持个人自用资质，运营商也不给个人主体做实名报备）。
 *    故先走【阿里云短信认证服务】（免资质、免签名、免模板，个人实名即可开通），
 *    等业务上量后再切腾讯云自有签名。切换方式：改环境变量 SMS_PROVIDER + 重新部署。
 *
 *    两通道的唯一实质差异 —— 验证码存哪：
 *      · 阿里云通道：验证码由【阿里云生成并保管】，我们拿不到明文。
 *        TemplateParam 必须传 {"code":"##code##","min":"5"} 占位符，
 *        传明文的话阿里云【无法校验】（官方文档明确说明）。
 *        校验走 CheckSmsVerifyCode，看 Model.VerifyResult == 'PASS'。
 *        防重放依赖 DuplicatePolicy=1（覆盖处理，旧码自动失效）。
 *      · 腾讯云通道：验证码我们自己生成，HMAC 后存 sms_verify_codes，校验时查库比对。
 *
 *    对外契约【完全不变】：前端始终只调 send / verify，登录页零改动。
 *    用户表 profiles、posts 等业务数据零影响。
 *
 * 安全要点：
 *   1. 腾讯云 SecretId/SecretKey/阿里云 AccessKey 只存在于本函数环境变量，
 *      绝不下发客户端（App 直连云 API 会被反编译提取密钥 → 盗刷短信费）。
 *   2. 验证码不落明文：腾讯云通道库里只存 HMAC-SHA256(CODE_PEPPER, phone|code)；
 *      阿里云通道我们连明文都拿不到，库里 code 字段存空串，仅作发送记录用于限流。
 *      短信验证码表对 anon 角色是「可读写」（云函数用 Publishable Key 访问），
 *      若不哈希，攻击者用公开的 Publishable Key 就能 SELECT 出所有人的待验证码 → 批量登录。
 *      加了 pepper（仅存在于云函数环境变量）后，读到哈希也算不出 6 位码。
 *   3. 单条码最多错 5 次即作废（需重新发送），配合 60 秒重发间隔防在线爆破。
 *
 * 零第三方依赖（仅 Node 内置 http / https / crypto）。
 *
 * 环境变量：
 *   SMS_PROVIDER                        通道选择：aliyun（默认）/ tencent
 *   TC_SECRET_ID / TC_SECRET_KEY        腾讯云 API 密钥（B 通道用）
 *   TC_SMS_SDK_APP_ID                   短信应用 SdkAppId（B 通道用，1401192900）
 *   TC_SMS_SIGN_NAME                    短信签名（B 通道用，摸鱼圈）
 *   TC_SMS_TEMPLATE_ID                  验证码模板 ID（B 通道用）
 *   TC_SMS_REGION                       默认 ap-guangzhou
 *   ALIYUN_ACCESS_KEY_ID                 阿里云 AccessKeyId（A 通道用）
 *   ALIYUN_ACCESS_KEY_SECRET             阿里云 AccessKeySecret（A 通道用）
 *   ALIYUN_SMS_SIGN_NAME                 阿里云【赠送】签名名（A 通道用，从控制台抄）
 *   ALIYUN_SMS_TEMPLATE_CODE             阿里云【赠送】模板 CODE（A 通道用，从控制台抄）
 *   ALIYUN_SMS_REGION                    默认 ap-southeast-1
 *   RDB_BASE / RDB_KEY                  云开发 PG(PostgREST) 端点 + Publishable Key
 *   CODE_PEPPER                         验证码哈希用的服务端盐（务必设随机值，勿留默认）
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

// ── 阿里云短信认证通道（A 阶段用，免资质）─────────────
const ALIYUN_AK = process.env.ALIYUN_ACCESS_KEY_ID || '';
const ALIYUN_SK = process.env.ALIYUN_ACCESS_KEY_SECRET || '';
const ALIYUN_SIGN_NAME = process.env.ALIYUN_SMS_SIGN_NAME || '';
const ALIYUN_SCHEME_NAME = process.env.ALIYUN_SMS_SCHEME_NAME || '';
const ALIYUN_TEMPLATE_CODE = process.env.ALIYUN_SMS_TEMPLATE_CODE || '';
const ALIYUN_REGION = process.env.ALIYUN_SMS_REGION || 'ap-southeast-1';
const ALIYUN_HOST = 'dypnsapi.aliyuncs.com';
const ALIYUN_VERSION = '2017-05-25';

/**
 * 通道选择。
 *   aliyun  → 阿里云短信认证服务（免资质，个人可用）—— 当前默认
 *   tencent → 腾讯云自有签名（需营业执照 + 签名模板过审 + 运营商报备）
 * 未显式配置时按「哪边配齐了用哪边」自动判断：阿里云配齐优先阿里云，
 * 否则腾讯云。这样即使忘了改环境变量也不会整个挂掉。
 */
const SMS_PROVIDER = String(
  process.env.SMS_PROVIDER ||
    (ALIYUN_AK && ALIYUN_SK && ALIYUN_SIGN_NAME && ALIYUN_TEMPLATE_CODE
      ? 'aliyun'
      : 'tencent'),
).toLowerCase();

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
// IP 频控（进程内计数，无需额外存储）
//
// ⚠️ 为什么需要：/sms 端点任何人可调。若不加限流，攻击者可用你的 AccessKey
//    刷爆短信套餐包（阿里云短信认证按量 0.042 元/次，套餐包用完后直接扣账户余额）。
//    配合「单号日限 5 条」不够 —— 攻击者可用成千上万个不同手机号。
//    这里按 IP 限：同一 IP 每小时最多发 20 条、单日最多 60 条。
//
//    局限：云函数多实例时每个实例各有一份计数（不精确）。
//    这是【兜底】而非唯一防线 —— 真正的硬防线是阿里云侧的套餐包额度上限。
// ─────────────────────────────────────────────
const IP_HOURLY_MAX = Number(process.env.SMS_IP_HOURLY_MAX || 20);
const IP_DAILY_MAX = Number(process.env.SMS_IP_DAILY_MAX || 60);
const ipHits = new Map(); // ip → { hour: ts, hourCount, day, dayCount }

// 定期清理过期条目，防止内存无限增长
setInterval(() => {
  const now = Date.now();
  for (const [ip, rec] of ipHits) {
    if (now - rec.day > 24 * 3600 * 1000 + 3600 * 1000) ipHits.delete(ip);
  }
}, 10 * 60 * 1000).unref();

function clientIp(req) {
  const xff = req.headers['x-forwarded-for'];
  if (xff) return String(xff).split(',')[0].trim();
  return String(req.socket && req.socket.remoteAddress ? req.socket.remoteAddress : 'unknown');
}

/** 返回 null 表示放行；否则返回错误响应 */
function checkIpRate(ip) {
  const now = Date.now();
  const hour = Math.floor(now / 3600000);
  const day = Math.floor(now / 86400000);
  let rec = ipHits.get(ip);
  if (!rec) {
    rec = { hour, hourCount: 0, day, dayCount: 0 };
    ipHits.set(ip, rec);
  }
  if (rec.hour !== hour) {
    rec.hour = hour;
    rec.hourCount = 0;
  }
  if (rec.day !== day) {
    rec.day = day;
    rec.dayCount = 0;
  }
  rec.hourCount += 1;
  rec.dayCount += 1;
  if (rec.hourCount > IP_HOURLY_MAX) {
    return fail(429, {
      ok: false,
      error: 'IP_RATE_LIMITED',
      message: '请求过于频繁，请稍后再试',
    });
  }
  if (rec.dayCount > IP_DAILY_MAX) {
    return fail(429, {
      ok: false,
      error: 'IP_RATE_LIMITED',
      message: '今日请求次数已达上限',
    });
  }
  return null;
}

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
// 阿里云短信认证：SendSmsVerifyCode / CheckSmsVerifyCode
// 签名：ACS3-HMAC-SHA256（阿里云 API 3.0），零依赖手写
// ─────────────────────────────────────────────

/** 阿里云 API 3.0 签名：ACS3-HMAC-SHA256 */
function aliyunSign(action, body) {
  const timestamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');
  const nonce = crypto.randomUUID ? crypto.randomUUID() : String(Date.now()) + Math.random();
  const payload = JSON.stringify(body);
  const contentSha256 = sha256hex(payload);

  // 参与签名的头：host + x-acs-* ，按字典序
  const canonicalHeaders =
    'host:' + ALIYUN_HOST + '\n' +
    'x-acs-action:' + action + '\n' +
    'x-acs-content-sha256:' + contentSha256 + '\n' +
    'x-acs-date:' + timestamp + '\n' +
    'x-acs-signature-nonce:' + nonce + '\n' +
    'x-acs-version:' + ALIYUN_VERSION + '\n';
  const signedHeaders =
    'host;x-acs-action;x-acs-content-sha256;x-acs-date;x-acs-signature-nonce;x-acs-version';

  // POST / 空 query
  const canonicalRequest = [
    'POST',
    '/',
    '',
    canonicalHeaders,
    signedHeaders,
    contentSha256,
  ].join('\n');

  const stringToSign =
    'ACS3-HMAC-SHA256\n' + sha256hex(canonicalRequest);

  const signature = crypto
    .createHmac('sha256', ALIYUN_SK)
    .update(stringToSign, 'utf8')
    .digest('hex');

  const authorization =
    'ACS3-HMAC-SHA256 Credential=' + ALIYUN_AK + ',' +
    'SignedHeaders=' + signedHeaders + ',' +
    'Signature=' + signature;

  return {
    url: 'https://' + ALIYUN_HOST + '/',
    headers: {
      Authorization: authorization,
      'Content-Type': 'application/json',
      'x-acs-action': action,
      'x-acs-content-sha256': contentSha256,
      'x-acs-date': timestamp,
      'x-acs-signature-nonce': nonce,
      'x-acs-version': ALIYUN_VERSION,
    },
    payload,
  };
}

/** 调阿里云 OpenAPI，返回解析后的 body（失败抛错，err.aliyunCode 带错误码） */
async function aliyunCall(action, body) {
  const signed = aliyunSign(action, body);
  const r = await httpsRequest(
    'POST',
    signed.url,
    signed.headers,
    signed.payload,
  );
  let data;
  try {
    data = JSON.parse(r.body || '{}');
  } catch (e) {
    throw new Error('ALIYUN_BAD_RESPONSE: ' + String(r.body).slice(0, 200));
  }
  if (data.Code && data.Code !== 'OK') {
    const err = new Error(data.Message || data.Code);
    err.aliyunCode = data.Code || '';
    err.aliyunRequestId = data.RequestId || '';
    throw err;
  }
  if (data.Success === false) {
    const err = new Error(data.Message || 'ALIPAY_FAILED');
    err.aliyunCode = data.Code || '';
    throw err;
  }
  return data;
}

/**
 * 发送验证码（阿里云通道）。
 *
 * ⚠️ 关键：TemplateParam 必须用 "##code##" 占位符，让【阿里云生成并保管】验证码。
 *    若传明文（如 {"code":"123456"}），CheckSmsVerifyCode 将【无法校验】（官方文档明确说明）。
 *    这样我们库里也永远拿不到明文码，安全性反而更高。
 *
 * DuplicatePolicy=1 → 覆盖处理，同号重发时旧码自动失效（防重放）。
 * Interval=60 → 与我们自己的 60 秒重发间隔对齐，双保险。
 */
async function aliyunSendCode(phone) {
  await aliyunCall('SendSmsVerifyCode', {
    PhoneNumber: phone,
    CountryCode: '86',
    // ⚠️ 短信认证 API 必须传 SchemeName（认证方案名称）——
    //    方案 = 签名+模板+有效期等打包的配置，在号码认证服务控制台
    //    「短信认证参数配置 → 方案配置」里查看（赠送方案）。
    //    空值会报 lc.ASSERT_ERROR（schemeName 非空断言）。
    ...(ALIYUN_SCHEME_NAME ? { SchemeName: ALIYUN_SCHEME_NAME } : {}),
    SignName: ALIYUN_SIGN_NAME,
    TemplateCode: ALIYUN_TEMPLATE_CODE,
    TemplateParam: JSON.stringify({ code: '##code##', min: String(CODE_TTL_MIN) }),
    CodeLength: 6,
    CodeType: 1,
    ValidTime: CODE_TTL_MIN * 60,
    DuplicatePolicy: 1,
    Interval: RESEND_SECONDS,
    ReturnVerifyCode: false,
    OutId: 'moyuquan-' + Date.now(),
  });
}

/**
 * 校验验证码（阿里云通道）。
 * 返回 true = 通过；false = 码不对/已失效。
 *
 * ⚠️ 官方强调：「接口请求成功不代表验证码核验成功，核验结果仅以
 *    Model.VerifyResult 参数返回值为准」——所以必须看 VerifyResult，不能只看 Code==='OK'。
 */
async function aliyunVerifyCode(phone, code) {
  const data = await aliyunCall('CheckSmsVerifyCode', {
    PhoneNumber: phone,
    CountryCode: '86',
    ...(ALIYUN_SCHEME_NAME ? { SchemeName: ALIYUN_SCHEME_NAME } : {}),
    // ⚠️ 不传 OutId —— 发送时 OutId 是 moyuquan-xxx，核验传空串会让
    //    阿里云对不上发送记录 → VerifyResult=UNKNOWN（实测踩坑）
    VerifyCode: String(code),
    CaseAuthPolicy: 1, // 不区分大小写
  });
  const model = data.Model || {};
  return model.VerifyResult === 'PASS';
}

// ─────────────────────────────────────────────
// 业务处理
// ─────────────────────────────────────────────
// ⚠️ 这里刻意把「缺什么」拆开报，而不是笼统的 SMS_NOT_CONFIGURED。
//   之前所有配置缺失都返回同一个码，运维只能反复试，无法一眼定位。
//   现在每个缺失项单独一个错误码，前端 sms_service.dart 也有对应翻译。
function notConfigured(missing) {
  return fail(503, {
    ok: false,
    error: 'SMS_NOT_CONFIGURED',
    missing,                       // 缺失项清单，便于排查
    message: `短信服务配置未完成，缺少：${missing.join('、')}`
      + '（等待短信签名/模板审核通过后填云函数环境变量）',
  });
}

async function handleSend(phone) {
  if (!isValidPhone(phone)) return fail(400, { ok: false, error: 'INVALID_PHONE' });

  // 逐项检查并报出缺哪几个 —— 顺序按"最可能先缺"的排
  const missing = [];
  if (SMS_PROVIDER === 'aliyun') {
    if (!ALIYUN_AK)             missing.push('ALIYUN_ACCESS_KEY_ID');
    if (!ALIYUN_SK)             missing.push('ALIYUN_ACCESS_KEY_SECRET');
    if (!ALIYUN_SIGN_NAME)      missing.push('ALIYUN_SMS_SIGN_NAME（赠送签名名）');
    if (!ALIYUN_TEMPLATE_CODE)  missing.push('ALIYUN_SMS_TEMPLATE_CODE（赠送模板CODE）');
  } else {
    if (!TC_SDK_APP_ID)          missing.push('TC_SMS_SDK_APP_ID（短信应用ID）');
    if (!TC_SECRET_ID)           missing.push('TC_SECRET_ID');
    if (!TC_SECRET_KEY)          missing.push('TC_SECRET_KEY');
    if (!TC_TEMPLATE_ID)         missing.push('TC_SMS_TEMPLATE_ID（模板ID，模板未过审时为空）');
  }
  if (!CODE_PEPPER)              missing.push('CODE_PEPPER');
  if (!RDB_BASE)                 missing.push('RDB_BASE');
  if (!RDB_KEY)                  missing.push('RDB_KEY');
  if (missing.length) return notConfigured(missing);

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

  if (SMS_PROVIDER === 'aliyun') {
    // 阿里云通道：码由阿里云生成并保管，我们只落一条「发送记录」用于限流。
    // code 字段存空串 —— 绝不能存明文（这张表 anon 可读）。
    try {
      await aliyunSendCode(phone);
    } catch (e) {
      return fail(502, {
        ok: false,
        error: 'SMS_API_ERROR',
        provider: 'aliyun',
        aliyunCode: e.aliyunCode || '',
        message: e.message,
      });
    }
    await rdbInsert({ phone: phone, code: '', used: false, attempts: 0 });
    return ok({ ok: true, provider: 'aliyun' });
  }

  // 腾讯云通道：码我们自己生成，只存哈希不落明文
  const code = genCode();
  await rdbInsert({ phone: phone, code: hashCode(phone, code), used: false, attempts: 0 });

  try {
    await callSendSms(phone, code);
  } catch (e) {
    return fail(502, {
      ok: false,
      error: 'SMS_API_ERROR',
      provider: 'tencent',
      tcCode: e.tcCode || '',
      message: e.message,
    });
  }
  return ok({ ok: true, provider: 'tencent' });
}

async function handleVerify(phone, code) {
  if (!isValidPhone(phone) || !/^\d{6}$/.test(String(code || ''))) {
    return fail(400, { ok: false, error: 'INVALID_INPUT' });
  }
  if (!CODE_PEPPER || !RDB_BASE || !RDB_KEY) {
    const missing = [];
    if (!CODE_PEPPER) missing.push('CODE_PEPPER');
    if (!RDB_BASE)    missing.push('RDB_BASE');
    if (!RDB_KEY)     missing.push('RDB_KEY');
    return notConfigured(missing);
  }

  if (SMS_PROVIDER === 'aliyun') {
    // 阿里云通道：校验交给阿里云（它才有明文码）。
    // 我们的库里只有发送记录，没有码可比对 —— 这正是「明文不落库」的好处。
    let passed = false;
    try {
      passed = await aliyunVerifyCode(phone, code);
    } catch (e) {
      // 阿里云返回 UNKNOWN 表示「码不匹配」，属于用户输错，不是服务异常。
      // 其余错误码（配额、参数等）才当作异常抛出。
      const code2 = e.aliyunCode || '';
      const isMismatch = code2 === 'ISV_MOBILE_NOT_EXIST' || code2 === 'UNKNOWN';
      if (!isMismatch) {
        return fail(502, {
          ok: false,
          error: 'SMS_API_ERROR',
          provider: 'aliyun',
          aliyunCode: code2,
          message: e.message,
        });
      }
      passed = false;
    }

    // 校验通过后，把该手机号的未用发送记录标记掉（清理 + 防重放）
    if (passed) {
      const rows = await rdbGet(
        'select=id&phone=eq.' + encodeURIComponent(phone) + '&used=eq.false',
      );
      for (const row of rows) {
        try {
          await rdbPatch(row.id, { used: true });
        } catch (e) {
          /* 单条失败不影响整体结果 */
        }
      }
    }
    return ok({ ok: passed, provider: 'aliyun' });
  }

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
      out = ok({
        ok: true,
        pong: true,
        ts: Date.now(),
        provider: SMS_PROVIDER,
        // 各通道的关键配置是否就绪（只回布尔，不回密钥内容）
        aliyunReady: !!(ALIYUN_AK && ALIYUN_SK && ALIYUN_SIGN_NAME && ALIYUN_TEMPLATE_CODE),
        tencentReady: !!(TC_SDK_APP_ID && TC_SECRET_ID && TC_SECRET_KEY && TC_TEMPLATE_ID),
      });
    } else if (action === 'send') {
      const limited = checkIpRate(clientIp(req));
      if (limited) {
        out = limited;
      } else {
        out = await handleSend(phone);
      }
    } else if (action === 'verify') {
      // verify 也限流：否则可暴力枚举 6 位码（100 万组合）
      const limited = checkIpRate(clientIp(req) + ':v');
      if (limited) {
        out = limited;
      } else {
        out = await handleVerify(phone, code);
      }
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
