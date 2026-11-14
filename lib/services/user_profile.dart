import 'dart:developer' show log;
import 'package:shared_preferences/shared_preferences.dart';
import 'backend_config.dart';
import 'tcb_rest_client.dart';

/// 当前设备用户资料（单一数据源）。
/// 内存单例 + SharedPreferences 持久化；资料本身同步到云库 profiles 表。
/// 登出 = resetToGuest()：清空所有用户态数据，回到干净游客。
class UserProfile {
  static const String kTable = 'profiles';
  static const String kId = 'me';

  static const String kGuestName = '钓鱼人';
  static const String kGuestBio = '这个人很懒，什么都没留下';
  static const String kGuestCity = '';
  static const String kGuestGender = '';
  static const String kGuestAvatar = '🐟';

  /// 当前用户真实 uid。
  ///
  /// ⚠️ 原实现全局固定 'me'，意味着所有设备、所有账号在云库里共用同一行
  ///    profiles，发帖 authorId、收藏、关注、点赞全部塌缩成一个人，
  ///    换个手机登录另一个账号，看到的还是这个人的数据。
  /// 现在改为按登录凭据（手机号 / Apple sub）稳定派生 uid：
  ///   同一账号在同一设备上多次登录得到同一个 id（数据可恢复）；
  ///   不同账号得到不同 id（数据彼此隔离）。
  /// 游客态下发一个随机 uid，落在本机 SP 中，保证游客自己的草稿/点赞不与他机混同。
  static String get id => instance.uid;
  /// 当前用户 uid 的实例副本（[id] 的数据源）。
  String uid = kId;

  /// 由登录凭据派生稳定 uid（手机号脱敏、Apple sub 原值）。
  static String _deriveUid(String credential) {
    if (credential.isEmpty) return '';
    // 仅取尾部哈希，短且不含手机号明文，避免在库里直接看到用户手机号
    var h = 0x811c9dc5;
    for (final unit in credential.codeUnits) {
      h = (h ^ unit) * 0x01000193;
      h &= 0xFFFFFFFF;
    }
    return 'u_${h.toRadixString(36)}';
  }

  static final UserProfile instance = UserProfile._();
  UserProfile._();

  // 本地持久化键（登录态同步，不发云库，避免多设备覆盖）
  static const _kIsLoggedIn = 'up_isLoggedIn';
  static const _kLoginMethod = 'up_loginMethod';
  static const _kLoginName = 'up_loginName';
  static const _kPhone = 'up_phone';
  static const _kAvatarData = 'up_avatarData';
  static const _kUid = 'up_uid';
  static const _kNickname = 'up_nickname';

  /// 启动时调用：从本地 SharedPreferences 恢复登录态。
  /// 不读云库，避免刷新后自动续登/被云库 profile 覆盖。
  static Future<void> hydrate() async {
    final p = await SharedPreferences.getInstance();
    instance.isLoggedIn = p.getBool(_kIsLoggedIn) ?? false;
    instance.loginMethod = p.getString(_kLoginMethod) ?? '';
    instance.loginName = p.getString(_kLoginName) ?? '';
    instance.phone = p.getString(_kPhone) ?? '';
    instance.avatarData = p.getString(_kAvatarData) ?? '';
    instance.uid = p.getString(_kUid) ?? '';
    instance.nickname = p.getString(_kNickname) ?? '';

    // 游客态也要有本机稳定 uid，否则游客态的点赞/收藏无法跨会话保留，
    // 且会和所有其他游客撞在同一个 'me' 上。
    if (instance.uid.isEmpty) {
      final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
      final rnd = identityHashCode(Object()).toRadixString(36);
      instance.uid = 'g_${ts.substring(ts.length - 6)}${rnd.substring(rnd.length - 4)}';
      await p.setString(_kUid, instance.uid);
    }
    log('[UserProfile] hydrate: uid=${instance.uid} loggedIn=${instance.isLoggedIn}');
  }

  Future<void> _persistLogin() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kIsLoggedIn, isLoggedIn);
    await p.setString(_kLoginMethod, loginMethod);
    await p.setString(_kLoginName, loginName);
    await p.setString(_kPhone, phone);
    await p.setString(_kAvatarData, avatarData);
    await p.setString(_kUid, uid);
    await p.setString(_kNickname, nickname);
  }

  // 基本信息
  String name = kGuestName;
  String bio = kGuestBio;
  String city = kGuestCity;
  String gender = kGuestGender;
  String avatarEmoji = kGuestAvatar;
  String phone = ''; // 手机号（仅登录态内存用，不对外暴露完整号）

  /// 可被他人搜到的昵称。
  ///
  /// ⚠️ 手机号登录时 [name] 会自动脱敏成 `138****8888`，别人不可能靠这个搜到你，
  ///    也没有任何一个字段能让你被搜到（库里不存完整手机号）。
  ///    所以必须允许用户自己起一个昵称作为唯一可检索的公开标识。
  String nickname = '';

  /// 自定义头像（压缩后的 JPEG base64，空串表示使用 emoji 默认头像）。
  /// 优先级高于 [avatarEmoji]；存本地 SP + 云库 profiles.avatarData 双份，
  /// 刷新/换设备都能恢复。早期量级直接存库，省掉对象存储桶。
  String avatarData = '';

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
    nickname = '';
    avatarData = '';
    isLoggedIn = false;
    loginMethod = '';
    loginName = '';
    // 换一个新的游客 uid：否则登出后仍能读到上个账号绑定的收藏/关注/点赞，
    // 也可能和别人撞同一个游客 id。
    uid = 'g_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
    _notify();
    _persistLogin(); // fire-and-forget
  }

  /// 登录成功后调用：写入登录态（保留/更新显示名），并立即同步到云库覆盖旧数据。
  /// [method] 登录方式：'apple' | 'phone'
  /// [displayName] 第三方返回的展示名（如 Apple 全名），手机号登录时传 null
  /// [phone] 手机号（手机号登录时传入，用于内部记录；展示名自动生成 138****xxxx 格式）
  Future<void> markLoggedIn({
    required String method,
    String? displayName,
    String? phone,
  }) async {
    isLoggedIn = true;
    loginMethod = method;
    loginName = displayName ?? '';
    // 同一凭据派生同一 uid → 云库资料可跨设备恢复
    final credential = (phone != null && phone.isNotEmpty)
        ? 'phone:$phone'
        : 'other:${displayName ?? ''}';
    final derived = _deriveUid(credential);
    if (derived.isNotEmpty) uid = derived;
    if (phone != null && phone.isNotEmpty) {
      this.phone = phone;
      // 手机号登录时，显示名自动脱敏生成，不依赖第三方返回
      final masked = '${phone.substring(0, 3)}****${phone.substring(7)}';
      name = masked;
      // ⚠️ 脱敏号没人能搜到。首次登录给一个可搜的默认昵称（钓友+uid尾巴），
      //    否则这个新注册用户在别人搜索框里是完全隐形的。
      if (nickname.trim().isEmpty) {
        nickname = '钓友${uid.length > 6 ? uid.substring(uid.length - 5) : uid}';
      }
      if (bio == kGuestBio) bio = '这个人很懒，什么都没留下';
    } else if (displayName != null && displayName.trim().isNotEmpty) {
      name = displayName.trim();
      if (nickname.trim().isEmpty) nickname = displayName.trim();
      if (bio == kGuestBio) bio = '这个人很懒，什么都没留下';
    }
    _notify();
    await _persistLogin(); // 同步落盘后再返回，避免杀进程丢登录态
    save(); // 同步到云库（覆盖老李等 mock profile）
  }

  /// 序列化（主键为当前用户真实 uid）
  ///
  /// ⚠️ **列名必须全小写**。2026-10-18 实测：PostgREST 对新加的列
  ///    是大小写敏感的 —— 库里建的是 `loginmethod` / `lastactiveat`，
  ///    传驼峰 `loginMethod` 会报 PGRST204「找不到该列」，**整条记录写不进去**。
  ///    （已有的老列如 nickname / userAId 本身没大小写，不受影响）
  ///
  /// 保留 _unsupportedColumns 作为防御：真缺列时剔除并自动重试，
  /// 保证核心字段（id / name / nickname）一定落库。
  static Set<String> _unsupportedColumns = <String>{};

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'nickname': nickname,
      'bio': bio,
      'city': city,
      'gender': gender,
      'avatarEmoji': avatarEmoji,
      'avatarData': avatarData,
      // ⚠️ 以下两列库里是小写，不能写驼峰
      'loginmethod': loginMethod,
      'lastactiveat': DateTime.now().toIso8601String(),
    };
    data.removeWhere((k, _) => _unsupportedColumns.contains(k));
    return data;
  }

  /// 用云库行覆盖本地字段
  ///
  /// ⚠️ PostgREST 返回的列名一律是**小写**（库里建的 loginMethod 读回来是
  ///    `loginmethod`、createdAt 是 `createdat`）。写用驼峰没问题，
  ///    读必须同时兼容两种大小写，否则新建的列永远读不到值。
  void applyFromCloud(Map<String, dynamic> row) {
    /// 取列值，兼容 PostgREST 的小写返回
    String? pick(String key) {
      if (row.containsKey(key)) return row[key]?.toString();
      final lower = key.toLowerCase();
      for (final e in row.entries) {
        if (e.key.toLowerCase() == lower) return e.value?.toString();
      }
      return null;
    }

    name = pick('name') ?? name;
    bio = pick('bio') ?? bio;
    city = pick('city') ?? city;
    gender = pick('gender') ?? gender;
    avatarEmoji = pick('avatarEmoji') ?? avatarEmoji;
    nickname = pick('nickname') ?? nickname;
    loginMethod = pick('loginMethod') ?? loginMethod;
    // 云库有头像则覆盖（无该字段时保留本地 SP 值）
    final cloudAvatar = pick('avatarData');
    if (cloudAvatar != null && cloudAvatar.isNotEmpty) avatarData = cloudAvatar;
    // 登录态仅内存，不由云库 profile 推导（避免刷新后自动续登）
    _notify();
  }

  /// 保存（写回云库，best-effort）
  ///
  /// 失败时若原因是「列不存在」（PGRST204），把该列记入黑名单并重试一次，
  /// 保证用户资料仍能落库 —— 否则整条注册资料永久丢失。
  void save() {
    _notify();
    if (!BackendConfig.cloudEnabled) return;
    TcbRestClient.upsert(kTable, toJson()).then((_) {
      log('[UserProfile] 已保存云库');
    }).catchError((e) {
      final msg = e.toString();
      final m = RegExp(r"column '([^']+)'").firstMatch(msg);
      if (m != null && _unsupportedColumns.add(m.group(1)!)) {
        log('[UserProfile] 列 ${m.group(1)} 不存在，去掉后重试一次');
        TcbRestClient.upsert(kTable, toJson()).then((_) {
          log('[UserProfile] 重试成功，资料已落库');
        }).catchError((e2) {
          log('[UserProfile] 重试仍失败：$e2');
        });
        return;
      }
      log('[UserProfile] 保存云库失败：$e');
    });
  }

  /// 启动后调用：从云库拉取当前用户资料覆盖本地；失败保留默认，不报错。
  Future<void> refreshFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query(kTable,
          params: {'select': '*', 'id': 'eq.$id', 'limit': '1'});
      if (rows.isNotEmpty) {
        applyFromCloud(rows.first);
        log('[UserProfile] 已从云库同步资料');
      }
    } catch (e) {
      log('[UserProfile] 云库同步失败，使用本地资料：$e');
    }
  }
}
