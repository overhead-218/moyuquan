import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';

/// 我的点赞（数据来自 PostService：云库 post_likes 表同步的 _likedIds）
///
/// 「我的」页新增入口（2026-11-26）：与「我的鱼获」同款布局。
class MyLikesPage extends StatefulWidget {
  const MyLikesPage({super.key});

  @override
  State<MyLikesPage> createState() => _MyLikesPageState();
}

class _MyLikesPageState extends State<MyLikesPage> {
  @override
  void initState() {
    super.initState();
    PostService.addListener(_refresh);
  }

  @override
  void dispose() {
    PostService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final posts = PostService.myLikedPosts();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0A7C74)),
        title: const Text(
          '我的点赞',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A7C74),
          ),
        ),
      ),
      body: posts.isEmpty
          ? const EmptyView(
              emoji: '❤️',
              title: '还没有点赞过的帖子',
              subtitle: '看到喜欢的鱼获或攻略\n点亮红心，就会出现在这里',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) => PostCard(post: posts[i]),
            ),
    );
  }
}
