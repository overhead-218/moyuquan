/// 关注服务（内存单例，会话内有效）。
/// - following：我关注的作者（按 userId）
/// - followers：关注我的人（本地预置为空，真实场景由云端关系生成）
/// 演示作者池 + 关注过的帖子作者/主页用户（ensureUser 注册后均可关注/展示）。
/// 登出/重启即重置（与后端账号体系解耦）。
class FollowService {
  static final FollowService instance = FollowService._();
  FollowService._();

  /// 演示作者池（帖子作者/榜单名人可动态 ensureUser 加入）。
  static const List<Map<String, String>> knownUsers = [
    {'id': 'u001', 'name': '海钓阿强', 'avatar': '🦈', 'bio': '海钓十年，专攻大鱼'},
    {'id': 'u002', 'name': '钓王老周', 'avatar': '🎣', 'bio': '淡水通吃'},
    {'id': 'u003', 'name': '老李', 'avatar': '🐟', 'bio': '野钓爱好者'},
    {'id': 'u004', 'name': '阿飞', 'avatar': '🦑', 'bio': '路亚玩家'},
    {'id': 'u005', 'name': '菜鸟', 'avatar': '🐠', 'bio': '新手求带'},
    {'id': 'u006', 'name': '野钓大叔', 'avatar': '🐡', 'bio': '只玩野钓'},
    {'id': 'u007', 'name': '江南老钓', 'avatar': '🦐', 'bio': '江南水域活地图'},
    {'id': 'u008', 'name': '渔民小张', 'avatar': '🐟', 'bio': '每日出船'},
    {'id': 'u009', 'name': '路亚新手', 'avatar': '🪝', 'bio': '学习路亚中'},
    {'id': 'u010', 'name': '钓鱼小白', 'avatar': '🐣', 'bio': '刚入坑'},
  ];

  /// 可关注用户池：预置 knownUsers，帖子作者等可动态注册。
  static final Map<String, Map<String, String>> _pool = {
    for (final u in knownUsers) u['id']!: Map<String, String>.from(u),
  };

  /// 我关注的作者 id（有序，先关注在前）
  final List<String> _following = [];

  /// 关注我的人（预置为空；真实场景由云端关系生成）
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

  /// 注册可关注用户（帖子作者/任意他人主页）；已存在则忽略。
  static void ensureUser(String userId,
      {String? name, String? avatar, String? bio}) {
    if (userId.isEmpty || userId == 'me') return;
    if (_pool.containsKey(userId)) return;
    _pool[userId] = {
      'id': userId,
      'name': name ?? '钓鱼人',
      'avatar': avatar ?? '🎣',
      'bio': bio ?? '',
    };
  }

  /// 取作者信息；未注册 id 返回通用占位。
  static Map<String, String> userInfo(String userId) =>
      _pool[userId] ?? {'id': userId, 'name': '钓鱼人', 'avatar': '🎣', 'bio': ''};

  /// 按昵称反查演示用户 id；找不到返回空串。
  static String userIdByName(String name) {
    for (final u in _pool.values) {
      if (u['name'] == name) return u['id']!;
    }
    return '';
  }

  // ── 操作 ─────────────────────────────────────────
  /// 切换关注状态（关注前先 ensureUser 保证可展示），返回是否已关注。
  bool toggleFollow(String userId,
      {String? name, String? avatar, String? bio}) {
    if (userId.isEmpty || userId == 'me') return isFollowing(userId);
    ensureUser(userId, name: name, avatar: avatar, bio: bio);
    if (_following.contains(userId)) {
      _following.remove(userId);
    } else {
      _following.insert(0, userId);
    }
    _notify();
    return _following.contains(userId);
  }

  /// 清空本地关注/粉丝（登出时调用）。
  void clearAll() {
    _following.clear();
    _followers.clear();
    _notify();
  }
}
