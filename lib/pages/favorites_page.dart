import 'package:flutter/material.dart';

import '../models/spot.dart';
import '../services/favorite_service.dart';
import '../services/spot_service.dart';
import '../widgets/post_card.dart';
import '../widgets/spot_fav_card.dart';

/// 我的收藏
///
/// ⚠️ 修复记录（2026-11-15）：原实现**只渲染帖子收藏**（favPosts），
///    完全没读钓点收藏（favSpotIds）。用户「我的收藏」里读不到自己收藏的钓点。
///    收藏功能本身是真的（云库 favorites 表有真实记录），是**展示层漏了一半**。
///    现在改成「帖子 / 钓点」双分段，两边都读云库真实数据。
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    FavoriteService.instance.addListener(_refresh);
    // 钓点缓存可能尚未从云库拉回，这里补一次
    _loadSpots();
  }

  @override
  void dispose() {
    FavoriteService.instance.removeListener(_refresh);
    _tabCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// 钓点收藏只存 id，需要从 SpotService 取完整对象。
  /// 云库拉取可能还没完成，缺的就跳过（下次进入页面会补上）。
  Future<void> _loadSpots() async {
    final ids = FavoriteService.instance.favSpotIds;
    if (ids.isEmpty) return;
    // SpotService 已有云库缓存时直接用；否则等一次刷新
    final missing = ids.where((id) => SpotService.getOne(id) == null).toList();
    if (missing.isNotEmpty) {
      await SpotService.refreshFromCloud();
      if (mounted) setState(() {});
    }
  }

  List<Spot> get _spots {
    final ids = FavoriteService.instance.favSpotIds;
    final out = <Spot>[];
    for (final id in ids) {
      final s = SpotService.getOne(id);
      if (s != null) out.add(s);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final posts = FavoriteService.instance.favPosts;
    final spots = _spots;
    final postCount = posts.length;
    final spotCount = spots.length;

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
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFF0A7C74),
          indicatorWeight: 3,
          labelColor: const Color(0xFF0A7C74),
          unselectedLabelColor: const Color(0xFF8A8578),
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: '帖子 $postCount'),
            Tab(text: '钓点 $spotCount'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildPosts(posts),
          _buildSpots(spots),
        ],
      ),
    );
  }

  Widget _buildPosts(List posts) {
    if (posts.isEmpty) {
      return const EmptyView(
        emoji: '🔖',
        title: '还没有收藏帖子',
        subtitle: '在帖子详情页点收藏按钮\n喜欢的帖子会保存在这里',
      );
    }
    return ListView.separated(
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
    );
  }

  Widget _buildSpots(List<Spot> spots) {
    if (spots.isEmpty) {
      return const EmptyView(
        emoji: '🎣',
        title: '还没有收藏钓点',
        subtitle: '在钓点详情页点右下角收藏\n喜欢的钓点会保存在这里',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: spots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final s = spots[i];
        return SpotFavCard(
          spot: s,
          onRemove: () async {
            await FavoriteService.instance.toggleSpotFav(s.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('已取消收藏'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        );
      },
    );
  }
}
