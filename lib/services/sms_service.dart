import 'dart:convert';
import 'dart:developer' show log;
import 'package:http/http.dart' as http;
import 'backend_config.dart';

/// 短信验证码服务
///
/// 阶段一（当前）：Mock 模式，验证码存内存（单例），不依赖数据库表，可本地/生产直接测。
/// 阶段二（凭证到位后）：切腾讯云短信 SDK，真实发码（验证码建议改存云函数/表，勿留客户端）。
///
/// 凭证配置（腾讯云控制台 → 短信 → 应用列表）：
///   - SmsSdkAppId   → 腾讯云短信应用 ID
///   - SignName      → 短信签名「【摸鱼圈】」
///   - TemplateId    → 验证码模板 ID
///   - SecretId/Key  → 云 API 密钥（放 CloudBase 环境变量更安全）
///
/// 凭证到位后：backend_config.dart 加字段 + 这里改为真实发码即可，UI/登录逻辑不变。
class SmsService {
  SmsService._();

  static final SmsService instance = SmsService._();

  // ─────────────────────────────────────────────
  // 凭证（凭证到位前先留空，isMockMode = true）
  // ─────────────────────────────────────────────
  static const bool _isMockMode = true; // 切 false 即切真实腾讯云短信

  static const String _secretId  = ''; // TODO: 填腾讯云 SecretId
  static const String _secretKey = ''; // TODO: 填腾讯云 SecretKey
  static const String _smsSdkAppId = ''; // TODO: 填短信 SdkAppId
  static const String _signName   = '摸鱼圈'; // 短信签名
  static const String _templateId = ''; // TODO: 填腾讯云模板 ID

  // 内存中的待验证验证码（mock 阶段用，key=手机号）
  final Map<String, _PendingCode> _pending = {};

  // ─────────────────────────────────────────────
  // 发送验证码
  // ─────────────────────────────────────────────
  /// 发送手机号验证码，返回 true 表示发送成功（mock/真实均返回 true）
  /// 失败时抛异常：QuotaExceeded（限流）/ InvalidPhone（号码格式错）/ NetworkError
  Future<void> sendCode(String phone) async {
    if (!_isValidPhone(phone)) {
      throw SmsException('InvalidPhone', '手机号格式不正确');
    }

    final code = _generateCode();

    if (_isMockMode) {
      // 阶段一：mock，验证码存内存（生产切真实后改存云函数/表）
      _pending[phone] = _PendingCode(code);
      log('[SmsService MOCK] 发送验证码 $code 到 $phone（未真实发短信）');
    } else {
      // 阶段二：真实腾讯云短信
      await _sendRealSms(phone, code);
    }
  }

  /// 验证验证码是否正确，正确返回 true，错误/过期返回 false
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

    // 阶段二：从数据库查验证码（需 sms_verify_codes 表，建表 SQL 见 schema_sms_verify.sql）
    final table = 'sms_verify_codes';
    final uri = Uri.parse(
      '${BackendConfig.restBase}/$table'
      '?select=code,used,created_at,id'
      '&phone=eq.$phone'
      '&used=eq.false'
      '&order=created_at.desc'
      '&limit=1',
    );
    final resp = await http.get(uri, headers: _authHeader);
    if (resp.statusCode != 200) return false;
    final List<dynamic> rows = jsonDecode(resp.body);
    if (rows.isEmpty) return false;
    final row = rows.first;
    final savedCode = row['code'] as String;
    final createdAt = DateTime.parse(row['created_at'] as String);
    if (DateTime.now().difference(createdAt).inMinutes > 10) return false;
    if (savedCode != code) return false;
    await http.patch(
      Uri.parse('${BackendConfig.restBase}/$table?id=eq.${row['id']}'),
      headers: {..._authHeader, 'Content-Type': 'application/json'},
      body: jsonEncode({'used': true}),
    );
    return true;
  }

  // ─────────────────────────────────────────────
  // 真实腾讯云短信（凭证到位后替换这里）
  // ─────────────────────────────────────────────
  Future<void> _sendRealSms(String phone, String code) async {
    // TODO: 填入真实腾讯云短信 API 调用
    // 腾讯云 SMS API: POST https://sms.tencentcloudapi.com/
    // Action: SendSms, PhoneNumberSet: ['+86$phone'],
    // TemplateId: _templateId, SignName: _signName,
    // TemplateParamSet: [code]（验证码填入模板参数）
    // 签名使用 HMAC-SHA256，凭证在 CloudBase 环境变量或 backend_config.dart
    throw UnimplementedError(
      '请在 backend_config.dart 配置腾讯云 SecretId/SecretKey/SmsSdkAppId/TemplateId 后替换 _sendRealSms 实现',
    );
  }

  // ─────────────────────────────────────────────
  // 工具
  // ─────────────────────────────────────────────
  Map<String, String> get _authHeader => {
    'Authorization': 'Bearer ${BackendConfig.publishableKey}',
    'Content-Type': 'application/json',
  };

  String _generateCode() {
    final r = DateTime.now().millisecondsSinceEpoch % 1000000;
    return r.toString().padLeft(6, '0');
  }

  bool _isValidPhone(String phone) {
    // 大陆手机号：1开头，11位，纯数字
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
