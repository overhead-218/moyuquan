import 'package:flutter/material.dart';
import '../models/post.dart';
import '../models/spot.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import '../services/spot_service.dart';
import '../services/tcb_rest_client.dart';
import '../services/user_profile.dart';
import 'post_detail_page.dart';
import 'spot_detail_page.dart';
import 'user_profile_page.dart';
import 'chat_detail_page.dart';

/// 搜索页：综合搜索 + 热门发现
/// Stitch 风格：Material 3 Expressive，暖白背景、青绿主色、金色点缀
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  /// 搜索历史（会话内记录）
  final List<String> _history = [];

  static const _hotTopics = [
    {'tag': '🔥 本周热帖', 'title': '野钓空军的十大原因', 'count': '2.3万'},
    {'tag': '💰 活动', 'title': '摸鱼圈钓友交流会·南京站', 'count': '1568'},
    {'tag': '📖 攻略', 'title': '夏季夜钓选位指南', 'count': '9804'},
    {'tag': '🎣 新手', 'title': '第一次海钓需要准备什么？', 'count': '8762'},
    {'tag': '🏆 赛事', 'title': '2026全国钓鱼锦标赛报名开启', 'count': '5431'},
    {'tag': '🌊 海钓', 'title': '舟山矶钓圣地合集', 'count': '4321'},
  ];
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _focusNode.requestFocus();
    // 预热真实用户表：进入搜索页就把 profiles 拉下来，
    // 这样「输入名字 → 看到人 → 点发消息」是一气呵成的，不用等网络往返。
    _userRows().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String q) {
    final query = q.trim();
    if (query.isEmpty) return;
    setState(() {
      _query = query;
      // 记录搜索历史（去重、置顶、最多 6 条）
      _history.remove(query);
      _history.insert(0, query);
      if (_history.length > 6) _history.removeRange(6, _history.length);
    });
    _searchController.clear();
    _focusNode.unfocus();
  }

  void _clearHistory() {
    setState(() => _history.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0A7C74)),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: '搜索用户、帖子、钓点...',
            hintStyle: const TextStyle(color: Color(0xFF999999)),
            filled: true,
            fillColor: const Color(0xFFF0EEE9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0A7C74),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        size: 18, color: Color(0xFF999999)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (v) => setState(() {}),
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF0A7C74)),
              onPressed: () => _search(_searchController.text),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0A7C74),
          unselectedLabelColor: const Color(0xFF999999),
          indicatorColor: const Color(0xFF0A7C74),
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: '综合搜索'),
            Tab(text: '热门发现'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab1：综合搜索
          _query.isEmpty ? _buildEmptyState() : _buildSearchResults(),
          // Tab2：热门发现
          _buildHotDiscover(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_history.isNotEmpty) ...[
            // 搜索历史标题
            const Text(
              '搜索历史',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
            // 搜索历史 chips：全圆浅青底
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _history.map((h) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = h;
                    _search(h);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F2F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history,
                            size: 14, color: Color(0xFF0A7C74)),
                        const SizedBox(width: 6),
                        Text(
                          h,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF0A7C74)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearHistory,
                child: const Text(
                  '清空历史',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 搜索云库 profiles 中的真实用户。
  ///
  /// 优先本地缓存（关注/粉丝列表里的人已缓存），再拉云库；
  /// 云库不可用时返回空列表，UI 会显示「无结果」而不是假人。
  List<Map<String, String>> _searchUsers(String q) {
    final keyword = q.trim().toLowerCase();
    final out = <Map<String, String>>[];
    final seen = <String>{};

    bool hit(String name, String id, [String nickname = '']) {
      if (keyword.isEmpty) return true;
      // 支持昵称/姓名模糊匹配，也允许直接用 uid 前缀找
      return name.toLowerCase().contains(keyword) ||
          nickname.toLowerCase().contains(keyword) ||
          id.toLowerCase().contains(keyword);
    }

    void add(String id, String name, String avatar, String bio,
        [String nickname = '']) {
      if (id.isEmpty || name.isEmpty) return;
      if (!hit(name, id, nickname)) return;
      if (!seen.add(id)) return;
      // 有昵称就用昵称展示，脱敏手机号当副标题
      final display = nickname.trim().isNotEmpty ? nickname.trim() : name;
      out.add({
        'id': id,
        'name': display,
        'avatar': avatar,
        'bio': bio,
        'sub': display == name ? '' : name,
      });
    }

    // 1) 已缓存的真实用户（关注/粉丝/帖子作者）
    for (final id in {
      ...FollowService.instance.followingIds,
      ...FollowService.instance.followerIds,
    }) {
      final info = FollowService.userInfo(id);
      add(id, info['name'] ?? '', info['avatar'] ?? '🎣', info['bio'] ?? '',
          info['nickname'] ?? '');
    }

    // 2) 云库 profiles 全量小表（用户量级有限，直接拉取后本地过滤）
    //    首次进入搜索页已预热，这里通常直接命中缓存，输入即出结果，不再闪烁。
    //
    //    ⚠️ PostgREST 返回列名一律小写（nickname / avatarEmoji...），
    //    两种大小写都要兼容，否则新建的 nickname 列读不到值 = 搜不到人。
    for (final r in _cachedUserRows) {
      String pick(String key) {
        if (r.containsKey(key)) return r[key] as String? ?? '';
        final lower = key.toLowerCase();
        for (final e in r.entries) {
          if (e.key.toLowerCase() == lower) return e.value as String? ?? '';
        }
        return '';
      }

      final id = pick('id');
      final name = pick('name');
      add(id, name, pick('avatarEmoji').isNotEmpty ? pick('avatarEmoji') : '🎣',
          pick('bio'), pick('nickname'));
    }

    // 3) 缓存还没回来时兜底异步拉一次
    if (_cachedUserRows.isEmpty && !_usersLoading) {
      _userRows().then((_) {
        if (mounted) setState(() {});
      });
    }

    return out;
  }

  static List<Map<String, dynamic>> _cachedUserRows = [];
  static bool _usersLoading = false;

  /// 启动即预热用户表，让「搜索名字→聊天」能立刻出结果。
  Future<List<Map<String, dynamic>>> _userRows() async {
    if (_cachedUserRows.isNotEmpty) return _cachedUserRows;
    if (_usersLoading) return _cachedUserRows;
    _usersLoading = true;
    try {
      final rows = await TcbRestClient.query('profiles', params: {
        // 带上 nickname：手机号登录的用户展示名是脱敏号 138****8888，
        // 光靠它别人搜不到（也搜不了完整手机号，因为库里没存），
        // 必须让用户自己起一个可被搜到的昵称。
        'select': 'id,name,nickname,avatarEmoji,bio',
        'limit': '500',
        'order': 'name.asc',
      });
      _cachedUserRows = rows;
      return rows;
    } catch (e) {
      return const [];
    } finally {
      _usersLoading = false;
    }
  }

  Widget _buildSearchResults() {
    final q = _query;
    // 用户：搜索云库 profiles 表中的真实注册用户
    // ⚠️ 原实现只搜 FollowService.knownUsers —— 那是 10 个硬编码假人
    //    （海钓阿强/钓鱼王老周/老李…），现在这个列表已删除。
    final users = _searchUsers(q);
    // 帖子：标题 / 正文 / 作者 / 地点匹配
    final posts = PostService.mockAll()
        .where((p) =>
            p.title.contains(q) ||
            p.content.contains(q) ||
            p.authorName.contains(q) ||
            p.location.contains(q))
        .toList();
    // 钓点：SpotService 内置搜索（名称 / 城市 / 类型 / 鱼种）
    final places = SpotService.search(q);
    if (users.isEmpty && posts.isEmpty && places.isEmpty) {
      return _buildNoResult(q);
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (users.isNotEmpty) ...[
            _SectionTitle('用户', Icons.person),
            ...users.map((u) => _UserTile(
                  userId: u['id']!,
                  name: u['name']!,
                  avatar: u['avatar']!,
                  bio: u['bio']!,
                  canChat: u['id']!.isNotEmpty &&
                      u['id'] != 'me' &&
                      u['id'] != UserProfile.id,
                )),
            const SizedBox(height: 8),
          ],
          if (posts.isNotEmpty) ...[
            _SectionTitle('帖子', Icons.article),
            ...posts.take(8).map((p) => _PostTile(post: p)),
            const SizedBox(height: 8),
          ],
          if (places.isNotEmpty) ...[
            _SectionTitle('钓点', Icons.location_on),
            ...places.take(8).map((p) => _PlaceTile(spot: p)),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildNoResult(String q) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            const Text('🔍', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              '没有找到与「$q」相关的内容',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 4),
            const Text(
              '换个关键词试试：钓友昵称、钓具品牌、路亚、千岛湖…',
              style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotDiscover() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 热门话题标题
          const Text(
            '🔥 热门话题',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          ..._hotTopics.map((t) => _HotTopicTile(
                tag: t['tag']!,
                title: t['title']!,
                count: t['count']!,
              )),
          const SizedBox(height: 24),
          // 搜索历史
          if (_history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF666666),
                  ),
                ),
                TextButton(
                  onPressed: _clearHistory,
                  child: const Text(
                    '清空',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 搜索历史 chips：全圆浅青底
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _history.map((h) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = h;
                    _search(h);
                    _tabController.animateTo(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F2F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      h,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF0A7C74)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionTitle(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0A7C74)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A7C74),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatefulWidget {
  final String userId;
  final String name, avatar, bio;

  /// 有稳定 uid 且不是自己时才能发消息
  /// （不能给「自己」发消息，也不接受 uid 为空的对象）
  final bool canChat;
  const _UserTile({
    required this.userId,
    required this.name,
    required this.avatar,
    required this.bio,
    this.canChat = false,
  });

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  @override
  void initState() {
    super.initState();
    FollowService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    FollowService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final following = FollowService.instance.isFollowing(widget.userId);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserProfilePage(
              name: widget.name,
              avatar: widget.avatar,
              bio: widget.bio,
              userId: widget.userId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(widget.avatar, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.bio,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 直接发消息：搜索结果一键进入会话，不必先去个人主页再点私信
            if (widget.canChat)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailPage(
                        name: widget.name,
                        avatar: widget.avatar,
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A7C74),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '发消息',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (widget.canChat) const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                FollowService.instance.toggleFollow(
                  widget.userId,
                  name: widget.name,
                  avatar: widget.avatar,
                  bio: widget.bio,
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: following
                      ? const Color(0xFFF0EEE9)
                      : const Color(0xFF0A7C74).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  following ? '已关注' : '+ 关注',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: following
                        ? const Color(0xFF999999)
                        : const Color(0xFF0A7C74),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  final Post post;
  const _PostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailPage(
              authorName: post.authorName,
              authorAvatar: post.authorAvatar,
              imageUrl: post.imageUrl,
              images: post.images,
              imageHeight: 200,
              likeCount: post.likeCount,
              index: 0,
              title: post.title,
              content: post.content,
              location: post.location,
              postType: post.type,
              commentCount: post.commentCount,
              postId: post.id,
              authorId: post.authorId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.article_outlined,
                    color: Color(0xFF0A7C74), size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${post.authorName} · ♥ ${post.likeCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final Spot spot;
  const _PlaceTile({required this.spot});

  @override
  Widget build(BuildContext context) {
    final stars = spot.rating == null
        ? ''
        : '★${spot.rating!.toStringAsFixed(1)}';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SpotDetailPage(spot: spot)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(spot.typeEmoji, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${spot.type} · ${spot.city}${spot.district}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            if (stars.isNotEmpty)
              Text(
                stars,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFC49A5E),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HotTopicTile extends StatelessWidget {
  final String tag, title, count;
  const _HotTopicTile({
    required this.tag,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isHot = tag.contains('🔥');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isHot
                  ? const Color(0xFFFF4757).withValues(alpha: 0.1)
                  : const Color(0xFF0A7C74).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isHot ? const Color(0xFFFF4757) : const Color(0xFF0A7C74),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}
