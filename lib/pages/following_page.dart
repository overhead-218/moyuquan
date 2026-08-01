import 'package:flutter/material.dart';

/// 关注页
class FollowingPage extends StatelessWidget {
  const FollowingPage({super.key});

  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _following = [
    {'name': '海钓阿强', 'avatar': '🎣', 'bio': '舟山专业海钓船长，带队8年', 'posts': '128'},
    {'name': '钓鱼王', 'avatar': '🐟', 'bio': '专注野钓15年，抖音粉丝12万', 'posts': '356'},
    {'name': '鱼妹儿', 'avatar': '🐟', 'bio': '钓鱼美食博主，爱分享渔获菜谱', 'posts': '89'},
    {'name': '江南老饕', 'avatar': '🦑', 'bio': '资深美食达人，钓获即食', 'posts': '67'},
    {'name': '野钓大叔', 'avatar': '🎣', 'bio': '野钓爱好者，分享每一个精彩瞬间', 'posts': '234'},
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
          '关注',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: _kPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _following.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final f = _following[i];
          return _FollowingCard(
            name: f['name'] as String,
            avatar: f['avatar'] as String,
            bio: f['bio'] as String,
            posts: f['posts'] as String,
          );
        },
      ),
    );
  }
}

// Top-level constants
const _kPrimaryFlw = Color(0xFF0A7C74);
const _kTealBgFlw = Color(0xFFE6F2F0);
const _kSurfaceFlw = Color(0xFFFFFFFF);
const _kTextPrimaryFlw = Color(0xFF1A1A1A);
const _kTextWeakFlw = Color(0xFF999999);
const _kShadowFlw = Color(0xFF1A1A1A);

class _FollowingCard extends StatelessWidget {
  final String name;
  final String avatar;
  final String bio;
  final String posts;

  const _FollowingCard({
    required this.name,
    required this.avatar,
    required this.bio,
    required this.posts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurfaceFlw,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 16,
            color: _kShadowFlw.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: _kTealBgFlw,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(avatar, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          // 信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextPrimaryFlw,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _kPrimaryFlw.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$posts 帖',
                        style: const TextStyle(
                          fontSize: 10,
                          color: _kPrimaryFlw,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  bio,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextWeakFlw,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 按钮
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTextWeakFlw,
              side: const BorderSide(color: Color(0xFFEDEAE3)),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              '已关注',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
