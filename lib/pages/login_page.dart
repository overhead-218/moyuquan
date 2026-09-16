import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'home_shell.dart';
import 'privacy_policy_page.dart';
import 'user_agreement_page.dart';
import '../services/user_profile.dart';
import '../services/sms_service.dart';

/// 登录页：Apple登录(iOS) / 游客模式；微信/手机号待接入（无 SDK 不展示假按钮）
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    // Logo 呼吸动画
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _logoFade =
        CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut);
    _logoScale = Tween<double>(begin: 0.95, end: 1.05).animate(_logoFade);
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  /// 登录成功统一入口：
  /// - 若登录页是栈首（登出/启动后进入）→ 替换为 HomeShell
  /// - 若从「我的→去登录」push 进入 → pop 返回，个人页自动刷新登录态
  void _enterHome() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    }
  }

  /// Apple 登录（仅 iOS 调用）：写入登录态后进入主页
  Future<void> _onAppleLogin() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      // 用 Apple 返回的姓名/邮箱前缀作为展示名（会话内有效）
      String? displayName;
      final given = credential.givenName ?? '';
      final family = credential.familyName ?? '';
      final full = '$family$given'.trim();
      if (full.isNotEmpty) {
        displayName = full;
      } else if (credential.email != null && credential.email!.isNotEmpty) {
        displayName = credential.email!.split('@').first;
      }
      UserProfile.instance
          .markLoggedIn(method: 'apple', displayName: displayName);
      if (!mounted) return;
      _enterHome();
    } catch (e) {
      // 用户取消授权或发生错误，静默返回登录页
    }
  }

  /// 游客模式：重置为干净游客身份后进入（无账号、无云端数据）
  void _onGuestLogin() {
    UserProfile.instance.resetToGuest();
    _enterHome();
  }

  // ─────────────────────────────────────────────
  // 手机号登录 BottomSheet
  // ─────────────────────────────────────────────
  void _showPhoneLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhoneLoginSheet(onSuccess: _enterHome),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F3EE), Color(0xFFE3EEEC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo 呼吸动画
              ScaleTransition(
                scale: _logoScale,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A7C74).withValues(alpha: 0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo_1024.png',
                      width: 110,
                      height: 110,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 主标题
              const Text(
                '摸鱼圈',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0A7C74),
                  letterSpacing: 4,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // 副标题
              const Text(
                '随时随地，分享渔趣',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                  letterSpacing: 1,
                  height: 1.4,
                ),
              ),

              const Spacer(flex: 3),

              // 登录入口：
              //   iOS → Apple 登录 + 游客模式（不显示手机号，规避 Apple 隐私问答变化）
              //   Web/Android → 「立即体验」+ 手机号登录
              if (!kIsWeb && Platform.isIOS)
                ...[
                  SignInWithAppleButton(
                    onPressed: _onAppleLogin,
                    style: SignInWithAppleButtonStyle.black,
                    height: 52,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: _onGuestLogin,
                    child: const Text(
                      '游客模式',
                      style: TextStyle(
                        color: Color(0xFF0A7C74),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]
              else
                ...[
                  // 主入口按钮（微信 SDK 未接入前不展示假登录按钮，以游客体验为主）
                  Container(
                    width: 280,
                    child: ElevatedButton(
                      onPressed: _onGuestLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A7C74),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        minimumSize: const Size(280, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phishing, size: 22),
                          SizedBox(width: 8),
                          Text(
                            '立即体验',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '体验版：微信/手机号登录即将开放',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 12),
                  // 手机号验证码登录（非 iOS）
                  TextButton(
                    onPressed: _showPhoneLoginSheet,
                    child: const Text(
                      '手机号登录',
                      style: TextStyle(
                        color: Color(0xFF0A7C74),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

              const SizedBox(height: 32),

              // 协议说明
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: '登录即同意'),
                    TextSpan(
                      text: '《用户协议》',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0A7C74),
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserAgreementPage(),
                              ),
                            ),
                    ),
                    const TextSpan(text: '与'),
                    TextSpan(
                      text: '《隐私政策》',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0A7C74),
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyPage(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 手机号验证码登录浮层
// ─────────────────────────────────────────────
class _PhoneLoginSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const _PhoneLoginSheet({required this.onSuccess});
  @override
  State<_PhoneLoginSheet> createState() => _PhoneLoginSheetState();
}

class _PhoneLoginSheetState extends State<_PhoneLoginSheet> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl  = TextEditingController();
  final _sms       = SmsService.instance;

  bool _codeSent    = false;
  bool _loading     = false;
  bool _countingDown = false;
  int  _countdown   = 0;
  String? _error;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  // 发送验证码
  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      setState(() => _error = '请输入正确的手机号');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _sms.sendCode(phone);
      setState(() { _codeSent = true; _loading = false; });
      _startCountdown();
    } on SmsException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = '发送失败，请稍后重试'; _loading = false; });
    }
  }

  // 倒计时 60s
  void _startCountdown() {
    setState(() { _countingDown = true; _countdown = 60; });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        setState(() => _countingDown = false);
        return false;
      }
      return true;
    });
  }

  // 验证并登录
  Future<void> _verifyAndLogin() async {
    final phone = _phoneCtrl.text.trim();
    final code  = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = '请输入6位验证码');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final ok = await _sms.verifyCode(phone, code);
      if (!ok) {
        setState(() { _error = '验证码错误或已过期'; _loading = false; });
        return;
      }
      // 验证码正确，写入登录态
      UserProfile.instance.markLoggedIn(method: 'phone', phone: phone);
      if (!mounted) return;
      Navigator.pop(context); // 关闭 BottomSheet
      widget.onSuccess();
    } catch (e) {
      setState(() { _error = '登录失败，请稍后重试'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部拖动条
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 标题
          const Text('手机号登录',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
              color: Color(0xFF0A7C74)), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('未注册的手机号将自动创建账号',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center),
          const SizedBox(height: 24),

          // 手机号输入
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            enabled: !_loading,
            maxLength: 11,
            decoration: InputDecoration(
              labelText: '手机号',
              hintText: '请输入手机号',
              prefixIcon: const Icon(Icons.phone_android),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),

          // 验证码输入 + 发送按钮（水平排列）
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  enabled: !_loading && _codeSent,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: '验证码',
                    hintText: _codeSent ? '请输入验证码' : '先获取验证码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: ElevatedButton(
                  onPressed: _loading || _countingDown ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _countingDown
                        ? const Color(0xFFE0E0E0)
                        : const Color(0xFF0A7C74),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _countingDown ? '${_countdown}s' : '获取验证码',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),

          // 错误提示
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center),
          ],

          // 测试模式提示（mock 阶段显示验证码，真实发码后自动隐藏）
          if (_codeSent && SmsService.isMockMode) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFC49A5E), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('测试验证码：',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8A6D3B))),
                  Text(_sms.mockCodeFor(_phoneCtrl.text.trim()) ?? '—',
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: Color(0xFF8A6D3B),
                      letterSpacing: 2,
                    )),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 登录按钮
          ElevatedButton(
            onPressed: _loading || !_codeSent ? null : _verifyAndLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A7C74),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE0E0E0),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('登录 / 注册',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),

          const SizedBox(height: 12),

          // 协议说明
          Text(
            '登录即同意《用户协议》与《隐私政策》',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
