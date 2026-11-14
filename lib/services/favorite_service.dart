import 'package:flutter/foundation.dart';

import '../models/post.dart';
import 'backend_config.dart';
import 'post_service.dart';
import 'tcb_rest_client.dart';
import 'user_profile.dart';

/// 收藏服务。
///
/// 数据源：云库 `favorites` 表（权威）+ 本地缓存（UI 即时响应）。
/// 同时管理「收藏的帖子」与「收藏的钓点」。
/// ⚠️ 原实现是纯内存单例，重启 App 收藏全丢、换设备看不到，
///    而且钓点收藏功能写好了却没有任何页面调用。现在全部走真实云库。
class FavoriteService {
  static final FavoriteService instance = FavoriteService._();
  FavoriteService._();

  static const _table = 'favorites';

  final List<Post> _favPosts = [];
  final List<String> _favSpotIds = [];

  final Set<void Function()> _listeners = {};
  void addListener(void Function() cb) => _listeners.add(cb);
  void removeListener(void Function() cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in List.of(_listeners)) {
      try {
        cb();
      } catch (_) {}
    }
  }

  // ── 帖子收藏 ─────────────────────────────
  List<Post> get favPosts => List.unmodifiable(_favPosts);
  int get postCount => _favPosts.length;

  bool isPostFav(String postId) => _favPosts.any((p) => p.id == postId);

  /// 切换帖子收藏，返回是否已收藏。
  Future<bool> togglePostFav(Post post) async {
    final had = isPostFav(post.id);
    if (had) {
      _favPosts.removeWhere((p) => p.id == post.id);
    } else {
      _favPosts.insert(0, post);
    }
    _notify();

    if (!BackendConfig.cloudEnabled) return !had;
    try {
      if (had) {
        await TcbRestClient.delete(_table,
            {'id': 'eq.${_favId('post', post.id)}'});
      } else {
        await TcbRestClient.upsert(_table, {
          'id': _favId('post', post.id),
          'userId': UserProfile.id,
          'targetType': 'post',
          'targetId': post.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      return !had;
    } catch (e) {
      debugPrint('[Favorite] 帖子收藏同步失败，已回滚：$e');
      if (had) {
        _favPosts.insert(0, post);
      } else {
        _favPosts.removeWhere((p) => p.id == post.id);
      }
      _notify();
      return had;
    }
  }

  // ── 钓点收藏 ─────────────────────────────
  List<String> get favSpotIds => List.unmodifiable(_favSpotIds);
  int get spotCount => _favSpotIds.length;

  bool isSpotFav(String spotId) => _favSpotIds.contains(spotId);

  /// 切换钓点收藏，返回是否已收藏。
  Future<bool> toggleSpotFav(String spotId) async {
    if (spotId.isEmpty) return false;
    final had = _favSpotIds.contains(spotId);
    if (had) {
      _favSpotIds.remove(spotId);
    } else {
      _favSpotIds.add(spotId);
    }
    _notify();

    if (!BackendConfig.cloudEnabled) return !had;
    try {
      if (had) {
        await TcbRestClient.delete(_table,
            {'id': 'eq.${_favId('spot', spotId)}'});
      } else {
        await TcbRestClient.upsert(_table, {
          'id': _favId('spot', spotId),
          'userId': UserProfile.id,
          'targetType': 'spot',
          'targetId': spotId,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      return !had;
    } catch (e) {
      debugPrint('[Favorite] 钓点收藏同步失败，已回滚：$e');
      if (had) {
        _favSpotIds.add(spotId);
      } else {
        _favSpotIds.remove(spotId);
      }
      _notify();
      return had;
    }
  }

  static String _favId(String type, String targetId) =>
      'fv_${type}_${UserProfile.id}_$targetId';

  // ── 云端同步 ───────────────────────────────────────
  /// 启动时调用：从云库恢复收藏列表。
  Future<void> refreshFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query(_table, params: {
        'select': '*',
        'userId': 'eq.${UserProfile.id}',
        'limit': '1000',
      });

      _favSpotIds
        ..clear()
        ..addAll(rows
            .where((r) => r['targetType'] == 'spot')
            .map((r) => r['targetId'] as String? ?? '')
            .where((e) => e.isNotEmpty));

      // 收藏的帖子：只存 id，正文从 PostService 当前缓存取，
      // 避免同一份帖子数据在两处副本不一致。
      final postIds = rows
          .where((r) => r['targetType'] == 'post')
          .map((r) => r['targetId'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
      _favPosts.clear();
      for (final id in postIds) {
        final p = await PostService.getOne(id);
        if (p != null) _favPosts.add(p);
      }

      _notify();
      debugPrint('[Favorite] 云库同步：帖子 ${_favPosts.length}，钓点 ${_favSpotIds.length}');
    } catch (e) {
      // 表未建时降级
      debugPrint('[Favorite] 云库同步失败（降级为空列表）：$e');
    }
  }

  /// 清空所有收藏缓存（登出时调用）。
  void clearAll() {
    _favPosts.clear();
    _favSpotIds.clear();
    _notify();
  }
}