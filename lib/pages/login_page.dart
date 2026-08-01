import 'package:flutter/material.dart';
import 'home_shell.dart';

/// 登录页：微信授权入口 + Logo呼吸动画 + 抖动提示
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _shakeCtrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _shake;

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

    // 微信按钮抖动提示
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );

    // 3秒后按钮轻微抖动，提示可点击
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _shakeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onWechatLogin() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const CircularProgressIndicator(
            color: Color(0xFF0A7C74),
            strokeWidth: 2.5,
          ),
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
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
                      color: const Color(0xFF0A7C74),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0A7C74).withValues(alpha: 0.28),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🎣',
                        style: TextStyle(fontSize: 56),
                      ),
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

              // 微信登录按钮（带抖动提示）
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final offset = _shake.value == 0
                      ? 0.0
                      : (_shake.value < 0.5
                          ? -4 * _shake.value
                          : 4 * (1 - (_shake.value - 0.5) * 2));
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Container(
                  width: 280,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  child: ElevatedButton(
                    onPressed: _onWechatLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF07C160),
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
                        Icon(Icons.wechat, size: 22),
                        SizedBox(width: 8),
                        Text(
                          '微信登录',
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
              ),

              const SizedBox(height: 20),

              // 其他登录方式
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '手机号登录',
                      style: TextStyle(
                        color: Color(0xFF0A7C74),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 1,
                    height: 12,
                    color: const Color(0xFFEDEAE3),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '游客模式',
                      style: TextStyle(
                        color: Color(0xFF0A7C74),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 协议说明
              const Text(
                '登录即同意《用户协议》与《隐私政策》',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF999999),
                  height: 1.4,
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
