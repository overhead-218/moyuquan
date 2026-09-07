import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../widgets/post_card.dart' show EmptyView;
import 'following_page.dart';

/// 我的粉丝（数据来自 FollowService；新用户默认无粉丝）
class FollowersPage extends StatefulWidget {
  const FollowersPage({super.key});

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
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
    final ids = FollowService.instance.followerIds;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0A7C74)),
        title: const Text(
          '我的粉丝',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A7C74),
          ),
        ),
      ),
      body: ids.isEmpty
          ? const EmptyView(
              emoji: '🐟',
              title: '还没有粉丝',
              subtitle: '多发布优质内容，钓友会来找你互动',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: ids.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final id = ids[i];
                final info = FollowService.userInfo(id);
                return _FollowerRow(
                  name: info['name']!,
                  avatar: info['avatar']!,
                  bio: info['bio'] ?? '',
                  isFollowing: FollowService.instance.isFollowing(id),
                  onToggle: () => FollowService.instance.toggleFollow(id),
                );
              },
            ),
    );
  }
}

class _FollowerRow extends StatelessWidget {
  final String name;
  final String avatar;
  final String bio;
  final bool isFollowing;
  final VoidCallback onToggle;

  const _FollowerRow({
    required this.name,
    required this.avatar,
    required this.bio,
    required this.isFollowing,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
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
              style: FilledButton.styleFrom(
                backgroundColor:
                    isFollowing ? const Color(0xFFF0EEE9) : const Color(0xFF0A7C74),
                foregroundColor:
                    isFollowing ? const Color(0xFF666666) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                isFollowing ? '已关注' : '回关',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
