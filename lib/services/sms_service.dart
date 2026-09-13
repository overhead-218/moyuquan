import 'dart:convert';
import 'dart:developer' show debugPrint;
import 'package:http/http.dart' as http;
import 'backend_config.dart';

/// 短信验证码服务
///
/// 阶段一（当前）：Mock 模式，验证码存 CloudBase sms_verify_codes 表（可本地测全流程）。
/// 阶段二（凭证到位后）：切腾讯云短信 SDK，真实发码。
///
/// 凭证配置（腾讯云控制台 → 短信 → 应用列表）：
///   - SmsSdkAppId   → 腾讯云短信应用 ID
///   - SignName      → 短信签名「【摸鱼圈】」
///   - TemplateId    → 验证码模板 ID
///   - SecretId/Key  → 云 API 密钥（放在 CloudBase 环境变量更安全）
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
      // 阶段一：mock，写 CloudBase 表，真实发码时替换这段
      await _mockSaveCode(phone, code);
      debugPrint('[SmsService MOCK] 发送验证码 $code 到 $phone（未真实发短信）');
    } else {
      // 阶段二：真实腾讯云短信
      await _sendRealSms(phone, code);
    }
  }

  /// 验证验证码是否正确，正确返回 true，错误/过期返回 false
  Future<bool> verifyCode(String phone, String code) async {
    if (!_isValidPhone(phone) || code.length != 6) return false;

    final table = 'sms_verify_codes';

    // 取该手机号最新一条未使用验证码（按 created_at desc）
    final uri = Uri.parse(
      '${BackendConfig.restBase}/$table'
      '?select=code,used,created_at'
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

    // 验证码 10 分钟内有效
    if (DateTime.now().difference(createdAt).inMinutes > 10) {
      return false;
    }
    if (savedCode != code) {
      return false;
    }

    // 标记为已使用（防止重放）
    await http.patch(
      Uri.parse('${BackendConfig.restBase}/$table?id=eq.${row['id']}'),
      headers: {..._authHeader, 'Content-Type': 'application/json'},
      body: jsonEncode({'used': true}),
    );

    return true;
  }

  // ─────────────────────────────────────────────
  // Mock 实现：写 CloudBase 表（凭证到位前本地测试用）
  // ─────────────────────────────────────────────
  Future<void> _mockSaveCode(String phone, String code) async {
    final table = 'sms_verify_codes';
    final uri = Uri.parse('${BackendConfig.restBase}/$table');

    final resp = await http.post(
      uri,
      headers: {..._authHeader, 'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'code': code,
        'used': false,
      }),
    );

    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw SmsException('NetworkError', '保存验证码失败: ${resp.statusCode}');
    }
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

/// 短信服务异常
class SmsException implements Exception {
  final String code;
  final String message;
  SmsException(this.code, this.message);
  @override
  String toString() => 'SmsException($code): $message';
}
