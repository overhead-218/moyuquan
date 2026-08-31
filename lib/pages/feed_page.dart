import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../services/spot_service.dart';
import '../services/geo_service.dart';
import '../services/moderation_service.dart';
import '../services/moderation_actions.dart';
import 'post_detail_page.dart';
import 'search_page.dart';
import 'map_page.dart';
import 'message_page.dart';

/// 首页：双列瀑布流 + 真实图片 + 点赞动画 + 跳转详情
/// 小红书风：紧凑瀑布流（4px 间距）+ 顶部纯文字分段 + 无 AppBar 标题
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  int _segmentIndex = 1; // 默认"发现"
  String _selectedCity = '上海'; // 默认城市（initState 会读 GeoService 记忆覆盖）

  // 城市列表：spot_service 完整 80+ 城作为权威源
  static final List<String> _allCities = SpotService.cities;

  static const _accent = Color(0xFFFF4458); // 小红书红

  @override
  void initState() {
    super.initState();
    // 拉黑后即时刷新 feed（移除被拉黑作者的帖子）
    ModerationService.instance.addListener(_onModerationChanged);
  }

  @override
  void dispose() {
    ModerationService.instance.removeListener(_onModerationChanged);
    super.dispose();
  }

  void _onModerationChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        elevation: 0,
        scrolledUnderElevation: 0,
        // 顶部只放搜索/通知图标，不显示应用名
        titleSpacing: 0,
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined, color: Color(0xFF333333)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MapPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF333333)),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, a, c) => const SearchPage(),
                  transitionsBuilder: (context, animation, t, child) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF333333),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MessagePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 分段栏：纯文字 + 当前项底部短红线（无背景 chip）
          // 左侧固定图标 → 中间居中分段 → 右侧固定图标
          SizedBox(
            height: 40,
            child: Stack(
              children: [
                // 中间居中分段
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SegmentItem(
                        label: '关注',
                        selected: _segmentIndex == 0,
                        accent: _accent,
                        onTap: () => setState(() => _segmentIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      _SegmentItem(
                        label: '发现',
                        selected: _segmentIndex == 1,
                        accent: _accent,
                        onTap: () => setState(() => _segmentIndex = 1),
                      ),
                      const SizedBox(width: 8),
                      _SegmentItem(
                        label: '同城',
                        selected: _segmentIndex == 2,
                        accent: _accent,
                        onTap: () => setState(() => _segmentIndex = 2),
                      ),
                    ],
                  ),
                ),
                // 左侧：城市下拉选择器
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: PopupMenuButton<String>(
                    initialValue: _selectedCity,
                    onSelected: (v) {
                      setState(() => _selectedCity = v);
                      GeoService.saveCity(v); // 同步到 localStorage，钓点页下次会读到
                    },
                    offset: const Offset(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.expand_more, size: 18, color: Color(0xFF333333)),
                          const SizedBox(width: 2),
                          Text(
                            _selectedCity,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (_) => _allCities
                        .map((c) => PopupMenuItem<String>(
                              value: c,
                              padding: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (c == _selectedCity)
                                      const Icon(Icons.check, size: 14, color: _accent)
                                    else
                                      const SizedBox(width: 14),
                                    if (c == _selectedCity) const SizedBox(width: 6),
                                    Text(c, style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                // 右侧：筛选图标
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: const Icon(Icons.tune, size: 18, color: Color(0xFF333333)),
                ),
              ],
            ),
          ),
          // 双列瀑布流 — 4px 极紧凑间距（接 Firestore）
          Expanded(
            child: StreamBuilder<List<Post>>(
              stream: PostService.streamAll(limit: 60),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('加载失败：${snap.error}'),
                    ),
                  );
                }
                var posts = snap.data ?? const <Post>[];
                // 过滤已拉黑作者的帖子（Guideline 1.2 合规）
                posts = posts
                    .where((p) => !ModerationService.instance.isBlocked(p.authorId))
                    .toList();
                // 同城 Tab：按选中城市过滤
                if (_segmentIndex == 2) {
                  posts = posts
                      .where((p) =>
                          p.location != null &&
                          p.location!.contains(_selectedCity))
                      .toList();
                }
                if (posts.isEmpty) {
                  return const Center(child: Text('还没有帖子'));
                }
                // 交替分配到左右列（瀑布流）
                final left = <Post>[];
                final right = <Post>[];
                for (var i = 0; i < posts.length; i++) {
                  if (i.isEven) {
                    left.add(posts[i]);
                  } else {
                    right.add(posts[i]);
                  }
                }
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左列
                        Expanded(
                          child: Column(
                            children: List.generate(left.length, (i) {
                              final p = left[i];
                              return Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: _FeedImageCard(
                                  post: p,
                                  index: i * 2,
                                  marginBottom: 4,
                                ),
                              );
                            }),
                          ),
                        ),
                        // 右列
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16, left: 2),
                            child: Column(
                              children: List.generate(right.length, (i) {
                                final p = right[i];
                                return _FeedImageCard(
                                  post: p,
                                  index: i * 2 + 1,
                                  marginBottom: 4,
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 分段项：纯文字 + 当前项底部红色短线
class _SegmentItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  const _SegmentItem({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? const Color(0xFF1A1A1A) : const Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: 2,
              width: selected ? 20 : 0,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedImageCard extends StatefulWidget {
  final Post post;
  final int index;
  final double marginBottom;

  const _FeedImageCard({
    required this.post,
    required this.index,
    this.marginBottom = 4,
  });

  @override
  State<_FeedImageCard> createState() => _FeedImageCardState();
}

class _FeedImageCardState extends State<_FeedImageCard>
    with SingleTickerProviderStateMixin {
  bool _liked = false;
  int _likeCount = 0;

  static const _fishEmojis = ['🎣', '🐟', '🐠', '🦈', '🦑', '🐡'];
  static const _gradientPairs = <List<Color>>[
    [Color(0xFF0A7C74), Color(0xFF148F86)],
    [Color(0xFFC49A5E), Color(0xFFE0B670)],
    [Color(0xFF0E7C7B), Color(0xFF4FA8A8)],
    [Color(0xFF2E8B7B), Color(0xFF5BAE9C)],
    [Color(0xFF1F6F8B), Color(0xFF4A90B8)],
    [Color(0xFF8B5A3C), Color(0xFFB8845C)],
  ];

  late final AnimationController _enterController;
  late final Animation<double> _enterAnim;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _enterController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _enterAnim = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutBack,
    );
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
  }

  void _showCardMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('举报帖子'),
              onTap: () {
                Navigator.pop(context);
                showReportSheet(
                  context,
                  targetType: 'post',
                  targetId: widget.post.id,
                  targetUserId: widget.post.authorId,
                  title: '举报帖子',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('拉黑作者'),
              onTap: () {
                Navigator.pop(context);
                confirmBlock(
                  context,
                  userId: widget.post.authorId,
                  userName: widget.post.authorName,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientPairs[widget.index % _gradientPairs.length];
    final fishEmoji = _fishEmojis[widget.index % _fishEmojis.length];

    return Padding(
      padding: EdgeInsets.only(bottom: widget.marginBottom),
      child: FadeTransition(
        opacity: _enterAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(_enterAnim),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, a, c) => PostDetailPage(
                    postId: widget.post.id,
                    authorId: widget.post.authorId,
                    authorName: widget.post.authorName,
                    authorAvatar: widget.post.authorAvatar,
                    imageUrl: widget.post.imageUrl,
                    imageHeight: widget.post.height,
                    likeCount: widget.post.likeCount,
                    index: widget.index,
                    title: widget.post.title,
                    content: widget.post.content,
                    location: widget.post.location,
                    postType: widget.post.type,
                    commentCount: widget.post.commentCount,
                  ),
                  transitionsBuilder: (context, animation, t, child) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片区
                  SizedBox(
                    height: widget.post.height,
                    width: double.infinity,
                    child: Image.network(
                      widget.post.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, st) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(fishEmoji,
                                style: const TextStyle(fontSize: 56)),
                          ),
                        );
                      },
                    ),
                  ),
                  // 内容区 — 标题 + 作者 + 点赞（小红书卡片风）
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 标题（帖子正文钩子，小红书卡片核心信息）
                        if (widget.post.title.isNotEmpty)
                          Text(
                            ModerationService.filterText(widget.post.title),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 8),
                        // 作者（头像+昵称） + 点赞
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 9,
                                    backgroundColor: const Color(0xFFF0ECE6),
                                    child: Text(
                                      widget.post.authorAvatar,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      widget.post.authorName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888888),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _toggleLike,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedScale(
                                    scale: _liked ? 1.4 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.elasticOut,
                                    child: Icon(
                                      _liked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 13,
                                      color: _liked
                                          ? const Color(0xFFFF4458)
                                          : const Color(0xFF999999),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$_likeCount',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: _showCardMenu,
                              behavior: HitTestBehavior.opaque,
                              child: const Icon(Icons.more_horiz,
                                  size: 16, color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}