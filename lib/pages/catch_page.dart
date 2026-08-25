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
import 'equip_detail_page.dart';

/// 鱼获榜 → 钓鱼精华聚合页
/// 4维度Tab：大鱼榜 · 热门钓点 · 热帖 · 人气钓友
class CatchPage extends StatefulWidget {
  const CatchPage({super.key});

  @override
  State<CatchPage> createState() => _CatchPageState();
}

class _CatchPageState extends State<CatchPage>
    with SingleTickerProviderStateMixin {
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
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _primary,
            letterSpacing: -0.3,
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
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
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
            const Text(
              '精华榜说明',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _textMain,
              ),
            ),
            const SizedBox(height: 16),
            _ruleItem('🏋️ 大鱼榜', '单尾最重，大鱼认证 ≥5kg'),
            _ruleItem('📍 热门钓点', '热度分 = 浏览×0.1 + 收藏×3 + 点评×5 + 新帖×10 + 评分×20'),
            _ruleItem('🔥 热帖', '综合热度 = 点赞×1 + 评论×2 + 收藏×3'),
            _ruleItem('⭐ 人气钓友', '积分累计：发帖+1，获赞+1，大鱼认证+10'),
            const SizedBox(height: 12),
            const Text(
              '参考 Bassmaster 赛制 · 摸鱼圈积分体系',
              style: TextStyle(fontSize: 12, color: _textWeak),
            ),
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
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textMain,
              ),
            ),
          ),
          Expanded(
            child: Text(
              desc,
              style: const TextStyle(fontSize: 13, color: _textMid),
            ),
          ),
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
          emoji: '🏋️',
          title: '大鱼榜',
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

class _FishCardState extends State<_FishCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top3 = widget.rank <= 3;
    final borderColor = widget.rank == 1
        ? _gold
        : widget.rank == 2
        ? const Color(0xFFB0BEC5)
        : widget.rank == 3
        ? const Color(0xFFCD7F32)
        : null;

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
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CatchDetailPage(
                    name: widget.item.userName,
                    avatar: widget.item.images.isNotEmpty
                        ? widget.item.images.first
                        : '',
                    fish: widget.item.fish,
                    weight: widget.item.weight.toStringAsFixed(1) + ' kg',
                    rank: widget.rank,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // 排名
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: widget.rank == 1
                            ? _gold
                            : widget.rank <= 3
                            ? const Color(0xFFF0EDE8)
                            : _bg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: widget.rank <= 3
                            ? Text(
                                '${widget.rank}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                '${widget.rank}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textMid,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 鱼图标
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.catching_pokemon,
                        color: _primary,
                        size: 24,
                      ),
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
                                child: Text(
                                  widget.item.fish,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _textMain,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.item.verified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  color: _gold,
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${widget.item.weight.toStringAsFixed(1)} kg  ·  ${widget.item.userName}  ·  ${widget.item.spotName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textWeak,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // 重量标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.item.weight.toStringAsFixed(1)}kg',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _primary,
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
          emoji: '📍',
          title: '热门钓点',
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
        scale: v,
        child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: top3
              ? Border.all(color: _rankColor.withValues(alpha: 0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SpotDetailPage(spot: spot)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 排名
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: rank <= 3 ? 18 : 14,
                        fontWeight: FontWeight.w900,
                        color: _rankColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 类型图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        spot.typeEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${spot.city} · ${spot.type} · ${spot.priceLabel}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textWeak,
                          ),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                      const Text(
                        '热度',
                        style: TextStyle(fontSize: 10, color: _textWeak),
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
          emoji: '🔥',
          title: '热帖',
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
      return List.from(all)..sort((a, b) {
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
    final score =
        post.likeCount * 1 + post.commentCount * 2 + (post.likeCount ~/ 5);
    final top3 = rank <= 3;
    final rankColor = rank == 1
        ? _gold
        : rank == 2
        ? const Color(0xFFB0BEC5)
        : rank == 3
        ? const Color(0xFFCD7F32)
        : _textWeak;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(
        scale: v,
        child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: top3
              ? Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PostDetailPage(
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
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: rank <= 3 ? 18 : 14,
                        fontWeight: FontWeight.w900,
                        color: rankColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 封面图
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      post.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: _primary.withValues(alpha: 0.08),
                        child: const Icon(
                          Icons.image,
                          color: _primary,
                          size: 24,
                        ),
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
                          post.title.isNotEmpty ? post.title : post.authorName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textMain,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              size: 11,
                              color: _textWeak,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              post.authorName,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _textWeak,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.location_on_outlined,
                              size: 11,
                              color: _textWeak,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                post.location,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _textWeak,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.favorite,
                              size: 12,
                              color: Color(0xFFFF4757),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${post.likeCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF4757),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.comment_outlined,
                              size: 12,
                              color: _textWeak,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${post.commentCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: _textWeak,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 热度
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _fmtScore(score),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const Text(
                        '热度',
                        style: TextStyle(fontSize: 10, color: _textWeak),
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
          emoji: '⭐',
          title: '人气钓友',
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
      map.putIfAbsent(
        c.userId,
        () => _AnglerProfile(
          userId: c.userId,
          userName: c.userName,
          avatarColor: _avatarColors[map.length % _avatarColors.length],
        ),
      );
      map[c.userId]!.score += c.verified ? 10 : 1;
      map[c.userId]!.verifiedCount += c.verified ? 1 : 0;
    }
    // 从帖子数据聚合
    try {
      for (var p in PostService.mockAll()) {
        map.putIfAbsent(
          p.authorId,
          () => _AnglerProfile(
            userId: p.authorId,
            userName: p.authorName,
            avatarColor: _avatarColors[map.length % _avatarColors.length],
          ),
        );
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
    required this.userId,
    required this.userName,
    required this.avatarColor,
    this.score = 0,
    this.likeCount = 0,
    this.postCount = 0,
    this.verifiedCount = 0,
  });
}

final _avatarColors = [
  const Color(0xFF0A7C74),
  const Color(0xFF0F4C5C),
  const Color(0xFFCD7F32),
  const Color(0xFF2E7D32),
  const Color(0xFFC49A5E),
  const Color(0xFF1565C0),
  const Color(0xFF6A1B9A),
  const Color(0xFFC62828),
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
        scale: v,
        child: Opacity(opacity: v, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: top3
              ? Border.all(color: _rankColor.withValues(alpha: 0.5), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: _primary.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfilePage(
                  name: angler.userName,
                  avatar: '',
                  bio: '钓鱼爱好者',
                  posts: angler.postCount,
                  followers: 0,
                  following: 0,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 排名
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: rank <= 3 ? 18 : 14,
                        fontWeight: FontWeight.w900,
                        color: _rankColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 头像
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: angler.avatarColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        angler.userName.isNotEmpty ? angler.userName[0] : '?',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
                            Text(
                              angler.userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _textMain,
                              ),
                            ),
                            if (angler.verifiedCount > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: _gold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '🐟×${angler.verifiedCount}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _gold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _statChip(
                              Icons.article_outlined,
                              '${angler.postCount}帖',
                            ),
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
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _gold,
                        ),
                      ),
                      const Text(
                        '积分',
                        style: TextStyle(fontSize: 10, color: _textWeak),
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
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.85), accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
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
class _RodTab extends StatefulWidget {
  const _RodTab();
  @override
  State<_RodTab> createState() => _RodTabState();
}

class _RodTabState extends State<_RodTab> {
  String? _selectedType;

  static final _rods = [
    _EquipItem(
      name: '禧玛诺 EXSENCE',
      spec: 'Infinity B86MH',
      type: '海鲈竿',
      waterType: '海水',
      score: 9820,
      heat: 4124,
      replies: 491,
      tags: ['旗舰', '感度强', '海鲈首选'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: 'EXSENCE 海鲈专用竿，感度与腰力兼备。',
      imageUrl: 'assets/images/equip/rod_01.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 EMERALDAS',
      spec: 'MX 86M-S',
      type: '鱿鱼竿',
      waterType: '海水',
      score: 9740,
      heat: 4091,
      replies: 487,
      tags: ['鱿鱼', '轻量', '路亚精品'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: 'EMERALDAS 鱿鱼 Egix 竿，轻量高感。',
      imageUrl: 'assets/images/equip/rod_02.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 LUNAMIS',
      spec: 'S86M',
      type: '海鲈竿',
      waterType: '海水',
      score: 9660,
      heat: 4057,
      replies: 483,
      tags: ['海鲈', '泛用', '腰力足'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: 'LUNAMIS 海鲈/轻海水泛用，腰力足。',
      imageUrl: 'assets/images/equip/rod_03.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 INFINITY',
      spec: '海鲈',
      type: '海鲈竿',
      waterType: '海水',
      score: 9580,
      heat: 4024,
      replies: 479,
      tags: ['海鲈', '旗舰', '感度'],
      gallery: [
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_15.jpg',
      ],
      desc: 'INFINITY 海鲈旗舰竿，抛投精准。',
      imageUrl: 'assets/images/equip/rod_04.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 TEREZ',
      spec: '船钓',
      type: '船钓竿',
      waterType: '海水',
      score: 9500,
      heat: 3990,
      replies: 475,
      tags: ['船钓', '根鱼', '暴力'],
      gallery: [
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_16.jpg',
      ],
      desc: 'TEREZ 船钓竿，应对深海根鱼巨物。',
      imageUrl: 'assets/images/spots/wm_05.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 SALTIGA',
      spec: '游戏竿',
      type: '海钓竿',
      waterType: '海水',
      score: 9420,
      heat: 3956,
      replies: 471,
      tags: ['海水', '旗舰', '船钓'],
      gallery: [
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
      ],
      desc: 'SALTIGA 游戏竿，海水船钓标杆。',
      imageUrl: 'assets/images/spots/wm_06.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 OCEA',
      spec: 'JIGGER',
      type: '铁板竿',
      waterType: '海水',
      score: 9340,
      heat: 3923,
      replies: 467,
      tags: ['海水', '铁板', '慢摇'],
      gallery: [
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
      ],
      desc: 'OCEA JIGGER 铁板慢摇专用竿。',
      imageUrl: 'assets/images/equip/rod_07.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 SEAPOWER',
      spec: '船竿',
      type: '船钓竿',
      waterType: '海水',
      score: 9260,
      heat: 3889,
      replies: 463,
      tags: ['船钓', '深海', '专业'],
      gallery: [
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
      ],
      desc: 'SEAPOWER 船竿，深海钓大物。',
      imageUrl: 'assets/images/spots/wm_08.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 GRAPPLER',
      spec: '慢摇',
      type: '慢摇竿',
      waterType: '海水',
      score: 9180,
      heat: 3856,
      replies: 459,
      tags: ['慢摇', '铁板', '船钓'],
      gallery: [
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
      ],
      desc: 'GRAPPLER 慢摇竿，深海铁板利器。',
      imageUrl: 'assets/images/equip/rod_09.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 MORETHAN',
      spec: '海水',
      type: '海钓竿',
      waterType: '海水',
      score: 9100,
      heat: 3822,
      replies: 455,
      tags: ['海水', '泛用', '感度'],
      gallery: [
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
      ],
      desc: 'MORETHAN 海水泛用竿。',
      imageUrl: 'assets/images/spots/wm_10.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 YASEI',
      spec: 'Predator',
      type: '海钓竿',
      waterType: '海水',
      score: 9020,
      heat: 3788,
      replies: 451,
      tags: ['海水', '掠食', '泛用'],
      gallery: [
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_06.jpg',
      ],
      desc: 'YASEI 掠食鱼专用海水竿。',
      imageUrl: 'assets/images/spots/wm_11.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 SEPHIA',
      spec: '鱿鱼',
      type: '鱿鱼竿',
      waterType: '海水',
      score: 8940,
      heat: 3755,
      replies: 447,
      tags: ['鱿鱼', '轻量', '感度'],
      gallery: [
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_07.jpg',
      ],
      desc: 'SEPHIA 鱿鱼 Egix 竿。',
      imageUrl: 'assets/images/equip/rod_12.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 EMERALDAS AIR',
      spec: '鱿鱼',
      type: '鱿鱼竿',
      waterType: '海水',
      score: 8860,
      heat: 3721,
      replies: 443,
      tags: ['鱿鱼', '航空碳', '轻量'],
      gallery: [
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_08.jpg',
      ],
      desc: 'EMERALDAS AIR 航空碳布鱿鱼竿。',
      imageUrl: 'assets/images/equip/rod_13.jpg',
    ),
    _EquipItem(
      name: 'Major Craft Giant Killing',
      spec: 'GK5C-732MH',
      type: '慢摇竿',
      waterType: '海水',
      score: 8780,
      heat: 3688,
      replies: 439,
      tags: ['慢摇', '铁板', '船钓'],
      gallery: [
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_09.jpg',
      ],
      desc: 'Giant Killing 5G 慢摇铁板竿。',
      imageUrl: 'assets/images/equip/rod_14.jpg',
    ),
    _EquipItem(
      name: 'Tenryu Horizon MJ',
      spec: 'HMJ642B-M',
      type: '船钓竿',
      waterType: '海水',
      score: 8700,
      heat: 3654,
      replies: 435,
      tags: ['船钓', '根鱼', '专业'],
      gallery: [
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_10.jpg',
      ],
      desc: 'Horizon MJ 船钓根鱼专业竿。',
      imageUrl: 'assets/images/equip/rod_15.jpg',
    ),
    _EquipItem(
      name: 'Gamakatsu LUXXE',
      spec: '海钓',
      type: '海钓竿',
      waterType: '海水',
      score: 8620,
      heat: 3620,
      replies: 431,
      tags: ['海钓', '感度', '进口'],
      gallery: [
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_11.jpg',
      ],
      desc: 'Gamakatsu LUXXE 海钓感度竿。',
      imageUrl: 'assets/images/equip/rod_16.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 SALTIGA',
      spec: 'Rockfish',
      type: '矶钓竿',
      waterType: '海水',
      score: 8540,
      heat: 3587,
      replies: 427,
      tags: ['矶钓', '根鱼', '海水'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: 'SALTIGA Rockfish 矶钓根鱼竿。',
      imageUrl: 'assets/images/spots/wm_01.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 OCEA CONQUEST',
      spec: '海水',
      type: '海钓竿',
      waterType: '海水',
      score: 8460,
      heat: 3553,
      replies: 423,
      tags: ['海水', '旗舰', '船钓'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: 'OCEA CONQUEST 海水旗舰竿。',
      imageUrl: 'assets/images/spots/wm_02.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 REDBACK',
      spec: 'Tairaba',
      type: '船钓竿',
      waterType: '海水',
      score: 8380,
      heat: 3520,
      replies: 419,
      tags: ['船钓', '鲷类', '海水'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: 'REDBACK 船钓鲷类竿。',
      imageUrl: 'assets/images/equip/rod_19.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 EXSENCE',
      spec: '海鲈',
      type: '海鲈竿',
      waterType: '海水',
      score: 8300,
      heat: 3486,
      replies: 415,
      tags: ['海鲈', '旗舰', '感度'],
      gallery: [
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_15.jpg',
      ],
      desc: 'EXSENCE 海鲈旗舰竿（再入榜）。',
      imageUrl: 'assets/images/equip/rod_20.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 STEEZ',
      spec: '路亚竿',
      type: '路亚竿',
      waterType: '淡水',
      score: 8220,
      heat: 3452,
      replies: 411,
      tags: ['旗舰', '路亚', '感度'],
      gallery: [
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_16.jpg',
      ],
      desc: 'STEEZ 路亚旗舰竿，极致手感。',
      imageUrl: 'assets/images/spots/wm_05.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 ZODIAS',
      spec: '路亚竿',
      type: '路亚竿',
      waterType: '淡水',
      score: 8140,
      heat: 3419,
      replies: 407,
      tags: ['路亚', '感度', '泛用'],
      gallery: [
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
      ],
      desc: 'ZODIAS 泛用路亚竿，HI-POWER X 抗扭曲。',
      imageUrl: 'assets/images/spots/wm_06.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 POISON',
      spec: '路亚竿',
      type: '路亚竿',
      waterType: '淡水',
      score: 8060,
      heat: 3385,
      replies: 403,
      tags: ['旗舰', '路亚', '雷强'],
      gallery: [
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
      ],
      desc: 'POISON 路亚旗舰，雷强炸水利器。',
      imageUrl: 'assets/images/spots/wm_07.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 BASS X',
      spec: '路亚',
      type: '路亚竿',
      waterType: '淡水',
      score: 7980,
      heat: 3352,
      replies: 399,
      tags: ['路亚', '入门', '性价比'],
      gallery: [
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
      ],
      desc: 'BASS X 入门路亚竿，性价比高。',
      imageUrl: 'assets/images/spots/wm_08.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 WORLD SHAULA',
      spec: 'BG 21055R-3',
      type: '雷强竿',
      waterType: '淡水',
      score: 7900,
      heat: 3318,
      replies: 395,
      tags: ['雷强', '重草', '暴力'],
      gallery: [
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
      ],
      desc: 'WORLD SHAULA 雷强竿，重草区暴力输出。',
      imageUrl: 'assets/images/equip/rod_25.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 BLACK LABEL',
      spec: '路亚',
      type: '路亚竿',
      waterType: '淡水',
      score: 7820,
      heat: 3284,
      replies: 391,
      tags: ['路亚', '泛用', '手感'],
      gallery: [
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
      ],
      desc: 'BLACK LABEL 泛用路亚，手感细腻。',
      imageUrl: 'assets/images/spots/wm_10.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 EXPRIDE',
      spec: '路亚',
      type: '路亚竿',
      waterType: '淡水',
      score: 7740,
      heat: 3251,
      replies: 387,
      tags: ['路亚', '泛用', '进阶'],
      gallery: [
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_06.jpg',
      ],
      desc: 'EXPRIDE 进阶路亚竿。',
      imageUrl: 'assets/images/spots/wm_11.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 CORVALUS',
      spec: '路亚',
      type: '路亚竿',
      waterType: '淡水',
      score: 7660,
      heat: 3217,
      replies: 383,
      tags: ['路亚', '耐用', '性价比'],
      gallery: [
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_07.jpg',
      ],
      desc: 'CORVALUS 耐用泛用路亚竿。',
      imageUrl: 'assets/images/spots/wm_12.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 CATANA',
      spec: '路亚',
      type: '路亚竿',
      waterType: '淡水',
      score: 7580,
      heat: 3184,
      replies: 379,
      tags: ['入门', '路亚', '实惠'],
      gallery: [
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_08.jpg',
      ],
      desc: 'CATANA 入门路亚竿，价格友好。',
      imageUrl: 'assets/images/spots/wm_13.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 FIRE WOLF',
      spec: '路亚',
      type: '路亚竿',
      waterType: '淡水',
      score: 7500,
      heat: 3150,
      replies: 375,
      tags: ['路亚', '入门', '轻量'],
      gallery: [
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_09.jpg',
      ],
      desc: 'FIRE WOLF 轻量入门路亚竿。',
      imageUrl: 'assets/images/spots/wm_14.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 BRENNIUS',
      spec: 'S80LS',
      type: '路亚竿',
      waterType: '淡水',
      score: 7420,
      heat: 3116,
      replies: 371,
      tags: ['泛用', '性价比', '耐用'],
      gallery: [
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_10.jpg',
      ],
      desc: 'BRENNIUS 泛用路亚，性价比耐用。',
      imageUrl: 'assets/images/equip/rod_31.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 LURENIST',
      spec: '86ML',
      type: '路亚竿',
      waterType: '淡水',
      score: 7340,
      heat: 3083,
      replies: 367,
      tags: ['软饵', '精细', '感度佳'],
      gallery: [
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_11.jpg',
      ],
      desc: 'LURENIST 精细软饵竿，感度佳。',
      imageUrl: 'assets/images/equip/rod_32.jpg',
    ),
    _EquipItem(
      name: 'Gamakatsu Luxe Yoihime',
      spec: 'Soh S78M',
      type: '阿鲫竿',
      waterType: '淡水',
      score: 7260,
      heat: 3049,
      replies: 363,
      tags: ['阿鲫', '轻量', '手感好'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: 'Luxe Yoihime 阿鲫竿，轻量手感好。',
      imageUrl: 'assets/images/equip/rod_33.jpg',
    ),
    _EquipItem(
      name: 'OLYMPIC Finezza',
      spec: '23GFINUS-832ML-T',
      type: '阿鲫竿',
      waterType: '淡水',
      score: 7180,
      heat: 3016,
      replies: 359,
      tags: ['阿鲫', '高感', '进口精品'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: 'Finezza UX 阿鲫高感竿。',
      imageUrl: 'assets/images/equip/rod_34.jpg',
    ),
    _EquipItem(
      name: 'Major Craft',
      spec: '路亚',
      type: '路亚竿',
      waterType: '淡水',
      score: 7100,
      heat: 2982,
      replies: 355,
      tags: ['路亚', '泛用', '性价比'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: 'Major Craft 泛用路亚竿。',
      imageUrl: 'assets/images/equip/rod_35.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 TRIFOLIA',
      spec: '鲤',
      type: '鲤竿',
      waterType: '淡水',
      score: 7020,
      heat: 2948,
      replies: 351,
      tags: ['鲤', '腰力', '大物'],
      gallery: [
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_15.jpg',
      ],
      desc: 'TRIFOLIA 鲤竿，腰力足博大物。',
      imageUrl: 'assets/images/spots/wm_04.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 YARAI',
      spec: '鲤',
      type: '鲤竿',
      waterType: '淡水',
      score: 6940,
      heat: 2915,
      replies: 347,
      tags: ['鲤', '硬调', '大物'],
      gallery: [
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_16.jpg',
      ],
      desc: 'YARAI 鲤竿，硬调博大物。',
      imageUrl: 'assets/images/spots/wm_05.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 GAMAKATSU',
      spec: '鲤',
      type: '鲤竿',
      waterType: '淡水',
      score: 6860,
      heat: 2881,
      replies: 343,
      tags: ['鲤', '进口', '耐用'],
      gallery: [
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
      ],
      desc: 'Gamakatsu 鲤竿，进口耐用。',
      imageUrl: 'assets/images/equip/rod_38.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 CARP',
      spec: '鲤',
      type: '鲤竿',
      waterType: '淡水',
      score: 6780,
      heat: 2848,
      replies: 339,
      tags: ['鲤', '泛用', '入门'],
      gallery: [
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
      ],
      desc: 'CARP 鲤竿，日常野钓。',
      imageUrl: 'assets/images/spots/wm_07.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 CARPZ',
      spec: '鲤',
      type: '鲤竿',
      waterType: '淡水',
      score: 6700,
      heat: 2814,
      replies: 335,
      tags: ['鲤', '腰力', '性价比'],
      gallery: [
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
      ],
      desc: 'CARPZ 鲤竿，性价比腰力款。',
      imageUrl: 'assets/images/spots/wm_08.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 LUNAMIS',
      spec: '淡水',
      type: '海鲈竿',
      waterType: '淡水',
      score: 6620,
      heat: 2780,
      replies: 331,
      tags: ['泛用', '腰力', '路亚'],
      gallery: [
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
      ],
      desc: 'LUNAMIS 淡水泛用版。',
      imageUrl: 'assets/images/equip/rod_41.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 STEEZ',
      spec: '鲫',
      type: '阿鲫竿',
      waterType: '淡水',
      score: 6540,
      heat: 2747,
      replies: 327,
      tags: ['旗舰', '阿鲫', '感度'],
      gallery: [
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
      ],
      desc: 'STEEZ 阿鲫旗舰竿。',
      imageUrl: 'assets/images/spots/wm_10.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 ZODIAS',
      spec: '鲫',
      type: '阿鲫竿',
      waterType: '淡水',
      score: 6460,
      heat: 2713,
      replies: 323,
      tags: ['阿鲫', '感度', '泛用'],
      gallery: [
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_06.jpg',
      ],
      desc: 'ZODIAS 阿鲫泛用竿。',
      imageUrl: 'assets/images/spots/wm_11.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 TATULA',
      spec: '路亚',
      type: '路亚竿',
      waterType: '淡水',
      score: 6380,
      heat: 2680,
      replies: 319,
      tags: ['路亚', '泛用', '手感'],
      gallery: [
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_07.jpg',
      ],
      desc: 'TATULA 路亚竿，泛用手感好。',
      imageUrl: 'assets/images/spots/wm_12.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 POISON',
      spec: '雷强',
      type: '雷强竿',
      waterType: '淡水',
      score: 6300,
      heat: 2646,
      replies: 315,
      tags: ['雷强', '旗舰', '暴力'],
      gallery: [
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_08.jpg',
      ],
      desc: 'POISON 雷强竿（再入榜）。',
      imageUrl: 'assets/images/spots/wm_13.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 MORETHAN',
      spec: '淡水',
      type: '泛用竿',
      waterType: '淡水',
      score: 6220,
      heat: 2612,
      replies: 311,
      tags: ['泛用', '感度', '性价比'],
      gallery: [
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_09.jpg',
      ],
      desc: 'MORETHAN 淡水泛用竿。',
      imageUrl: 'assets/images/spots/wm_14.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 EXPRIDE',
      spec: '鲫',
      type: '阿鲫竿',
      waterType: '淡水',
      score: 6140,
      heat: 2579,
      replies: 307,
      tags: ['阿鲫', '进阶', '感度'],
      gallery: [
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_10.jpg',
      ],
      desc: 'EXPRIDE 阿鲫进阶竿。',
      imageUrl: 'assets/images/spots/wm_15.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 BLACK LABEL',
      spec: '雷强',
      type: '雷强竿',
      waterType: '淡水',
      score: 6060,
      heat: 2545,
      replies: 303,
      tags: ['雷强', '泛用', '手感'],
      gallery: [
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_11.jpg',
      ],
      desc: 'BLACK LABEL 雷强泛用。',
      imageUrl: 'assets/images/spots/wm_16.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 WORLD SHAULA',
      spec: ' frog',
      type: '雷强竿',
      waterType: '淡水',
      score: 5980,
      heat: 2512,
      replies: 299,
      tags: ['雷强', '炸水', '暴力'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: 'WORLD SHAULA 蛙饵雷强竿（再入榜）。',
      imageUrl: 'assets/images/equip/rod_49.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 GIANT KILLING',
      spec: '路亚',
      type: '路亚竿',
      waterType: '淡水',
      score: 5900,
      heat: 2478,
      replies: 295,
      tags: ['路亚', '泛用', '感度'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: 'Giant Killing 淡水路亚版。',
      imageUrl: 'assets/images/equip/rod_50.jpg',
    ),
    _EquipItem(
      name: 'OLYMPIC Finezza',
      spec: '鲫',
      type: '阿鲫竿',
      waterType: '淡水',
      score: 5820,
      heat: 2444,
      replies: 291,
      tags: ['阿鲫', '高感', '进口'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: 'Finezza 阿鲫高感（再入榜）。',
      imageUrl: 'assets/images/equip/rod_51.jpg',
    ),
    _EquipItem(
      name: '化氏 一味MAX',
      spec: 'YX-722ML',
      type: '路亚竿',
      waterType: '淡水',
      score: 5100,
      heat: 3200,
      replies: 480,
      tags: ['旗舰', '轻量', '感度好', '碳纤维'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: '化氏一味MAX路亚竿，国产路亚天花板，超轻量高感度，全碳纤维设计，主攻鳜鱼马口。',
    ),
    _EquipItem(
      name: '化氏 一味2代',
      spec: 'YIWEI-2 682M',
      type: '路亚竿',
      waterType: '淡水',
      score: 4600,
      heat: 2800,
      replies: 420,
      tags: ['旗舰', '感度好', '轻量', '泛用'],
      gallery: [
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: '化氏一味2代路亚竿，升级版碳布调教，感度锐利，适合鳜鱼/翘嘴/黑鱼泛用。',
    ),
    _EquipItem(
      name: '化氏 龙纹鲤',
      spec: 'LONGWEN-2402',
      type: '路亚竿',
      waterType: '淡水',
      score: 3800,
      heat: 2200,
      replies: 330,
      tags: ['性价比', '感度好', '轻量', '台钓'],
      gallery: [
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
      ],
      desc: '化氏龙纹鲤路亚竿，经典系列，调性精准，性价比高，适合鳜鱼/翘嘴。',
    ),
    _EquipItem(
      name: '光威 翔云',
      spec: 'XIANGYUN-2102',
      type: '路亚竿',
      waterType: '淡水',
      score: 2900,
      heat: 1600,
      replies: 240,
      tags: ['入门', '性价比', '轻量', '泛用'],
      gallery: [
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
      ],
      desc: '光威翔云路亚竿，入门级性价比首选，轻量顺手，适合新手练习和野钓。',
    ),
    _EquipItem(
      name: '光威 骇浪',
      spec: 'HAILANG-2402',
      type: '路亚竿',
      waterType: '淡水',
      score: 3400,
      heat: 2000,
      replies: 300,
      tags: ['旗舰', '感度好', '大物', '雷强'],
      gallery: [
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
      ],
      desc: '光威骇浪路亚竿，雷强专用设计，强力护环，主攻黑鱼大物，强度极高。',
    ),
    _EquipItem(
      name: '光威 海明威',
      spec: 'HAIMING-2202',
      type: '路亚竿',
      waterType: '淡水',
      score: 3200,
      heat: 1850,
      replies: 278,
      tags: ['旗舰', '感度好', '轻量', '鳜鱼'],
      gallery: [
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
      ],
      desc: '光威海明威路亚竿，高感度设计，鳜鱼专用，轻量高感度，反应灵敏。',
    ),
    _EquipItem(
      name: '汉鼎 魂',
      spec: 'HUN-1802',
      type: '路亚竿',
      waterType: '淡水',
      score: 2600,
      heat: 1400,
      replies: 210,
      tags: ['入门', '性价比', '轻量', '泛用'],
      gallery: [
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
      ],
      desc: '汉鼎魂路亚竿，入门性价比首选，轻量顺手，适合马口/鳜鱼/翘嘴野钓。',
    ),
    _EquipItem(
      name: '汉鼎 战',
      spec: 'ZHAN-2102',
      type: '路亚竿',
      waterType: '淡水',
      score: 3100,
      heat: 1750,
      replies: 263,
      tags: ['旗舰', '感度好', '大物', '竞技'],
      gallery: [
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
      ],
      desc: '汉鼎战路亚竿，黑坑竞技专用，高感度，竿身强度高，主攻鳜鱼大物。',
    ),
    _EquipItem(
      name: '汉鼎 鼎',
      spec: 'DING-2402',
      type: '路亚竿',
      waterType: '淡水',
      score: 3500,
      heat: 2100,
      replies: 315,
      tags: ['旗舰', '感度好', '轻量', '翘嘴'],
      gallery: [
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
      ],
      desc: '汉鼎鼎路亚竿，远投专用，高感度，轻量高强度，主攻翘嘴/鳜鱼。',
    ),
    _EquipItem(
      name: '佳钓尼 伏魔',
      spec: 'FUMO-2102',
      type: '路亚竿',
      waterType: '淡水',
      score: 2400,
      heat: 1250,
      replies: 188,
      tags: ['入门', '性价比', '轻量', '泛用'],
      gallery: [
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
      ],
      desc: '佳钓尼伏魔路亚竿，网红爆款，性价比极高，轻量顺手，新手首选。',
    ),
    _EquipItem(
      name: '佳钓尼 无二',
      spec: 'WUER-2402',
      type: '路亚竿',
      waterType: '淡水',
      score: 3000,
      heat: 1700,
      replies: 255,
      tags: ['旗舰', '感度好', '轻量', '竞技'],
      gallery: [
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
      ],
      desc: '佳钓尼无二路亚竿，旗舰级感度设计，全碳纤维，轻量高感度，竞技首选。',
    ),
    _EquipItem(
      name: '佳钓尼 火烈鸟',
      spec: 'HUOLIEN-2102',
      type: '路亚竿',
      waterType: '淡水',
      score: 2700,
      heat: 1500,
      replies: 225,
      tags: ['性价比', '感度好', '泛用', '轻量'],
      gallery: [
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
      ],
      desc: '佳钓尼火烈鸟路亚竿，独特涂装，高感度设计，适合鳜鱼/翘嘴泛用。',
    ),
    _EquipItem(
      name: '天元 浪尖',
      spec: 'LANGJIAN-2402',
      type: '路亚竿',
      waterType: '淡水',
      score: 4300,
      heat: 2650,
      replies: 398,
      tags: ['旗舰', '感度好', '大物', '竞技'],
      gallery: [
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
      ],
      desc: '天元浪尖路亚竿，邓刚老师联名设计，高感度竞技级别，主攻黑坑大物。',
    ),
    _EquipItem(
      name: '天元 千川',
      spec: 'QIANCHUAN-2702',
      type: '路亚竿',
      waterType: '淡水',
      score: 4800,
      heat: 3050,
      replies: 458,
      tags: ['旗舰', '感度好', '轻量', '鳜鱼'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
      ],
      desc: '天元千川路亚竿，邓刚老师旗舰级，轻量高感度，全碳纤维设计，鳜鱼专用。',
    ),
    _EquipItem(
      name: '天元 刚舟',
      spec: 'GANGZHOU-2102',
      type: '路亚竿',
      waterType: '淡水',
      score: 3600,
      heat: 2150,
      replies: 323,
      tags: ['旗舰', '感度好', '远投', '翘嘴'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: '天元刚舟路亚竿，远投专用设计，高感度，竿身轻盈，主攻翘嘴远投。',
    ),
    _EquipItem(
      name: '化氏 龙象',
      spec: 'LONGXIANG-3604',
      type: '台钓竿',
      waterType: '淡水',
      score: 3800,
      heat: 2300,
      replies: 345,
      tags: ['鲤竿', '性价比', '腰力好', '综合'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: '化氏龙象台钓竿，鲤竿经典，腰力强劲，适合综合鲤草，综合性能出色。',
    ),
    _EquipItem(
      name: '光威 刚毅',
      spec: 'GANGYI-4505',
      type: '台钓竿',
      waterType: '淡水',
      score: 3200,
      heat: 1900,
      replies: 285,
      tags: ['鲤竿', '性价比', '腰力好', '入门'],
      gallery: [
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: '光威刚毅台钓竿，入门鲤竿首选，腰力好，性价比高，适合休闲鲤草。',
    ),
    _EquipItem(
      name: '光威 天下',
      spec: 'TIANXIA-3604',
      type: '台钓竿',
      waterType: '淡水',
      score: 4200,
      heat: 2600,
      replies: 390,
      tags: ['鲤竿', '旗舰', '腰力好', '竞技'],
      gallery: [
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
      ],
      desc: '光威天下台钓竿，旗舰鲤竿，腰力强，竞技鲤草首选，手感细腻。',
    ),
    _EquipItem(
      name: '汉鼎 鲢鳙',
      spec: 'LIANYONG-5006',
      type: '台钓竿',
      waterType: '淡水',
      score: 3500,
      heat: 2100,
      replies: 315,
      tags: ['鲢鳙竿', '性价比', '远投', '大物'],
      gallery: [
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
      ],
      desc: '汉鼎鲢鳙台钓竿，远投专用，竿身高强度，主攻鲢鳙大物，性价比高。',
    ),
    _EquipItem(
      name: '汉鼎 青鲢',
      spec: 'QINGLIAN-4505',
      type: '台钓竿',
      waterType: '淡水',
      score: 3100,
      heat: 1800,
      replies: 270,
      tags: ['鲢鳙竿', '性价比', '腰力好', '入门'],
      gallery: [
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
      ],
      desc: '汉鼎青鲢台钓竿，入门鲢鳙首选，腰力好，远投性能好，钓鲢鳙首选。',
    ),
    _EquipItem(
      name: '佳钓尼 满江红',
      spec: 'MANJIANG-3604',
      type: '台钓竿',
      waterType: '淡水',
      score: 2800,
      heat: 1600,
      replies: 240,
      tags: ['鲤竿', '性价比', '腰力好', '综合'],
      gallery: [
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
      ],
      desc: '佳钓尼满江红台钓竿，网红爆款鲤竿，腰力好，性价比高，综合性能出色。',
    ),
    _EquipItem(
      name: '佳钓尼 岚酷',
      spec: 'LANKU-4505',
      type: '台钓竿',
      waterType: '淡水',
      score: 3400,
      heat: 2000,
      replies: 300,
      tags: ['鲤竿', '旗舰', '腰力好', '竞技'],
      gallery: [
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
      ],
      desc: '佳钓尼岚酷台钓竿，旗舰鲤竿，腰力强，竞技鲤草首选，手感细腻。',
    ),
    _EquipItem(
      name: '宝飞龙 BARFILON 天翔',
      spec: 'TIANXIANG-3604',
      type: '台钓竿',
      waterType: '淡水',
      score: 4600,
      heat: 2850,
      replies: 428,
      tags: ['鲤竿', '旗舰', '高端', '碳纤维'],
      gallery: [
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
      ],
      desc: '宝飞龙天翔台钓竿，高端碳纤维鲤竿，腰力极强，竞技鲤草首选，手感卓越。',
    ),
    _EquipItem(
      name: '宝飞龙 BARFILON 极光',
      spec: 'JIGUANG-4505',
      type: '台钓竿',
      waterType: '淡水',
      score: 5200,
      heat: 3250,
      replies: 488,
      tags: ['鲤竿', '旗舰', '高端', '竞技'],
      gallery: [
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
      ],
      desc: '宝飞龙极光台钓竿，旗舰级鲤竿，全碳纤维设计，腰力极强，竞技首选。',
    ),
    _EquipItem(
      name: '龙王恨 LOONVA 蓝白传奇',
      spec: 'LB-3604',
      type: '台钓竿',
      waterType: '淡水',
      score: 2900,
      heat: 1650,
      replies: 248,
      tags: ['鲤竿', '性价比', '腰力好', '入门'],
      gallery: [
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
      ],
      desc: '龙王恨蓝白传奇台钓竿，入门鲤竿首选，腰力好，性价比高，适合休闲鲤草。',
    ),
    _EquipItem(
      name: '钓鱼王 韧者',
      spec: 'RENZHE-3604',
      type: '台钓竿',
      waterType: '淡水',
      score: 2700,
      heat: 1500,
      replies: 225,
      tags: ['鲤竿', '性价比', '腰力好', '综合'],
      gallery: [
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
      ],
      desc: '钓鱼王韧者台钓竿，经典国货，腰力好，性价比高，综合鲤草表现均衡。',
    ),
    _EquipItem(
      name: '科尼 宙斯',
      spec: 'ZEUS-2402',
      type: '路亚竿',
      waterType: '淡水',
      score: 5800,
      heat: 3600,
      replies: 540,
      tags: ['旗舰', '高端', '感度好', '国礼'],
      gallery: [
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
      ],
      desc: '科尼宙斯路亚竿，国礼级高端路亚竿，2014亚信峰会国礼赠外国元首，感度卓越，收藏价值高。',
    ),
    _EquipItem(
      name: '科尼 海神',
      spec: 'POSEIDON-2702',
      type: '路亚竿',
      waterType: '淡水',
      score: 5400,
      heat: 3350,
      replies: 503,
      tags: ['旗舰', '高端', '感度好', '大物'],
      gallery: [
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
      ],
      desc: '科尼海神路亚竿，国礼级高端路亚竿，高感度设计，主攻大物，综合性能卓越。',
    ),
    _EquipItem(
      name: '小凤仙 轻舞',
      spec: 'QINGWU-2102',
      type: '路亚竿',
      waterType: '淡水',
      score: 2100,
      heat: 1100,
      replies: 165,
      tags: ['入门', '轻量', '女性', '感度好'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
      ],
      desc: '小凤仙轻舞路亚竿，专为女性钓友设计，超轻量，感度好，涂装精美。',
    ),
    _EquipItem(
      name: '本汀 神鲤',
      spec: 'SHENLI-3604',
      type: '台钓竿',
      waterType: '淡水',
      score: 3300,
      heat: 1950,
      replies: 293,
      tags: ['鲤竿', '性价比', '腰力好', '硬调'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: '本汀神鲤台钓竿，广州台钓专家，硬调腰力好，适合鲤草综合，性价比高。',
    ),
  ];

  List<String> get _types => const ['海水', '淡水'];

  List<_EquipItem> get _filtered {
    final list = _selectedType == null
        ? _rods
        : _rods.where((e) => e.waterType == _selectedType).toList();
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final types = _types;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _HeroBanner(
          emoji: '🎣',
          title: '鱼竿榜',
          subtitle: '鲤综合 · 鲈鱼 · 鳜鱼 · 海钓 · 巨物',
          accent: Color(0xFF0277BD),
        ),
        const SizedBox(height: 12),
        // 类型筛选栏
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: '全部',
                selected: _selectedType == null,
                onTap: () => setState(() => _selectedType = null),
              ),
              for (var t in types) ...[
                const SizedBox(width: 6),
                _FilterChip(
                  label: t,
                  selected: _selectedType == t,
                  onTap: () => setState(() => _selectedType = t),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < items.length; i++)
          _EquipCard(item: items[i], rank: i + 1, delay: i * 35),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 6: 鱼轮榜
// ═══════════════════════════════════════════════════════
class _ReelTab extends StatefulWidget {
  const _ReelTab();
  @override
  State<_ReelTab> createState() => _ReelTabState();
}

class _ReelTabState extends State<_ReelTab> {
  String? _selectedType;

  static final _reels = [
    _EquipItem(
      name: '禧玛诺 STELLA SW',
      spec: '5000XG',
      type: '纺车轮',
      waterType: '海水',
      score: 10200,
      heat: 4284,
      replies: 510,
      tags: ['旗舰', '海水', '顺滑', '远投'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: '禧玛诺海水旗舰纺车，HAGANE 齿轮与防水结构，主攻海鲈青物大物。',
      imageUrl: 'assets/images/equip/reel_01.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 SALTIGA',
      spec: '10L',
      type: '纺车轮',
      waterType: '海水',
      score: 10120,
      heat: 4250,
      replies: 506,
      tags: ['旗舰', '海水', '耐用', '巨物'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: '达亿瓦海水 spinning 标杆，ATD 刹车与 MQ 一体机身，船钓岸投通吃。',
      imageUrl: 'assets/images/equip/reel_02.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 CATALINA',
      spec: '8000H',
      type: '纺车轮',
      waterType: '海水',
      score: 10040,
      heat: 4217,
      replies: 502,
      tags: ['海水', '泛用', '耐磨'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: 'SALTIGA 同门海水泛用轮，性价比更高的远投岸钓选择。',
      imageUrl: 'assets/images/spots/wm_03.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 TWIN POWER SW',
      spec: '6000XG',
      type: '纺车轮',
      waterType: '海水',
      score: 9960,
      heat: 4183,
      replies: 498,
      tags: ['海水', '轻量', '泛用'],
      gallery: [
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_15.jpg',
      ],
      desc: 'SW 海水版 Twin Power，X-PROTECT 防水，海淡水两用。',
      imageUrl: 'assets/images/equip/reel_04.png',
    ),
    _EquipItem(
      name: '禧玛诺 SARAGOSA SW',
      spec: '8000PG',
      type: '纺车轮',
      waterType: '海水',
      score: 9880,
      heat: 4150,
      replies: 494,
      tags: ['海水', '耐用', '性价比'],
      gallery: [
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_16.jpg',
      ],
      desc: '入门级海水纺车，皮实耐造，根鱼与远投都稳。',
      imageUrl: 'assets/images/spots/wm_05.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 CERTATE HD',
      spec: 'LT5000-XH',
      type: '纺车轮',
      waterType: '海水',
      score: 9800,
      heat: 4116,
      replies: 490,
      tags: ['海水', '耐磨', '泛用'],
      gallery: [
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
      ],
      desc: 'HD 重金属版本，MONOCOQUE 机身，海水淡水均强。',
      imageUrl: 'assets/images/equip/reel_06.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 FREAMS SW',
      spec: 'LT4000-CXH',
      type: '纺车轮',
      waterType: '海水',
      score: 9720,
      heat: 4082,
      replies: 486,
      tags: ['海水', '轻量', '泛用'],
      gallery: [
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
      ],
      desc: 'LT 轻量海水轮，长时间作钓不累手。',
      imageUrl: 'assets/images/equip/reel_07.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 SPHEROS SW',
      spec: '8000PG',
      type: '纺车轮',
      waterType: '海水',
      score: 9640,
      heat: 4049,
      replies: 482,
      tags: ['海水', '耐用', '入门'],
      gallery: [
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
      ],
      desc: '平民海水纺车，结构扎实，新手海钓首选。',
      imageUrl: 'assets/images/equip/reel_08.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 BG',
      spec: 'SW6000',
      type: '纺车轮',
      waterType: '海水',
      score: 9560,
      heat: 4015,
      replies: 478,
      tags: ['海水', '耐用', '性价比'],
      gallery: [
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
      ],
      desc: '达亿瓦经典平民海水轮，皮实耐造口碑款。',
      imageUrl: 'assets/images/equip/reel_09.png',
    ),
    _EquipItem(
      name: '禧玛诺 OCEA',
      spec: 'JIGGER FT',
      type: '鼓轮',
      waterType: '海水',
      score: 9480,
      heat: 3982,
      replies: 474,
      tags: ['海水', '铁板', '船钓'],
      gallery: [
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
      ],
      desc: 'OCEA 系列铁板/船钓鼓轮，深海慢摇专用。',
      imageUrl: 'assets/images/equip/reel_10.png',
    ),
    _EquipItem(
      name: '达亿瓦 SEAPOWER',
      spec: '电动绞',
      type: '鼓轮',
      waterType: '海水',
      score: 9400,
      heat: 3948,
      replies: 470,
      tags: ['海水', '电动', '船钓'],
      gallery: [
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_06.jpg',
      ],
      desc: '电动绞盘轮，深海船钓省力利器。',
      imageUrl: 'assets/images/equip/reel_11.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 TALICA',
      spec: '16',
      type: '鼓轮',
      waterType: '海水',
      score: 9320,
      heat: 3914,
      replies: 466,
      tags: ['海水', '杠杆刹车', '巨物'],
      gallery: [
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_07.jpg',
      ],
      desc: '杠杆刹车鼓轮，应对鲨鱼金枪等巨物。',
      imageUrl: 'assets/images/equip/reel_12.png',
    ),
    _EquipItem(
      name: '禧玛诺 FORCEMASTER',
      spec: '3000',
      type: '电绞',
      waterType: '海水',
      score: 9240,
      heat: 3881,
      replies: 462,
      tags: ['海水', '电动', '深海'],
      gallery: [
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_08.jpg',
      ],
      desc: 'FORCEMASTER 电绞，深海钓大物效率拉满。',
      imageUrl: 'assets/images/spots/wm_13.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 EXSENCE',
      spec: 'C3000MHG',
      type: '纺车轮',
      waterType: '海水',
      score: 9160,
      heat: 3847,
      replies: 458,
      tags: ['海水', '海鲈', '感度'],
      gallery: [
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_09.jpg',
      ],
      desc: '专为海鲈青物设计的海水 spinning，抛投精准。',
      imageUrl: 'assets/images/equip/reel_14.png',
    ),
    _EquipItem(
      name: '达亿瓦 EMERALDAS',
      spec: '鱿鱼轮',
      type: '纺车轮',
      waterType: '海水',
      score: 9080,
      heat: 3814,
      replies: 454,
      tags: ['海水', '鱿鱼', '轻量'],
      gallery: [
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_10.jpg',
      ],
      desc: 'Egix 鱿鱼专用轮，轻量高感度。',
      imageUrl: 'assets/images/equip/reel_15.png',
    ),
    _EquipItem(
      name: '佩恩 SPINFISHER',
      spec: '6500',
      type: '纺车轮',
      waterType: '海水',
      score: 9000,
      heat: 3780,
      replies: 450,
      tags: ['海水', '耐用', '巨物'],
      gallery: [
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_11.jpg',
      ],
      desc: 'Penn 经典海水轮，抗造耐海水腐蚀。',
      imageUrl: 'assets/images/spots/wm_16.jpg',
    ),
    _EquipItem(
      name: '阿布加西亚 REVO',
      spec: '海水版',
      type: '水滴轮',
      waterType: '海水',
      score: 8920,
      heat: 3746,
      replies: 446,
      tags: ['海水', '水滴', '耐用'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: 'Abu Revo 海水水滴，海鲈雷强可用。',
      imageUrl: 'assets/images/spots/wm_01.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 TRANX',
      spec: '300',
      type: '水滴轮',
      waterType: '海水',
      score: 8840,
      heat: 3713,
      replies: 442,
      tags: ['海水', '水滴', '巨物'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: 'TRANX 海水水滴/鼓轮，暴力作钓首选。',
      imageUrl: 'assets/images/spots/wm_02.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 TAGGED',
      spec: '海水纺车',
      type: '纺车轮',
      waterType: '海水',
      score: 8760,
      heat: 3679,
      replies: 438,
      tags: ['海水', '耐用', '泛用'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: 'TAGGED 海水系列，岸投根鱼专用。',
      imageUrl: 'assets/images/spots/wm_03.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 BAITMATIC',
      spec: '电动',
      type: '电绞',
      waterType: '海水',
      score: 8680,
      heat: 3646,
      replies: 434,
      tags: ['海水', '电动', '船钓'],
      gallery: [
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_15.jpg',
      ],
      desc: 'BAITMATIC 电绞，海底钓大物稳定输出。',
      imageUrl: 'assets/images/spots/wm_04.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 EXIST',
      spec: 'SF2500SS',
      type: '纺车轮',
      waterType: '淡水',
      score: 8600,
      heat: 3612,
      replies: 430,
      tags: ['旗舰', '淡水', '感度', '轻量'],
      gallery: [
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_16.jpg',
      ],
      desc: '达亿瓦淡水 spinning 旗舰，极致轻量与顺滑。',
      imageUrl: 'assets/images/equip/reel_21.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 STELLA',
      spec: '2500S',
      type: '纺车轮',
      waterType: '淡水',
      score: 8520,
      heat: 3578,
      replies: 426,
      tags: ['旗舰', '淡水', '顺滑'],
      gallery: [
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
      ],
      desc: 'STELLA 淡水版，微物泛用天花板。',
      imageUrl: 'assets/images/equip/reel_22.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 VANFORD',
      spec: 'C2000S',
      type: '纺车轮',
      waterType: '淡水',
      score: 8440,
      heat: 3545,
      replies: 422,
      tags: ['轻量', 'CI4+', '性价比'],
      gallery: [
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
      ],
      desc: 'CI4+ 碳纤机身，超轻路亚泛用轮。',
      imageUrl: 'assets/images/equip/reel_23.png',
    ),
    _EquipItem(
      name: '禧玛诺 NASCI',
      spec: '2500',
      type: '纺车轮',
      waterType: '淡水',
      score: 8360,
      heat: 3511,
      replies: 418,
      tags: ['入门', '耐用', '泛用'],
      gallery: [
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
      ],
      desc: '入门泛用纺车，皮实耐造口碑款。',
      imageUrl: 'assets/images/equip/reel_24.png',
    ),
    _EquipItem(
      name: '达亿瓦 CALDIA',
      spec: 'FC LT2000S',
      type: '纺车轮',
      waterType: '淡水',
      score: 8280,
      heat: 3478,
      replies: 414,
      tags: ['入门', '耐用', '性价比'],
      gallery: [
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
      ],
      desc: 'CALDIA LT 轻量入门，新手友好。',
      imageUrl: 'assets/images/equip/reel_25.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 MIRAVEL',
      spec: '1000',
      type: '纺车轮',
      waterType: '淡水',
      score: 8200,
      heat: 3444,
      replies: 410,
      tags: ['轻量', '泛用', '性价比'],
      gallery: [
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
      ],
      desc: '2026 新款泛用纺车，手感与性价比兼具。',
      imageUrl: 'assets/images/equip/reel_26.png',
    ),
    _EquipItem(
      name: '禧玛诺 ULTEGRA',
      spec: 'C2000S',
      type: '纺车轮',
      waterType: '淡水',
      score: 8120,
      heat: 3410,
      replies: 406,
      tags: ['泛用', '轻量', '进阶'],
      gallery: [
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_06.jpg',
      ],
      desc: '进阶泛用纺车，X-SHIP 传动顺滑。',
      imageUrl: 'assets/images/equip/reel_27.png',
    ),
    _EquipItem(
      name: '禧玛诺 COMPLEX XR',
      spec: 'C2500',
      type: '纺车轮',
      waterType: '淡水',
      score: 8040,
      heat: 3377,
      replies: 402,
      tags: ['轻量', '远投', '进阶'],
      gallery: [
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_07.jpg',
      ],
      desc: 'COMPLEX XR 远投泛用，出线顺畅。',
      imageUrl: 'assets/images/equip/reel_28.png',
    ),
    _EquipItem(
      name: '禧玛诺 NEXAVE',
      spec: '2000',
      type: '纺车轮',
      waterType: '淡水',
      score: 7960,
      heat: 3343,
      replies: 398,
      tags: ['入门', '耐用', '性价比'],
      gallery: [
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_08.jpg',
      ],
      desc: 'NEXAVE 入门纺车，日常泛用稳。',
      imageUrl: 'assets/images/spots/wm_13.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 SIENNA',
      spec: '1000',
      type: '纺车轮',
      waterType: '淡水',
      score: 7880,
      heat: 3310,
      replies: 394,
      tags: ['入门', '轻量', '实惠'],
      gallery: [
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_09.jpg',
      ],
      desc: 'SIENNA 入门轻量，休闲野钓够用。',
      imageUrl: 'assets/images/spots/wm_14.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 ALIVIO',
      spec: '2500',
      type: '纺车轮',
      waterType: '淡水',
      score: 7800,
      heat: 3276,
      replies: 390,
      tags: ['入门', '耐用', '泛用'],
      gallery: [
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_10.jpg',
      ],
      desc: 'ALIVIO 皮实泛用，野钓老伙计。',
      imageUrl: 'assets/images/spots/wm_15.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 REGAL',
      spec: '1000',
      type: '纺车轮',
      waterType: '淡水',
      score: 7720,
      heat: 3242,
      replies: 386,
      tags: ['轻量', '泛用', '入门'],
      gallery: [
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_11.jpg',
      ],
      desc: 'REGAL LT 轻量入门，手感顺。',
      imageUrl: 'assets/images/spots/wm_16.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 FUEGO',
      spec: '1000',
      type: '纺车轮',
      waterType: '淡水',
      score: 7640,
      heat: 3209,
      replies: 382,
      tags: ['轻量', '性价比', '泛用'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: 'FUEGO LT 性价比泛用，日常利器。',
      imageUrl: 'assets/images/spots/wm_01.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 LEGALIS',
      spec: 'LT2000',
      type: '纺车轮',
      waterType: '淡水',
      score: 7560,
      heat: 3175,
      replies: 378,
      tags: ['轻量', '入门', '泛用'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: 'LEGALIS LT 轻量入门纺车。',
      imageUrl: 'assets/images/spots/wm_02.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 CROSSFIRE',
      spec: '2000',
      type: '纺车轮',
      waterType: '淡水',
      score: 7480,
      heat: 3142,
      replies: 374,
      tags: ['入门', '耐用', '实惠'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: 'CROSSFIRE 入门泛用，价格友好。',
      imageUrl: 'assets/images/spots/wm_03.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 STEEZ SV TW',
      spec: 'LIGHT TW 100H',
      type: '水滴轮',
      waterType: '淡水',
      score: 7400,
      heat: 3108,
      replies: 370,
      tags: ['旗舰', '轻量', '微物', '竞技'],
      gallery: [
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_15.jpg',
      ],
      desc: 'STEEZ SV TW 淡水水滴旗舰，微物竞技利器。',
      imageUrl: 'assets/images/equip/reel_36.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 ZILLION TW',
      spec: '150',
      type: '水滴轮',
      waterType: '淡水',
      score: 7320,
      heat: 3074,
      replies: 366,
      tags: ['巨物', '高转速', '大力矩'],
      gallery: [
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_16.jpg',
      ],
      desc: 'ZILLION TW 高转速水滴，雷强巨物首选。',
      imageUrl: 'assets/images/equip/reel_37.png',
    ),
    _EquipItem(
      name: '达亿瓦 TATULA TW',
      spec: '200H',
      type: '水滴轮',
      waterType: '淡水',
      score: 7240,
      heat: 3041,
      replies: 362,
      tags: ['泛用', '刹车稳', '入门首选'],
      gallery: [
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
      ],
      desc: 'TATULA TW 泛用水滴，刹车稳定好上手。',
      imageUrl: 'assets/images/equip/reel_38.png',
    ),
    _EquipItem(
      name: '禧玛诺 METANIUM',
      spec: 'DC 71XG',
      type: '水滴轮',
      waterType: '淡水',
      score: 7160,
      heat: 3007,
      replies: 358,
      tags: ['DC', '稳定', '泛用'],
      gallery: [
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
      ],
      desc: 'METANIUM DC 电子刹车，抛投稳定防炸线。',
      imageUrl: 'assets/images/equip/reel_39.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 ANTARES',
      spec: '100HG',
      type: '水滴轮',
      waterType: '淡水',
      score: 7080,
      heat: 2974,
      replies: 354,
      tags: ['旗舰', '轻量', '精准'],
      gallery: [
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
      ],
      desc: 'ANTARES 淡水水滴旗舰，抛投精准。',
      imageUrl: 'assets/images/equip/reel_40.png',
    ),
    _EquipItem(
      name: '禧玛诺 SCORPION',
      spec: 'DC 200XG',
      type: '水滴轮',
      waterType: '淡水',
      score: 7000,
      heat: 2940,
      replies: 350,
      tags: ['DC', '泛用', '稳定'],
      gallery: [
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
      ],
      desc: 'SCORPION DC 电子刹车泛用水滴。',
      imageUrl: 'assets/images/equip/reel_41.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 SLX',
      spec: 'BFS XG',
      type: '水滴轮',
      waterType: '淡水',
      score: 6920,
      heat: 2906,
      replies: 346,
      tags: ['微物', '轻量', '性价比'],
      gallery: [
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
      ],
      desc: 'SLX BFS 微物水滴，轻饵远投利器。',
      imageUrl: 'assets/images/equip/reel_42.png',
    ),
    _EquipItem(
      name: '禧玛诺 CALCUTTA',
      spec: 'CONQUEST BFS',
      type: '水滴轮',
      waterType: '淡水',
      score: 6840,
      heat: 2873,
      replies: 342,
      tags: ['旗舰', '轻量', '收藏'],
      gallery: [
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_06.jpg',
      ],
      desc: 'CALCUTTA CONQUEST BFS，水滴收藏级。',
      imageUrl: 'assets/images/equip/reel_43.jpg',
    ),
    _EquipItem(
      name: '阿布加西亚 MAX',
      spec: '水滴',
      type: '水滴轮',
      waterType: '淡水',
      score: 6760,
      heat: 2839,
      replies: 338,
      tags: ['入门', '耐用', '性价比'],
      gallery: [
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_07.jpg',
      ],
      desc: 'Abu Max 入门水滴，雷强练手友好。',
      imageUrl: 'assets/images/spots/wm_12.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 SS AIR',
      spec: '水滴',
      type: '水滴轮',
      waterType: '淡水',
      score: 6680,
      heat: 2806,
      replies: 334,
      tags: ['轻量', '竞技', '感度'],
      gallery: [
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_08.jpg',
      ],
      desc: 'SS AIR 轻量竞技水滴，手感细腻。',
      imageUrl: 'assets/images/spots/wm_13.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 CURADO',
      spec: 'DC 150',
      type: '水滴轮',
      waterType: '淡水',
      score: 6600,
      heat: 2772,
      replies: 330,
      tags: ['DC', '泛用', '耐用'],
      gallery: [
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_09.jpg',
      ],
      desc: 'CURADO DC 泛用水滴，皮实稳定。',
      imageUrl: 'assets/images/spots/wm_14.jpg',
    ),
    _EquipItem(
      name: '达亿瓦 TATULA SV TW',
      spec: 'SV 100',
      type: '水滴轮',
      waterType: '淡水',
      score: 6520,
      heat: 2738,
      replies: 326,
      tags: ['SV', '微物', '泛用'],
      gallery: [
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_10.jpg',
      ],
      desc: 'TATULA SV TW 微物泛用水滴。',
      imageUrl: 'assets/images/equip/reel_47.png',
    ),
    _EquipItem(
      name: '达亿瓦 FUEGO CT',
      spec: '水滴',
      type: '水滴轮',
      waterType: '淡水',
      score: 6440,
      heat: 2705,
      replies: 322,
      tags: ['入门', '性价比', '泛用'],
      gallery: [
        'assets/images/spots/wm_16.jpg',
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_11.jpg',
      ],
      desc: 'FUEGO CT 入门水滴，性价比高。',
      imageUrl: 'assets/images/spots/wm_16.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 EXSENCE',
      spec: 'C3000',
      type: '纺车轮',
      waterType: '通用',
      score: 6360,
      heat: 2671,
      replies: 318,
      tags: ['海淡两用', '感度', '泛用'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: 'EXSENCE 海淡两用 spinning，一伦走天下。',
      imageUrl: 'assets/images/equip/reel_49.png',
    ),
    _EquipItem(
      name: '达亿瓦 CALCUTTA',
      spec: 'CONQUEST',
      type: '水滴轮',
      waterType: '通用',
      score: 6280,
      heat: 2638,
      replies: 314,
      tags: ['收藏', '泛用', '耐用'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: 'CALCUTTA CONQUEST 泛用收藏水滴。',
      imageUrl: 'assets/images/equip/reel_50.jpg',
    ),
    _EquipItem(
      name: '禧玛诺 COMPLEX',
      spec: 'XTR',
      type: '纺车轮',
      waterType: '通用',
      score: 6200,
      heat: 2604,
      replies: 310,
      tags: ['泛用', '轻量', '远投'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: 'COMPLEX 泛用远投纺车。',
      imageUrl: 'assets/images/equip/reel_51.png',
    ),
    _EquipItem(
      name: '光威 速鬼',
      spec: 'SG-1000',
      type: '水滴轮',
      waterType: '淡水',
      score: 3200,
      heat: 1450,
      replies: 203,
      tags: ['入门', '顺滑', '轻量', '性价比'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: '光威水滴轮入门级，顺滑启动，适合台钓综合，支持微物抛投。',
    ),
    _EquipItem(
      name: '光威 巨兽',
      spec: 'JS-2000',
      type: '水滴轮',
      waterType: '淡水',
      score: 2850,
      heat: 1200,
      replies: 180,
      tags: ['旗舰', '大物', '刹车精准', '耐造'],
      gallery: [
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_15.jpg',
      ],
      desc: '光威旗舰水滴轮，磁刹+离心双模式，主攻黑坑大物，综合性能强。',
    ),
    _EquipItem(
      name: '海伯 风暴',
      spec: 'STORM 2.0',
      type: '水滴轮',
      waterType: '淡水',
      score: 3100,
      heat: 1380,
      replies: 198,
      tags: ['轻量', '刹车稳', '入门', '性价比'],
      gallery: [
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_01.jpg',
      ],
      desc: '海伯风暴二代水滴轮，轻量化机身，刹车稳定，新手首选。',
    ),
    _EquipItem(
      name: '海伯 战神',
      spec: 'WARRIOR X',
      type: '水滴轮',
      waterType: '淡水',
      score: 3400,
      heat: 1600,
      replies: 220,
      tags: ['旗舰', '刹车精准', '大物', '竞技'],
      gallery: [
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_02.jpg',
      ],
      desc: '海伯战神X水滴轮，磁力刹车系统，精准控制，主攻竞技黑坑。',
    ),
    _EquipItem(
      name: 'KASTKING 卡斯丁 捕王',
      spec: 'CAPP-200',
      type: '水滴轮',
      waterType: '淡水',
      score: 2950,
      heat: 1320,
      replies: 190,
      tags: ['性价比', '远投', '刹车稳', '入门'],
      gallery: [
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_03.jpg',
      ],
      desc: 'KASTKING卡斯丁捕王水滴轮，美国品牌中国产，高性价比，远投性能优秀。',
    ),
    _EquipItem(
      name: 'KASTKING 卡斯丁 隐战',
      spec: 'SPECTRE-X',
      type: '水滴轮',
      waterType: '淡水',
      score: 3300,
      heat: 1550,
      replies: 210,
      tags: ['轻量', '旗舰', '刹车精准', '竞技'],
      gallery: [
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_04.jpg',
      ],
      desc: 'KASTKING隐战旗舰水滴轮，镁合金机身，轻量化设计，竞技首选。',
    ),
    _EquipItem(
      name: '汉鼎 逆鳞',
      spec: 'NL-1500',
      type: '水滴轮',
      waterType: '淡水',
      score: 2700,
      heat: 1100,
      replies: 165,
      tags: ['入门', '性价比', '轻量', '台钓'],
      gallery: [
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_05.jpg',
      ],
      desc: '汉鼎逆鳞水滴轮，国产性价比之王，顺滑度好，适合台钓综合。',
    ),
    _EquipItem(
      name: '汉鼎 玄武',
      spec: 'XW-2000',
      type: '水滴轮',
      waterType: '淡水',
      score: 3100,
      heat: 1400,
      replies: 195,
      tags: ['旗舰', '刹车精准', '大物', '竞技'],
      gallery: [
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_06.jpg',
      ],
      desc: '汉鼎玄武旗舰水滴轮，双刹车系统，精准控饵，主攻黑坑大物。',
    ),
    _EquipItem(
      name: '迪佳 TICA 战狼',
      spec: 'WARWOLF',
      type: '水滴轮',
      waterType: '淡水',
      score: 3050,
      heat: 1350,
      replies: 188,
      tags: ['耐用', '刹车稳', '大物', '性价比'],
      gallery: [
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_07.jpg',
      ],
      desc: 'TICA迪佳战狼水滴轮，台湾老牌，耐用性强，刹车稳定，黑坑通用。',
    ),
    _EquipItem(
      name: '迪佳 TICA 烈焰',
      spec: 'INFERNO',
      type: '水滴轮',
      waterType: '淡水',
      score: 3250,
      heat: 1500,
      replies: 205,
      tags: ['旗舰', '刹车精准', '轻量', '竞技'],
      gallery: [
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_08.jpg',
      ],
      desc: 'TICA迪佳烈焰旗舰水滴轮，轻量紧凑，刹车精准，竞技速攻首选。',
    ),
    _EquipItem(
      name: '光威 鳞影',
      spec: 'LY-3000',
      type: '纺车轮',
      waterType: '淡水',
      score: 2400,
      heat: 980,
      replies: 140,
      tags: ['入门', '轻量', '顺滑', '性价比'],
      gallery: [
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_09.jpg',
      ],
      desc: '光威鳞影纺车轮，轻量铝合金机身，适合台钓综合，性价比突出。',
    ),
    _EquipItem(
      name: '光威 鲨齿',
      spec: 'SHARK-4000',
      type: '纺车轮',
      waterType: '通用',
      score: 2800,
      heat: 1200,
      replies: 172,
      tags: ['旗舰', '大物', '刹车稳', '耐用'],
      gallery: [
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_10.jpg',
      ],
      desc: '光威鲨齿旗舰纺车轮，不锈钢齿轮，主攻大物，综合性能强。',
    ),
    _EquipItem(
      name: '光威 潜龙',
      spec: 'QL-5000',
      type: '纺车轮',
      waterType: '海水',
      score: 2650,
      heat: 1100,
      replies: 158,
      tags: ['远投', '海水', '大物', '耐用'],
      gallery: [
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_11.jpg',
      ],
      desc: '光威潜龙海水纺车轮，防水结构，远投性能好，海钓岸投通吃。',
    ),
    _EquipItem(
      name: '海伯 猎手',
      spec: 'HUNTER-3000',
      type: '纺车轮',
      waterType: '淡水',
      score: 2550,
      heat: 1050,
      replies: 150,
      tags: ['性价比', '顺滑', '入门', '台钓'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: '海伯猎手纺车轮，顺滑度好，性价比高，新手入门首选。',
    ),
    _EquipItem(
      name: '海伯 巨鳞',
      spec: 'GIANT-5000',
      type: '纺车轮',
      waterType: '淡水',
      score: 2950,
      heat: 1300,
      replies: 185,
      tags: ['旗舰', '大物', '刹车稳', '耐用'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: '海伯巨鳞旗舰纺车轮，不锈钢主齿，适合大物，综合性能出色。',
    ),
    _EquipItem(
      name: '海伯 掠食者',
      spec: 'PREDATOR-X',
      type: '纺车轮',
      waterType: '海水',
      score: 2850,
      heat: 1250,
      replies: 178,
      tags: ['海水', '远投', '刹车稳', '船钓'],
      gallery: [
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_14.jpg',
      ],
      desc: '海伯掠食者海水纺车轮，强劲刹车，远投性能好，船钓岸投两用。',
    ),
    _EquipItem(
      name: 'KASTKING 卡斯丁 远航',
      spec: 'ENDURO-4000',
      type: '纺车轮',
      waterType: '淡水',
      score: 2700,
      heat: 1150,
      replies: 162,
      tags: ['远投', '性价比', '刹车稳', '入门'],
      gallery: [
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_15.jpg',
      ],
      desc: 'KASTKING卡斯丁远航纺车轮，远投性能优秀，性价比极高，新手首选。',
    ),
    _EquipItem(
      name: 'KASTKING 卡斯丁 海王',
      spec: 'NEPTUNE-6000',
      type: '纺车轮',
      waterType: '海水',
      score: 3100,
      heat: 1420,
      replies: 198,
      tags: ['海水', '旗舰', '大物', '耐用'],
      gallery: [
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_01.jpg',
      ],
      desc: 'KASTKING海王海水纺车轮，强劲刹车与防水结构，主攻海水大物。',
    ),
    _EquipItem(
      name: '汉鼎 玄铁',
      spec: 'XT-3500',
      type: '纺车轮',
      waterType: '淡水',
      score: 2450,
      heat: 1000,
      replies: 145,
      tags: ['入门', '性价比', '轻量', '台钓'],
      gallery: [
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_02.jpg',
      ],
      desc: '汉鼎玄铁纺车轮，轻量紧凑，顺滑度好，入门性价比首选。',
    ),
    _EquipItem(
      name: '汉鼎 盘龙',
      spec: 'PL-4500',
      type: '纺车轮',
      waterType: '淡水',
      score: 2800,
      heat: 1180,
      replies: 168,
      tags: ['旗舰', '大物', '刹车稳', '竞技'],
      gallery: [
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_03.jpg',
      ],
      desc: '汉鼎盘龙旗舰纺车轮，刹车强劲，适合黑坑大物，综合性能强。',
    ),
    _EquipItem(
      name: '汉鼎 海狼',
      spec: 'SEAWOLF-5000',
      type: '纺车轮',
      waterType: '海水',
      score: 2700,
      heat: 1120,
      replies: 160,
      tags: ['海水', '大物', '远投', '耐用'],
      gallery: [
        'assets/images/spots/wm_08.jpg',
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_04.jpg',
      ],
      desc: '汉鼎海狼海水纺车轮，防水防腐结构，远投性能好，海钓通用。',
    ),
    _EquipItem(
      name: '迪佳 TICA 铁甲',
      spec: 'IRON-4000',
      type: '纺车轮',
      waterType: '淡水',
      score: 2600,
      heat: 1080,
      replies: 152,
      tags: ['耐用', '刹车稳', '性价比', '入门'],
      gallery: [
        'assets/images/spots/wm_09.jpg',
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_05.jpg',
      ],
      desc: 'TICA迪佳铁甲纺车轮，台湾工艺，耐用性强，刹车稳定，入门首选。',
    ),
    _EquipItem(
      name: '迪佳 TICA 海皇',
      spec: 'SEAKING-6000',
      type: '纺车轮',
      waterType: '海水',
      score: 2950,
      heat: 1320,
      replies: 186,
      tags: ['海水', '旗舰', '大物', '远投'],
      gallery: [
        'assets/images/spots/wm_10.jpg',
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_06.jpg',
      ],
      desc: 'TICA迪佳海皇旗舰海水纺车轮，强刹车系统，远投性能好，主攻海水大物。',
    ),
    _EquipItem(
      name: '宝熊 Okuma 银狼',
      spec: 'SILVER-WOLF',
      type: '纺车轮',
      waterType: '淡水',
      score: 2500,
      heat: 1020,
      replies: 148,
      tags: ['性价比', '顺滑', '入门', '台钓'],
      gallery: [
        'assets/images/spots/wm_11.jpg',
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_07.jpg',
      ],
      desc: '宝熊Okuma银狼纺车轮，台湾品牌，品质可靠，顺滑度好，入门性价比高。',
    ),
    _EquipItem(
      name: '宝熊 Okuma 银鳞',
      spec: 'SILVER-SCALE',
      type: '纺车轮',
      waterType: '淡水',
      score: 2750,
      heat: 1150,
      replies: 165,
      tags: ['旗舰', '刹车稳', '大物', '竞技'],
      gallery: [
        'assets/images/spots/wm_12.jpg',
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_08.jpg',
      ],
      desc: '宝熊Okuma银鳞旗舰纺车轮，刹车精准，综合性能强，黑坑竞技首选。',
    ),
    _EquipItem(
      name: '佳钓尼 JIADIAONI 伏魔',
      spec: 'FUMO-3000',
      type: '纺车轮',
      waterType: '淡水',
      score: 2350,
      heat: 950,
      replies: 135,
      tags: ['入门', '性价比', '轻量', '台钓'],
      gallery: [
        'assets/images/spots/wm_13.jpg',
        'assets/images/spots/wm_03.jpg',
        'assets/images/spots/wm_09.jpg',
      ],
      desc: '佳钓尼伏魔纺车轮，国产新锐品牌，性价比之王，新手入门首选。',
    ),
    _EquipItem(
      name: '佳钓尼 JIADIAONI 无二',
      spec: 'WUER-4000',
      type: '纺车轮',
      waterType: '淡水',
      score: 2650,
      heat: 1100,
      replies: 158,
      tags: ['旗舰', '刹车稳', '大物', '竞技'],
      gallery: [
        'assets/images/spots/wm_14.jpg',
        'assets/images/spots/wm_04.jpg',
        'assets/images/spots/wm_10.jpg',
      ],
      desc: '佳钓尼无二旗舰纺车轮，刹车精准，强度高，黑坑竞技首选。',
    ),
    _EquipItem(
      name: '钓鱼王 狂鳞',
      spec: 'KUANGLIN-5000',
      type: '纺车轮',
      waterType: '淡水',
      score: 2700,
      heat: 1130,
      replies: 162,
      tags: ['性价比', '大物', '刹车稳', '耐用'],
      gallery: [
        'assets/images/spots/wm_15.jpg',
        'assets/images/spots/wm_05.jpg',
        'assets/images/spots/wm_11.jpg',
      ],
      desc: '钓鱼王狂鳞纺车轮，经典国货品牌，耐用性强，综合性能均衡。',
    ),
    _EquipItem(
      name: '伊酷达 ECOODA 铁血',
      spec: 'TIEXUE-4000',
      type: '纺车轮',
      waterType: '淡水',
      score: 2550,
      heat: 1050,
      replies: 150,
      tags: ['性价比', '刹车稳', '入门', '竞技'],
      gallery: [
        'assets/images/spots/wm_01.jpg',
        'assets/images/spots/wm_06.jpg',
        'assets/images/spots/wm_12.jpg',
      ],
      desc: '伊酷达ECOODA铁血纺车轮，专业竞技品牌，刹车稳定，性价比极高。',
    ),
    _EquipItem(
      name: '渔卫士 天网',
      spec: 'TIANWANG-5000',
      type: '纺车轮',
      waterType: '淡水',
      score: 2800,
      heat: 1200,
      replies: 172,
      tags: ['旗舰', '大物', '刹车稳', '竞技'],
      gallery: [
        'assets/images/spots/wm_02.jpg',
        'assets/images/spots/wm_07.jpg',
        'assets/images/spots/wm_13.jpg',
      ],
      desc: '渔卫士天网旗舰纺车轮，刹车精准，强度高，主攻黑坑大物，综合性能出色。',
    ),
  ];

  List<String> get _types => const ['海水', '淡水'];

  List<_EquipItem> get _filtered {
    final list = _selectedType == null
        ? _reels
        : _reels.where((e) => e.waterType == _selectedType).toList();
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final types = _types;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _HeroBanner(
          emoji: '🔄',
          title: '鱼轮榜',
          subtitle: '水滴轮 · 纺车轮口碑排行',
          accent: Color(0xFF6A1B9A),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: '全部',
                selected: _selectedType == null,
                onTap: () => setState(() => _selectedType = null),
              ),
              for (var t in types) ...[
                const SizedBox(width: 6),
                _FilterChip(
                  label: t,
                  selected: _selectedType == t,
                  onTap: () => setState(() => _selectedType = t),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < items.length; i++)
          _EquipCard(item: items[i], rank: i + 1, delay: i * 35),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 7: 饵料榜
// ═══════════════════════════════════════════════════════
class _LureTab extends StatefulWidget {
  const _LureTab();
  @override
  State<_LureTab> createState() => _LureTabState();
}

class _LureTabState extends State<_LureTab> {
  String? _selectedType;

  static final _lures = [
    _EquipItem(
      name: '德州钓组',
      spec: 'Texas Rig',
      type: '软饵',
      score: 9870,
      heat: 4120,
      replies: 543,
      tags: ['通用', '防挂', '野钓首选'],
      imageUrl: 'assets/images/equip/德州钓组.png',
    ),
    _EquipItem(
      name: '卡罗钓组',
      spec: 'Carolina Rig',
      type: '软饵',
      score: 8540,
      heat: 2980,
      replies: 321,
      tags: ['远投', '底层搜索', '大鱼专用'],
      imageUrl: 'assets/images/equip/卡罗钓组.png',
    ),
    _EquipItem(
      name: '铅头钩+卷尾',
      spec: 'Jig Head + Grubs',
      type: '软饵',
      score: 8210,
      heat: 2760,
      replies: 287,
      tags: ['感度', '快速搜索', '鲈鱼首选'],
      imageUrl: 'assets/images/equip/铅头钩_卷尾.png',
    ),
    _EquipItem(
      name: '复合亮片',
      spec: 'Spinnerbait',
      type: '亮片',
      score: 7980,
      heat: 2540,
      replies: 265,
      tags: ['远投', '全水层', '四季通用'],
      imageUrl: 'assets/images/equip/复合亮片.png',
    ),
    _EquipItem(
      name: '深潜小米诺',
      spec: 'Deep Diving Minnow 10-15g',
      type: '硬饵',
      score: 7650,
      heat: 2320,
      replies: 243,
      tags: ['远投', '深场', '大嘴鲈'],
      imageUrl: 'assets/images/equip/深潜小米诺.png',
    ),
    _EquipItem(
      name: '铅笔',
      spec: 'Popper 120F',
      type: '水面',
      score: 7320,
      heat: 2100,
      replies: 221,
      tags: ['水面系', '夏天', '炸水'],
      imageUrl: 'assets/images/equip/铅笔.png',
    ),
    _EquipItem(
      name: '胡须公',
      spec: 'Buzz Bait',
      type: '水面',
      score: 7100,
      heat: 1980,
      replies: 198,
      tags: ['噪音诱鱼', '夜晚', '大水面'],
      imageUrl: 'assets/images/equip/胡须公.png',
    ),
    _EquipItem(
      name: 'VIB',
      spec: 'VIB 8-12cm',
      type: '铁板',
      score: 6890,
      heat: 1870,
      replies: 176,
      tags: ['沉底搜索', '高感度', '巨物'],
      imageUrl: 'assets/images/equip/VIB_深海VIB.png',
    ),
    _EquipItem(
      name: 'Wacky',
      spec: 'Wacky Rig',
      type: '软饵',
      score: 6650,
      heat: 1760,
      replies: 165,
      tags: ['简单', '高感度', '精细作钓'],
      imageUrl: 'assets/images/equip/Wacky.png',
    ),
    _EquipItem(
      name: '德州钓组（无铅）',
      spec: 'Naked Texas',
      type: '软饵',
      score: 6430,
      heat: 1650,
      replies: 143,
      tags: ['自然', '高难度', '老手专用'],
      imageUrl: 'assets/images/equip/德州钓组_无铅.png',
    ),
  ];

  List<String> get _types {
    final t = _lures.map((e) => e.type).toSet().toList();
    t.sort();
    return t;
  }

  List<_EquipItem> get _filtered {
    final list = _selectedType == null
        ? _lures
        : _lures.where((e) => e.type == _selectedType).toList();
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final types = _types;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _HeroBanner(
          emoji: '🪤',
          title: '饵料榜',
          subtitle: '软饵 · 硬饵 · 亮片 · 水面系 · 铁板',
          accent: Color(0xFF2E7D32),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: '全部',
                selected: _selectedType == null,
                onTap: () => setState(() => _selectedType = null),
              ),
              for (var t in types) ...[
                const SizedBox(width: 6),
                _FilterChip(
                  label: t,
                  selected: _selectedType == t,
                  onTap: () => setState(() => _selectedType = t),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < items.length; i++)
          _EquipCard(item: items[i], rank: i + 1, delay: i * 35),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// TAB 8: 小药榜
// ═══════════════════════════════════════════════════════
class _BaitTab extends StatefulWidget {
  const _BaitTab();
  @override
  State<_BaitTab> createState() => _BaitTabState();
}

class _BaitTabState extends State<_BaitTab> {
  String? _selectedType;

  static final _baits = [
    _EquipItem(
      name: 'DMT 促食剂',
      spec: 'DMT Powder',
      type: '促食',
      score: 9120,
      heat: 3210,
      replies: 398,
      tags: ['穿透力强', '四季通用', '竞技必备'],
      imageUrl: 'assets/images/equip/DMT_促食剂.png',
    ),
    _EquipItem(
      name: '南北 鱼开胃',
      spec: 'South-North 鱼开胃',
      type: '促食',
      score: 8760,
      heat: 2980,
      replies: 365,
      tags: ['野钓必备', '穿透力', '性价比'],
      imageUrl: 'assets/images/equip/南北_鱼开胃.png',
    ),
    _EquipItem(
      name: '丸九 荒食',
      spec: 'Maruyrug HM-8',
      type: '鲤鱼类',
      score: 8430,
      heat: 2650,
      replies: 321,
      tags: ['鲤鱼类', '留鱼久', '竞技首选'],
      imageUrl: 'assets/images/equip/丸九_荒食.png',
    ),
    _EquipItem(
      name: '丸九 天下无双',
      spec: 'Maruyrug 无双',
      type: '鲤鱼类',
      score: 8100,
      heat: 2430,
      replies: 298,
      tags: ['高端', '留鱼强', '大物'],
      imageUrl: 'assets/images/equip/丸九_天下无双.png',
    ),
    _EquipItem(
      name: '魔力鸟 诱',
      spec: 'MIRUNE 诱 30%',
      type: '聚鱼',
      score: 7870,
      heat: 2210,
      replies: 276,
      tags: ['聚鱼快', '四季通用', '奶鲤'],
      imageUrl: 'assets/images/equip/魔力鸟_诱.png',
    ),
    _EquipItem(
      name: '老G 系列',
      spec: 'LaoG DPT/GLA/NBA',
      type: '综合',
      score: 7650,
      heat: 2100,
      replies: 254,
      tags: ['国产精品', '性价比', '奶鲤首选'],
      imageUrl: 'assets/images/equip/老G_系列.png',
    ),
    _EquipItem(
      name: '穿透王',
      spec: 'Penetrate King',
      type: '促食',
      score: 7430,
      heat: 1980,
      replies: 232,
      tags: ['穿透强', '夜钓', '肥水'],
      imageUrl: 'assets/images/equip/穿透王.png',
    ),
    _EquipItem(
      name: '威护 千里香',
      spec: 'Weihu 千里香',
      type: '中药类',
      score: 7210,
      heat: 1870,
      replies: 221,
      tags: ['中药底', '留鱼', '野钓'],
      imageUrl: 'assets/images/equip/威护_千里香.png',
    ),
    _EquipItem(
      name: '化氏 药酒',
      spec: 'Huashi 药酒',
      type: '中药类',
      score: 6980,
      heat: 1760,
      replies: 198,
      tags: ['野钓', '留鱼', '自制感'],
      imageUrl: 'assets/images/equip/化氏_药酒.png',
    ),
    _EquipItem(
      name: '红薯膏',
      spec: '红薯膏 浓缩型',
      type: '味型类',
      score: 6760,
      heat: 1650,
      replies: 187,
      tags: ['薯香', '鲤鱼类', '秋冬季'],
      imageUrl: 'assets/images/equip/红薯膏.png',
    ),
  ];

  List<String> get _types {
    final t = _baits.map((e) => e.type).toSet().toList();
    t.sort();
    return t;
  }

  List<_EquipItem> get _filtered {
    final list = _selectedType == null
        ? _baits
        : _baits.where((e) => e.type == _selectedType).toList();
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final types = _types;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const _HeroBanner(
          emoji: '💧',
          title: '小药榜',
          subtitle: '促食 · 聚鱼 · 味型 · 中药类',
          accent: Color(0xFFBF360C),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: '全部',
                selected: _selectedType == null,
                onTap: () => setState(() => _selectedType = null),
              ),
              for (var t in types) ...[
                const SizedBox(width: 6),
                _FilterChip(
                  label: t,
                  selected: _selectedType == t,
                  onTap: () => setState(() => _selectedType = t),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < items.length; i++)
          _EquipCard(item: items[i], rank: i + 1, delay: i * 35),
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
  final String waterType; // 海水 | 淡水 | 通用
  final int score; // 综合热度
  final int heat; // 讨论热度
  final int replies;
  final List<String> tags;
  final String? imageUrl; // 产品图片路径
  final List<String> gallery; // 详情页更多介绍图
  final String desc; // 产品简介
  const _EquipItem({
    required this.name,
    required this.spec,
    required this.type,
    this.waterType = '通用',
    required this.score,
    required this.heat,
    required this.replies,
    required this.tags,
    this.imageUrl,
    this.gallery = const [],
    this.desc = '',
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
  @override
  Widget build(BuildContext context) {
    final top3 = rank <= 3;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + delay),
      curve: Curves.easeOutBack,
      builder: (_, v, child) => Transform.scale(
        scale: v,
        child: Opacity(opacity: v, child: child),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EquipDetailPage(
              name: item.name,
              spec: item.spec,
              type: item.type,
              rank: rank,
              score: item.score,
              heat: item.heat,
              replies: item.replies,
              tags: item.tags,
              imageUrl: item.imageUrl,
              waterType: item.waterType,
              gallery: item.gallery,
              desc: item.desc,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: top3
                ? Border.all(
                    color: _rankColor.withAlpha((0.5 * 255).toInt()),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: _primary.withAlpha((0.06 * 255).toInt()),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EquipDetailPage(
                    name: item.name,
                    spec: item.spec,
                    type: item.type,
                    rank: rank,
                    score: item.score,
                    heat: item.heat,
                    replies: item.replies,
                    tags: item.tags,
                    imageUrl: item.imageUrl,
                    waterType: item.waterType,
                    gallery: item.gallery,
                    desc: item.desc,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: rank <= 3 ? 18 : 14,
                          fontWeight: FontWeight.w900,
                          color: _rankColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 装备图片
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _rankColor.withAlpha((0.08 * 255).toInt()),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item.imageUrl != null
                            ? Image.asset(
                                item.imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 28,
                                    color: _rankColor.withAlpha(
                                      (0.4 * 255).toInt(),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 28,
                                  color: _rankColor.withAlpha(
                                    (0.4 * 255).toInt(),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _textMain,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: _rankColor.withAlpha(
                                    (0.15 * 255).toInt(),
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  rank == 1 ? 'TOP' : '#$rank',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: _rankColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.spec,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textWeak,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _rankColor.withAlpha((0.12 * 255).toInt()),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              item.type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _rankColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 3,
                            children: item.tags
                                .take(3)
                                .map(
                                  (t) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _primary.withAlpha(
                                        (0.06 * 255).toInt(),
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      t,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: _primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fmt(item.score),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                        Text(
                          '综合热度',
                          style: const TextStyle(fontSize: 9, color: _textWeak),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.forum_outlined,
                              size: 10,
                              color: _textWeak,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${item.replies}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: _textWeak,
                              ),
                            ),
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
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ── 全局常量 ────────────────────────────────────────────
const _primary = Color(0xFF0A7C74);
const _bg = Color(0xFFF7F3EE);
const _gold = Color(0xFFC49A5E);
const _textMain = Color(0xFF1A1A1A);
const _textMid = Color(0xFF666666);
const _textWeak = Color(0xFF999999);

// 装备类型筛选 Chip
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _primary
                : _primary.withAlpha((0.2 * 255).toInt()),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _primary,
          ),
        ),
      ),
    );
  }
}
