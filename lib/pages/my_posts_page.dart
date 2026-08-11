import 'package:flutter/material.dart';
import 'post_detail_page.dart';

/// 我的帖子
class MyPostsPage extends StatelessWidget {
  const MyPostsPage({super.key});

  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _posts = [
    {
      'title': '周末两天狂拉20斤鲤鱼，饵料配方分享',
      'image': 'https://picsum.photos/seed/mypost1/400/300.jpg',
      'likes': '892',
      'comments': '56',
      'time': '3天前',
      'avatar': '🎣',
      'name': '老李',
      'content': '自己配的饵料，牛窝三号加轻麸，上鱼效果很好',
      'location': '南京·六合',
      'postType': 'catch',
      'commentCount': 56,
    },
    {
      'title': '清晨5点出发，大板鲫连竿上岸全过程',
      'image': 'https://picsum.photos/seed/mypost2/400/280.jpg',
      'likes': '645',
      'comments': '34',
      'time': '1周前',
      'avatar': '🎣',
      'name': '老李',
      'content': '凌晨五点出门，到地方天还没亮，打窝等半小时开始连竿',
      'location': '南京·浦口',
      'postType': 'catch',
      'commentCount': 34,
    },
    {
      'title': '第一次海钓就爆箱，石斑鱼狂拉！',
      'image': 'https://picsum.photos/seed/mypost3/400/320.jpg',
      'likes': '1203',
      'comments': '89',
      'time': '2周前',
      'avatar': '🎣',
      'name': '老李',
      'content': '第一次海钓就上头，石斑鱼一条接一条，累得手都酸了',
      'location': '宁波·象山港',
      'postType': 'catch',
      'commentCount': 89,
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
          '我的帖子',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: _kPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final p = _posts[i];
          return _PostCard(
            title: p['title'] as String,
            image: p['image'] as String,
            likes: p['likes'] as String,
            comments: p['comments'] as String,
            time: p['time'] as String,
            avatar: p['avatar'] as String,
            name: p['name'] as String,
            index: i,
            content: p['content'] as String,
            location: p['location'] as String,
            postType: p['postType'] as String,
            commentCount: p['commentCount'] as int,
          );
        },
      ),
    );
  }
}

// Top-level constants
const _kPrimaryMP = Color(0xFF0A7C74);
const _kSurfaceMP = Color(0xFFFFFFFF);
const _kTextPrimaryMP = Color(0xFF1A1A1A);
const _kTextWeakMP = Color(0xFF999999);
const _kShadowMP = Color(0xFF1A1A1A);

class _PostCard extends StatelessWidget {
  final String title;
  final String image;
  final String likes;
  final String comments;
  final String time;
  final String avatar;
  final String name;
  final int index;
  final String content;
  final String location;
  final String postType;
  final int commentCount;

  const _PostCard({
    required this.title,
    required this.image,
    required this.likes,
    required this.comments,
    required this.time,
    required this.avatar,
    required this.name,
    required this.index,
    required this.content,
    required this.location,
    required this.postType,
    required this.commentCount,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailPage(
              authorName: name,
              authorAvatar: avatar,
              imageUrl: image,
              imageHeight: 240,
              likeCount: int.parse(likes),
              index: index,
              title: title,
              content: content,
              location: location,
              postType: postType,
              commentCount: commentCount,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kSurfaceMP,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 16,
              color: _kShadowMP.withValues(alpha: 0.06),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, st) => Container(
                  color: const Color(0xFFE6F2F0),
                  child: const Center(
                    child: Text('📷', style: TextStyle(fontSize: 48)),
                  ),
                ),
              ),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimaryMP,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(avatar, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kPrimaryMP,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.favorite, size: 12, color: _kTextWeakMP),
                      const SizedBox(width: 3),
                      Text(
                        likes,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextWeakMP,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.chat_bubble_outline,
                          size: 12, color: _kTextWeakMP),
                      const SizedBox(width: 3),
                      Text(
                        comments,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextWeakMP,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextWeakMP,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
