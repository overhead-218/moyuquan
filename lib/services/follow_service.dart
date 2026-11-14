import 'package:flutter/foundation.dart';

import 'backend_config.dart';
import 'tcb_rest_client.dart';
import 'user_profile.dart';

/// 关注服务。
///
/// 数据源：云库 `follows` 表（权威）+ 本地缓存（UI 即时响应）。
/// ⚠️ 原实现是纯内存单例 + 10 个硬编码演示用户（「海钓阿强」「钓鱼王老周」等），
///    关注状态重启即丢、跨设备无效，粉丝列表永远是空的，
///    搜索用户也只能搜到这 10 个假人。现在全部走真实云库。
class FollowService {
  static final FollowService instance = FollowService._();
  FollowService._();

  static const _table = 'follows';

  /// 用户资料缓存：userId -> {name, avatar, bio}，用于关注/粉丝列表展示。
  /// 来源是云库 profiles 表与真实发帖作者，不再使用假用户池。
  static final Map<String, Map<String, String>> _profileCache = {};

  /// 我关注的作者 id（有序，先关注在前）
  final List<String> _following = [];

  /// 关注我的人
  final List<String> _followers = [];

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

  // ── 查询 ─────────────────────────────────────────
  List<String> get followingIds => List.unmodifiable(_following);
  List<String> get followerIds => List.unmodifiable(_followers);
  int get followingCount => _following.length;
  int get followerCount => _followers.length;

  bool isFollowing(String userId) => _following.contains(userId);

  /// 缓存作者资料（发帖、榜单等场景发现新作者时调用）。
  static void cacheUser(String userId,
      {String? name, String? avatar, String? bio}) {
    if (userId.isEmpty) return;
    final cur = _profileCache[userId] ?? {};
    _profileCache[userId] = {
      'id': userId,
      'name': name ?? cur['name'] ?? '钓鱼人',
      'avatar': avatar ?? cur['avatar'] ?? '🎣',
      'bio': bio ?? cur['bio'] ?? '',
    };
  }

  /// 取作者信息；未缓存时返回通用占位（不编造人设）。
  static Map<String, String> userInfo(String userId) =>
      _profileCache[userId] ??
      {'id': userId, 'name': '钓鱼人', 'avatar': '🎣', 'bio': ''};

  /// 按昵称反查已缓存的用户 id；找不到返回空串。
  static String userIdByName(String name) {
    for (final u in _profileCache.values) {
      if (u['name'] == name) return u['id']!;
    }
    return '';
  }

  /// 批量补齐用户资料显示名（关注/粉丝列表用）。
  static Future<void> hydrateProfiles(List<String> userIds) async {
    if (!BackendConfig.cloudEnabled) return;
    final missing = userIds.where((id) => !_profileCache.containsKey(id)).toList();
    if (missing.isEmpty) return;
    try {
      // PostgREST 的 in 过滤：id=in.(a,b,c)
      final rows = await TcbRestClient.query('profiles', params: {
        'select': 'id,name,avatarEmoji,bio',
        'id': 'in.(${missing.join(',')})',
        'limit': '${missing.length}',
      });
      for (final r in rows) {
        final id = r['id'] as String? ?? '';
        if (id.isEmpty) continue;
        _profileCache[id] = {
          'id': id,
          'name': r['name'] as String? ?? '钓鱼人',
          'avatar': r['avatarEmoji'] as String? ?? '🎣',
          'bio': r['bio'] as String? ?? '',
        };
      }
    } catch (e) {
      // profiles 无此用户行属正常（发帖用户可能未建 profile），静默降级
      debugPrint('[Follow] 用户资料补齐失败：$e');
    }
  }

  // ── 云端同步 ───────────────────────────────────────
  /// 启动时调用：从云库恢复我关注的人与我的粉丝。
  Future<void> refreshFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final me = UserProfile.id;
      final followingRows = await TcbRestClient.query(_table, params: {
        'select': 'followeeId',
        'followerId': 'eq.$me',
        'limit': '1000',
      });
      final followerRows = await TcbRestClient.query(_table, params: {
        'select': 'followerId',
        'followeeId': 'eq.$me',
        'limit': '1000',
      });

      _following
        ..clear()
        ..addAll(followingRows
            .map((r) => r['followeeId'] as String? ?? '')
            .where((e) => e.isNotEmpty));
      _followers
        ..clear()
        ..addAll(followerRows
            .map((r) => r['followerId'] as String? ?? '')
            .where((e) => e.isNotEmpty));

      await hydrateProfiles([..._following, ..._followers]);
      _notify();
      debugPrint('[Follow] 云库同步：关注 ${_following.length}，粉丝 ${_followers.length}');
    } catch (e) {
      // 表未建时降级，不阻断启动
      debugPrint('[Follow] 云库同步失败（降级为空列表）：$e');
    }
  }

  static String _followId(String followerId, String followeeId) =>
      'f_${followerId}_$followeeId';

  // ── 操作 ─────────────────────────────────────────
  /// 切换关注状态，返回是否已关注。写库失败会回滚本地态。
  Future<bool> toggleFollow(String userId,
      {String? name, String? avatar, String? bio}) async {
    if (userId.isEmpty || userId == UserProfile.id) return isFollowing(userId);
    cacheUser(userId, name: name, avatar: avatar, bio: bio);

    final nowFollow = !_following.contains(userId);
    if (nowFollow) {
      _following.insert(0, userId);
    } else {
      _following.remove(userId);
    }
    _notify();

    if (!BackendConfig.cloudEnabled) return nowFollow;

    try {
      if (nowFollow) {
        await TcbRestClient.upsert(_table, {
          'id': _followId(UserProfile.id, userId),
          'followerId': UserProfile.id,
          'followeeId': userId,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        await TcbRestClient.delete(
            _table, {'id': 'eq.${_followId(UserProfile.id, userId)}'});
      }
      return nowFollow;
    } catch (e) {
      debugPrint('[Follow] 关注同步失败，已回滚：$e');
      if (nowFollow) {
        _following.remove(userId);
      } else {
        _following.insert(0, userId);
      }
      _notify();
      return !nowFollow;
    }
  }

  /// 清空本地关注/粉丝缓存（登出时调用）。
  void clearAll() {
    _following.clear();
    _followers.clear();
    _profileCache.clear();
    _notify();
  }
}