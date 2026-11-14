import 'package:flutter/foundation.dart';

import '../models/catch_item.dart';
import '../utils/region.dart';
import 'backend_config.dart';
import 'tcb_rest_client.dart';
import 'user_profile.dart';

/// 渔获服务 / 榜单数据源。
///
/// 数据源：云库 `catches` 表（权威）+ `catch_likes` 表。
/// ⚠️ 原实现是 16 条硬编码 mock，整个文件连 `tcb_rest_client.dart` 都没 import，
///    没有任何网络能力 —— 所谓「大鱼榜」「人气钓友榜」全是这几个写死的人
///    （蓝鳍金枪鱼 164kg归「海钓阿强」、青鱼 64kg 归「钓鱼王」…）在互相刷榜。
/// 现在改为真实云库查询。
class CatchService {
  static const _table = 'catches';
  static const _likeTable = 'catch_likes';
  static final _ctrl = ChangeNotifier();

  /// 云库渔获缓存
  static List<CatchItem> _cache = [];

  /// catchId -> 我是否点过赞
  static final Map<String, bool> _liked = {};
  static bool _likesLoaded = false;

  static ChangeNotifier subscribe() => _ctrl;

  static bool get isDataEmpty => _cache.isEmpty;

  /// 全部渔获（真实数据；云库为空时返回空列表而非假数据）
  static List<CatchItem> allItems() => List.unmodifiable(_cache);

  // ---------------------------------------------------------------------------
  // 序列化
  // ---------------------------------------------------------------------------
  static List<String> _decodeImages(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  static Map<String, dynamic> toRow(CatchItem c) => {
        'id': c.id,
        'userId': c.userId,
        'userName': c.userName,
        'userAvatar': c.userAvatar ?? '',
        'fish': c.fish,
        'species': '',
        'weightKg': c.weight,
        'lengthCm': c.length,
        'spotId': c.spotId ?? '',
        'spotName': c.spotName ?? '',
        'city': c.city ?? '',
        'images': c.images.join(','),
        'note': c.note ?? '',
        'likeCount': c.likes,
        'commentCount': c.comments,
        'verified': c.verified,
        'createdAt': c.createdAt.toIso8601String(),
      };

  static CatchItem fromRow(Map<String, dynamic> r) => CatchItem(
        id: r['id'] as String? ?? '',
        userId: r['userId'] as String? ?? '',
        userName: r['userName'] as String? ?? '钓友',
        userAvatar: (r['userAvatar'] as String?)?.isNotEmpty == true
            ? r['userAvatar'] as String
            : null,
        fish: r['fish'] as String? ?? '',
        weight: (r['weightKg'] as num?)?.toDouble() ?? 0,
        length: (r['lengthCm'] as num?)?.toDouble(),
        spotId: (r['spotId'] as String?)?.isNotEmpty == true ? r['spotId'] as String : null,
        spotName: (r['spotName'] as String?)?.isNotEmpty == true ? r['spotName'] as String : null,
        city: (r['city'] as String?)?.isNotEmpty == true ? r['city'] as String : null,
        images: _decodeImages(r['images']),
        note: (r['note'] as String?)?.isNotEmpty == true ? r['note'] as String : null,
        createdAt:
            DateTime.tryParse(r['createdAt'] as String? ?? '') ?? DateTime.now(),
        likes: (r['likeCount'] as num?)?.toInt() ?? 0,
        comments: (r['commentCount'] as num?)?.toInt() ?? 0,
        verified: r['verified'] == true,
      );

  // ---------------------------------------------------------------------------
  // 云端同步
  // ---------------------------------------------------------------------------

  /// 启动时调用：从云库拉取渔获。
  ///
  /// 云库为空（还没人发渔获）时返回空列表，榜单页会显示空态，
  /// 而不是拿16 条假数据撑场面。
  static Future<void> refreshFromCloud({int limit = 500}) async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query(_table, params: {
        'select': '*',
        'limit': '$limit',
        'order': 'createdAt.desc',
      });
      _cache = rows
          .map(fromRow)
          .where((c) => c.id.isNotEmpty)
          .toList();
      _ctrl.notifyListeners();
      debugPrint('[Catch] 云库同步 ${_cache.length} 条渔获');
    } catch (e) {
      // 表未建时保持空列表
      debugPrint('[Catch] 云库同步失败（榜单将为空）：$e');
      _cache = [];
      _ctrl.notifyListeners();
    }
  }

  /// 拉取我点过赞的渔获。
  static Future<void> refreshLikesFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query(_likeTable, params: {
        'select': 'catchId',
        'userId': 'eq.${UserProfile.id}',
        'limit': '1000',
      });
      for (final r in rows) {
        final id = r['catchId'] as String? ?? '';
        if (id.isNotEmpty) _liked[id] = true;
      }
      _likesLoaded = true;
    } catch (e) {
      debugPrint('[Catch] 点赞态同步失败（降级为会话内状态）：$e');
      _likesLoaded = true;
    }
  }

  static bool isLiked(String catchId) => _liked[catchId] ?? false;

  /// 切换渔获点赞（写入 catch_likes 明细表）。
  static Future<bool> toggleLike(String catchId) async {
    if (catchId.isEmpty) return false;
    final nowLiked = !(_liked[catchId] ?? false);
    final likeId = 'cl_${UserProfile.id}_$catchId';
    _liked[catchId] = nowLiked;
    _ctrl.notifyListeners();

    if (!BackendConfig.cloudEnabled) return nowLiked;
    try {
      if (nowLiked) {
        await TcbRestClient.upsert(_likeTable, {
          'id': likeId,
          'catchId': catchId,
          'userId': UserProfile.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        await TcbRestClient.delete(_likeTable, {'id': 'eq.$likeId'});
      }
      final idx = _cache.indexWhere((c) => c.id == catchId);
      if (idx >= 0) {
        final c = _cache[idx];
        final newLikes = (c.likes + (nowLiked ? 1 : -1)).clamp(0, 1 << 30);
        _cache[idx] = CatchItem(
          id: c.id,
          userId: c.userId,
          userName: c.userName,
          userAvatar: c.userAvatar,
          fish: c.fish,
          weight: c.weight,
          length: c.length,
          spotId: c.spotId,
          spotName: c.spotName,
          city: c.city,
          images: c.images,
          note: c.note,
          createdAt: c.createdAt,
          likes: newLikes,
          comments: c.comments,
          verified: c.verified,
        );
        await TcbRestClient.update(_table, {'id': 'eq.$catchId'}, {'likeCount': newLikes});
        _ctrl.notifyListeners();
      }
      return nowLiked;
    } catch (e) {
      debugPrint('[Catch] 点赞同步失败，已回滚：$e');
      _liked[catchId] = !nowLiked;
      _ctrl.notifyListeners();
      return !nowLiked;
    }
  }

  /// 发布渔获（写入云库）。
  static Future<bool> publish(CatchItem c) async {
    _cache.insert(0, c);
    _ctrl.notifyListeners();
    if (!BackendConfig.cloudEnabled) return true;
    try {
      await TcbRestClient.insert(_table, toRow(c));
      return true;
    } catch (e) {
      debugPrint('[Catch] 发布失败：$e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 榜单（基于真实数据聚合）
  // ---------------------------------------------------------------------------

  /// 重量榜（单尾最重）
  /// [region] 按城市推断大区筛选；[water] 按鱼种推断淡海水筛选。
  static List<CatchItem> weightRanking({
    int limit = 50,
    FishingRegion region = FishingRegion.all,
    WaterType water = WaterType.all,
  }) {
    var list = List<CatchItem>.from(_cache);
    if (region != FishingRegion.all) {
      list = list.where((c) => c.city != null && regionOfCity(c.city!) == region).toList();
    }
    if (water != WaterType.all) {
      list = list.where((c) => waterTypeOfFish(c.fish) == water).toList();
    }
    list.sort((a, b) => b.weight.compareTo(a.weight));
    return list.take(limit).toList();
  }

  /// 数量榜（本周累计尾数）
  static List<Map<String, dynamic>> countRanking({int limit = 20}) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    final counts = <String, int>{};
    final userInfo = <String, CatchItem>{};

    for (final c in _cache) {
      if (c.createdAt.isAfter(weekStart)) {
        counts[c.userId] = (counts[c.userId] ?? 0) + 1;
        userInfo[c.userId] = c;
      }
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) {
      final info = userInfo[e.key]!;
      return {
        'userId': e.key,
        'userName': info.userName,
        'count': e.value,
        'latestCatch': info,
      };
    }).toList();
  }

  /// 赛季榜（积分累计）
  static List<Map<String, dynamic>> seasonRanking({int limit = 50}) {
    final points = <String, int>{};
    final userInfo = <String, CatchItem>{};

    for (final c in _cache) {
      points[c.userId] = (points[c.userId] ?? 0) + c.points;
      userInfo[c.userId] = c;
    }

    final sorted = points.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) {
      final info = userInfo[e.key]!;
      return {
        'userId': e.key,
        'userName': info.userName,
        'points': e.value,
        'topCatch': info,
      };
    }).toList();
  }

  /// 新秀榜。
  ///
  /// ⚠️ 原实现用 `userId == 'u009' || userId == 'u010'` 这个写死判断谁是新手，
  ///    完全不查真实注册时间。现在基于「注册时间距今30 天内」判定。
  /// 若账号体系尚未记录注册时间，则该用户不参与新秀榜（不编造）。
  static List<Map<String, dynamic>> rookieRanking({
    int limit = 20,
    Map<String, DateTime> registeredAt = const {},
  }) {
    if (registeredAt.isEmpty) return const [];
    final now = DateTime.now();
    final points = <String, int>{};
    final userInfo = <String, CatchItem>{};

    for (final c in _cache) {
      final reg = registeredAt[c.userId];
      if (reg == null) continue;
      if (c.createdAt.difference(reg).inDays > 30) continue;
      points[c.userId] = (points[c.userId] ?? 0) + c.points;
      userInfo[c.userId] = c;
    }

    final sorted = points.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) {
      final info = userInfo[e.key]!;
      return {
        'userId': e.key,
        'userName': info.userName,
        'points': e.value,
        'topCatch': info,
      };
    }).toList();
  }

  /// 同城榜（指定城市，按重量）
  static List<CatchItem> cityRanking(String city, {int limit = 20}) {
    final filtered = _cache.where((c) => c.city == city).toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    return filtered.take(limit).toList();
  }

  /// 月度赛（指定月份 + 鱼种）
  static List<CatchItem> monthlyRanking({
    required int year,
    required int month,
    String? targetFish,
    double? minWeight,
    int limit = 50,
  }) {
    final filtered = _cache.where((c) {
      if (c.createdAt.year != year || c.createdAt.month != month) return false;
      if (targetFish != null && c.fish != targetFish) return false;
      if (minWeight != null && c.weight < minWeight) return false;
      return true;
    }).toList();

    filtered.sort((a, b) => b.weight.compareTo(a.weight));
    return filtered.take(limit).toList();
  }

  /// 清空本机缓存（登出时调用）。
  static void resetMyContent() {
    _liked.clear();
    _likesLoaded = false;
  }
}