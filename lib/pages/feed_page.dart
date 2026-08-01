import 'package:flutter/material.dart';
import 'post_detail_page.dart';
import 'search_page.dart';

/// 首页：双列瀑布流 + 真实图片 + 点赞动画 + 跳转详情
/// Stitch 风格：Material 3 Expressive，暖白背景、青绿主色、金色点缀
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  int _segmentIndex = 1; // 默认"发现"

  static const _photos = <String>[
    'https://picsum.photos/seed/fishing-app-1/400/300.jpg',
    'https://picsum.photos/seed/fishing-app-2/400/280.jpg',
    'https://picsum.photos/seed/fishing-app-3/400/320.jpg',
    'https://picsum.photos/seed/fishing-app-4/400/260.jpg',
    'https://picsum.photos/seed/fishing-app-5/400/340.jpg',
    'https://picsum.photos/seed/fishing-app-6/400/300.jpg',
  ];

  static const _heights = <double>[200, 240, 180, 220, 260, 200];
  static const _avatars = <String>['🎣', '🐟', '🦈', '🐠', '🦑', '🎣'];
  static const _names = <String>['老李', '阿飞', '钓鱼王', '海钓阿强', '菜鸟', '野钓大叔'];
  static const _likes = <String>['128', '356', '892', '67', '445', '203'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '摸鱼圈',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A7C74),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF0A7C74)),
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
              color: Color(0xFF0A7C74),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 分段栏 — 全圆 chip 浅青底
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2F0),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  _SegmentItem(
                    label: '关注',
                    selected: _segmentIndex == 0,
                    onTap: () => setState(() => _segmentIndex = 0),
                  ),
                  _SegmentItem(
                    label: '发现',
                    selected: _segmentIndex == 1,
                    onTap: () => setState(() => _segmentIndex = 1),
                  ),
                  _SegmentItem(
                    label: '同城',
                    selected: _segmentIndex == 2,
                    onTap: () => setState(() => _segmentIndex = 2),
                  ),
                ],
              ),
            ),
          ),
          // 双列瀑布流
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左列
                    Expanded(
                      child: Column(
                        children: List.generate(3, (i) {
                          final idx = i * 2;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16, right: 8),
                            child: _FeedImageCard(
                              imageUrl: _photos[idx],
                              height: _heights[idx],
                              avatar: _avatars[idx],
                              name: _names[idx],
                              likes: _likes[idx],
                              index: idx,
                            ),
                          );
                        }),
                      ),
                    ),
                    // 右列
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 30, left: 8),
                        child: Column(
                          children: List.generate(3, (i) {
                            final idx = i * 2 + 1;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _FeedImageCard(
                                imageUrl: _photos[idx],
                                height: _heights[idx],
                                avatar: _avatars[idx],
                                name: _names[idx],
                                likes: _likes[idx],
                                index: idx,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0A7C74) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF666666),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedImageCard extends StatefulWidget {
  final String imageUrl;
  final double height;
  final String avatar;
  final String name;
  final String likes;
  final int index;

  const _FeedImageCard({
    required this.imageUrl,
    required this.height,
    required this.avatar,
    required this.name,
    required this.likes,
    required this.index,
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
    _likeCount = int.parse(widget.likes);
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

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientPairs[widget.index % _gradientPairs.length];
    final fishEmoji = _fishEmojis[widget.index % _fishEmojis.length];

    return FadeTransition(
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
                  authorName: widget.name,
                  authorAvatar: widget.avatar,
                  imageUrl: widget.imageUrl,
                  imageHeight: widget.height,
                  likeCount: int.parse(widget.likes),
                  index: widget.index,
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图片区
                SizedBox(
                  height: widget.height,
                  width: double.infinity,
                  child: Image.network(
                    widget.imageUrl,
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
                // 用户信息区 — 头像+昵称 与 点赞 分行清晰
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(widget.avatar,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                                size: 16,
                                color: _liked
                                    ? const Color(0xFFFF4757)
                                    : const Color(0xFF999999),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_likeCount',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
