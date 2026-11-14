import 'package:flutter/foundation.dart';

import 'backend_config.dart';
import 'tcb_rest_client.dart';
import 'user_profile.dart';

/// 钓点点赞服务。
///
/// 数据源：云库 `spot_likes` 表。
/// ⚠️ 原实现里钓点详情页的点赞数是写死的 `int _likeCount = 568`，
///    也就是说不管看哪个钓点，点赞数都从 568 起步，且点了不入库、不持久。
///    现在改为真实计数。
class SpotLikeService {
  static final SpotLikeService instance = SpotLikeService._();
  SpotLikeService._();

  static const _table = 'spot_likes';

  /// spotId -> 我是否点过赞
  static final Map<String, bool> _liked = {};
  /// spotId -> 真实点赞总数（来自云库聚合）
  static final Map<String, int> _counts = {};
  static bool _loaded = false;

  static bool isLiked(String spotId) => _liked[spotId] ?? false;

  /// 取该钓点的真实点赞数；无数据时返回 0。
  static int countOf(String spotId) => _counts[spotId] ?? 0;

  /// 启动时加载我点过赞的钓点。
  static Future<void> refreshFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query(_table, params: {
        'select': 'spotId',
        'userId': 'eq.${UserProfile.id}',
        'limit': '1000',
      });
      for (final r in rows) {
        final id = r['spotId'] as String? ?? '';
        if (id.isNotEmpty) _liked[id] = true;
      }
      _loaded = true;
      debugPrint('[SpotLike] 已同步点赞态 ${_liked.length} 条');
    } catch (e) {
      debugPrint('[SpotLike] 点赞态同步失败（降级为会话内状态）：$e');
      _loaded = true;
    }
  }

  /// 拉取指定钓点的真实点赞总数。
  ///
  /// 注意：`spots` 表目前没有点赞数字段，这里通过点赞明细表聚合。
  /// 明细表行数大时应改为云函数侧聚合计数表，避免全表扫描。
  static Future<int> fetchCount(String spotId) async {
    if (!BackendConfig.cloudEnabled) return _counts[spotId] ?? 0;
    try {
      final rows = await TcbRestClient.query(
        _table,
        params: {
          'select': 'id',
          'spotId': 'eq.$spotId',
          'limit': '5000',
        },
      );
      final n = rows.length;
      _counts[spotId] = n;
      return n;
    } catch (e) {
      debugPrint('[SpotLike] 点赞数获取失败：$e');
      return _counts[spotId] ?? 0;
    }
  }

  /// 切换点赞，返回是否已点赞。写库失败会回滚。
  static Future<bool> toggleLike(String spotId) async {
    if (spotId.isEmpty) return false;
    final nowLiked = !(_liked[spotId] ?? false);
    final likeId = 'sl_${UserProfile.id}_$spotId';

    _liked[spotId] = nowLiked;
    _counts[spotId] = ((_counts[spotId] ?? 0) + (nowLiked ? 1 : -1))
        .clamp(0, 1 << 30);

    if (!BackendConfig.cloudEnabled) return nowLiked;

    try {
      if (nowLiked) {
        await TcbRestClient.upsert(_table, {
          'id': likeId,
          'spotId': spotId,
          'userId': UserProfile.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        await TcbRestClient.delete(_table, {'id': 'eq.$likeId'});
      }
      return nowLiked;
    } catch (e) {
      debugPrint('[SpotLike] 点赞同步失败，已回滚：$e');
      _liked[spotId] = !nowLiked;
      _counts[spotId] = ((_counts[spotId] ?? 1) + (nowLiked ? -1 : 1))
          .clamp(0, 1 << 30);
      return !nowLiked;
    }
  }

  /// 登出时清空本机点赞态。
  static void resetMyContent() {
    _liked.clear();
    _loaded = false;
  }
}