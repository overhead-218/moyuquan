import 'backend_config.dart';
import 'tcb_rest_client.dart';

/// 当前登录用户资料（单一数据源）。
/// 内存单例，会话内有效；接云库后可在启动时 load()、保存时 save() 写回。
class UserProfile {
  static const String _table = 'profiles';
  static const String kId = 'me';

  static final UserProfile instance = UserProfile._();
  UserProfile._();

  String name = '老李';
  String bio = '已钓鱼 3 年 · 钓获 128 种';
  String city = '杭州';
  String gender = '男';
  String avatarEmoji = '🎣';

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

  /// 序列化（列名与 profiles 表 1:1，主键 id 固定 'me'）
  Map<String, dynamic> toJson() => {
        'id': kId,
        'name': name,
        'bio': bio,
        'city': city,
        'gender': gender,
        'avatarEmoji': avatarEmoji,
      };

  /// 用云库行覆盖本地字段
  void applyFromCloud(Map<String, dynamic> row) {
    name = row['name']?.toString() ?? name;
    bio = row['bio']?.toString() ?? bio;
    city = row['city']?.toString() ?? city;
    gender = row['gender']?.toString() ?? gender;
    avatarEmoji = row['avatarEmoji']?.toString() ?? avatarEmoji;
    _notify();
  }

  /// 保存（写回云库，best-effort）
  void save() {
    _notify();
    if (!BackendConfig.cloudEnabled) return;
    TcbRestClient.upsert(_table, toJson()).then((_) {
      print('[UserProfile] 已保存云库');
    }).catchError((e) {
      print('[UserProfile] 保存云库失败：$e');
    });
  }

  /// 启动后调用：从云库拉取当前用户资料覆盖本地；失败保留默认，不报错。
  Future<void> refreshFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query(_table,
          params: {'select': '*', 'id': 'eq.$kId', 'limit': '1'});
      if (rows.isNotEmpty) {
        applyFromCloud(rows.first);
        print('[UserProfile] 已从云库同步资料');
      }
    } catch (e) {
      print('[UserProfile] 云库同步失败，使用本地资料：$e');
    }
  }
}
