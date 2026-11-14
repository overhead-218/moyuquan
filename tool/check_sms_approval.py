# -*- coding: utf-8 -*-
"""查腾讯云短信签名/模板的审核状态（只读，不发短信不扣费）。

需要 TC_SECRET_ID / TC_SECRET_KEY。凭证只从环境变量或 cloudbaserc.json 读，
**不会打印明文**。走云 API 官方接口 v20210111。

用法：
    export TC_SECRET_ID=AKIDxxxx
    export TC_SECRET_KEY=xxxx
    python tool/check_sms_approval.py
"""
import hashlib
import hmac
import io
import json
import os
import random
import string
import sys
import time
import urllib.parse
import urllib.request

ENV = 'moyuquan-d5g0pvpcw55f8a62e'
SDK_APP_ID = '1401192900'
HOST = 'sms.tencentcloudapi.com'
SERVICE = 'sms'
VERSION = '2021-01-11'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

GREEN, RED, YEL, OFF = '\033[92m', '\033[91m', '\033[93m', '\033[0m'

# 审核状态码 → 中文
SIGN_STATUS = {
    '0': '未提交', '1': '审核中', '2': '审核通过', '3': '审核未通过',
    '4': '待审核',
}
TPL_STATUS = {
    '0': '未提交', '1': '审核中', '2': '审核通过', '3': '审核未通过',
    '4': '待审核',
}


def read_creds():
    sid = os.environ.get('TC_SECRET_ID', '')
    skey = os.environ.get('TC_SECRET_KEY', '')
    if sid and skey:
        return sid, skey
    p = os.path.join(ROOT, 'cloudbaserc.json')
    if os.path.exists(p):
        cfg = json.load(io.open(p, encoding='utf-8'))
        for f in cfg.get('functions', []):
            if f.get('name') == 'sms':
                ev = f.get('envVariables', {}) or {}
                sid = sid or ev.get('TC_SECRET_ID', '')
                skey = skey or ev.get('TC_SECRET_KEY', '')
    return sid, skey


def tc_call(action, params, sid, skey):
    """腾讯云 API 3.0 签名（TC3-HMAC-SHA256）"""
    host = HOST
    service = SERVICE
    timestamp = int(time.time())
    date = time.strftime('%Y-%m-%d', time.gmtime(timestamp))

    canonical_headers = f'content-type:application/json; charset=utf-8\nhost:{host}\n'
    signed_headers = 'content-type;host'
    payload = json.dumps(params, ensure_ascii=False)
    canonical_request = (
        f'POST\n/\n\n{canonical_headers}\n{signed_headers}\n'
        f'{hashlib.sha256(payload.encode()).hexdigest()}')

    def _hmac(k, m):
        return hmac.new(k, m.encode('utf-8'), hashlib.sha256).digest()

    cred = f'TC3-HMAC-SHA256\n{timestamp}\n{date}/sms/tc3_request\n' \
           f'{hashlib.sha256(canonical_request.encode()).hexdigest()}'
    secret_date = _hmac(('TC3' + skey).encode(), date)
    secret_service = _hmac(secret_date, service)
    secret_signing = _hmac(secret_service, 'tc3_request')
    signature = hmac.new(secret_signing, cred.encode(), hashlib.sha256).hexdigest()

    authorization = (
        f'TC3-HMAC-SHA256 Credential={sid}/{date}/sms/tc3_request, '
        f'SignedHeaders={signed_headers}, Signature={signature}')
    headers = {
        'Authorization': authorization,
        'Content-Type': 'application/json; charset=utf-8',
        'Host': host,
        'X-TC-Action': action,
        'X-TC-Version': VERSION,
        'X-TC-Timestamp': str(timestamp),
        'X-TC-Region': 'ap-guangzhou',
    }
    req = urllib.request.Request(f'https://{host}', data=payload.encode(),
                                 headers=headers, method='POST')
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.loads(r.read().decode())
    except Exception as e:
        body = ''
        if hasattr(e, 'read'):
            try:
                body = e.read().decode()[:400]
            except Exception:
                pass
        return {'ok': False, 'err': str(e)[:200], 'body': body}


def main():
    sid, skey = read_creds()
    if not sid or not skey:
        print(f'{RED}没有腾讯云凭证{OFF}\n')
        print('  需要 TC_SECRET_ID / TC_SECRET_KEY 才能查审核状态。')
        print('  两种填法（都不会泄露给别人）：')
        print('   1) 环境变量：')
        print('      export TC_SECRET_ID=AKIDxxxxxxxx')
        print('      export TC_SECRET_KEY=xxxxxxxx')
        print('   2) 直接填进 cloudbaserc.json 的 sms 函数 envVariables')
        print(f'\n  获取入口：腾讯云控制台 → 访问管理 → API 密钥管理')
        return 1

    print(f'凭证：SecretId {sid[:6]}…{sid[-4:]}\n')
    print('=' * 60)
    print(' 1. 短信签名审核状态')
    print('=' * 60)
    r = tc_call('DescribeSmsSignList', {'SmsSdkAppId': SDK_APP_ID, 'Limit': 20},
                sid, skey)
    if r.get('Response', {}).get('Error'):
        e = r['Response']['Error']
        print(f"{RED}✗ 接口报错 {e.get('Code')}{OFF}: {e.get('Message')}")
        if 'AuthFailure' in str(e.get('Code')):
            print('  → SecretId/SecretKey 不对，或该密钥没有短信权限')
        return 1
    signs = r['Response'].get('DescribeSmsSignListStatusSet', [])
    if not signs:
        print(f'{YEL}没有任何签名{OFF} —— 还没申请。请到：')
        print('  腾讯云控制台 → 短信 → 国内短信 → 签名管理 → 新增签名')
        print('  签名内容填「摸鱼圈」（须与 App 名一致，苹果审核要求）')
    for s in signs:
        st = str(s.get('Status'))
        mark = f'{GREEN}✓{OFF}' if st == '2' else f'{YEL}!{OFF}'
        print(f"  {mark} {s.get('SignName', '?')}  [{SIGN_STATUS.get(st, st)}]")
        if st == '3' and s.get('RejectedReason'):
            print(f"      未通过原因：{s['RejectedReason']}")

    print()
    print('=' * 60)
    print(' 2. 验证码模板审核状态')
    print('=' * 60)
    r = tc_call('DescribeSmsTemplateList', {'SmsSdkAppId': SDK_APP_ID, 'Limit': 50},
                sid, skey)
    tpls = r.get('Response', {}).get('DescribeSmsTemplateStatusSet', [])
    if not tpls:
        print(f'{YEL}没有任何模板{OFF} —— 还没申请。请到：')
        print('  国内短信 → 模板管理 → 新增模板')
        print('  模板内容必须一字不差（与 docs/短信开通清单.md 保持一致）：')
        print('  您的验证码为{1}，{2}分钟内有效，请勿向他人泄露。如非本人操作请忽略本条短信。')
    for t in tpls:
        st = str(t.get('Status'))
        mark = f'{GREEN}✓{OFF}' if st == '2' else f'{YEL}!{OFF}'
        name = (t.get('TemplateName') or '')[:16]
        print(f"  {mark} ID={t.get('TemplateId')} {name} [{TPL_STATUS.get(st, st)}]")
        if st == '3' and t.get('RejectedReason'):
            print(f"      未通过原因：{t['RejectedReason']}")

    approved_sign = [s for s in signs if str(s.get('Status')) == '2']
    approved_tpl = [t for t in tpls if str(t.get('Status')) == '2']
    print()
    print('=' * 60)
    if approved_sign and approved_tpl:
        print(f'{GREEN}✓ 签名和模板都已过审{OFF} —— 可以直接收尾：')
        print(f'    python tool/finish_sms_setup.py')
        print(f'  模板 ID 填：{approved_tpl[0].get("TemplateId")}')
    elif approved_sign:
        print(f'{GREEN}✓ 签名已过审{OFF}，但模板还没有通过的 → 去申请模板')
    elif approved_tpl:
        print(f'{GREEN}✓ 模板已过审{OFF}，但签名还没有通过的 → 去申请签名')
    else:
        print(f'{YEL}!签名和模板都还没过审{OFF} —— 等审核通过后再收尾')
    print('=' * 60)
    return 0


if __name__ == '__main__':
    sys.exit(main())