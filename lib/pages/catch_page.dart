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
    _tabCtrl = TabController(length: 4, vsync: this);
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

// ── 全局常量 ────────────────────────────────────────────
const _primary   = Color(0xFF0A7C74);
const _bg        = Color(0xFFF7F3EE);
const _gold      = Color(0xFFC49A5E);
const _textMain  = Color(0xFF1A1A1A);
const _textMid   = Color(0xFF666666);
const _textWeak  = Color(0xFF999999);
