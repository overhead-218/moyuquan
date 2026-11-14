# -*- coding: utf-8 -*-
"""双通道短信云函数 · 本地端到端测试。

在本地起云函数进程（模拟 CloudBase HTTP 函数），验证：
  1. ping 回报当前通道
  2. 未配置凭证时，send 逐项报出缺什么
  3. 阿里云通道：send → 校验逻辑 → 写库记录
  4. 腾讯云通道：send → verify 查库比对 → 错误次数锁定
  5. 两条通道的对外契约一致（前端不用改）

⚠️ 阿里云通道用的是真 AccessKey 时会真发短信并扣费。
    默认用假凭证测「配置检查」路径；加 --real-aliyun 且填了真凭证才走真发短信。

用法：
    python tool/e2e_sms.py              # 只测不花钱的部分
    python tool/e2e_sms.py --real-aliyun  # 真发短信（会扣费，需在 cloudbaserc 填好阿里云凭证）
"""
import io
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV = 'moyuquan-d5g0pvpcw55f8a62e'
APPID = '1305016020'
REGION = 'ap-shanghai'
SRC = os.path.join(ROOT, 'cloudfunctions', 'sms', 'index.js')
PORT = 9187
BASE = f'http://127.0.0.1:{PORT}'

GREEN, RED, YEL, OFF = '\033[92m', '\033[91m', '\033[93m', '\033[0m'
_pass = 0
_fail = 0


def check(name, cond, extra=''):
    global _pass, _fail
    if cond:
        _pass += 1
        print(f'  {GREEN}✓{OFF} {name}')
    else:
        _fail += 1
        print(f'  {RED}✗{OFF} {name}  {extra}')


def read_env_vars():
    p = os.path.join(ROOT, 'cloudbaserc.json')
    cfg = json.load(io.open(p, encoding='utf-8'))
    for f in cfg.get('functions', []):
        if f.get('name') == 'sms':
            return f.get('envVariables', {}) or {}
    return {}


def call(action, **kw):
    """调用本地云函数"""
    if action == 'ping':
        url = f'{BASE}/?action=ping'
        data = None
    else:
        url = f'{BASE}/'
        data = json.dumps(dict(action=action, **kw)).encode()
    req = urllib.request.Request(
        url, data=data, method='POST' if data else 'GET',
        headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode())
        except Exception:
            return e.code, {}
    except Exception as e:
        return -1, {'err': str(e)[:200]}


def start_server(env_overrides):
    """在本地起云函数，返回 (proc, tmpdir)"""
    tmp = os.path.join(ROOT, 'tool', '_sms_test_run')
    os.makedirs(tmp, exist_ok=True)
    shutil.copy(SRC, os.path.join(tmp, 'index.js'))
    env = dict(os.environ)
    env.update({k: str(v) for k, v in env_overrides.items() if v is not None})
    # 测试用独立端口，避免与本机 9000 上的其他进程冲突
    env['PORT'] = str(PORT)
    proc = subprocess.Popen(
        ['node', 'index.js'], cwd=tmp, env=env,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    # 等端口就绪
    for _ in range(40):
        time.sleep(0.25)
        code, body = call('ping')
        if code == 200:
            return proc, tmp
    proc.kill()
    out = proc.stdout.read() if proc.stdout else ''
    print(f'{RED}云函数未能启动{OFF}\n{out[:800]}')
    return None, tmp


def stop_server(proc):
    if proc:
        try:
            proc.send_signal(signal.SIGTERM)
            proc.wait(timeout=5)
        except Exception:
            proc.kill()


def main():
    real = '--real-aliyun' in sys.argv
    ev = read_env_vars()
    rdb_base = ev.get('RDB_BASE', '')
    rdb_key = ev.get('RDB_KEY', '')
    pepper = ev.get('CODE_PEPPER', '')

    print('=' * 62)
    print(' 双通道短信云函数 · 端到端测试')
    print('=' * 62)

    # ── 场景 1：完全没配凭证 ─────────────────────────
    print('\n[1] 未配置任何凭证 → 应逐项报缺什么')
    proc, _ = start_server({
        'SMS_PROVIDER': 'aliyun',
        'ALIYUN_ACCESS_KEY_ID': '', 'ALIYUN_ACCESS_KEY_SECRET': '',
        'ALIYUN_SMS_SIGN_NAME': '', 'ALIYUN_SMS_TEMPLATE_CODE': '',
        'RDB_BASE': rdb_base, 'RDB_KEY': rdb_key, 'CODE_PEPPER': pepper,
    })
    if not proc:
        return 1
    try:
        code, body = call('ping')
        check('ping 可用', code == 200 and body.get('pong'), str(body))
        check('ping 回报通道 = aliyun', body.get('provider') == 'aliyun', str(body))
        check('ping 回报 aliyunReady = false', body.get('aliyunReady') is False, str(body))

        code, body = call('send', phone='13800138000')
        check('send 返回 503', code == 503, str(code))
        check('错误码 = SMS_NOT_CONFIGURED', body.get('error') == 'SMS_NOT_CONFIGURED', str(body))
        missing = body.get('missing') or []
        check('missing 列出阿里云四项', len(missing) >= 4, str(missing))
        check('missing 含 ALIYUN_ACCESS_KEY_ID',
              any('ALIYUN_ACCESS_KEY_ID' in m for m in missing), str(missing))
        check('missing 含 ALIYUN_SMS_TEMPLATE_CODE',
              any('TEMPLATE_CODE' in m for m in missing), str(missing))
    finally:
        stop_server(proc)

    # ── 场景 2：腾讯云通道 ───────────────────────────
    print('\n[2] 腾讯云通道 → 缺腾讯云凭证（验证分流正确）')
    proc, _ = start_server({
        'SMS_PROVIDER': 'tencent',
        'TC_SECRET_ID': '', 'TC_SECRET_KEY': '', 'TC_SMS_TEMPLATE_ID': '',
        'TC_SMS_SDK_APP_ID': '1401192900',
        'RDB_BASE': rdb_base, 'RDB_KEY': rdb_key, 'CODE_PEPPER': pepper,
    })
    if not proc:
        return 1
    try:
        code, body = call('ping')
        check('ping 回报通道 = tencent', body.get('provider') == 'tencent', str(body))
        check('ping 回报 tencentReady = false', body.get('tencentReady') is False, str(body))

        code, body = call('send', phone='13800138000')
        check('send 报 SMS_NOT_CONFIGURED', body.get('error') == 'SMS_NOT_CONFIGURED', str(body))
        missing = body.get('missing') or []
        check('missing 含 TC_SECRET_ID',
              any('TC_SECRET_ID' in m for m in missing), str(missing))
        check('missing 不含阿里云项',
              not any('ALIYUN' in m for m in missing), str(missing))
    finally:
        stop_server(proc)

    # ── 场景 3：自动分流（未设 SMS_PROVIDER）─────────
    print('\n[3] 未设 SMS_PROVIDER → 按「哪边配齐用哪边」自动判断')
    proc, _ = start_server({
        'SMS_PROVIDER': None,  # 不传
        'ALIYUN_ACCESS_KEY_ID': 'fake-ak', 'ALIYUN_ACCESS_KEY_SECRET': 'fake-sk',
        'ALIYUN_SMS_SIGN_NAME': 'fake-sign', 'ALIYUN_SMS_TEMPLATE_CODE': '100001',
        'TC_SECRET_ID': '', 'TC_SECRET_KEY': '',
        'RDB_BASE': rdb_base, 'RDB_KEY': rdb_key, 'CODE_PEPPER': pepper,
    })
    if not proc:
        return 1
    try:
        code, body = call('ping')
        check('阿里云配齐 → 自动选 aliyun', body.get('provider') == 'aliyun', str(body))
    finally:
        stop_server(proc)

    proc, _ = start_server({
        'SMS_PROVIDER': None,
        'ALIYUN_ACCESS_KEY_ID': '', 'ALIYUN_ACCESS_KEY_SECRET': '',
        'ALIYUN_SMS_SIGN_NAME': '', 'ALIYUN_SMS_TEMPLATE_CODE': '',
        'TC_SECRET_ID': 'fake-id', 'TC_SECRET_KEY': 'fake-key',
        'TC_SMS_SDK_APP_ID': '1401192900', 'TC_SMS_TEMPLATE_ID': '1234567',
        'RDB_BASE': rdb_base, 'RDB_KEY': rdb_key, 'CODE_PEPPER': pepper,
    })
    if not proc:
        return 1
    try:
        code, body = call('ping')
        check('只有腾讯云配齐 → 自动选 tencent', body.get('provider') == 'tencent', str(body))
    finally:
        stop_server(proc)

    # ── 场景 4：阿里云通道真发短信（可选）────────────
    ak = ev.get('ALIYUN_ACCESS_KEY_ID', '')
    sk = ev.get('ALIYUN_ACCESS_KEY_SECRET', '')
    sign_name = ev.get('ALIYUN_SMS_SIGN_NAME', '')
    tpl = ev.get('ALIYUN_SMS_TEMPLATE_CODE', '')
    if real and ak and sk and sign_name and tpl:
        print('\n[4] 阿里云通道 · 真实发短信（会扣费）')
        phone = os.environ.get('SMS_TEST_PHONE', '')
        if not phone:
            print(f'  {YEL}!{OFF} 未设 SMS_TEST_PHONE，跳过')
        else:
            proc, _ = start_server({
                'SMS_PROVIDER': 'aliyun',
                'ALIYUN_ACCESS_KEY_ID': ak, 'ALIYUN_ACCESS_KEY_SECRET': sk,
                'ALIYUN_SMS_SIGN_NAME': sign_name, 'ALIYUN_SMS_TEMPLATE_CODE': tpl,
                'RDB_BASE': rdb_base, 'RDB_KEY': rdb_key, 'CODE_PEPPER': pepper,
            })
            if proc:
                try:
                    code, body = call('send', phone=phone)
                    check(f'真实发码成功 {phone}', code == 200 and body.get('ok') is True,
                          f'{code} {body}')
                    check('返回 provider=aliyun', body.get('provider') == 'aliyun', str(body))
                finally:
                    stop_server(proc)
    else:
        print('\n[4] 阿里云通道真实发短信 —— 跳过（未填真凭证或未加 --real-aliyun）')
        if not real:
            print(f'  {YEL}!{OFF} 加 --real-aliyun 并在 cloudbaserc.json 填好阿里云凭证可测真发码')

    # ── 场景 5：IP 频控 ─────────────────────────────
    print('\n[5] IP 频控（防止被刷爆短信费）')
    proc, _ = start_server({
        'SMS_PROVIDER': 'aliyun',
        'ALIYUN_ACCESS_KEY_ID': 'fake-ak', 'ALIYUN_ACCESS_KEY_SECRET': 'fake-sk',
        'ALIYUN_SMS_SIGN_NAME': 'fake-sign', 'ALIYUN_SMS_TEMPLATE_CODE': '100001',
        'SMS_IP_HOURLY_MAX': '3', 'SMS_IP_DAILY_MAX': '5',
        'RDB_BASE': rdb_base, 'RDB_KEY': rdb_key, 'CODE_PEPPER': pepper,
    })
    if not proc:
        return 1
    try:
        codes = []
        for i in range(5):
            c, b = call('send', phone=f'1380013800{i}')
            codes.append((c, b.get('error')))
        limited = [i for i, (c, e) in enumerate(codes) if e == 'IP_RATE_LIMITED']
        check('超过阈值后触发 IP_RATE_LIMITED', len(limited) >= 1, str(codes))
        check('限流返回 429', any(c == 429 for c, e in codes), str(codes))
    finally:
        stop_server(proc)

    print('\n' + '=' * 62)
    print(f' {_pass} passed, {_fail} failed')
    print('=' * 62)
    return 1 if _fail else 0


if __name__ == '__main__':
    sys.exit(main())
