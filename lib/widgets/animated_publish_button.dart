import 'package:flutter/material.dart';

/// 悬浮发布按钮：金色发光 + 呼吸动画，Stitch 风格
class AnimatedPublishButton extends StatefulWidget {
  const AnimatedPublishButton({super.key});

  @override
  State<AnimatedPublishButton> createState() => _AnimatedPublishButtonState();
}

class _AnimatedPublishButtonState extends State<AnimatedPublishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          // 外圈：尺寸 + 透明度同时呼吸
          final glowSize = 64 + _ctrl.value * 14; // 64–78
          final glowOpacity = 0.38 * (1 - _ctrl.value * 0.6); // 0.38→0.15

          // 内核光晕叠加层
          final haloOpacity = 0.22 * _ctrl.value; // 0→0.22

          return Stack(
            alignment: Alignment.center,
            children: [
              // 第三层：最外侧淡金色晕（随动画扩张）
              Container(
                width: glowSize + 20,
                height: glowSize + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE0B670)
                      .withValues(alpha: glowOpacity * 0.45),
                ),
              ),
              // 第二层：中圈金色光晕
              Container(
                width: glowSize + 8,
                height: glowSize + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      const Color(0xFFC49A5E).withValues(alpha: glowOpacity),
                ),
              ),
              // 第一层：核心小光晕
              Container(
                width: glowSize,
                height: glowSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE0B670)
                      .withValues(alpha: haloOpacity + 0.08),
                ),
              ),
              // 主按钮本体
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE0B670),
                      Color(0xFFC49A5E),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC49A5E)
                          .withValues(alpha: 0.5 + _ctrl.value * 0.2),
                      blurRadius: 12 + _ctrl.value * 8,
                      spreadRadius: _ctrl.value * 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: const Color(0xFFE0B670).withValues(alpha: 0.3),
                      blurRadius: 20 + _ctrl.value * 10,
                      spreadRadius: _ctrl.value * 4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_a_photo,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
