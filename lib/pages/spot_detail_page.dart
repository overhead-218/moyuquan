import 'package:flutter/material.dart';

/// 钓点详情页
class SpotDetailPage extends StatefulWidget {
  final String name;
  final String emoji;
  final String meta;

  const SpotDetailPage({
    super.key,
    required this.name,
    required this.emoji,
    required this.meta,
  });

  @override
  State<SpotDetailPage> createState() => _SpotDetailPageState();
}

class _SpotDetailPageState extends State<SpotDetailPage> {
  bool _favorite = false;

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kLightTeal = Color(0xFF148F86);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kGold = Color(0xFFC49A5E);
  static const Color _kShadow = Color(0xFF1A1A1A);
  static const Color _kRed = Color(0xFFFF4757);

  // 模拟钓友动态
  final List<Map<String, dynamic>> _posts = [
    {
      'user': '海钓阿强',
      'avatar': '🎣',
      'fish': '鲈鱼 3.2kg',
      'text': '今天手感不错，连竿好几条！饵料用的玉米粒。',
      'likes': 24,
      'time': '2小时前',
    },
    {
      'user': '野钓大叔',
      'avatar': '🐟',
      'fish': '鲫鱼 0.8kg',
      'text': '这个钓点鲫鱼密度可以，建议早上去，人少口好。',
      'likes': 12,
      'time': '昨天',
    },
    {
      'user': '江南老饕',
      'avatar': '🦑',
      'fish': '黑鲷 1.5kg',
      'text': '矶钓收获，风有点大但鱼情活跃，推荐。',
      'likes': 8,
      'time': '3天前',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        slivers: [
          // 顶部图片区
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: _kPrimary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _favorite ? Icons.favorite : Icons.favorite_border,
                  color: _favorite ? _kRed : Colors.white,
                ),
                onPressed: () => setState(() => _favorite = !_favorite),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://picsum.photos/seed/${Uri.encodeComponent(widget.name)}/800/400',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_kLightTeal, _kPrimary],
                        ),
                      ),
                      child: Center(
                        child: Text(widget.emoji, style: const TextStyle(fontSize: 64)),
                      ),
                    ),
                  ),
                  // 底部渐变遮罩
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ],
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
                  // 标题 + 距离
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _kTextPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kTealBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me, size: 14, color: _kPrimary),
                            const SizedBox(width: 4),
                            Text(
                              _extractDistance(widget.meta),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _kPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 评分
                  Row(
                    children: [
                      const Icon(Icons.star, size: 18, color: _kGold),
                      const SizedBox(width: 4),
                      const Text(
                        '4.8',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(126 条评价)',
                        style: TextStyle(
                          fontSize: 13,
                          color: _kTextWeak,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 鱼种标签
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _extractFishTypes(widget.meta)
                        .map(
                          (fish) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _kSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _kTealBg,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              fish,
                              style: const TextStyle(
                                fontSize: 13,
                                color: _kPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // 钓点介绍
                  const Text(
                    '钓点介绍',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '水深适中，水流平缓，适合新手和休闲钓。岸边有缓坡方便抛竿，周边有树林遮阴。建议清晨或傍晚出钓，鱼口更活跃。',
                    style: TextStyle(
                      fontSize: 14,
                      color: _kTextWeak,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 钓友动态
                  const Text(
                    '钓友动态',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // 钓友动态列表
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = _posts[index];
                return _buildPostCard(post);
              },
              childCount: _posts.length,
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      // 底部固定栏
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, -2),
              blurRadius: 8,
              color: _kShadow.withValues(alpha: 0.04),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
        ),
        child: SafeArea(
          child: Row(
            children: [
              // 导航按钮
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _kTealBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.navigation, color: _kPrimary),
                    label: const Text(
                      '导航前往',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 发帖按钮
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kLightTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      '分享渔获',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 钓友动态卡片
  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: _kTealBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(post['avatar'] as String,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post['user'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _kTextPrimary,
                        ),
                      ),
                      Text(
                        post['time'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: _kTextWeak,
                        ),
                      ),
                    ],
                  ),
                ),
                // 鱼获标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    post['fish'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kGold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post['text'] as String,
              style: TextStyle(
                fontSize: 14,
                color: _kTextPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.favorite_border, size: 18, color: _kTextWeak),
                const SizedBox(width: 4),
                Text(
                  '${post['likes']}',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kTextWeak,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chat_bubble_outline, size: 18, color: _kTextWeak),
                const SizedBox(width: 4),
                const Text(
                  '0',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kTextWeak,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 从 meta 提取距离（如 "鲈鱼 · 鲫鱼 · 距离 1.2km" → "1.2km"）
  String _extractDistance(String meta) {
    final match = RegExp(r'距离\s*([\d.]+km)').firstMatch(meta);
    return match?.group(1) ?? '未知';
  }

  /// 从 meta 提取鱼种列表（如 "鲈鱼 · 鲫鱼 · 距离 1.2km" → [鲈鱼, 鲫鱼]）
  List<String> _extractFishTypes(String meta) {
    final parts = meta.split('·').map((e) => e.trim()).toList();
    final fishTypes = <String>[];
    for (final p in parts) {
      if (!p.startsWith('距离')) fishTypes.add(p);
    }
    return fishTypes.isEmpty ? ['综合鱼种'] : fishTypes;
  }
}
