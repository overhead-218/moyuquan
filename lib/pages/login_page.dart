import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'home_shell.dart';
import 'privacy_policy_page.dart';
import 'user_agreement_page.dart';
import '../services/user_profile.dart';

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

              // 登录入口：iOS 显示 Apple+游客；Web/Android 显示「立即体验」
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
