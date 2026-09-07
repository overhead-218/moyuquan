import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../widgets/post_card.dart' show EmptyView;
import 'user_profile_page.dart';

/// 我的关注（数据来自 FollowService）
class FollowingPage extends StatefulWidget {
  const FollowingPage({super.key});

  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
  @override
  void initState() {
    super.initState();
    FollowService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    FollowService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final ids = FollowService.instance.followingIds;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0A7C74)),
        title: const Text(
          '我的关注',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A7C74),
          ),
        ),
      ),
      body: ids.isEmpty
          ? const EmptyView(
              emoji: '🫶',
              title: '还没有关注任何人',
              subtitle: '去刷帖子，看到喜欢的钓友点个关注吧',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: ids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final info = FollowService.userInfo(ids[i]);
                return _UserCard(
                  name: info['name']!,
                  avatar: info['avatar']!,
                  bio: info['bio'] ?? '',
                  following: true,
                  onToggle: () =>
                      FollowService.instance.toggleFollow(ids[i]),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(
                        name: info['name']!,
                        avatar: info['avatar']!,
                        bio: info['bio'] ?? '',
                        userId: ids[i],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// 用户卡片：头像 + 昵称 + 简介 + 关注/取关按钮
class _UserCard extends StatelessWidget {
  final String name;
  final String avatar;
  final String bio;
  final bool following;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _UserCard({
    required this.name,
    required this.avatar,
    required this.bio,
    required this.following,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F2F0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(avatar, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF999999)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 32,
              child: FilledButton(
                onPressed: onToggle,
                style: following
                    ? FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF0EEE9),
                        foregroundColor: const Color(0xFF666666),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      )
                    : FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0A7C74),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                child: Text(
                  following ? '已关注' : '关注',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
