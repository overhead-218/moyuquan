import 'backend_config.dart';
import 'chat_service.dart';
import 'tcb_rest_client.dart';
import 'user_profile.dart';

/// 会话列表数据源。
///
/// ⚠️ 原实现存在严重隐私问题：会话存在一张全局共享的 `messages` 表里，
///    `refreshFromCloud()` 直接 `select *` 拉全表，不按当前用户过滤，
///    也没有 userId/userAId 列 —— 任何用户登录都能看到所有人的私信摘要
///    （对方昵称、最后一条消息内容、未读数）。
/// 现在改为读`conversations` 表并严格按当前 uid 过滤。
class MessageService {
  /// 会话表（按 userAId / userBId 归属）
  static const String _table = 'conversations';

  // _cache 为稳定引用，外部捕获的引用（message_page 的 messages）自动可见。
  // 初始为空：新用户没有任何会话，全部由真实聊天行为产生。
  static final List<Map<String, dynamic>> _cache = <Map<String, dynamic>>[];

  /// 对方用户资料缓存：uid -> {name, avatar}，用于会话列表展示
  static final Map<String, Map<String, String>> _peerInfo = {};

  static final Set<void Function()> _listeners = {};
  static void addListener(void Function() cb) => _listeners.add(cb);
  static void removeListener(void Function() cb) => _listeners.remove(cb);
  static void _notify() {
    for (final cb in List.of(_listeners)) {
      try {
        cb();
      } catch (_) {}
    }
  }

  /// 会话列表（与旧接口一致：List<Map>，含 name/last/time/avatar/unread）
  static List<Map<String, dynamic>> get messages => _cache;

  /// 总未读数（所有会话未读之和）
  static int get totalUnread =>
      _cache.fold(0, (sum, m) => sum + ((m['unread'] as num?)?.toInt() ?? 0));

  /// 标记某会话已读（本地 + 云库）
  static void markRead(String name) {
    final idx = _cache.indexWhere((m) => m['name'] == name);
    if (idx < 0) return;
    _cache[idx] = {..._cache[idx], 'unread': 0};
    _notify();
    _pushRead(_cache[idx]['conversationId'] as String? ?? '');
  }

  /// 更新/创建会话（本地）：聊天页发出消息后调用，
  /// 让会话列表显示最后一条消息并置顶。
  /// 云库写入由 [ChatService.send] 负责，这里只维护本地列表。
  static void upsertConversation({
    required String name,
    required String avatar,
    String userId = '',
    required String last,
    String time = '刚刚',
    int unread = 0,
  }) {
    final idx = _cache.indexWhere((m) => m['name'] == name);
    final convId = userId.isNotEmpty
        ? ChatService.conversationId(UserProfile.id, userId)
        : 'conv_$name';
    if (userId.isNotEmpty) {
      _peerInfo[userId] = {'name': name, 'avatar': avatar};
    }
    final row = <String, dynamic>{
      'name': name,
      'last': last,
      'time': time,
      'avatar': avatar,
      'unread': unread,
      'userId': userId,
      'conversationId': convId,
    };
    if (idx >= 0) {
      _cache.removeAt(idx);
    }
    _cache.insert(0, row);
    _notify();
  }

  /// 清空会话（登出时调用）。
  static void clearAll() {
    _cache.clear();
    _peerInfo.clear();
    _notify();
  }

  /// 删除单个会话（清空聊天记录时调用）。
  static void removeConversation(String name) {
    final idx = _cache.indexWhere((m) => m['name'] == name);
    if (idx >= 0) {
      final convId = _cache[idx]['conversationId'] as String? ?? '';
      if (convId.isNotEmpty) {
        ChatService.deleteConversation(convId);
      }
    }
    _cache.removeWhere((m) => m['name'] == name);
    _notify();
  }

  /// 标记全部已读
  static void markAllRead() {
    for (var i = 0; i < _cache.length; i++) {
      _cache[i] = {..._cache[i], 'unread': 0};
    }
    _notify();
    for (final m in _cache) {
      _pushRead(m['conversationId'] as String? ?? '');
    }
  }

  /// 启动后调用：拉取「与我有关」的会话。
  ///
  /// ⚠️ 修复隐私问题：原实现直接 `select *` 拉全局 messages 表，
  ///    不按当前用户过滤 → 任何人都能看到所有人的私信摘要。
  /// 现在严格只取 userAId = 我 或 userBId = 我 的会话。
  static Future<void> refreshFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final me = UserProfile.id;
      // ⚠️ PostgREST 的 or 语法用**点号**分隔条件：`(userAId.eq.me,userBId.eq.me)`
      //    写成 `(userAId=eq.me,userBId=eq.me)` 会直接报
      //    PGRST100 "failed to parse logic tree" → 会话列表永远加载不出来。
      final rows = await TcbRestClient.query(_table, params: {
        'select': '*',
        'or': '(userAId.eq.$me,userBId.eq.$me)',
        'limit': '200',
        'order': 'lastAt.desc',
      });

      final peerIds = <String>[];
      for (final r in rows) {
        // 对端 = 不是我的那一侧
        final peer = (r['userAId'] as String? ?? '') == me
            ? (r['userBId'] as String? ?? '')
            : (r['userAId'] as String? ?? '');
        if (peer.isNotEmpty) peerIds.add(peer);
      }
      await _hydratePeers(peerIds);

      _cache
        ..clear()
        ..addAll(rows.map((r) {
          final aId = r['userAId'] as String? ?? '';
          final peerId = aId == me ? (r['userBId'] as String? ?? '') : aId;
          final unreadForMe = aId == me
              ? (r['unreadB'] as num?)?.toInt() ?? 0
              : (r['unreadA'] as num?)?.toInt() ?? 0;
          final info = _peerInfo[peerId];
          return <String, dynamic>{
            'name': info?['name'] ?? '钓友',
            'avatar': info?['avatar'] ?? '🎣',
            'last': r['lastMsg'] as String? ?? '',
            'time': r['lastAt'] as String? ?? '',
            'unread': unreadForMe,
            'userId': peerId,
            'conversationId': r['id'] as String? ?? '',
          };
        }));
      _notify();
      print('[MessageService] 已同步 ${_cache.length} 条会话');
    } catch (e) {
      // 表未建时保持空列表
      print('[MessageService] 会话同步失败（消息列表为空）：$e');
      _cache.clear();
      _notify();
    }
  }

  /// 补齐对端用户昵称/头像（来自 profiles 表）
  static Future<void> _hydratePeers(List<String> ids) async {
    final missing = ids.where((id) => !_peerInfo.containsKey(id)).toList();
    if (missing.isEmpty) return;
    try {
      final rows = await TcbRestClient.query('profiles', params: {
        // 带上 nickname：手机号用户的 name 是 138****8888 脱敏号，
        // 会话列表优先展示 nickname。
        'select': 'id,name,nickname,avatarEmoji',
        'id': 'in.(${missing.join(',')})',
        'limit': '${missing.length}',
      });
      for (final r in rows) {
        final id = r['id'] as String? ?? '';
        if (id.isEmpty) continue;
        // PostgREST 返回列名可能全小写，两种大小写都兼容
        String pick(String key) {
          if (r.containsKey(key)) return r[key] as String? ?? '';
          final lower = key.toLowerCase();
          for (final e in r.entries) {
            if (e.key.toLowerCase() == lower) return e.value as String? ?? '';
          }
          return '';
        }

        final nick = pick('nickname');
        final name = pick('name');
        _peerInfo[id] = {
          'name': nick.isNotEmpty ? nick : (name.isNotEmpty ? name : '钓友'),
          'avatar': pick('avatarEmoji').isNotEmpty ? pick('avatarEmoji') : '🎣',
        };
      }
    } catch (e) {
      // profiles 无对应行时保留占位名，不编造人设
    }
  }

  /// 把对方会话标记为已读
  static void _pushRead(String conversationId) {
    if (!BackendConfig.cloudEnabled || conversationId.isEmpty) return;
    final me = UserProfile.id;
    TcbRestClient.query(_table, params: {
      'select': 'id,userAId',
      'id': 'eq.$conversationId',
      'limit': '1',
    }).then((rows) async {
      if (rows.isEmpty) return;
      final aId = rows.first['userAId'] as String? ?? '';
      // 我是 userA 则清 unreadB，反之清 unreadA
      final patch = aId == me ? {'unreadB': 0} : {'unreadA': 0};
      await TcbRestClient.update(_table, {'id': 'eq.$conversationId'}, patch);
    }).catchError((e) {
      print('[MessageService] 已读同步失败：$e');
    });
  }
}
