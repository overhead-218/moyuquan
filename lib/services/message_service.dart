import 'backend_config.dart';
import 'tcb_rest_client.dart';

/// 消息数据源（mock + 云库可切换）。
/// profile 页与消息页均通过此入口读取，未读数由列表动态统计，不写死。
class MessageService {
  static const String _table = 'messages';

  static final List<Map<String, dynamic>> _seed = [
    {'name': '海钓阿强', 'last': '明天出发钓鱼？', 'time': '刚刚', 'avatar': '🎣', 'unread': 2},
    {'name': '钓鱼王', 'last': '这个饵料配方很赞', 'time': '12:30', 'avatar': '🐟', 'unread': 0},
    {'name': '野钓大叔', 'last': '[图片]', 'time': '昨天', 'avatar': '🎣', 'unread': 1},
    {'name': '江南老饕', 'last': '好的，到时见', 'time': '昨天', 'avatar': '🦑', 'unread': 0},
    {'name': '老李', 'last': '上次那个钓点还有?', 'time': '周一', 'avatar': '🐠', 'unread': 0},
    {'name': '渔民小张', 'last': '今天收获不错', 'time': '周日', 'avatar': '🐟', 'unread': 0},
    {'name': '菜鸟', 'last': '新手求带', 'time': '周日', 'avatar': '🎣', 'unread': 5},
  ];

  // _cache 为稳定引用，外部捕获的引用（message_page 的 messages）自动可见。
  static final List<Map<String, dynamic>> _cache =
      _seed.map((m) => Map<String, dynamic>.from(m)).toList();

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
    _pushRead(name);
  }

  /// 标记全部已读
  static void markAllRead() {
    for (var i = 0; i < _cache.length; i++) {
      _cache[i] = {..._cache[i], 'unread': 0};
    }
    _notify();
    for (final m in _cache) {
      _pushRead(m['name'] as String);
    }
  }

  /// 启动后调用：从云库拉取会话覆盖本地；失败保留 mock，永不白屏。
  static Future<void> refreshFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query(_table,
          params: {'select': '*', 'limit': '100'});
      if (rows.isNotEmpty) {
        _cache
          ..clear()
          ..addAll(rows.map(_rowToMsg));
        _notify();
        print('[MessageService] 已从云库同步 ${_cache.length} 条会话');
      }
    } catch (e) {
      print('[MessageService] 云库同步失败，使用本地数据：$e');
    }
  }

  /// 一次性：把本地 mock 会话写入云库（id=name，按主键冲突忽略）。
  static Future<void> seedFromMockToCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    for (final m in _seed) {
      await TcbRestClient.upsert(_table, _msgToRow(m)).catchError((e) {
        print('[MessageService] seed 跳过 ${m['name']}: $e');
      });
    }
    await refreshFromCloud();
  }

  static void _pushRead(String name) {
    if (!BackendConfig.cloudEnabled) return;
    TcbRestClient.update(_table, {'id': 'eq.$name'}, {'unread': 0})
        .then((_) {
      print('[MessageService] 已同步已读：$name');
    }).catchError((e) {
      print('[MessageService] 已读同步失败（本地已更新）：$e');
    });
  }

  static Map<String, dynamic> _rowToMsg(Map<String, dynamic> row) => {
        'name': row['name'] ?? '',
        'last': row['last'] ?? '',
        'time': row['time'] ?? '',
        'avatar': row['avatar'] ?? '🎣',
        'unread': row['unread'] is int
            ? row['unread']
            : int.tryParse('${row['unread']}') ?? 0,
      };

  static Map<String, dynamic> _msgToRow(Map<String, dynamic> m) => {
        'id': m['name'] ?? '',
        'name': m['name'],
        'last': m['last'],
        'time': m['time'],
        'avatar': m['avatar'],
        'unread': m['unread'],
      };
}
