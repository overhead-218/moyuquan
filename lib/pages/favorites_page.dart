import 'package:flutter/material.dart';
import '../services/favorite_service.dart';
import '../widgets/post_card.dart';

/// 我的收藏（帖子收藏，数据来自 FavoriteService）
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    FavoriteService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    FavoriteService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final posts = FavoriteService.instance.favPosts;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF0A7C74)),
        title: const Text(
          '我的收藏',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A7C74),
          ),
        ),
      ),
      body: posts.isEmpty
          ? const EmptyView(
              emoji: '🔖',
              title: '还没有收藏',
              subtitle: '在帖子详情页点收藏按钮\n喜欢的帖子会保存在这里',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, i) {
                final p = posts[i];
                return PostCard(
                  post: p,
                  onRemove: () {
                    FavoriteService.instance.togglePostFav(p);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已取消收藏'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
