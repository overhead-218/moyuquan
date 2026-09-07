import '../models/post.dart';

/// 收藏服务（内存单例，会话内有效）。
/// 同时管理「收藏的帖子」与「收藏的钓点」；登出/重启即重置。
class FavoriteService {
  static final FavoriteService instance = FavoriteService._();
  FavoriteService._();

  final List<Post> _favPosts = [];
  final List<String> _favSpotIds = [];

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

  // ── 帖子收藏 ─────────────────────────────
  List<Post> get favPosts => List.unmodifiable(_favPosts);
  int get postCount => _favPosts.length;

  bool isPostFav(String postId) =>
      _favPosts.any((p) => p.id == postId);

  /// 切换帖子收藏，返回是否已收藏。
  bool togglePostFav(Post post) {
    final idx = _favPosts.indexWhere((p) => p.id == post.id);
    if (idx >= 0) {
      _favPosts.removeAt(idx);
    } else {
      _favPosts.insert(0, post);
    }
    _notify();
    return idx < 0;
  }

  // ── 钓点收藏 ─────────────────────────────
  List<String> get favSpotIds => List.unmodifiable(_favSpotIds);
  int get spotCount => _favSpotIds.length;

  bool isSpotFav(String spotId) => _favSpotIds.contains(spotId);

  /// 切换钓点收藏，返回是否已收藏。
  bool toggleSpotFav(String spotId) {
    if (spotId.isEmpty) return false;
    if (_favSpotIds.contains(spotId)) {
      _favSpotIds.remove(spotId);
    } else {
      _favSpotIds.add(spotId);
    }
    _notify();
    return _favSpotIds.contains(spotId);
  }

  /// 清空所有收藏（登出时调用）。
  void clearAll() {
    _favPosts.clear();
    _favSpotIds.clear();
    _notify();
  }
}
