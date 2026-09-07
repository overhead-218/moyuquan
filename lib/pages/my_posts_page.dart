import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';

/// 我的帖子（数据来自 PostService：authorId == 'me'）
class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
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
    final posts = PostService.myPosts();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0A7C74)),
        title: const Text(
          '我的帖子',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A7C74),
          ),
        ),
      ),
      body: posts.isEmpty
          ? const EmptyView(
              emoji: '📝',
              title: '还没有发布帖子',
              subtitle: '去首页点中间的 + ，晒鱼获或写日记\n发布后就会出现在这里',
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
