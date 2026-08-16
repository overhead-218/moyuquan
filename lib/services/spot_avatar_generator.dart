import 'dart:math';
import 'package:flutter/material.dart';

/// 钓点数字头像生成器
/// 根据钓点ID哈希生成独一无二的视觉标识
/// 风格：扁平插画 + 青蓝主题色 + 几何抽象
class SpotAvatarGenerator {
  static const _gold = Color(0xFFC49A5E);
  static const _bg = Color(0xFFF7F3EE);
  
  /// 水域类型配色
  static const _waterColors = [
    Color(0xFF0A7C5C), // 湖泊 - 青蓝
    Color(0xFF1E5F8E), // 河流 - 深蓝
    Color(0xFF2E7D8C), // 水库 - 蓝绿
    Color(0xFF3D6B7F), // 黑坑 - 灰蓝
    Color(0xFF0D8B8B), // 野钓 -  turquoise
    Color(0xFF5D4E37), // 养殖塘 - 土褐
  ];
  
  /// 鱼种配色
  static const _fishColors = [
    Color(0xFFE8B84A), // 金黄（鲤鱼）
    Color(0xFF8B9DC3), // 银灰（鲫鱼）
    Color(0xFF4A6741), // 墨绿（草鱼）
    Color(0xFF2C5282), // 深蓝（鲈鱼）
    Color(0xFF9B2C2C), // 暗红（鳜鱼）
    Color(0xFF744210), // 棕褐（鲶鱼）
  ];
  
  /// 背景图案类型
  static const _bgPatterns = ['waves', 'ripples', 'sunset', 'mist', 'rain'];
  
  /// 装饰元素
  static const _decorations = ['rod', 'tent', 'boat', 'sun', 'moon', 'mountain'];

  /// 生成头像
  static Widget generate({
    required String spotId,
    required String spotType,
    required List<String> fishSpecies,
    double size = 80,
  }) {
    final hash = _hash(spotId);
    final r = Random(hash);
    final waterColor = _waterColors[r.nextInt(_waterColors.length)];
    final fishColor = _fishColors[r.nextInt(_fishColors.length)];
    final bgPattern = _bgPatterns[r.nextInt(_bgPatterns.length)];
    final decoration = _decorations[r.nextInt(_decorations.length)];
    
    return CustomPaint(
      size: Size(size, size),
      painter: _SpotAvatarPainter(
        waterColor: waterColor,
        fishColor: fishColor,
        bgPattern: bgPattern,
        decoration: decoration,
        hash: hash,
        spotType: spotType,
      ),
    );
  }
  
  /// 简单字符串哈希
  static int _hash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash = hash & hash;
    }
    return hash.abs();
  }
}

class _SpotAvatarPainter extends CustomPainter {
  final Color waterColor;
  final Color fishColor;
  final String bgPattern;
  final String decoration;
  final int hash;
  final String spotType;
  
  _SpotAvatarPainter({
    required this.waterColor,
    required this.fishColor,
    required this.bgPattern,
    required this.decoration,
    required this.hash,
    required this.spotType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // 背景圆形
    final bgPaint = Paint()
      ..color = SpotAvatarGenerator._bg
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);
    
    // 绘制背景图案
    _drawBackground(canvas, size, center, radius);
    
    // 绘制水域主体
    _drawWaterBody(canvas, size, center, radius);
    
    // 绘制鱼形
    _drawFish(canvas, size, center);
    
    // 绘制装饰
    _drawDecoration(canvas, size, center, radius);
    
    // 外圈边框
    final borderPaint = Paint()
      ..color = waterColor.withAlpha(180)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius - 1.5, borderPaint);
  }
  
  void _drawBackground(Canvas canvas, Size size, Offset center, double radius) {
    final paint = Paint()
      ..color = waterColor.withAlpha(30)
      ..style = PaintingStyle.fill;
    
    switch (bgPattern) {
      case 'waves':
        for (var i = 0; i < 3; i++) {
          final y = size.height * 0.3 + i * 15;
          final path = Path()
            ..moveTo(0, y)
            ..quadraticBezierTo(size.width * 0.25, y - 8, size.width * 0.5, y)
            ..quadraticBezierTo(size.width * 0.75, y + 8, size.width, y)
            ..lineTo(size.width, y + 20)
            ..lineTo(0, y + 20)
            ..close();
          canvas.drawPath(path, paint);
        }
        break;
        
      case 'ripples':
        for (var i = 1; i <= 3; i++) {
          final ripplePaint = Paint()
            ..color = waterColor.withAlpha(40 - i * 10)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2;
          canvas.drawCircle(center, radius * 0.3 * i, ripplePaint);
        }
        break;
        
      case 'sunset':
        final gradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFB347).withAlpha(60),
            waterColor.withAlpha(40),
          ],
        );
        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
        break;
        
      default:
        // 默认渐变
        final gradient = RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [
            waterColor.withAlpha(50),
            SpotAvatarGenerator._bg,
          ],
        );
        final rect = Rect.fromLTWH(0, 0, size.width, size.height);
        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    }
  }
  
  void _drawWaterBody(Canvas canvas, Size size, Offset center, double radius) {
    final random = Random(hash);
    
    // 水域形状 - 根据钓点类型变化
    final waterPaint = Paint()
      ..color = waterColor.withAlpha(200)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final baseY = size.height * 0.55;
    
    path.moveTo(0, baseY);
    
    // 波浪形水域边缘
    for (var x = 0.0; x <= size.width; x += 10) {
      final waveHeight = 5 + random.nextDouble() * 8;
      final y = baseY + sin(x / size.width * pi * 2) * waveHeight;
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, waterPaint);
    
    // 水面高光
    final highlightPaint = Paint()
      ..color = Colors.white.withAlpha(60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.2 + i * 0.25);
      final y = baseY + 10 + random.nextDouble() * 15;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + 15 + random.nextDouble() * 10, y),
        highlightPaint,
      );
    }
  }
  
  void _drawFish(Canvas canvas, Size size, Offset center) {
    final random = Random(hash);
    final fishPaint = Paint()
      ..color = fishColor
      ..style = PaintingStyle.fill;
    
    final fishX = size.width * (0.35 + random.nextDouble() * 0.3);
    final fishY = size.height * (0.45 + random.nextDouble() * 0.15);
    final fishSize = 12 + random.nextDouble() * 8;
    final facingRight = random.nextBool();
    
    final fishPath = Path();
    
    if (facingRight) {
      // 鱼头朝右
      fishPath.moveTo(fishX - fishSize, fishY);
      fishPath.quadraticBezierTo(
        fishX - fishSize * 0.3, fishY - fishSize * 0.6,
        fishX + fishSize * 0.5, fishY - fishSize * 0.3,
      );
      fishPath.quadraticBezierTo(
        fishX + fishSize, fishY,
        fishX + fishSize * 0.5, fishY + fishSize * 0.3,
      );
      fishPath.quadraticBezierTo(
        fishX - fishSize * 0.3, fishY + fishSize * 0.6,
        fishX - fishSize, fishY,
      );
    } else {
      // 鱼头朝左
      fishPath.moveTo(fishX + fishSize, fishY);
      fishPath.quadraticBezierTo(
        fishX + fishSize * 0.3, fishY - fishSize * 0.6,
        fishX - fishSize * 0.5, fishY - fishSize * 0.3,
      );
      fishPath.quadraticBezierTo(
        fishX - fishSize, fishY,
        fishX - fishSize * 0.5, fishY + fishSize * 0.3,
      );
      fishPath.quadraticBezierTo(
        fishX + fishSize * 0.3, fishY + fishSize * 0.6,
        fishX + fishSize, fishY,
      );
    }
    
    fishPath.close();
    canvas.drawPath(fishPath, fishPaint);
    
    // 鱼尾
    final tailPath = Path();
    final tailX = facingRight ? fishX - fishSize : fishX + fishSize;
    tailPath.moveTo(tailX, fishY);
    tailPath.lineTo(tailX + (facingRight ? -8 : 8), fishY - 6);
    tailPath.lineTo(tailX + (facingRight ? -8 : 8), fishY + 6);
    tailPath.close();
    canvas.drawPath(tailPath, fishPaint);
    
    // 鱼眼
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final eyeX = facingRight ? fishX + fishSize * 0.3 : fishX - fishSize * 0.3;
    canvas.drawCircle(Offset(eyeX, fishY - 2), 2.5, eyePaint);
    
    final pupilPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(eyeX + (facingRight ? 0.5 : -0.5), fishY - 2), 1.2, pupilPaint);
  }
  
  void _drawDecoration(Canvas canvas, Size size, Offset center, double radius) {
    final random = Random(hash);
    final decorPaint = Paint()
      ..color = SpotAvatarGenerator._gold.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    
    final decorFillPaint = Paint()
      ..color = SpotAvatarGenerator._gold.withAlpha(150)
      ..style = PaintingStyle.fill;
    
    switch (decoration) {
      case 'rod':
        // 钓竿
        final rodX = size.width * 0.15;
        final rodTop = size.height * 0.25;
        final rodBottom = size.height * 0.75;
        
        canvas.drawLine(
          Offset(rodX, rodTop),
          Offset(rodX + 8, rodBottom),
          decorPaint..strokeWidth = 3,
        );
        
        // 鱼线
        final linePaint = Paint()
          ..color = Colors.grey.withAlpha(150)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(rodX + 8, rodBottom),
          Offset(rodX + 20, size.height * 0.85),
          linePaint,
        );
        break;
        
      case 'sun':
        // 太阳
        final sunX = size.width * 0.75;
        final sunY = size.height * 0.25;
        canvas.drawCircle(Offset(sunX, sunY), 10, decorFillPaint);
        
        // 光芒
        for (var i = 0; i < 8; i++) {
          final angle = i * pi / 4;
          final start = Offset(
            sunX + cos(angle) * 12,
            sunY + sin(angle) * 12,
          );
          final end = Offset(
            sunX + cos(angle) * 18,
            sunY + sin(angle) * 18,
          );
          canvas.drawLine(start, end, decorPaint..strokeWidth = 2);
        }
        break;
        
      case 'mountain':
        // 远山
        final mountainPath = Path()
          ..moveTo(size.width * 0.6, size.height * 0.35)
          ..lineTo(size.width * 0.75, size.height * 0.15)
          ..lineTo(size.width * 0.9, size.height * 0.35)
          ..close();
        canvas.drawPath(mountainPath, decorFillPaint);
        break;
        
      case 'boat':
        // 小船
        final boatY = size.height * 0.65;
        final boatPath = Path()
          ..moveTo(size.width * 0.7, boatY)
          ..quadraticBezierTo(
            size.width * 0.8, boatY + 12,
            size.width * 0.9, boatY,
          )
          ..lineTo(size.width * 0.85, boatY - 3)
          ..lineTo(size.width * 0.75, boatY - 3)
          ..close();
        canvas.drawPath(boatPath, decorFillPaint);
        break;
        
      default:
        // 默认：小圆点装饰
        for (var i = 0; i < 3; i++) {
          final x = size.width * (0.7 + i * 0.08);
          final y = size.height * (0.2 + random.nextDouble() * 0.15);
          canvas.drawCircle(Offset(x, y), 3 + random.nextDouble() * 2, decorFillPaint);
        }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
