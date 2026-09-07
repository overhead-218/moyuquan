import 'package:flutter/material.dart';
import '../services/post_service.dart';
import '../widgets/post_card.dart';

/// 我的鱼获（数据来自 PostService：authorId == 'me' 且 type == 'catch'）
class MyCatchPage extends StatefulWidget {
  const MyCatchPage({super.key});

  @override
  State<MyCatchPage> createState() => _MyCatchPageState();
}

class _MyCatchPageState extends State<MyCatchPage> {
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
    final posts = PostService.myCatchPosts();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0A7C74)),
        title: const Text(
          '我的鱼获',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A7C74),
          ),
        ),
      ),
      body: posts.isEmpty
          ? const EmptyView(
              emoji: '🐟',
              title: '还没有鱼获记录',
              subtitle: '钓到大鱼后，用首页 + 里的「晒鱼获」\n分享你的战果吧',
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
