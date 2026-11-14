import 'dart:convert';
import 'dart:developer' show log;
import 'dart:math' show Random;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:http/http.dart' as http;
import 'backend_config.dart';

/// 短信验证码服务
///
/// 当前通道：**阿里云短信认证服务**（免资质，免签名/模板审核，个人实名即可开通）。
///
/// 为什么不用腾讯云国内短信：账号没有营业执照，腾讯云自 2025-09-18 起
/// 不再支持个人认证自用资质，运营商也不给个人主体做签名实名报备 → 这条路走不通。
///
/// 上线前 checklist：
///   1. 阿里云开通「号码认证服务」→ 短信认证（控制台 https://dypns.console.aliyun.com/）
///      · 在「短信认证参数管理」里拿到【赠送签名名】和【赠送模板 CODE】
///   2. 创建 AccessKey ID / Secret
///   3. 填进 cloudbaserc.json 的 functions[].envVariables：
///      ALIYUN_ACCESS_KEY_ID / ALIYUN_ACCESS_KEY_SECRET /
///      ALIYUN_SMS_SIGN_NAME / ALIYUN_SMS_TEMPLATE_CODE / SMS_PROVIDER=aliyun
///   4. 部署云函数：tcb fn deploy sms --env-id <envId> --force
///      ⚠️ HTTP 型函数的访问域名必须带 APPID+地域：
///      https://{envId}-{appid}.{region}.app.tcloudbase.com/sms
///      （不带 APPID 的 {envId}.service.tcloudbase.com 对 HTTP 型函数会报 FUNCTIONS_PARAM_INVALID）
///   5. CODE_PEPPER（随机 64 位 hex，验证码哈希用盐）—— 已填好
///   6. sql/schema_sms_grants_v2.sql（列类型升级 + anon 表级授权）—— 已执行
///   7. _isMockMode 改 false，重新构建前端
///
/// 后期切换到腾讯云自有签名（拿到营业执照后）：把 SMS_PROVIDER 改成 tencent，
/// 填上 TC_* 那几个环境变量，重新部署云函数即可。**前端与数据库零改动。**
class SmsService {
  SmsService._();

  static final SmsService instance = SmsService._();

  /// ⚠️ 上线阻断项：当前 `_isMockMode = true`，短信验证码是内存生成的假码。
  ///
  ///   现状（已实测）：云函数端点可用，但返回
  ///   `{"ok":false,"error":"SMS_NOT_CONFIGURED"}`
  ///   —— 说明 `sms_verify_codes` 表已通，但**阿里云 AccessKey / 赠送签名 / 赠送模板未填**。
  ///
  ///   因此不能直接改成 false，否则所有用户都发不出验证码、无法登录。
  ///
  ///   解除条件（全部满足后，把下面改成 false）：
  ///     1. 阿里云开通号码认证服务的「短信认证」功能；
  ///     2. 在「短信认证参数管理」拿到赠送签名名与赠送模板 CODE；
  ///     3. cloudbaserc.json 填 ALIYUN_ACCESS_KEY_ID / ALIYUN_ACCESS_KEY_SECRET /
  ///        ALIYUN_SMS_SIGN_NAME / ALIYUN_SMS_TEMPLATE_CODE / SMS_PROVIDER=aliyun；
  ///     4. 重新部署云函数 `tcb fn deploy sms --env-id moyuquan-d5g0pvpcw55f8a62e --force`；
  ///     5. 控制台执行 sql/schema_sms_grants_v2.sql；
  ///     6. 用真机号验证「发送 → 收到 → 校验」全链路通过。
  ///
  ///  已做的保护（避免 mock 阶段被刷/泄露）：
  ///   - 登录页的「测试验证码」提示条改为仅 debug 构建显示，release 包不再外显假码；
  ///   - 验证码改用 Random.secure()，不再用时间戳取模（可预测且同毫秒会撞码）。
  static const bool _isMockMode = true;

  /// 界面用来判断是否显示「测试验证码」提示条。
  ///
  /// ⚠️ 真实发码后返回 false；mock 阶段也只在 debug 包返回 true，
  ///    避免 release 包把内存里的假验证码直接显示给用户（合规风险）。
  static bool get isMockMode => _isMockMode && kDebugMode;

  // 内存中的待验证验证码（仅 mock 阶段用）
  final Map<String, _PendingCode> _pending = {};

  /// 取当前手机号的 mock 验证码（仅 mock 模式，真实模式返回 null）
  String? mockCodeFor(String phone) => _isMockMode ? _pending[phone]?.code : null;

  // ─────────────────────────────────────────────
  // 发送验证码
  // ─────────────────────────────────────────────
  /// 失败抛 SmsException：InvalidPhone / TOO_FREQUENT / DAILY_LIMIT /
  /// SMS_NOT_CONFIGURED / SMS_API_ERROR / NetworkError
  Future<void> sendCode(String phone) async {
    if (!_isValidPhone(phone)) {
      throw SmsException('InvalidPhone', '手机号格式不正确');
    }

    if (_isMockMode) {
      final code = _generateCode();
      _pending[phone] = _PendingCode(code);
      // ⚠️ 不再把验证码明文打进日志（release 包日志也会被上传/收集）。
      log('[SmsService MOCK] 已生成验证码到 $phone（未真实发短信）'
          '${kDebugMode ? ' code=$code' : ''}');
      return;
    }

    final data = await _call({'action': 'send', 'phone': phone});
    if (data['ok'] != true) {
      final err = data['error']?.toString() ?? 'NetworkError';
      throw SmsException(err, _friendlyMessage(err, data));
    }
  }

  /// 把云函数返回的内部错误码翻成用户能看懂、运营能据此定位的话。
  ///
  /// ⚠️ 这里的区分很重要：以前所有失败都显示「验证码发送失败」，
  ///    而实际最常见的是**服务端配置没配完**（签名/模板/密钥没填），
  ///    用户看到"发送失败"只会反复点，运营也看不出到底缺什么。
  ///    现在把「配置未完成」和「用户操作问题」分开报。
  static String _friendlyMessage(String code, Map<String, dynamic> data) {
    final serverMsg = data['message']?.toString() ?? '';
    switch (code) {
      case 'SMS_NOT_CONFIGURED':
        // 云函数会回一个 missing 清单，直接用它做提示，运营一眼能看到缺什么
        final missing = (data['missing'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const <String>[];
        return missing.isEmpty
            ? '短信服务正在开通中，暂不能登录。可先用 Apple 登录，'
                '或稍后再试（运营已收到告警：短信签名/模板或密钥未配置）'
            : '短信服务正在开通中（缺 ${missing.join('、')}）。'
                '可先用 Apple 登录，或稍后再试';
      case 'SMS_SIGN_NOT_CONFIGURED':
      case 'SIGN_NOT_CONFIGURED':
        return '短信签名尚未审核通过，暂不能登录。可先用 Apple 登录';
      case 'SMS_TEMPLATE_NOT_CONFIGURED':
      case 'TEMPLATE_NOT_CONFIGURED':
        return '短信模板尚未审核通过，暂不能登录。可先用 Apple 登录';
      case 'INVALID_PHONE':
        return '手机号格式不正确';
      case 'TOO_FREQUENT':
        return '发送太频繁，请 ${_retryAfterSeconds(data)} 秒后再试';
      case 'DAILY_LIMIT':
        return '该手机号今日发送次数已达上限，明天再试';
      case 'IP_RATE_LIMITED':
        return '请求过于频繁，请稍后再试';
      case 'CODE_EXPIRED':
        return '验证码已过期，请重新获取';
      case 'CODE_MISMATCH':
        return '验证码不正确';
      case 'TOO_MANY_FAILS':
        return '错误次数过多，请重新获取验证码';
      case 'TOO_MANY_ATTEMPTS':
        return '错误次数过多，请重新获取验证码';
      case 'NO_CODE':
        return '请先获取验证码';
      case 'WRONG_CODE':
        return '验证码不正确';
      case 'EXPIRED':
        return '验证码已过期，请重新获取';
      case 'SMS_API_ERROR':
        // 阿里云通道会把具体错误码带回来（如配额超限、模板不存在），
        // 有具体码就显示具体信息，方便运营定位；没有就给通用文案。
        final provider = data['provider']?.toString() ?? '';
        final detail = provider == 'aliyun'
            ? (data['aliyunCode']?.toString() ?? '')
            : (data['tcCode']?.toString() ?? '');
        return detail.isNotEmpty
            ? '短信服务暂时异常（$detail），请稍后重试'
            : '短信服务暂时异常，请稍后重试';
      case 'NetworkError':
        return '网络异常，请检查网络后重试';
      default:
        return serverMsg.isNotEmpty ? serverMsg : '验证码发送失败，请稍后重试';
    }
  }

  /// 从云函数响应里取建议等待秒数（没有就默认 60）
  static int _retryAfterSeconds(Map<String, dynamic> data) {
    for (final k in ['retryAfter', 'retryAfterSeconds', 'retry_after']) {
      final v = data[k];
      if (v is num && v > 0) return v.toInt();
    }
    return 60;
  }

  // ─────────────────────────────────────────────
  // 校验验证码
  // ─────────────────────────────────────────────
  Future<bool> verifyCode(String phone, String code) async {
    if (!_isValidPhone(phone) || code.length != 6) return false;

    if (_isMockMode) {
      final p = _pending[phone];
      if (p == null) return false;
      // 验证码 10 分钟内有效
      if (DateTime.now().difference(p.createdAt).inMinutes > 10) {
        _pending.remove(phone);
        return false;
      }
      final ok = p.code == code;
      if (ok) _pending.remove(phone); // 防重放
      return ok;
    }

    final data = await _call({'action': 'verify', 'phone': phone, 'code': code});
    if (data['ok'] == true) return true;

    // 校验失败时也要区分「服务端配置没配完」和「用户验证码填错」——
    // 否则用户会以为自己码打错了，实际上是短信根本没发出去过。
    final err = data['error']?.toString() ?? 'NetworkError';
    if (_isConfigError(err)) {
      throw SmsException(err, _friendlyMessage(err, data));
    }
    // 阿里云通道：ok:false 且带 provider=aliyun → 是「码不匹配」，
    // 不是服务异常，直接返回 false 让界面提示验证码错误。
    if (data['provider']?.toString() == 'aliyun') return false;
    return false;
  }

  /// 是否属于「服务端配置未完成」类错误（不是用户操作问题）
  static bool _isConfigError(String code) => const {
        'SMS_NOT_CONFIGURED',
        'SMS_SIGN_NOT_CONFIGURED',
        'SIGN_NOT_CONFIGURED',
        'SMS_TEMPLATE_NOT_CONFIGURED',
        'TEMPLATE_NOT_CONFIGURED',
        'SMS_API_ERROR',
      }.contains(code);

  // ─────────────────────────────────────────────
  // 调用云函数（真实模式唯一通路；密钥都在云函数侧）
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>> _call(Map<String, dynamic> payload) async {
    try {
      final resp = await http
          .post(
            Uri.parse(BackendConfig.smsEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'ok': false, 'error': 'BadResponse'};
    } catch (e) {
      log('[SmsService] 云函数调用失败: $e');
      return <String, dynamic>{
        'ok': false,
        'error': 'NetworkError',
        'message': '网络异常，请稍后重试',
      };
    }
  }

  // ─────────────────────────────────────────────
  // 工具
  // ─────────────────────────────────────────────
  /// 生成 6 位验证码。
  ///
  /// ⚠️ 原实现是 `DateTime.now().millisecondsSinceEpoch % 1000000`：
  ///   1. 极可预测 —— 攻击者只要拿到发送时刻的毫秒时间戳就能算出验证码，
  ///      等于没有验证码；
  ///   2. 同一毫秒内发两个号会撞码。
  /// 现改为密码学安全随机源（Random.secure）。
  String _generateCode() {
    final rnd = Random.secure();
    return (rnd.nextInt(900000) + 100000).toString();
  }

  bool _isValidPhone(String phone) {
    // 大陆手机号：1 开头，11 位纯数字
    return RegExp(r'^1[3-9]\d{9}$').hasMatch(phone);
  }
}

/// 待验证验证码（内存，mock 阶段）
class _PendingCode {
  final String code;
  final DateTime createdAt;
  _PendingCode(this.code) : createdAt = DateTime.now();
}

/// 短信服务异常
class SmsException implements Exception {
  final String code;
  final String message;
  SmsException(this.code, this.message);
  @override
  String toString() => 'SmsException($code): $message';
}
