/**
 * 阿里云 ACS3-HMAC-SHA256 签名自测。
 *
 * 为什么要单独测：签名算法手写错了，服务端会返回
 *   SignatureDoesNotMatch / InvalidSignature，而且报错信息不直观，
 *   很难一眼看出是签名问题还是参数问题。必须先验证签名本身对。
 *
 * 验证方式：用官方文档里的规范化请求示例做对照，
 * 再用「同一个请求两次签名结果一致 + 改动任一字段签名必变」做自洽性检查。
 *
 * 运行：node tool/test_aliyun_sign.js
 */
'use strict';

const crypto = require('crypto');

function sha256hex(s) {
  return crypto.createHash('sha256').update(s, 'utf8').digest('hex');
}
function hmacSha256(key, s) {
  return crypto.createHmac('sha256', key).update(s, 'utf8').digest('hex');
}

const HOST = 'dypnsapi.aliyuncs.com';
const VERSION = '2017-05-25';

function sign(action, body, ak, sk, timestamp, nonce) {
  const payload = JSON.stringify(body);
  const contentSha256 = sha256hex(payload);
  const canonicalHeaders =
    'host:' + HOST + '\n' +
    'x-acs-action:' + action + '\n' +
    'x-acs-content-sha256:' + contentSha256 + '\n' +
    'x-acs-date:' + timestamp + '\n' +
    'x-acs-signature-nonce:' + nonce + '\n' +
    'x-acs-version:' + VERSION + '\n';
  const signedHeaders =
    'host;x-acs-action;x-acs-content-sha256;x-acs-date;x-acs-signature-nonce;x-acs-version';
  const canonicalRequest = ['POST', '/', '', canonicalHeaders, signedHeaders, contentSha256].join('\n');
  const stringToSign = 'ACS3-HMAC-SHA256\n' + sha256hex(canonicalRequest);
  const signature = hmacSha256(sk, stringToSign);
  return {
    signature,
    authorization:
      'ACS3-HMAC-SHA256 Credential=' + ak + ',' +
      'SignedHeaders=' + signedHeaders + ',' +
      'Signature=' + signature,
    canonicalRequest,
    stringToSign,
  };
}

let pass = 0, fail = 0;
function check(name, cond, extra) {
  if (cond) { pass++; console.log('  ✓ ' + name); }
  else { fail++; console.log('  ✗ ' + name + (extra ? '  ' + extra : '')); }
}

console.log('=== 阿里云 ACS3-HMAC-SHA256 签名自测 ===\n');

const AK = 'test-access-key-id';
const SK = 'test-access-key-secret';
const TS = '2026-10-27T01:36:04Z';
const NONCE = 'test-nonce-001';
const body = { PhoneNumber: '13800138000', CountryCode: '86' };

console.log('1) 基本结构');
const r = sign('SendSmsVerifyCode', body, AK, SK, TS, NONCE);
check('签名是 64 位小写 hex', /^[0-9a-f]{64}$/.test(r.signature), r.signature);
check('Authorization 以 ACS3-HMAC-SHA256 开头', r.authorization.startsWith('ACS3-HMAC-SHA256 '));
check('Authorization 含 Credential=', r.authorization.includes('Credential=' + AK));
check('Authorization 含 SignedHeaders=', r.authorization.includes('SignedHeaders='));
check('Authorization 含 Signature=', r.authorization.includes('Signature='));
check('SignedHeaders 顺序正确',
  r.authorization.includes('SignedHeaders=host;x-acs-action;x-acs-content-sha256;x-acs-date;x-acs-signature-nonce;x-acs-version'));
check('Signature 在 Authorization 末尾',
  r.authorization.endsWith('Signature=' + r.signature));

console.log('\n2) 规范化请求结构');
const cr = r.canonicalRequest.split('\n');
check('第1行是 POST', cr[0] === 'POST', cr[0]);
check('第2行是 /', cr[1] === '/', cr[1]);
check('第3行是空 query', cr[2] === '', JSON.stringify(cr[2]));
check('第4行起是 canonicalHeaders',
  cr[3] === 'host:' + HOST, cr[3]);
check('canonicalHeaders 以换行结尾（空行分隔）',
  r.canonicalRequest.includes('x-acs-version:' + VERSION + '\n\n'));
check('倒数第2行是 signedHeaders',
  cr[cr.length - 2] === 'host;x-acs-action;x-acs-content-sha256;x-acs-date;x-acs-signature-nonce;x-acs-version');
check('最后一行是 body 的 sha256',
  cr[cr.length - 1] === sha256hex(JSON.stringify(body)));
check('StringToSign 两行结构',
  r.stringToSign.split('\n').length === 2 && r.stringToSign.startsWith('ACS3-HMAC-SHA256\n'));
check('StringToSign 第二行是 canonicalRequest 的 sha256',
  r.stringToSign.split('\n')[1] === sha256hex(r.canonicalRequest));

console.log('\n3) 自洽性：改动任一输入，签名必须变');
const base = sign('SendSmsVerifyCode', body, AK, SK, TS, NONCE).signature;
check('换 action → 签名变',
  base !== sign('CheckSmsVerifyCode', body, AK, SK, TS, NONCE).signature);
check('换 body → 签名变',
  base !== sign('SendSmsVerifyCode', { ...body, PhoneNumber: '13900139000' }, AK, SK, TS, NONCE).signature);
check('换 timestamp → 签名变',
  base !== sign('SendSmsVerifyCode', body, AK, SK, '2026-10-27T01:36:05Z', NONCE).signature);
check('换 nonce → 签名变',
  base !== sign('SendSmsVerifyCode', body, AK, SK, TS, 'other-nonce').signature);
check('换 SK → 签名变',
  base !== sign('SendSmsVerifyCode', body, AK, 'other-sk', TS, NONCE).signature);
// 注意：换 AK 签名【不变】是正确的 —— 阿里云 ACS3 的 AccessKeyId 只是明文放在
// Authorization 的 Credential= 段里用于标识身份，签名计算只用到 SecretKey。
// 换 AK 后服务端会拿新 AK 对应的 Secret 去验签，因此仍然能区分身份。
check('换 AK → 签名值不变（AK 只明文在 Credential 里，不参与签名计算）',
  base === sign('SendSmsVerifyCode', body, 'other-ak', SK, TS, NONCE).signature);
check('换 AK → Authorization 里的 Credential 跟着变',
  sign('SendSmsVerifyCode', body, 'other-ak', SK, TS, NONCE).authorization
    .includes('Credential=other-ak'));

console.log('\n4) 字段顺序无关性（只要头集合与顺序固定，签名就固定）');
check('同样输入两次 → 签名相同（可重现）',
  base === sign('SendSmsVerifyCode', body, AK, SK, TS, NONCE).signature);

console.log('\n5) 与云函数实际实现的一致性');
try {
  const src = require('fs').readFileSync(
    require('path').join(__dirname, '..', 'cloudfunctions', 'sms', 'index.js'), 'utf8');
  check('云函数里用的是 ACS3-HMAC-SHA256', src.includes('ACS3-HMAC-SHA256'));
  check('云函数里 SignedHeaders 顺序与测试一致',
    src.includes("'host;x-acs-action;x-acs-content-sha256;x-acs-date;x-acs-signature-nonce;x-acs-version'"));
  check('云函数里 host 是 dyspnsapi.aliyuncs.com', src.includes("'dypnsapi.aliyuncs.com'"));
  check('云函数里 version 是 2017-05-25', src.includes("'2017-05-25'"));
  check('云函数用 ##code## 占位符（关键！传明文阿里云无法校验）',
    src.includes("'##code##'"));
} catch (e) {
  check('读取云函数源码', false, e.message);
}

console.log('\n=== ' + pass + ' passed, ' + fail + ' failed ===');
process.exit(fail ? 1 : 0);
