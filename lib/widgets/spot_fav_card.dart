import 'package:flutter/material.dart';

import '../models/spot.dart';
import '../pages/spot_detail_new.dart';

/// 收藏页里的钓点卡片。
///
/// 与钓点发现页的卡片视觉保持一致（同一套配色/角标/图片处理），
/// 但尺寸更适合收藏列表：整行可点进详情，右上角提供取消收藏。
class SpotFavCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback onRemove;

  const SpotFavCard({super.key, required this.spot, required this.onRemove});

  static const _primary = Color(0xFF0A7C74);
  static const _surface = Color(0xFFFFFFFF);
  static const _textWeak = Color(0xFF8A8578);

  static ImageProvider _imgProvider(String url) =>
      url.startsWith('assets/') ? AssetImage(url) : NetworkImage(url);

  static List<Color> _fallbackColors(String type) {
    switch (type) {
      case '野钓':
        return const [Color(0xFF14564E), Color(0xFF0A7C74)];
      case '路亚':
        return const [Color(0xFF0F4C5C), Color(0xFF148F86)];
      case '黑坑':
        return const [Color(0xFF33383D), Color(0xFF5C6670)];
      case '斤塘':
        return const [Color(0xFF6B5230), Color(0xFFC49A5E)];
      case '农家乐':
        return const [Color(0xFF3F5A30), Color(0xFF7FA65A)];
      case '游钓基地':
        return const [Color(0xFF114A54), Color(0xFF2E8C99)];
      case '养殖塘':
        return const [Color(0xFF24503F), Color(0xFF5A9C7E)];
      default:
        return const [Color(0xFF0A7C74), Color(0xFF148F86)];
    }
  }

  Widget _noPhoto() {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: _fallbackColors(spot.type))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(spot.typeEmoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 3),
          Text(
            '暂无实景照片',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SpotDetailPageNew(spot: spot)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // 封面
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (spot.displayImages.isEmpty)
                    _noPhoto()
                  else
                    Image(
                      image: _imgProvider(spot.displayImages.first),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _noPhoto(),
                    ),
                  // 类型标签
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${spot.typeEmoji} ${spot.type}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 信息区
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      spot.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A2520),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 13, color: _textWeak),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${spot.city} · ${spot.district}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: _textWeak),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (spot.price > 0) ...[
                          Text(
                            '¥${spot.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                          const Text(
                            ' 起',
                            style: TextStyle(fontSize: 11, color: _textWeak),
                          ),
                        ] else
                          const Text(
                            '免费',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                        if (spot.photoBadge != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: _primary.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                spot.photoBadge!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: _primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 取消收藏
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.favorite, color: Color(0xFFFF4458), size: 22),
              tooltip: '取消收藏',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
