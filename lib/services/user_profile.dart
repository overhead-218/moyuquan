/// 当前登录用户资料（单一数据源）。
/// 内存单例，会话内有效；后续接 SharedPreferences 可做到重启保留。
class UserProfile {
  static final UserProfile instance = UserProfile._();
  UserProfile._();

  String name = '老李';
  String bio = '已钓鱼 3 年 · 钓获 128 种';
  String city = '杭州';
  String gender = '男';
  String avatarEmoji = '🎣';
}
