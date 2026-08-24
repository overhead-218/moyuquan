import 'package:flutter/material.dart';

/// 装备详情页（鱼竿/鱼轮/饵料/小药共用）
class EquipDetailPage extends StatelessWidget {
  final String name;
  final String spec;
  final String type; // 鱼竿/鱼轮/饵料/小药
  final String waterType; // 海水 | 淡水 | 通用
  final int rank;
  final int score; // 综合热度
  final int heat;  // 讨论热度
  final int replies;
  final List<String> tags;
  final String? imageUrl;
  final List<String> gallery; // 详情页更多介绍图
  final String desc; // 产品简介

  const EquipDetailPage({
    super.key,
    required this.name,
    required this.spec,
    required this.type,
    this.waterType = '通用',
    required this.rank,
    required this.score,
    required this.heat,
    required this.replies,
    required this.tags,
    this.imageUrl,
    this.gallery = const [],
    this.desc = '',
  });

  // 配色
  static const _primary  = Color(0xFF0A7C74);
  static const _bg       = Color(0xFFF7F3EE);
  static const _surface  = Color(0xFFFFFFFF);
  static const _gold     = Color(0xFFC49A5E);
  static const _textMain = Color(0xFF1A1A1A);
  static const _textMid  = Color(0xFF666666);
  static const _textWeak = Color(0xFF999999);

  Color get _rankColor {
    if (rank == 1) return _gold;
    if (rank == 2) return const Color(0xFFB0BEC5);
    if (rank == 3) return const Color(0xFFCD7F32);
    return _textWeak;
  }

  Color get _waterColor {
    if (waterType == '海水') return const Color(0xFF1E88E5);
    if (waterType == '淡水') return const Color(0xFF2E7D32);
    return const Color(0xFF757575);
  }

  String _fmt(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          // 头部图片 + 渐变遮罩
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: _primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _surface.withValues(alpha: 0.2),
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
                    color: _surface.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                ),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 产品图
                  if (imageUrl != null)
                    Image.asset(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _primary.withValues(alpha: 0.1),
                        child: Center(
                          child: Icon(
                            type == '鱼竿' ? Icons.sports_cricket
                                : type == '鱼轮' ? Icons.settings
                                : type == '饵料' ? Icons.catching_pokemon
                                : Icons.water_drop,
                            size: 80, color: _primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: _primary.withValues(alpha: 0.08),
                      child: Center(
                        child: Icon(
                          type == '鱼竿' ? Icons.sports_cricket
                              : type == '鱼轮' ? Icons.settings
                              : type == '饵料' ? Icons.catching_pokemon
                              : Icons.water_drop,
                          size: 80, color: _primary.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  // 渐变遮罩
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                  // 底部信息
                  Positioned(
                    left: 20, right: 20, bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (rank <= 3) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _rankColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  rank == 1 ? 'TOP 1' : '#$rank',
                                  style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _surface.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _waterColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                waterType,
                                style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          spec,
                          style: TextStyle(
                            fontSize: 13, color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 热度数据栏
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.06),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _HeatItem(
                      icon: Icons.whatshot,
                      iconColor: const Color(0xFFFF6B35),
                      label: '综合热度',
                      value: _fmt(score),
                    ),
                  ),
                  Container(width: 1, height: 36, color: _bg),
                  Expanded(
                    child: _HeatItem(
                      icon: Icons.trending_up,
                      iconColor: _primary,
                      label: '讨论热度',
                      value: _fmt(heat),
                    ),
                  ),
                  Container(width: 1, height: 36, color: _bg),
                  Expanded(
                    child: _HeatItem(
                      icon: Icons.forum_outlined,
                      iconColor: const Color(0xFF4A90D9),
                      label: '讨论数',
                      value: '$replies',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 产品标签
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('产品标签', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _textMain,
                  )),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: tags.map((t) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(t, style: const TextStyle(
                        fontSize: 13, color: _primary, fontWeight: FontWeight.w500,
                      )),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),

          // 实景图集
          if (gallery.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.06),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('实景图集', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _textMain,
                    )),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: gallery.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            gallery[i], width: 130, height: 180, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 130, height: 180,
                              color: _primary.withValues(alpha: 0.08),
                              child: const Center(child: Icon(Icons.image_outlined, color: _primary)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 规格参数
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.06),
                    blurRadius: 8, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('规格参数', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _textMain,
                  )),
                  const SizedBox(height: 12),
                  _SpecRow(label: '产品名称', value: name),
                  _SpecRow(label: '规格型号', value: spec),
                  _SpecRow(label: '产品类型', value: type),
                  _SpecRow(label: '适用水域', value: waterType),
                  _SpecRow(label: '热度排名', value: '#$rank'),
                  _SpecRow(label: '热度指数', value: _fmt(score)),
                ],
              ),
            ),
          ),

          // 产品简介
          if (desc.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.06),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('产品简介', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _textMain,
                    )),
                    const SizedBox(height: 10),
                    Text(desc, style: const TextStyle(
                      fontSize: 13, color: _textMid, height: 1.6,
                    )),
                  ],
                ),
              ),
            ),

          // 钓友评价
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('钓友评价', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _textMain,
                      )),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('精选 ${tags.length} 条',
                          style: const TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ReviewCard(
                    avatar: '钓',
                    name: '路亚发烧友',
                    time: '3天前',
                    content: tags.isNotEmpty
                        ? '用了一段时间，这款${type}真的不错，${tags.first}是最大亮点。手感很好，值得入手。'
                        : '用了一段时间，这款${type}真心不错，值得推荐。',
                    stars: 5,
                  ),
                  const SizedBox(height: 10),
                  _ReviewCard(
                    avatar: '鲈',
                    name: '台钓老手',
                    time: '1周前',
                    content: tags.length > 1
                        ? '朋友推荐的，试了两次，${tags[1]}确实给力。性价比很高，强烈推荐！'
                        : '朋友推荐的，试了两次效果不错，性价比很高！',
                    stars: 4,
                  ),
                  const SizedBox(height: 10),
                  _ReviewCard(
                    avatar: '鳜',
                    name: '野钓爱好者',
                    time: '2周前',
                    content: '钓获稳定，${tags.isNotEmpty ? tags.last : '整体表现'}值得信赖。已经推荐给钓友了。',
                    stars: 4,
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _HeatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _HeatItem({
    required this.icon, required this.iconColor,
    required this.label, required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w800, color: EquipDetailPage._textMain,
        )),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          fontSize: 10, color: EquipDetailPage._textWeak,
        )),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;

  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(
              fontSize: 13, color: Color(0xFF999999),
            )),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A),
            )),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String avatar;
  final String name;
  final String time;
  final String content;
  final int stars;

  const _ReviewCard({
    required this.avatar, required this.name,
    required this.time, required this.content, required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0A7C74).withValues(alpha: 0.05),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Color(0xFF0A7C74).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(avatar, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Color(0xFF0A7C74),
                  )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    )),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < stars ? Icons.star : Icons.star_border,
                        size: 12, color: Color(0xFFC49A5E),
                      )),
                    ),
                  ],
                ),
              ),
              Text(time, style: const TextStyle(
                fontSize: 11, color: Color(0xFF999999),
              )),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(
            fontSize: 13, color: Color(0xFF666666), height: 1.5,
          )),
        ],
      ),
    );
  }
}
