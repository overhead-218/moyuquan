import 'dart:developer' show log;
import 'backend_config.dart';
import 'tcb_rest_client.dart';

/// 当前设备用户资料（单一数据源）。
/// 内存单例，会话内有效；启动默认为「本地游客」（中性默认值，非 mock 账号）。
/// 登出 = resetToGuest()：清空所有用户态数据，回到干净游客。
class UserProfile {
  static const String _table = 'profiles';
  static const String kId = 'me';

  static const String kGuestName = '钓鱼人';
  static const String kGuestBio = '这个人很懒，什么都没留下';
  static const String kGuestCity = '';
  static const String kGuestGender = '';
  static const String kGuestAvatar = '🐟';

  static final UserProfile instance = UserProfile._();
  UserProfile._();

  // 基本信息
  String name = kGuestName;
  String bio = kGuestBio;
  String city = kGuestCity;
  String gender = kGuestGender;
  String avatarEmoji = kGuestAvatar;
  String phone = ''; // 手机号（仅登录态内存用，不对外暴露完整号）

  // 登录态（仅内存，无持久化）：
  // - 启动/登出后：isLoggedIn=false（游客浏览态）
  // - Apple/手机号登录成功：isLoggedIn=true，loginMethod 记录来源
  bool isLoggedIn = false;
  String loginMethod = ''; // 'apple' | 'guest' | 'phone'
  String loginName = ''; // 第三方返回的显示名（如 Apple 全名）

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

  /// 重置为干净游客态（登出调用）：清空所有用户数据并通知 UI。
  void resetToGuest() {
    name = kGuestName;
    bio = kGuestBio;
    city = kGuestCity;
    gender = kGuestGender;
    avatarEmoji = kGuestAvatar;
    phone = '';
    isLoggedIn = false;
    loginMethod = '';
    loginName = '';
    _notify();
  }

  /// 登录成功后调用：写入登录态（保留/更新显示名）。
  /// [method] 登录方式：'apple' | 'phone'
  /// [displayName] 第三方返回的展示名（如 Apple 全名），手机号登录时传 null
  /// [phone] 手机号（手机号登录时传入，用于内部记录；展示名自动生成 138****xxxx 格式）
  void markLoggedIn({
    required String method,
    String? displayName,
    String? phone,
  }) {
    isLoggedIn = true;
    loginMethod = method;
    loginName = displayName ?? '';
    if (phone != null && phone.isNotEmpty) {
      this.phone = phone;
      // 手机号登录时，显示名自动脱敏生成，不依赖第三方返回
      final masked = '${phone.substring(0, 3)}****${phone.substring(7)}';
      name = masked;
      if (bio == kGuestBio) bio = '这个人很懒，什么都没留下';
    } else if (displayName != null && displayName.trim().isNotEmpty) {
      name = displayName.trim();
      if (bio == kGuestBio) bio = '这个人很懒，什么都没留下';
    }
    _notify();
  }

  /// 序列化（列名与 profiles 表 1:1，主键 id 固定 'me'）
  Map<String, dynamic> toJson() => {
        'id': kId,
        'name': name,
        'bio': bio,
        'city': city,
        'gender': gender,
        'avatarEmoji': avatarEmoji,
        'loginMethod': loginMethod,
      };

  /// 用云库行覆盖本地字段
  void applyFromCloud(Map<String, dynamic> row) {
    name = row['name']?.toString() ?? name;
    bio = row['bio']?.toString() ?? bio;
    city = row['city']?.toString() ?? city;
    gender = row['gender']?.toString() ?? gender;
    avatarEmoji = row['avatarEmoji']?.toString() ?? avatarEmoji;
    loginMethod = row['loginMethod']?.toString() ?? loginMethod;
    isLoggedIn = loginMethod.isNotEmpty;
    _notify();
  }

  /// 保存（写回云库，best-effort）
  void save() {
    _notify();
    if (!BackendConfig.cloudEnabled) return;
    TcbRestClient.upsert(_table, toJson()).then((_) {
      log('[UserProfile] 已保存云库');
    }).catchError((e) {
      log('[UserProfile] 保存云库失败：$e');
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
        log('[UserProfile] 已从云库同步资料');
      }
    } catch (e) {
      log('[UserProfile] 云库同步失败，使用本地资料：$e');
    }
  }
}
