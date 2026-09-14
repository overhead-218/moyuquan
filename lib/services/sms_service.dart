import 'dart:convert';
import 'dart:developer' show log;
import 'package:http/http.dart' as http;
import 'backend_config.dart';

/// 短信验证码服务
///
/// 阶段一（当前，_isMockMode = true）：验证码存内存（单例），不发真实短信，界面显示测试码。
/// 阶段二（签名/模板/密钥到位后）：把 _isMockMode 改成 false ——
///   走 CloudBase 云函数 `sms`（HTTP 访问服务），由云函数持有腾讯云 SecretId/SecretKey
///   调 SendSms 并发码/校验。客户端永远不接触任何腾讯云密钥（防止反编译盗刷）。
///
/// 上线前 checklist：
///   1. 腾讯云短信签名「摸鱼圈」+ 验证码模板 审核通过 → 拿到 TemplateId
///   2. CAM 新建 SecretId / SecretKey
///   3. 填进 cloudbaserc.json 的 functions[].envVariables
///      （TC_SECRET_ID / TC_SECRET_KEY / TC_SMS_TEMPLATE_ID）
///   4. 部署云函数：tcb fn deploy sms --env-id <envId> --force --httpFn
///      ⚠️ HTTP 型函数的访问域名必须带 APPID+地域：
///      https://{envId}-{appid}.{region}.app.tcloudbase.com/sms
///      （不带 APPID 的 {envId}.service.tcloudbase.com 对 HTTP 型函数会报 FUNCTIONS_PARAM_INVALID）
///   5. cloudbaserc.json 的 envVariables 里填 CODE_PEPPER（随机 64 位 hex，验证码哈希用盐）
///   6. 控制台执行 sql/schema_sms_grants_v2.sql（列类型升级 + anon 表级授权）
///   7. _isMockMode 改 false，重新构建前端
class SmsService {
  SmsService._();

  static final SmsService instance = SmsService._();

  /// 总开关：true = mock（内存验证码 + 界面显示测试码）；false = 走云函数真实发码。
  static const bool _isMockMode = true;

  /// 界面用来判断是否显示「测试验证码」提示条（真实发码后自动消失）
  static bool get isMockMode => _isMockMode;

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
      log('[SmsService MOCK] 发送验证码 $code 到 $phone（未真实发短信）');
      return;
    }

    final data = await _call({'action': 'send', 'phone': phone});
    if (data['ok'] != true) {
      throw SmsException(
        data['error']?.toString() ?? 'NetworkError',
        data['message']?.toString() ?? '验证码发送失败',
      );
    }
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
    return data['ok'] == true;
  }

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
  String _generateCode() {
    final r = DateTime.now().millisecondsSinceEpoch % 1000000;
    return r.toString().padLeft(6, '0');
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
