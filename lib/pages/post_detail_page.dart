import 'package:flutter/material.dart';
import 'user_profile_page.dart';

/// 帖子详情页
class PostDetailPage extends StatefulWidget {
  final String authorName;
  final String authorAvatar;
  final String imageUrl;
  final double imageHeight;
  final int likeCount;
  final int index;

  const PostDetailPage({
    super.key,
    required this.authorName,
    required this.authorAvatar,
    required this.imageUrl,
    required this.imageHeight,
    required this.likeCount,
    required this.index,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartScale;
  bool _liked = false;
  late int _likeCount;

  static const _kPrimary = Color(0xFF0A7C74);
  static const Color _kLightTeal = Color(0xFF148F86);
  static const Color _kDarkTeal = Color(0xFF075C56);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kGold = Color(0xFFC49A5E);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _gradientPairs = <List<Color>>[
    [Color(0xFF0A7C74), Color(0xFF148F86)],
    [Color(0xFFC49A5E), Color(0xFFE0B670)],
    [Color(0xFF0E7C7B), Color(0xFF4FA8A8)],
    [Color(0xFF2E8B7B), Color(0xFF5BAE9C)],
    [Color(0xFF1F6F8B), Color(0xFF4A90B8)],
    [Color(0xFF8B5A3C), Color(0xFFB8845C)],
  ];

  static const _fishEmojis = ['🎣', '🐟', '🐠', '🦈', '🦑', '🐡'];
  static const _comments = [
    {'name': '海钓阿强', 'avatar': '🎣', 'text': '钓得太棒了！下次带上我！', 'time': '2小时前'},
    {'name': '钓鱼王', 'avatar': '🐟', 'text': '这个饵料配方求分享', 'time': '4小时前'},
    {'name': '菜鸟', 'avatar': '🎣', 'text': '慕了慕了，新手求带', 'time': '6小时前'},
  ];

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likeCount;

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _heartCtrl,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    if (_liked) {
      _heartCtrl.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientPairs[widget.index % _gradientPairs.length];
    final fishEmoji = _fishEmojis[widget.index % _fishEmojis.length];

    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        slivers: [
          // 图片区 AppBar
          SliverAppBar(
            expandedHeight: widget.imageHeight + 60,
            pinned: true,
            backgroundColor: gradient[0],
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kSurface.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kSurface.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
                ),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SizedBox(
                height: widget.imageHeight + 60,
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
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, st) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(fishEmoji, style: const TextStyle(fontSize: 80)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 内容区
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 作者信息卡
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfilePage(
                            name: widget.authorName,
                            avatar: widget.authorAvatar,
                            bio: '专注野钓，热爱分享',
                            posts: 12,
                            followers: 356,
                            following: 89,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kSurface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 4),
                            blurRadius: 16,
                            color: _kShadow.withValues(alpha: 0.06),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: _kTealBg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                widget.authorAvatar,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.authorName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '3小时前 · 南京',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _kTextWeak,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kPrimary,
                              side: const BorderSide(color: Color(0xFF0A7C74)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text(
                              '+ 关注',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 标题
                  const Text(
                    '周末钓鱼记录',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 正文
                  const Text(
                    '今天天气非常好，一大早就出发了，去了南京郊区的野钓点。鱼口很旺，连竿上了十几条大板鲫，最大的有半斤多！饵料用的是老坛玉米加蓝鲫，效果非常好。',
                    style: TextStyle(
                      fontSize: 15,
                      color: _kTextPrimary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 标签
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Tag('野钓'),
                      _Tag('大板鲫'),
                      _Tag('老坛玉米'),
                      _Tag('南京'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 点赞互动栏
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 4),
                          blurRadius: 16,
                          color: _kShadow.withValues(alpha: 0.06),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ScaleTransition(
                          scale: _heartScale,
                          child: GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              children: [
                                Icon(
                                  _liked ? Icons.favorite : Icons.favorite_border,
                                  color: _liked
                                      ? const Color(0xFFFF4757)
                                      : _kTextWeak,
                                  size: 26,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_likeCount',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _liked
                                        ? const Color(0xFFFF4757)
                                        : _kTextWeak,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Icon(Icons.chat_bubble_outline,
                            color: _kTextWeak, size: 24),
                        const SizedBox(width: 6),
                        Text(
                          '${_comments.length}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kTextWeak,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.share_outlined,
                            color: _kTextWeak.withValues(alpha: 0.7), size: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 评论标题
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble, size: 18, color: _kPrimary),
                      const SizedBox(width: 6),
                      const Text(
                        '评论',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_comments.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 评论列表
                  ..._comments.map((c) => _CommentItem(
                        name: c['name'] as String,
                        avatar: c['avatar'] as String,
                        text: c['text'] as String,
                        time: c['time'] as String,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0A7C74),
        ),
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final String name;
  final String avatar;
  final String text;
  final String time;

  const _CommentItem({
    required this.name,
    required this.avatar,
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE6F2F0),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(avatar, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
