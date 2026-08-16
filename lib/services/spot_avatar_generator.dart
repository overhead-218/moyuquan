import 'dart:math';
import 'package:flutter/material.dart';

const _eyeWhite = Color(0xFFFFFFFF);
const _eyeBlack = Color(0xFF1A1A1A);
const _bubbleColor = Color(0xFFB3E5FC);

/// 钓点数字头像 - 像素风（NFT CryptoPunks 风格）
/// 每条鱼都是 16x16 网格硬边像素，配色/特征由钓点ID哈希决定，独一无二
class SpotAvatarGenerator {
  // 背景调色板（复古 8-bit）
  static const _bgPalette = [
    Color(0xFF0A7C5C), // 青蓝
    Color(0xFF1E5F8E), // 深蓝
    Color(0xFF2E7D8C), // 蓝绿
    Color(0xFF5D4E37), // 棕褐
    Color(0xFF8E44AD), // 紫
    Color(0xFF16A085), // 绿
    Color(0xFFC0392B), // 红
    Color(0xFF2C3E50), // 深灰蓝
  ];

  // 鱼身调色板
  static const _fishPalette = [
    Color(0xFFE8B84A), // 金黄（鲤）
    Color(0xFF8B9DC3), // 银灰（鲫）
    Color(0xFF4A6741), // 墨绿（草）
    Color(0xFF2C5282), // 深蓝（鲈）
    Color(0xFF9B2C2C), // 暗红（鳜）
    Color(0xFFE74C3C), // 橙红
    Color(0xFF3498DB), // 蓝
    Color(0xFFF39C12), // 橙黄
  ];

  static const _bellyColor = Color(0xFFFDF6E3);

  static Widget generate({
    required String spotId,
    required String spotType,
    required List<String> fishSpecies,
    double size = 80,
  }) {
    final r = Random(_hash(spotId));
    final bg = _bgPalette[r.nextInt(_bgPalette.length)];
    final body = _fishPalette[r.nextInt(_fishPalette.length)];
    final fin = _darken(body, 0.35);
    final eyeStyle = r.nextInt(3); // 0普通 1大眼 2X眼
    final hasBubbles = r.nextBool();
    final bubbleCount = r.nextInt(4);

    return CustomPaint(
      size: Size(size, size),
      painter: _FishPixelPainter(
        gridSize: 16,
        bg: bg,
        body: body,
        belly: _bellyColor,
        fin: fin,
        eyeStyle: eyeStyle,
        hasBubbles: hasBubbles,
        bubbleCount: bubbleCount,
      ),
    );
  }

  static Color _darken(Color c, double amount) {
    final f = 1 - amount;
    return Color.fromRGBO((c.r * f).round(), (c.g * f).round(), (c.b * f).round(), 1);
  }

  static int _hash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash) + input.codeUnitAt(i);
      hash = hash & hash;
    }
    return hash.abs();
  }
}

class _FishPixelPainter extends CustomPainter {
  final int gridSize;
  final Color bg;
  final Color body;
  final Color belly;
  final Color fin;
  final int eyeStyle;
  final bool hasBubbles;
  final int bubbleCount;

  _FishPixelPainter({
    required this.gridSize,
    required this.bg,
    required this.body,
    required this.belly,
    required this.fin,
    required this.eyeStyle,
    required this.hasBubbles,
    required this.bubbleCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pixel = size.width / gridSize;
    final grid = List.generate(gridSize, (_) => List<Color?>.filled(gridSize, null));

    _fillBackground(grid);
    _fillBody(grid);
    _fillFins(grid);
    _fillTail(grid);
    _fillEye(grid);
    _fillMouth(grid);
    if (hasBubbles) _fillBubbles(grid);

    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        final c = grid[y][x];
        if (c != null) {
          paint.color = c;
          // +0.5 消除像素间隙
          canvas.drawRect(Rect.fromLTWH(x * pixel, y * pixel, pixel + 0.5, pixel + 0.5), paint);
        }
      }
    }
  }

  void _fillBackground(List<List<Color?>> grid) {
    for (var y = 0; y < gridSize; y++) {
      for (var x = 0; x < gridSize; x++) {
        grid[y][x] = bg;
      }
    }
  }

  void _fillBody(List<List<Color?>> grid) {
    // 鱼身 x:2-11, y:4-11
    for (var y = 4; y <= 11; y++) {
      for (var x = 2; x <= 11; x++) {
        grid[y][x] = body;
      }
    }
    // 鱼腹（下半浅色）
    for (var y = 9; y <= 11; y++) {
      for (var x = 3; x <= 10; x++) {
        grid[y][x] = belly;
      }
    }
    // 圆角去角
    grid[4][2] = null; grid[4][11] = null;
    grid[5][2] = null; grid[5][11] = null;
    grid[11][2] = null; grid[11][11] = null;
    grid[10][2] = null; grid[10][11] = null;
  }

  void _fillFins(List<List<Color?>> grid) {
    // 背鳍
    grid[3][5] = fin; grid[3][6] = fin; grid[2][6] = fin; grid[3][7] = fin; grid[3][8] = fin;
    // 腹鳍
    grid[12][5] = fin; grid[12][6] = fin; grid[13][6] = fin; grid[12][7] = fin; grid[12][8] = fin;
  }

  void _fillTail(List<List<Color?>> grid) {
    // 鱼尾（右侧三角）
    grid[5][12] = fin; grid[4][13] = fin; grid[5][13] = fin; grid[6][13] = fin; grid[7][13] = fin;
    grid[6][14] = fin; grid[7][14] = fin; grid[8][14] = fin; grid[9][13] = fin; grid[10][13] = fin;
    grid[11][12] = fin;
  }

  void _fillEye(List<List<Color?>> grid) {
    if (eyeStyle == 0) {
      grid[6][4] = _eyeWhite; grid[6][5] = _eyeBlack;
      grid[7][4] = _eyeWhite; grid[7][5] = _eyeBlack;
    } else if (eyeStyle == 1) {
      // 大眼
      grid[5][4] = _eyeWhite; grid[5][5] = _eyeBlack;
      grid[6][4] = _eyeWhite; grid[6][5] = _eyeBlack;
      grid[7][4] = _eyeWhite; grid[7][5] = _eyeBlack;
      grid[8][4] = _eyeWhite; grid[8][5] = _eyeBlack;
    } else {
      // X 眼
      grid[6][4] = _eyeBlack; grid[7][5] = _eyeBlack;
      grid[7][4] = _eyeBlack; grid[6][5] = _eyeBlack;
    }
  }

  void _fillMouth(List<List<Color?>> grid) {
    grid[9][2] = _eyeBlack; grid[9][3] = _eyeBlack;
  }

  void _fillBubbles(List<List<Color?>> grid) {
    final positions = [
      [2, 13], [3, 14], [1, 14], [4, 14]
    ];
    for (var i = 0; i < bubbleCount && i < positions.length; i++) {
      final p = positions[i];
      grid[p[0]][p[1]] = _bubbleColor;
      if (p[0] + 1 < gridSize) grid[p[0] + 1][p[1]] = _bubbleColor;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
