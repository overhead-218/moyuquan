# -*- coding: utf-8 -*-
"""短信上线收尾：填凭证 → 部署云函数 → 实测发码 → 自检。

为什么需要这个：过审后要手工改 cloudbaserc.json、部署云函数、真机验证，
容易漏步骤或填错列名。本脚本把这些串成一条命令，并且**每步都实测校验**，
不会「工具说成功」就当真。

用法（推荐）：
    # 不带参数进入交互模式，逐项提示输入，密钥不回显
    python tool/finish_sms_setup.py

    # 或从环境变量读（适合 CI）
    export TC_SECRET_ID=AKIDxxxx
    export TC_SECRET_KEY=xxxx
    export TC_SMS_TEMPLATE_ID=1234567
    python tool/finish_sms_setup.py --non-interactive

检查当前状态（不改任何东西）：
    python tool/finish_sms_setup.py --check
"""
import argparse
import getpass
import io
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENV = 'moyuquan-d5g0pvpcw55f8a62e'
REGION = 'ap-shanghai'
APPID = '1305016020'
SMS_URL = f'https://{ENV}-{APPID}.{REGION}.app.tcloudbase.com/sms'
SECRETS = ('cloudbaserc.json', 'sms_verify_secret.json', '.env')

GREEN, RED, YEL, OFF = '\033[92m', '\033[91m', '\033[93m', '\033[0m'


def sh(cmd, env=None):
    e = dict(os.environ, MSYS_NO_PATHCONV='1', MSYS2_ARG_CONV_EXCL='*')
    if env:
        e.update(env)
    if isinstance(cmd, list):
        cmd = ' '.join(f'"{c}"' if ' ' in c else c for c in cmd)
    p = subprocess.run(cmd, capture_output=True, text=True, shell=True,
                       encoding='utf-8', errors='replace', env=e)
    return (p.stdout or '') + (p.stderr or '')


def step(n, msg):
    print(f'\n[{n}] {msg}')


def ok(msg):
    print(f'  {GREEN}✓{OFF} {msg}')


def bad(msg):
    print(f'  {RED}✗{OFF} {msg}')


def warn(msg):
    print(f'  {YEL}!{OFF} {msg}')


# ── 读取当前已填的凭证 ─────────────────────────────
def read_env_vars():
    """从 cloudbaserc.json 读 sms 函数的环境变量（不打印密钥明文）"""
    p = os.path.join(ROOT, 'cloudbaserc.json')
    cfg = json.load(io.open(p, encoding='utf-8'))
    for f in cfg.get('functions', []):
        if f.get('name') == 'sms':
            return f.get('envVariables', {}) or {}
    return {}


def mask(v):
    if not v:
        return '(空)'
    v = str(v)
    return f'{v[:4]}…{v[-4:]} (len={len(v)})'


def collect(provider='aliyun'):
    """收集凭证值：优先环境变量 → 已填的 cloudbaserc → 交互输入"""
    cur = read_env_vars()
    got = {}

    if provider == 'aliyun':
        fields = (
            ('ALIYUN_ACCESS_KEY_ID', '阿里云 AccessKey ID（形如 LTAI5t…）'),
            ('ALIYUN_ACCESS_KEY_SECRET', '阿里云 AccessKey Secret（30 位左右）'),
            ('ALIYUN_SMS_SIGN_NAME', '赠送签名名（控制台「短信认证参数管理」里抄）'),
            ('ALIYUN_SMS_TEMPLATE_CODE', '赠送模板 CODE（同上，一般是数字如 100001）'),
        )
    else:
        fields = (
            ('TC_SECRET_ID', '腾讯云 SecretId（AKID 开头）'),
            ('TC_SECRET_KEY', '腾讯云 SecretKey'),
            ('TC_SMS_TEMPLATE_ID', '短信模板 ID（纯数字）'),
        )

    for key, prompt in fields:
        v = os.environ.get(key) or cur.get(key) or ''
        if not v and not os.environ.get('NO_INPUT'):
            print(f'\n  {prompt}')
            v = getpass.getpass('  > ').strip()
        got[key] = v.strip()

    got['SMS_PROVIDER'] = provider
    # 阿里云通道：区域默认 ap-southeast-1；腾讯云通道沿用已有配置
    got['ALIYUN_SMS_REGION'] = cur.get('ALIYUN_SMS_REGION') or 'ap-southeast-1'
    got['TC_SMS_SDK_APP_ID'] = cur.get('TC_SMS_SDK_APP_ID') or '1401192900'
    got['TC_SMS_SIGN_NAME'] = cur.get('TC_SMS_SIGN_NAME') or '摸鱼圈'
    got['TC_SMS_REGION'] = cur.get('TC_SMS_REGION') or 'ap-guangzhou'
    return cur, got


# ── 校验 ───────────────────────────────────────────
def validate(got, provider='aliyun'):
    errs = []
    if provider == 'aliyun':
        ak = got.get('ALIYUN_ACCESS_KEY_ID', '')
        sk = got.get('ALIYUN_ACCESS_KEY_SECRET', '')
        sign = got.get('ALIYUN_SMS_SIGN_NAME', '')
        tpl = got.get('ALIYUN_SMS_TEMPLATE_CODE', '')
        if not ak:
            errs.append('ALIYUN_ACCESS_KEY_ID 为空')
        elif not ak.startswith('LTAI'):
            errs.append(f'ALIYUN_ACCESS_KEY_ID 格式不像（应形如 LTAI5t…，当前 {ak[:8]}…）')
        if not sk:
            errs.append('ALIYUN_ACCESS_KEY_SECRET 为空')
        elif len(sk) < 20:
            errs.append(f'ALIYUN_ACCESS_KEY_SECRET 长度只有 {len(sk)}，明显不完整')
        if not sign:
            errs.append('ALIYUN_SMS_SIGN_NAME 为空（控制台「短信认证参数管理」→ 签名配置里抄）')
        if not tpl:
            errs.append('ALIYUN_SMS_TEMPLATE_CODE 为空（控制台「短信认证参数管理」→ 模板配置里抄）')
        return errs

    sid, skey, tid = (got.get('TC_SECRET_ID'), got.get('TC_SECRET_KEY'),
                      got.get('TC_SMS_TEMPLATE_ID'))
    if not sid:
        errs.append('TC_SECRET_ID 为空')
    elif not sid.startswith('AKID'):
        errs.append(f'TC_SECRET_ID 格式不对（应以 AKID 开头，当前 {sid[:6]}…）')
    if not skey:
        errs.append('TC_SECRET_KEY 为空')
    elif len(skey) < 20:
        errs.append(f'TC_SECRET_KEY 长度只有 {len(skey)}，明显不完整')
    if not tid:
        errs.append('TC_SECRET_ID 为空' if not sid else 'TC_SMS_TEMPLATE_ID 为空')
    elif not tid.isdigit():
        errs.append(f'TC_SMS_TEMPLATE_ID 应为纯数字，当前 {tid[:10]}…')
    return errs


# ── 写配置 ─────────────────────────────────────────
def write_config(cur, got, provider='aliyun'):
    p = os.path.join(ROOT, 'cloudbaserc.json')
    raw = io.open(p, encoding='utf-8').read()
    cfg = json.loads(raw)
    for f in cfg['functions']:
        if f.get('name') != 'sms':
            continue
        ev = f.setdefault('envVariables', {})
        ev['SMS_PROVIDER'] = provider
        if provider == 'aliyun':
            ev['ALIYUN_ACCESS_KEY_ID'] = got['ALIYUN_ACCESS_KEY_ID']
            ev['ALIYUN_ACCESS_KEY_SECRET'] = got['ALIYUN_ACCESS_KEY_SECRET']
            ev['ALIYUN_SMS_SIGN_NAME'] = got['ALIYUN_SMS_SIGN_NAME']
            ev['ALIYUN_SMS_TEMPLATE_CODE'] = got['ALIYUN_SMS_TEMPLATE_CODE']
            ev['ALIYUN_SMS_REGION'] = got['ALIYUN_SMS_REGION']
            show = ('ALIYUN_ACCESS_KEY_ID', 'ALIYUN_ACCESS_KEY_SECRET',
                    'ALIYUN_SMS_SIGN_NAME', 'ALIYUN_SMS_TEMPLATE_CODE',
                    'ALIYUN_SMS_REGION')
        else:
            ev['TC_SECRET_ID'] = got['TC_SECRET_ID']
            ev['TC_SECRET_KEY'] = got['TC_SECRET_KEY']
            ev['TC_SMS_SDK_APP_ID'] = got['TC_SMS_SDK_APP_ID']
            ev['TC_SMS_SIGN_NAME'] = got['TC_SMS_SIGN_NAME']
            ev['TC_SMS_TEMPLATE_ID'] = got['TC_SMS_TEMPLATE_ID']
            ev['TC_SMS_REGION'] = got['TC_SMS_REGION']
            show = ('TC_SECRET_ID', 'TC_SECRET_KEY', 'TC_SMS_TEMPLATE_ID',
                    'TC_SMS_SDK_APP_ID', 'TC_SMS_SIGN_NAME')
    io.open(p, 'w', encoding='utf-8').write(
        json.dumps(cfg, ensure_ascii=False, indent=2) + '\n')
    ok(f'已写入 cloudbaserc.json（SMS_PROVIDER={provider}）')
    for k in show:
        print(f'      {k} = {mask(got.get(k))}')


# ── 探测云函数 ─────────────────────────────────────
def probe(action='ping', phone=None, code=None):
    try:
        if action == 'ping':
            req = urllib.request.Request(SMS_URL + '?action=ping')
        else:
            body = json.dumps({'action': action, 'phone': phone,
                               'code': code}).encode()
            req = urllib.request.Request(
                SMS_URL, data=body, method='POST',
                headers={'Content-Type': 'application/json'})
        with urllib.request.urlopen(req, timeout=40) as r:
            return r.status, json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode())
        except Exception:
            return e.code, {}
    except Exception as e:
        return -1, {'err': str(e)[:150]}


def check_mode():
    step(0, '当前状态体检')
    ev = read_env_vars()
    provider = (ev.get('SMS_PROVIDER') or 'aliyun').lower()
    print(f'  当前通道  : {provider}')
    if provider == 'aliyun':
        print(f"  AccessKey : {mask(ev.get('ALIYUN_ACCESS_KEY_ID'))}")
        print(f"  Secret    : {mask(ev.get('ALIYUN_ACCESS_KEY_SECRET'))}")
        print(f"  赠送签名  : {mask(ev.get('ALIYUN_SMS_SIGN_NAME'))}")
        print(f"  赠送模板  : {mask(ev.get('ALIYUN_SMS_TEMPLATE_CODE'))}")
    else:
        print(f"  SecretId  : {mask(ev.get('TC_SECRET_ID'))}")
        print(f"  SecretKey : {mask(ev.get('TC_SECRET_KEY'))}")
        print(f"  模板ID    : {mask(ev.get('TC_SMS_TEMPLATE_ID'))}")
        print(f"  SdkAppId  : {mask(ev.get('TC_SMS_SDK_APP_ID'))}")
        print(f"  签名      : {mask(ev.get('TC_SMS_SIGN_NAME'))}")

    code, body = probe('ping')
    print(f'\n  云函数 ping → {code} {body}')
    if body.get('pong'):
        ok('云函数在跑（HTTP 型，域名带 APPID 是对的）')
    if body.get('provider'):
        ok(f'云函数当前通道 = {body.get("provider")}')
        if body.get('provider') != provider:
            warn(f'⚠️ 线上通道({body.get("provider")}) 与配置({provider}) 不一致 '
                 '—— 改完 cloudbaserc.json 必须重新 deploy 才生效')

    code, body = probe('send', '13800138000')
    err = body.get('error')
    print(f'  云函数 send → {code} error={err}')
    missing = body.get('missing')
    if missing:
        warn('云函数逐项报告缺：' + '、'.join(str(m) for m in missing))
    if err == 'SMS_NOT_CONFIGURED':
        warn('尚未配置凭证 —— 需要先过审签名/模板并填 3 个值')
    elif err in ('TOO_FREQUENT', 'DAILY_LIMIT'):
        warn('凭证已生效！当前是限流（说明请求真的走到腾讯云了）')
    elif code == 200 and body.get('ok'):
        ok('凭证已生效，且能真实发码')

    # 数据库侧：SQL 用【双引号】包裹传给 --sql。
    # 实测：单引号包裹会被 cmd 吃掉前导单引号，报 SQLSTATE 42601 unterminated quoted string。
    def query(sql):
        # 注意：SQL 只能包【一层】双引号。sh() 会给含空格的参数自动加引号，
        # 这里必须绕开 sh() 直接拼命令，否则变成 ""select ..."" 被 cmd 拒。
        return sh(f'tcb.cmd db execute -e {ENV} --sql "{sql}"')

    out = query("select string_agg(privilege_type, ',') as p "
                "from information_schema.role_table_grants "
                "where table_name='sms_verify_codes' and grantee='anon'")
    for need in ('INSERT', 'SELECT', 'UPDATE'):
        if need in out:
            ok(f'anon 对 sms_verify_codes 有 {need} 权限')
        else:
            bad(f'anon 缺 {need} 权限 → 执行 sql/schema_sms_grants_v2.sql')
            print('  ' + out.strip()[-160:])
    return ev


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只体检，不改动')
    ap.add_argument('--non-interactive', action='store_true')
    ap.add_argument('--phone', help='真实要测试的手机号（发码测试用）')
    ap.add_argument('--provider', choices=['aliyun', 'tencent'], default='aliyun',
                    help='用哪条通道（默认 aliyun）')
    a = ap.parse_args()

    print('=' * 62)
    print(' 摸鱼圈 · 短信上线收尾')
    print('=' * 62)

    if a.check:
        check_mode()
        return 0

    provider = a.provider
    if os.environ.get('NO_INPUT') or a.non_interactive:
        os.environ['NO_INPUT'] = '1'

    cur = read_env_vars()
    if provider == 'aliyun':
        filled_before = all([
            cur.get('ALIYUN_ACCESS_KEY_ID'), cur.get('ALIYUN_ACCESS_KEY_SECRET'),
            cur.get('ALIYUN_SMS_SIGN_NAME'), cur.get('ALIYUN_SMS_TEMPLATE_CODE')
        ])
        env_probe = 'ALIYUN_ACCESS_KEY_ID'
    else:
        filled_before = all([
            cur.get('TC_SECRET_ID'), cur.get('TC_SECRET_KEY'),
            cur.get('TC_SMS_TEMPLATE_ID')
        ])
        env_probe = 'TC_SECRET_ID'
    if filled_before and not a.non_interactive and not os.environ.get(env_probe):
        warn('cloudbaserc.json 里似乎已有值，本次会覆盖。继续？y/N')
        if input('  > ').strip().lower() not in ('y', 'yes'):
            print('已取消')
            return 1

    step(1, f'收集凭证（通道：{provider}）')
    _, got = collect(provider)
    errs = validate(got, provider)
    if errs:
        bad('值不合法，已中止（未改动任何文件）：')
        for e in errs:
            print(f'      - {e}')
        return 1
    ok(f'{4 if provider == "aliyun" else 3} 个值格式校验通过')

    step(2, '写入 cloudbaserc.json')
    write_config(cur, got, provider)

    step(3, '部署云函数 sms')
    out = sh(['tcb.cmd', 'fn', 'deploy', 'sms', '--env-id', ENV, '--force'])
    if 'Deploy' in out or 'Success' in out or 'success' in out or '部署' in out:
        ok('部署命令已执行')
    else:
        warn('部署输出异常，请人工确认：')
        print('\n'.join(out.strip().splitlines()[-8:]))

    step(4, '实测云函数')
    code, body = probe('ping')
    if body.get('pong'):
        ok(f'ping 正常（{code}）')
        if body.get('provider'):
            ok(f'线上通道 = {body.get("provider")}')
            if body.get('provider') != provider:
                bad(f'通道不匹配！期望 {provider}，实际 {body.get("provider")}')
    else:
        bad(f'ping 异常 {code} {body} —— 部署可能没成功')

    test_phone = a.phone or '13800138000'
    code, body = probe('send', test_phone)
    err = body.get('error')
    print(f'  send({test_phone}) → {code}')
    print(f'  返回：{json.dumps(body, ensure_ascii=False)}')

    if err == 'SMS_NOT_CONFIGURED':
        bad('仍报未配置 → 说明环境变量没传到云函数')
        print('  排查：tcb fn log sms --env-id ' + ENV + '  看是否读到变量')
        print('  注意：cloudbaserc.json 改了必须重新 deploy 才会生效')
    elif err == 'TOO_FREQUENT':
        ok('凭证生效（60 秒重发间隔命中，说明请求真的走到了服务商）')
    elif err == 'DAILY_LIMIT':
        ok('凭证生效（今日次数已用完，属正常）')
    elif err == 'IP_RATE_LIMITED':
        warn('触发了 IP 频控（说明请求到达了云函数，但被限流）')
    elif body.get('ok'):
        ok('验证码已真实发送，请查收短信')
    elif err == 'SMS_API_ERROR':
        warn('服务商 API 报错 —— 凭证能读到，但签名/模板/配额有问题')
        print(f'  code    : {body.get("aliyunCode") or body.get("tcCode")}')
        print(f'  message : {body.get("message")}')
    else:
        warn('未知返回，请对照上面的 JSON 判断')

    step(5, '还差的两件事（脚本无法代劳）')
    print('  1) 编辑 lib/services/sms_service.dart：')
    print('       static const bool _isMockMode = true;  →  改成 false')
    print('     然后重新构建部署：')
    print('       flutter build web --release')
    print('       MSYS_NO_PATHCONV=1 tcb.cmd hosting deploy '
          '"C:\\Dev\\fishing_app_new\\build\\web" "/" -e ' + ENV)
    print('  2) 用真机号跑一遍：发送 → 收到短信 → 填码 → 登录')

    print('\n' + '=' * 62)
    return 0


if __name__ == '__main__':
    sys.exit(main())