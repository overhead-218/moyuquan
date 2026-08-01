import 'package:flutter/material.dart';

/// 粉丝页
class FollowersPage extends StatelessWidget {
  const FollowersPage({super.key});

  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kGold = Color(0xFFC49A5E);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _followers = [
    {'name': '阿飞', 'avatar': '🐠', 'bio': '钓鱼新手，求带', 'followers': '234'},
    {'name': '菜鸟', 'avatar': '🎣', 'bio': '第一次海钓，石斑爆箱', 'followers': '567'},
    {'name': '渔民小张', 'avatar': '🐟', 'bio': '鄱阳湖渔民，专注野钓', 'followers': '890'},
    {'name': '老周', 'avatar': '🦈', 'bio': '夜钓爱好者', 'followers': '345'},
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
          '粉丝',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _followers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final f = _followers[i];
          return _FollowerCard(
            name: f['name'] as String,
            avatar: f['avatar'] as String,
            bio: f['bio'] as String,
            followers: f['followers'] as String,
          );
        },
      ),
    );
  }
}

// Top-level constants
const _kTealBgFwr = Color(0xFFE6F2F0);
const _kSurfaceFwr = Color(0xFFFFFFFF);
const _kTextPrimaryFwr = Color(0xFF1A1A1A);
const _kTextWeakFwr = Color(0xFF999999);
const _kGoldFwr = Color(0xFFC49A5E);
const _kShadowFwr = Color(0xFF1A1A1A);

class _FollowerCard extends StatelessWidget {
  final String name;
  final String avatar;
  final String bio;
  final String followers;

  const _FollowerCard({
    required this.name,
    required this.avatar,
    required this.bio,
    required this.followers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurfaceFwr,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 16,
            color: _kShadowFwr.withValues(alpha: 0.06),
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
              color: _kTealBgFwr,
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
                        color: _kTextPrimaryFwr,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _kGoldFwr.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$followers 粉丝',
                        style: const TextStyle(
                          fontSize: 10,
                          color: _kGoldFwr,
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
                    color: _kTextWeakFwr,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // 关注按钮
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A7C74),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              '+ 关注',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
