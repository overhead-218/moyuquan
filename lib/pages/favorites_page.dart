import 'package:flutter/material.dart';
import 'post_detail_page.dart';

/// 收藏页
class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _items = [
    {
      'title': '野钓空军的十大原因',
      'author': '钓鱼王',
      'avatar': '🐟',
      'likes': '2341',
      'time': '3天前',
      'image': 'https://picsum.photos/seed/fav1/400/300.jpg',
      'content': '空军的原因有很多，但你真的知道是哪个吗',
      'location': '南京·六合',
      'postType': 'diary',
      'commentCount': 128,
    },
    {
      'title': '夏季夜钓选位指南',
      'author': '海钓阿强',
      'avatar': '🚤',
      'likes': '1567',
      'time': '1周前',
      'image': 'https://picsum.photos/seed/fav2/400/280.jpg',
      'content': '夜钓选位是关键，水深和地形决定了鱼获',
      'location': '宁波·象山港',
      'postType': 'spot',
      'commentCount': 89,
    },
    {
      'title': '第一次海钓需要准备什么？',
      'author': '菜鸟',
      'avatar': '🎣',
      'likes': '892',
      'time': '2周前',
      'image': 'https://picsum.photos/seed/fav3/400/320.jpg',
      'content': '装备、饵料、安全，一个都不能少',
      'location': '温州·洞头岛',
      'postType': 'diary',
      'commentCount': 67,
    },
    {
      'title': '舟山矶钓圣地合集',
      'author': '江南老饕',
      'avatar': '🦑',
      'likes': '2104',
      'time': '3周前',
      'image': 'https://picsum.photos/seed/fav4/400/260.jpg',
      'content': '矶钓天堂，建议收藏',
      'location': '杭州·千岛湖',
      'postType': 'spot',
      'commentCount': 201,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          '我的收藏',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final item = _items[i];
          return _FavoriteCard(
            title: item['title'] as String,
            author: item['author'] as String,
            avatar: item['avatar'] as String,
            likes: item['likes'] as String,
            time: item['time'] as String,
            image: item['image'] as String,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailPage(
                    authorName: item['author'] as String,
                    authorAvatar: item['avatar'] as String,
                    imageUrl: item['image'] as String,
                    imageHeight: 240,
                    likeCount: int.parse(item['likes'] as String),
                    index: i,
                    title: item['title'] as String,
                    content: item['content'] as String,
                    location: item['location'] as String,
                    postType: item['postType'] as String,
                    commentCount: item['commentCount'] as int,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Top-level constants for use in nested widgets
const _kPrimaryFav = Color(0xFF0A7C74);
const _kSurfaceFav = Color(0xFFFFFFFF);
const _kTextPrimaryFav = Color(0xFF1A1A1A);
const _kTextWeakFav = Color(0xFF999999);
const _kShadowFav = Color(0xFF1A1A1A);

class _FavoriteCard extends StatelessWidget {
  final String title;
  final String author;
  final String avatar;
  final String likes;
  final String time;
  final String image;
  final VoidCallback onTap;

  const _FavoriteCard({
    required this.title,
    required this.author,
    required this.avatar,
    required this.likes,
    required this.time,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurfaceFav,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 16,
              color: _kShadowFav.withValues(alpha: 0.06),
            ),
          ],
        ),
        child: Row(
          children: [
            // 图片
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 110,
                height: 110,
                child: Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, st) => Container(
                    color: const Color(0xFFE6F2F0),
                    child: const Center(
                      child: Text('📷', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                ),
              ),
            ),
            // 内容
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kTextPrimaryFav,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(avatar, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          author,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kPrimaryFav,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.favorite, size: 11, color: _kTextWeakFav),
                        const SizedBox(width: 2),
                        Text(
                          likes,
                          style: const TextStyle(
                            fontSize: 11,
                            color: _kTextWeakFav,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _kTextWeakFav,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 收藏图标
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.favorite,
                color: const Color(0xFFFF4757).withValues(alpha: 0.7),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
