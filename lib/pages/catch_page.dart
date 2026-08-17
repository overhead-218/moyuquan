import 'package:flutter/material.dart';
import '../models/catch_item.dart';
import '../models/post.dart';
import '../models/spot.dart';
import '../services/catch_service.dart';
import '../services/post_service.dart';
import '../services/spot_service.dart';
import 'catch_detail_page.dart';
import 'post_detail_page.dart';
import 'spot_detail_page.dart';
import 'user_profile_page.dart';

/// 鱼获榜 → 钓鱼精华聚合页
/// 4维度Tab：大鱼榜 · 热门钓点 · 热帖 · 人气钓友
class CatchPage extends StatefulWidget {
  const CatchPage({super.key});

  @override
  State<CatchPage> createState() => _CatchPageState();
}

class _CatchPageState extends State<CatchPage> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '精华',
          style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: _primary, letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: _primary, size: 22),
            onPressed: () => _showRules(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _primary,
          indicatorWeight: 3,
          labelColor: _primary,
          unselectedLabelColor: _textWeak,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: '🏋️ 大鱼榜'),
            Tab(text: '🎣 鱼竿'),
            Tab(text: '🔄 鱼轮'),
            Tab(text: '🪤 饵料'),
            Tab(text: '💧 小药'),
            Tab(text: '📍 热门钓点'),
            Tab(text: '🔥 热帖'),
            Tab(text: '⭐ 人气钓友'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _FishRankingTab(),
          _RodTab(),
          _ReelTab(),
          _LureTab(),
          _BaitTab(),
          _HotSpotTab(),
          _HotPostTab(),
          _TopAnglerTab(),
        ],
      ),
    );
  }

  void _showRules(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('精华榜说明', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700, color: _textMain,
            )),
            const SizedBox(height: 16),
            _ruleItem('🏋️ 大鱼榜', '单尾最重，大鱼认证 ≥5kg'),
            _ruleItem('📍 热门钓点', '热度分 = 浏览×0.1 + 收藏×3 + 点评×5 + 新帖×10 + 评分×20'),
            _ruleItem('🔥 热帖', '综合热度 = 点赞×1 + 评论×2 + 收藏×3'),
            _ruleItem('⭐ 人气钓友', '积分累计：发帖+1，获赞+1，大鱼认证+10'),
            const SizedBox(height: 12),
            const Text('参考 Bassmaster 赛制 · 摸鱼圈积分体系',
                style: TextStyle(fontSize: 12, color: _textWeak)),
          ],
        ),
      ),
    );
  }

  Widget _ruleItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(title, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: _textMain,
            )),
          ),
          Expanded(child: Text(desc, style: const TextStyle(
            fontSize: 13, color: _textMid,
          ))),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 1: 大鱼榜
// ═══════════════════════════════════════════════════════
class _FishRankingTab extends StatelessWidget {
  const _FishRankingTab();

  @override
  Widget build(BuildContext context) {
    final ranking = CatchService.weightRanking(limit: 20);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroBanner(
          emoji: '🏋️', title: '大鱼榜',
          subtitle: '单尾最重，大鱼认证 ≥5kg',
          accent: _primary,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < ranking.length; i++)
          _FishCard(item: ranking[i], rank: i + 1, delay: i * 50),
      ],
    );
  }
}

class _FishCard extends StatefulWidget {
  final CatchItem item;
  final int rank;
  final int delay;
  const _FishCard({required this.item, required this.rank, this.delay = 0});

  @override
  State<_FishCard> createState() => _FishCardState();
}

class _FishCardState extends State<_FishCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final top3 = widget.rank <= 3;
    final borderColor = widget.rank == 1 ? _gold
        : widget.rank == 2 ? const Color(0xFFB0BEC5)
        : widget.rank == 3 ? const Color(0xFFCD7F32) : null;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: top3 ? Border.all(color: borderColor!, width: 2) : null,
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.08),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CatchDetailPage(
                  name: widget.item.userName,
                  avatar: widget.item.images.isNotEmpty ? widget.item.images.first : '',
                  fish: widget.item.fish,
                  weight: widget.item.weight.toStringAsFixed(1) + ' kg',
                  rank: widget.rank,
                )),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // 排名
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: widget.rank == 1 ? _gold
                            : widget.rank <= 3 ? const Color(0xFFF0EDE8) : _bg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: widget.rank <= 3
                            ? Text('${widget.rank}', style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ))
                            : Text('${widget.rank}', style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: _textMid,
                              )),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 鱼图标
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.catching_pokemon, color: _primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    // 信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(widget.item.fish,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                                    color: _textMain),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.item.verified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, color: _gold, size: 14),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.item.weight.toStringAsFixed(1)} kg  ·  ${widget.item.userName}  ·  ${widget.item.spotName}',
                            style: const TextStyle(fontSize: 12, color: _textWeak),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // 重量标签
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.item.weight.toStringAsFixed(1)}kg',
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 2: 热门钓点
// ═══════════════════════════════════════════════════════
class _HotSpotTab extends StatelessWidget {
  const _HotSpotTab();

  @override
  Widget build(BuildContext context) {
    final spots = SpotService.sortByHotspot(SpotService.all).take(15).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroBanner(
          emoji: '📍', title: '热门钓点',
          subtitle: '热度分 = 浏览·收藏·点评·新帖·评分',
          accent: const Color(0xFF0F4C5C),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < spots.length; i++)
          _SpotRankCard(spot: spots[i], rank: i + 1, delay: i * 40),
      ],
    );
  }
}

class _SpotRankCard extends StatelessWidget {
  final Spot spot;
  final int rank;
  final int delay;
  const _SpotRankCard({required this.spot, required this.rank, this.delay = 0});

  Color get _rankColor {
    if (rank == 1) return _gold;
    if (rank == 2) return const Color(0xFFB0BEC5);
    if (rank == 3) return const Color(0xFFCD7F32);
    return _textWeak;
  }

  @override
  Widget build(BuildContext context) {
    final top3 = rank <= 3;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(
        scale: v, child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: top3 ? Border.all(color: _rankColor.withValues(alpha: 0.5), width: 1.5) : null,
          boxShadow: [BoxShadow(
            color: _primary.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2),
          )],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => SpotDetailPage(spot: spot)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 排名
                  SizedBox(
                    width: 28,
                    child: Text('$rank', style: TextStyle(
                      fontSize: rank <= 3 ? 18 : 14,
                      fontWeight: FontWeight.w900,
                      color: _rankColor,
                    )),
                  ),
                  const SizedBox(width: 10),
                  // 类型图标
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(spot.typeEmoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(spot.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: _textMain),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${spot.city} · ${spot.type} · ${spot.priceLabel}',
                          style: const TextStyle(fontSize: 12, color: _textWeak),
                        ),
                      ],
                    ),
                  ),
                  // 热度分
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmtHot(spot.hotspotScore.toInt()),
                        style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _primary,
                        ),
                      ),
                      const Text('热度', style: TextStyle(fontSize: 10, color: _textWeak)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtHot(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ═══════════════════════════════════════════════════════
// TAB 3: 热帖
// ═══════════════════════════════════════════════════════
class _HotPostTab extends StatelessWidget {
  const _HotPostTab();

  @override
  Widget build(BuildContext context) {
    final posts = _hotPosts();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroBanner(
          emoji: '🔥', title: '热帖',
          subtitle: '点赞×1 + 评论×2 + 收藏×3',
          accent: const Color(0xFFE65100),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < posts.length; i++)
          _PostRankCard(post: posts[i], rank: i + 1, delay: i * 40),
      ],
    );
  }

  // 综合热度 = likes*1 + comments*2 + favorites*3
  List<Post> _hotPosts() {
    try {
      final all = PostService.mockAll();
      return List.from(all)
        ..sort((a, b) {
          final sa = a.likeCount * 1 + a.commentCount * 2 + (a.likeCount ~/ 5);
          final sb = b.likeCount * 1 + b.commentCount * 2 + (b.likeCount ~/ 5);
          return sb.compareTo(sa);
        });
    } catch (_) {
      return [];
    }
  }
}

class _PostRankCard extends StatelessWidget {
  final Post post;
  final int rank;
  final int delay;
  const _PostRankCard({required this.post, required this.rank, this.delay = 0});

  @override
  Widget build(BuildContext context) {
    final score = post.likeCount * 1 + post.commentCount * 2 + (post.likeCount ~/ 5);
    final top3 = rank <= 3;
    final rankColor = rank == 1 ? _gold
        : rank == 2 ? const Color(0xFFB0BEC5)
        : rank == 3 ? const Color(0xFFCD7F32) : _textWeak;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(
        scale: v, child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: top3 ? Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5) : null,
          boxShadow: [BoxShadow(
            color: _primary.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2),
          )],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
                MaterialPageRoute(builder: (_) => PostDetailPage(
                  authorName: post.authorName,
                  authorAvatar: post.authorAvatar,
                  imageUrl: post.imageUrl,
                  imageHeight: post.height,
                  likeCount: post.likeCount,
                  commentCount: post.commentCount,
                  index: 0,
                  title: post.title,
                  content: post.content,
                  location: post.location,
                  postType: post.type,
                )),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('$rank', style: TextStyle(
                      fontSize: rank <= 3 ? 18 : 14,
                      fontWeight: FontWeight.w900, color: rankColor,
                    )),
                  ),
                  const SizedBox(width: 10),
                  // 封面图
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post.imageUrl,
                      width: 56, height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56, height: 56,
                        color: _primary.withValues(alpha: 0.08),
                        child: const Icon(Icons.image, color: _primary, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title.isNotEmpty ? post.title
                              : post.authorName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: _textMain),
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 11, color: _textWeak),
                            const SizedBox(width: 3),
                            Text(post.authorName,
                              style: const TextStyle(fontSize: 11, color: _textWeak)),
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on_outlined, size: 11, color: _textWeak),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(post.location,
                                style: const TextStyle(fontSize: 11, color: _textWeak),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.favorite, size: 12, color: Color(0xFFFF4757)),
                            const SizedBox(width: 3),
                            Text('${post.likeCount}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFFF4757))),
                            const SizedBox(width: 10),
                            const Icon(Icons.comment_outlined, size: 12, color: _textWeak),
                            const SizedBox(width: 3),
                            Text('${post.commentCount}',
                                style: const TextStyle(fontSize: 12, color: _textWeak)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 热度
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmtScore(score), style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFE65100),
                      )),
                      const Text('热度', style: TextStyle(fontSize: 10, color: _textWeak)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtScore(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ═══════════════════════════════════════════════════════
// TAB 4: 人气钓友
// ═══════════════════════════════════════════════════════
class _TopAnglerTab extends StatelessWidget {
  const _TopAnglerTab();

  @override
  Widget build(BuildContext context) {
    final anglers = _topAnglers();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HeroBanner(
          emoji: '⭐', title: '人气钓友',
          subtitle: '积分 = 发帖+1 · 获赞+1 · 大鱼认证+10',
          accent: _gold,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < anglers.length; i++)
          _AnglerCard(angler: anglers[i], rank: i + 1, delay: i * 50),
      ],
    );
  }

  List<_AnglerProfile> _topAnglers() {
    final Map<String, _AnglerProfile> map = {};
    // 从渔获数据聚合
    for (var c in CatchService.weightRanking(limit: 100)) {
      map.putIfAbsent(c.userId, () => _AnglerProfile(
        userId: c.userId,
        userName: c.userName,
        avatarColor: _avatarColors[map.length % _avatarColors.length],
      ));
      map[c.userId]!.score += c.verified ? 10 : 1;
      map[c.userId]!.verifiedCount += c.verified ? 1 : 0;
    }
    // 从帖子数据聚合
    try {
      for (var p in PostService.mockAll()) {
        map.putIfAbsent(p.authorId, () => _AnglerProfile(
          userId: p.authorId,
          userName: p.authorName,
          avatarColor: _avatarColors[map.length % _avatarColors.length],
        ));
        map[p.authorId]!.score += 1 + p.likeCount;
        map[p.authorId]!.likeCount += p.likeCount;
        map[p.authorId]!.postCount += 1;
      }
    } catch (_) {}
    final list = map.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return list.take(20).toList();
  }
}

class _AnglerProfile {
  String userId;
  String userName;
  int score;
  int likeCount;
  int postCount;
  int verifiedCount;
  Color avatarColor;
  _AnglerProfile({
    required this.userId, required this.userName, required this.avatarColor,
    this.score = 0, this.likeCount = 0, this.postCount = 0, this.verifiedCount = 0,
  });
}

final _avatarColors = [
  const Color(0xFF0A7C74), const Color(0xFF0F4C5C),
  const Color(0xFFCD7F32), const Color(0xFF2E7D32),
  const Color(0xFFC49A5E), const Color(0xFF1565C0),
  const Color(0xFF6A1B9A), const Color(0xFFC62828),
];

class _AnglerCard extends StatelessWidget {
  final _AnglerProfile angler;
  final int rank;
  final int delay;
  const _AnglerCard({required this.angler, required this.rank, this.delay = 0});

  Color get _rankColor {
    if (rank == 1) return _gold;
    if (rank == 2) return const Color(0xFFB0BEC5);
    if (rank == 3) return const Color(0xFFCD7F32);
    return _textWeak;
  }

  @override
  Widget build(BuildContext context) {
    final top3 = rank <= 3;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(
        scale: v, child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: top3 ? Border.all(color: _rankColor.withValues(alpha: 0.5), width: 1.5) : null,
          boxShadow: [BoxShadow(
            color: _primary.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2),
          )],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => UserProfilePage(
                name: angler.userName,
                avatar: '',
                bio: '钓鱼爱好者',
                posts: angler.postCount,
                followers: 0,
                following: 0,
              )),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 排名
                  SizedBox(
                    width: 28,
                    child: Text('$rank', style: TextStyle(
                      fontSize: rank <= 3 ? 18 : 14,
                      fontWeight: FontWeight.w900, color: _rankColor,
                    )),
                  ),
              const SizedBox(width: 10),
              // 头像
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: angler.avatarColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    angler.userName.isNotEmpty ? angler.userName[0] : '?',
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 名字+数据
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(angler.userName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: _textMain)),
                        if (angler.verifiedCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('🐟×${angler.verifiedCount}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: _gold)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _statChip(Icons.article_outlined, '${angler.postCount}帖'),
                        const SizedBox(width: 6),
                        _statChip(Icons.favorite, '${angler.likeCount}赞'),
                      ],
                    ),
                  ],
                ),
              ),
              // 总积分
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmtScore(angler.score),
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w800, color: _gold,
                    ),
                  ),
                  const Text('积分', style: TextStyle(fontSize: 10, color: _textWeak)),
                ],
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: _textWeak),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(fontSize: 11, color: _textWeak)),
      ],
    );
  }

  String _fmtScore(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ═══════════════════════════════════════════════════════
// 通用组件
// ═══════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  const _HeroBanner({
    required this.emoji, required this.title,
    required this.subtitle, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.85), accent],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white,
              )),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.8),
              )),
            ],
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════
// TAB 5: 鱼竿榜
// ═══════════════════════════════════════════════════════
class _RodTab extends StatelessWidget {
  const _RodTab();

  static final _rods = [
    _EquipItem(name: '达亿瓦 阿比德', spec: 'EXIST AI 168ML', type: '鲤综合', score: 9820, heat: 3421, replies: 286, tags: ['轻量', '感度强', '野钓神器']),
    _EquipItem(name: '禧玛诺 红猪', spec: 'POISSANT 270', type: '鲤综合', score: 9210, heat: 2890, replies: 198, tags: ['手感好', '抛投稳', '入门首选']),
    _EquipItem(name: '达亿瓦 布拉迪', spec: 'BRADI FX 180', type: '鲤竞技', score: 8750, heat: 2650, replies: 312, tags: ['高阶', '回鱼快', '竞技首选']),
    _EquipItem(name: '禧玛诺 沙漠者', spec: 'DESOLATE S86L+', type: '鳜鱼', score: 8530, heat: 2340, replies: 165, tags: ['软饵', '精细作钓', '感度极佳']),
    _EquipItem(name: 'NS 进化论', spec: 'EVOLUTION TOUCH 183', type: '鲈鱼', score: 8190, heat: 2100, replies: 143, tags: ['泛用', '腰力足', '国产精品']),
    _EquipItem(name: '达亿瓦 阿比德', spec: 'EXIST AIR 162', type: '鲈鱼', score: 7910, heat: 1980, replies: 124, tags: ['轻量', '感度强', '水滴轮适配']),
    _EquipItem(name: 'Gloomis E12', spec: 'E12XST 769', type: '海钓', score: 7640, heat: 1820, replies: 98, tags: ['海钓', '远投', '防锈']),
    _EquipItem(name: '品钓 鲟龙', spec: 'XUNLONG PRO 210', type: '巨物', score: 7320, heat: 1650, replies: 77, tags: ['巨物', '100g铅', '水库大物']),
    _EquipItem(name: 'NS 阿尔法', spec: 'ALPHA X 186', type: '鲈鱼', score: 7100, heat: 1430, replies: 89, tags: ['远投', '大坝', '泛用']),
    _EquipItem(name: '禧玛诺 安塔里斯', spec: 'ANTARES 180', type: '鲤综合', score: 6950, heat: 1290, replies: 64, tags: ['轻量', '高感', '竞技首选']),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _HeroBanner(
          emoji: '🎣', title: '鱼竿榜',
          subtitle: '钓友口碑综合排行',
          accent: Color(0xFF0277BD),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _rods.length; i++)
          _EquipCard(item: _rods[i], rank: i + 1, delay: i * 35),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 6: 鱼轮榜
// ═══════════════════════════════════════════════════════
class _ReelTab extends StatelessWidget {
  const _ReelTab();

  static final _reels = [
    _EquipItem(name: '达亿瓦 斯泰拉', spec: 'STEEZ AIR 1018H', type: '水滴轮', score: 10230, heat: 4210, replies: 512, tags: ['旗舰', '轻量', '感度极佳', '竞技首选']),
    _EquipItem(name: '禧玛诺 班塔', spec: 'BANTA 150SH', type: '水滴轮', score: 9540, heat: 3780, replies: 398, tags: ['泛用', '刹车稳', '入门首选']),
    _EquipItem(name: '达亿瓦 Zillion', spec: 'ZILLION TW HD 1016XHL', type: '水滴轮', score: 9130, heat: 3340, replies: 287, tags: ['巨物', '高转速', '大力矩']),
    _EquipItem(name: '禧玛诺 安塔', spec: 'ANTARES DC MD', type: '水滴轮', score: 8760, heat: 2890, replies: 243, tags: ['电磁刹车', '远投', '新手友好'], imageUrl: 'assets/images/equip/shimano_antares_dc.jpg'),
    _EquipItem(name: '阿布 BFS', spec: 'REVO BFS X', type: '纺车轮', score: 8420, heat: 2560, replies: 221, tags: ['微物', '轻量', '性价比']),
    _EquipItem(name: '达亿瓦 蜘蛛', spec: 'SPIDER MINI 80', type: '纺车轮', score: 8100, heat: 2230, replies: 198, tags: ['小饵', '泛用', '感度好']),
    _EquipItem(name: '禧玛诺 万奎士', spec: 'VANQUISH C3000', type: '纺车轮', score: 7890, heat: 1980, replies: 176, tags: ['远投', '轻量', '海水淡水产']),
    _EquipItem(name: '达亿瓦 红蝴蝶', spec: 'CALAIS 200H', type: '水滴轮', score: 7650, heat: 1760, replies: 154, tags: ['泛用', '顺滑', '性价比']),
    _EquipItem(name: 'NS 红蝎', spec: 'RED SCORPION X', type: '纺车轮', score: 7420, heat: 1650, replies: 132, tags: ['入门', '耐用', '国产精品']),
    _EquipItem(name: '品钓 雷霆', spec: 'THUNDER PRO 2000', type: '纺车轮', score: 7180, heat: 1490, replies: 108, tags: ['巨物', '大力矩', '水库专用']),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _HeroBanner(
          emoji: '🔄', title: '鱼轮榜',
          subtitle: '水滴轮 · 纺车轮口碑排行',
          accent: Color(0xFF6A1B9A),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _reels.length; i++)
          _EquipCard(item: _reels[i], rank: i + 1, delay: i * 35),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 7: 饵料榜
// ═══════════════════════════════════════════════════════
class _LureTab extends StatelessWidget {
  const _LureTab();

  static final _lures = [
    _EquipItem(name: '德州钓组', spec: 'Texas Rig', type: '软饵', score: 9870, heat: 4120, replies: 543, tags: ['通用', '防挂', '野钓首选']),
    _EquipItem(name: '卡罗钓组', spec: 'Carolina Rig', type: '软饵', score: 8540, heat: 2980, replies: 321, tags: ['远投', '底层搜索', '大鱼专用']),
    _EquipItem(name: '铅头钩+卷尾', spec: 'Jig Head + Grubs', type: '软饵', score: 8210, heat: 2760, replies: 287, tags: ['感度', '快速搜索', '鲈鱼首选']),
    _EquipItem(name: '复合亮片', spec: 'Spinnerbait', type: '亮片', score: 7980, heat: 2540, replies: 265, tags: ['远投', '全水层', '四季通用']),
    _EquipItem(name: '深潜小米诺', spec: 'Deep Diving Minnow 10-15g', type: '硬饵', score: 7650, heat: 2320, replies: 243, tags: ['远投', '深场', '大嘴鲈']),
    _EquipItem(name: '铅笔', spec: 'Popper 120F', type: '水面', score: 7320, heat: 2100, replies: 221, tags: ['水面系', '夏天', '炸水']),
    _EquipItem(name: '胡须公', spec: 'Buzz Bait', type: '水面', score: 7100, heat: 1980, replies: 198, tags: ['噪音诱鱼', '夜晚', '大水面']),
    _EquipItem(name: 'VIB', spec: 'VIB 8-12cm', type: '铁板', score: 6890, heat: 1870, replies: 176, tags: ['沉底搜索', '高感度', '巨物']),
    _EquipItem(name: 'Wacky', spec: 'Wacky Rig', type: '软饵', score: 6650, heat: 1760, replies: 165, tags: ['简单', '高感度', '精细作钓']),
    _EquipItem(name: '德州钓组（无铅）', spec: 'Naked Texas', type: '软饵', score: 6430, heat: 1650, replies: 143, tags: ['自然', '高难度', '老手专用']),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _HeroBanner(
          emoji: '🪤', title: '饵料榜',
          subtitle: '软饵 · 硬饵 · 亮片 · 水面系排行',
          accent: Color(0xFF2E7D32),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _lures.length; i++)
          _EquipCard(item: _lures[i], rank: i + 1, delay: i * 35),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 8: 小药榜
// ═══════════════════════════════════════════════════════
class _BaitTab extends StatelessWidget {
  const _BaitTab();

  static final _baits = [
    _EquipItem(name: 'DMT 促食剂', spec: 'DMT Powder', type: '促食', score: 9120, heat: 3210, replies: 398, tags: ['穿透力强', '四季通用', '竞技必备']),
    _EquipItem(name: '南北 鱼开胃', spec: 'South-North 鱼开胃', type: '促食', score: 8760, heat: 2980, replies: 365, tags: ['野钓必备', '穿透力', '性价比']),
    _EquipItem(name: '丸九 荒食', spec: 'Maruyrug HM-8', type: '鲤鱼类', score: 8430, heat: 2650, replies: 321, tags: ['鲤鱼类', '留鱼久', '竞技首选']),
    _EquipItem(name: '丸九 天下无双', spec: 'Maruyrug 无双', type: '鲤鱼类', score: 8100, heat: 2430, replies: 298, tags: ['高端', '留鱼强', '大物']),
    _EquipItem(name: '魔力鸟 诱', spec: 'MIRUNE 诱 30%', type: '聚鱼', score: 7870, heat: 2210, replies: 276, tags: ['聚鱼快', '四季通用', '奶鲤']),
    _EquipItem(name: '老G 系列', spec: 'LaoG DPT/GLA/NBA', type: '综合', score: 7650, heat: 2100, replies: 254, tags: ['国产精品', '性价比', '奶鲤首选']),
    _EquipItem(name: '穿透王', spec: 'Penetrate King', type: '促食', score: 7430, heat: 1980, replies: 232, tags: ['穿透强', '夜钓', '肥水']),
    _EquipItem(name: '威护 千里香', spec: 'Weihu 千里香', type: '中药类', score: 7210, heat: 1870, replies: 221, tags: ['中药底', '留鱼', '野钓']),
    _EquipItem(name: '化氏 药酒', spec: 'Huashi 药酒', type: '中药类', score: 6980, heat: 1760, replies: 198, tags: ['野钓', '留鱼', '自制感']),
    _EquipItem(name: '红薯膏', spec: '红薯膏 浓缩型', type: '味型类', score: 6760, heat: 1650, replies: 187, tags: ['薯香', '鲤鱼类', '秋冬季']),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _HeroBanner(
          emoji: '💧', title: '小药榜',
          subtitle: '促食 · 聚鱼 · 味型 · 中药类排行',
          accent: Color(0xFFBF360C),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < _baits.length; i++)
          _EquipCard(item: _baits[i], rank: i + 1, delay: i * 35),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// 装备数据模型
// ═══════════════════════════════════════════════════════
class _EquipItem {
  final String name;
  final String spec;
  final String type;
  final int score;  // 综合热度
  final int heat;    // 讨论热度
  final int replies;
  final List<String> tags;
  final String? imageUrl;  // 产品图片路径
  const _EquipItem({
    required this.name, required this.spec, required this.type,
    required this.score, required this.heat, required this.replies,
    required this.tags, this.imageUrl,
  });
}

// ═══════════════════════════════════════════════════════
// 装备卡片（鱼竿/鱼轮/饵料/小药共用）
// ═══════════════════════════════════════════════════════
class _EquipCard extends StatelessWidget {
  final _EquipItem item;
  final int rank;
  final int delay;
  const _EquipCard({required this.item, required this.rank, this.delay = 0});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return const Color(0xFF999999);
  }

  @override
  Widget build(BuildContext context) {
    final top3 = rank <= 3;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(
        scale: v, child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: top3 ? Border.all(color: _rankColor.withAlpha((0.5 * 255).toInt()), width: 1.5) : null,
          boxShadow: [BoxShadow(
            color: _primary.withAlpha((0.06 * 255).toInt()), blurRadius: 6, offset: const Offset(0, 2),
          )],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showEquipDetail(context, item, rank),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text('$rank', style: TextStyle(
                      fontSize: rank <= 3 ? 18 : 14,
                      fontWeight: FontWeight.w900, color: _rankColor,
                    )),
                  ),
                  const SizedBox(width: 10),
                  // 装备图片
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: _rankColor.withAlpha((0.08 * 255).toInt()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: item.imageUrl != null
                    ? Image.asset(
                        item.imageUrl!,
                        width: 60, height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            rank <= 3 ? Icons.star : Icons.settings_input_component,
                            color: _rankColor, size: 24,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          rank <= 3 ? Icons.star : Icons.settings_input_component,
                          color: _rankColor, size: 24,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(item.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: _textMain),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (rank <= 3) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: _rankColor.withAlpha((0.15 * 255).toInt()),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rank == 1 ? 'TOP' : '#$rank',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800,
                                color: _rankColor),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.spec,
                      style: const TextStyle(fontSize: 12, color: _textWeak),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4, runSpacing: 3,
                      children: item.tags.take(3).map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: _primary.withAlpha((0.06 * 255).toInt()),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(t, style: const TextStyle(
                          fontSize: 10, color: _primary, fontWeight: FontWeight.w500,
                        )),
                      )).toList(),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmt(item.score),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _primary)),
                  Text('综合热度', style: const TextStyle(fontSize: 9, color: _textWeak)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.forum_outlined, size: 10, color: _textWeak),
                      const SizedBox(width: 2),
                      Text('${item.replies}', style: const TextStyle(fontSize: 10, color: _textWeak)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  void _showEquipDetail(BuildContext context, _EquipItem item, int rank) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.imageUrl != null)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            item.imageUrl!,
                            width: 200, height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 200, height: 200,
                              color: _primary.withValues(alpha: 0.08),
                              child: const Icon(Icons.catching_pokemon, size: 60, color: _primary),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _textMain)),
                              const SizedBox(height: 4),
                              Text(item.spec, style: const TextStyle(fontSize: 14, color: _textMid)),
                            ],
                          ),
                        ),
                        if (rank <= 3)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _rankColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(rank == 1 ? 'TOP 1' : '#$rank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _rankColor)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: _primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                          child: Text(item.type, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _primary)),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.whatshot, size: 16, color: Color(0xFFFF6B35)),
                        const SizedBox(width: 4),
                        Text(_fmt(item.score), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFF6B35))),
                        const Text(' 综合热度', style: TextStyle(fontSize: 12, color: _textWeak)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('产品标签', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: item.tags.map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                        child: Text(t, style: const TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w500)),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('热度明细', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _StatBox(icon: Icons.whatshot, label: '综合热度', value: _fmt(item.score))),
                        const SizedBox(width: 10),
                        Expanded(child: _StatBox(icon: Icons.trending_up, label: '讨论热度', value: _fmt(item.heat))),
                        const SizedBox(width: 10),
                        Expanded(child: _StatBox(icon: Icons.forum_outlined, label: '讨论数', value: '${item.replies}')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('钓友评价', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32, height: 32,
                                decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                child: const Center(child: Text('钓', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primary))),
                              ),
                              const SizedBox(width: 10),
                              const Text('钓友口碑', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item.tags.isNotEmpty ? '这款${item.type}在钓友中评价不错，${item.tags.first}是主要亮点。' : '暂无用户评价。', style: const TextStyle(fontSize: 13, color: _textMid, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatBox({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, size: 20, color: _primary),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textMain)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: _textWeak)),
        ],
      ),
    );
  }
}




// ═══════════════════════════════════════════════════════
// TAB 5: 鱼竿榜 — 真实电商热销数据
// ═══════════════════════════════════════════════════════

// ── 全局常量 ────────────────────────────────────────────
const _primary   = Color(0xFF0A7C74);
const _bg        = Color(0xFFF7F3EE);
const _gold      = Color(0xFFC49A5E);
const _textMain  = Color(0xFF1A1A1A);
const _textMid   = Color(0xFF666666);
const _textWeak  = Color(0xFF999999);
