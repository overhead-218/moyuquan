import 'dart:math';

import 'package:flutter/material.dart';
import '../models/spot.dart';
import '../services/geo_service.dart';
import '../services/spot_service.dart';
import 'spot_detail_page.dart';
import 'spot_submit_page.dart';

// ── 全局常量（所有类共用）────────────────────────────
const _primary    = Color(0xFF0A7C74);
const _bg         = Color(0xFFF7F3EE);
const _surface    = Color(0xFFFFFFFF);
const _gold       = Color(0xFFC49A5E);
const _textMain   = Color(0xFF1A1A1A);
const _textWeak   = Color(0xFF999999);

/// 钓点发现页
/// 携程三层漏斗：城市 → 综合热度排序 → 筛选
class SpotDiscoveryPage extends StatefulWidget {
  const SpotDiscoveryPage({super.key});

  @override
  State<SpotDiscoveryPage> createState() => _SpotDiscoveryPageState();
}

class _SpotDiscoveryPageState extends State<SpotDiscoveryPage> {
  String _selectedCity = '上海';
  String _selectedType = '全部'; // 全部 | 路亚 | 野钓 | 黑坑 | 斤塘 | 农家乐 | 游钓基地 | 养殖塘
  String _sortBy = '热度';      // 热度 | 距离 | 评分
  final List<Spot> _allSpots = SpotService.all;

  // 用户坐标：浏览器定位成功则更新，失败保持南京市中心兜底
  double _userLat = 32.06;
  double _userLon = 118.78;
  bool _userPicked = false; // 用户手动选过城市后，定位结果不再覆盖城市

  @override
  void initState() {
    super.initState();
    // 云库同步完成后刷新列表（_allSpots 引用原地更新即可见，这里触发 rebuild）
    SpotService.addListener(_onCloudUpdate);
    // 1. 记住的城市优先 — 记忆有效意味着用户曾经手动选过，置 _userPicked=true
    //    防止后续定位覆盖用户的明确选择。
    //    ⚠️ 这里必须用异步版 loadCityAsync()：原生端的城市记忆存在
    //    SharedPreferences 里，首帧读取必然是 null。旧代码用同步 loadCity()，
    //    在 App 端永远读不到，导致「记住的城市」功能在手机上完全失效。
    GeoService.loadCityAsync().then((saved) {
      if (!mounted || saved == null) return;
      if (!_cities.contains(saved)) return;
      setState(() {
        _selectedCity = saved;
        _userPicked = true;
      });
    });
    // 2. 浏览器定位（刷新真实坐标 + 未手动选择时映射城市）
    _tryLocate();
  }

  void _onCloudUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SpotService.removeListener(_onCloudUpdate);
    super.dispose();
  }

  Future<void> _tryLocate() async {
    final pos = await GeoService.locate();
    if (!mounted || pos == null) return;
    setState(() {
      _userLat = pos.lat;
      _userLon = pos.lon;
      if (!_userPicked) {
        final nearest = _nearestCity(pos.lat, pos.lon);
        if (nearest != null && _cities.contains(nearest)) {
          _selectedCity = nearest;
        }
      }
    });
  }

  /// 找离坐标最近的钓点所在城市（城市尺度粗匹配）。
  String? _nearestCity(double lat, double lon) {
    String? best;
    var bestD = double.infinity;
    for (final s in _allSpots) {
      final d = _distKm(lat, lon, s.latitude, s.longitude);
      if (d < bestD) {
        bestD = d;
        best = s.city;
      }
    }
    return best;
  }

  /// Haversine 距离（公里）。
  static double _distKm(double la1, double lo1, double la2, double lo2) {
    const r = 6371.0;
    final dLat = (la2 - la1) * pi / 180;
    final dLon = (lo2 - lo1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(la1 * pi / 180) * cos(la2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * asin(sqrt(a));
  }

  // 按抖音/小红书搜索量排序：路亚 > 野钓 > 黑坑 > 斤塘 > 农家乐 > 游钓基地 > 养殖塘
  static const _types = ['全部', '路亚', '野钓', '黑坑', '斤塘', '农家乐', '游钓基地', '养殖塘'];
  static const _typeEmojis = ['🎮', '🌿', '🏴‍☠️', '🐟', '🏡', '🏞', '🐟'];

  static const _cities = [
    '南京','杭州','宁波','温州',
    '上海','深圳','上饶','松原',
    '成都','乐山','宜宾','眉山','泸州','德阳','绵阳','南充','广元',
    '武汉','十堰','鄂州',
    '贵阳','遵义','黔东南','黔南','黔西南','安顺','毕节',
    '昆明','大理','曲靖','楚雄','玉溪','红河','德宏','临沧',
    '黄山','南宁','柳州','桂林','玉林','百色',
  ];

  List<Spot> get _filtered {
    var list = _allSpots.where((s) => s.city == _selectedCity).toList();
    if (_selectedType != '全部') list = list.where((s) => s.type == _selectedType).toList();
    if (_sortBy == '热度') list = SpotService.sortByHotspot(list);
    if (_sortBy == '评分') {
      list = List<Spot>.from(list);
      list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    }
    if (_sortBy == '距离') {
      list = SpotService.sortByDistance(list, _userLat, _userLon);
    }
    return list;
  }

  // 推荐位：全市热度 TOP 5
  List<Spot> get _top5 => SpotService.sortByHotspot(
    _allSpots.where((s) => s.city == _selectedCity).toList()
  ).take(5).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── 顶部：城市选择 ────────────────────────────────
            _buildHeader(),

            // ── 筛选栏 ──────────────────────────────────────
            _buildFilterBar(),

            // ── 内容区 ──────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? _buildEmpty()
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // 推荐位（热度TOP 5）
                        if (_filtered.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSectionTitle('🔥 热门推荐', '热度最高 · ${_selectedCity}'),
                          const SizedBox(height: 10),
                          _buildTopBanner(),
                          const SizedBox(height: 24),
                          _buildSectionTitle('📍 钓点列表', '共 ${_filtered.length} 个'),
                          const SizedBox(height: 10),
                        ],
                        // 全部钓点列表
                        ..._filtered.map((s) => _SpotCard(
                          spot: s,
                          index: _filtered.indexOf(s),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SpotDetailPage(spot: s)),
                          ),
                        )),
                        const SizedBox(height: 100),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: _primary, size: 22),
          const SizedBox(width: 6),
          const Text(
            '钓点',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: _textMain, letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: _primary),
            onPressed: _openSearch,
            tooltip: '搜索钓点',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: _primary),
            onPressed: _addSpot,
            tooltip: '添加钓点',
          ),
          PopupMenuButton<String>(
            initialValue: _selectedCity,
            onSelected: (v) {
              setState(() {
                _selectedCity = v;
                _userPicked = true;
              });
              GeoService.saveCity(v);
            },
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: _primary),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCity,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primary),
                  ),
                  const Icon(Icons.expand_more, size: 14, color: _primary),
                ],
              ),
            ),
            itemBuilder: (_) => _cities.map((c) => PopupMenuItem<String>(
              value: c,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (c == _selectedCity) const Icon(Icons.check, size: 14, color: _primary)
                  else const SizedBox(width: 14),
                  const SizedBox(width: 6),
                  Text(c, style: TextStyle(
                    fontSize: 13,
                    fontWeight: c == _selectedCity ? FontWeight.w700 : FontWeight.w400,
                  )),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 类型筛选（横向滚动）
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_types.length, (i) {
                final t = _types[i];
                final sel = _selectedType == t;
                final emoji = i < _typeEmojis.length ? _typeEmojis[i] : '🎣';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? _primary : _surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? _primary : _primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: sel ? [
                          BoxShadow(color: _primary.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
                        ] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 4),
                          Text(
                            t,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? Colors.white : _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          // 排序
          Row(
            children: [
              Text(
                '共 ${_filtered.length} 个钓点',
                style: const TextStyle(fontSize: 12, color: _textWeak),
              ),
              const Spacer(),
              _SortChip(label: '热度', selected: _sortBy == '热度',
                onTap: () => setState(() => _sortBy = '热度')),
              const SizedBox(width: 6),
              _SortChip(label: '评分', selected: _sortBy == '评分',
                onTap: () => setState(() => _sortBy = '评分')),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showFilterSheet(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _primary.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_list, size: 13, color: _primary),
                      SizedBox(width: 3),
                      Text('筛选', style: TextStyle(fontSize: 11, color: _primary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    final top = _top5;
    if (top.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: top.length,
        itemBuilder: (context, i) {
          final s = top[i];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SpotDetailPage(spot: s)),
            ),
            child: Container(
              width: 140,
              margin: EdgeInsets.only(right: i < top.length - 1 ? 10 : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Builder(builder: (_) {
                    final imgs = s.displayImages;
                    // ⚠️ 没有照片时不再套用通用示意图 —— 一张跟这个钓点无关的
                    //    钓鱼照会让用户误以为那就是实景。改为纯色占位 + 明示。
                    if (imgs.isEmpty) return _noPhotoTile(s, compact: true);
                    final url = imgs.first;
                    final isHttp = url.startsWith('http');
                    return isHttp
                        ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _noPhotoTile(s, compact: true),
                          loadingBuilder: (_, child, p) => p == null ? child : _noPhotoTile(s, compact: true),
                        )
                        : Image.asset(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _noPhotoTile(s, compact: true));
                  }),
                  // 渐变遮罩
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                  // 序号
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: i == 0 ? _gold : _primary.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        i == 0 ? 'TOP1' : '#${i + 1}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  // 左下角照片来源角标：有商家实拍/平台实景才显示，无图不显示
                  if (s.photoBadge != null)
                    Positioned(
                      bottom: 44, left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              s.imageSource == SpotImageSource.merchant
                                  ? Icons.storefront_outlined
                                  : (s.imageSource == SpotImageSource.community
                                      ? Icons.groups_outlined
                                      : (s.imageSource == SpotImageSource.platformShot
                                          ? Icons.photo_camera_back_outlined
                                          : Icons.public_outlined)),
                              size: 9, color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(s.photoBadge!,
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  // 底部信息
                  Positioned(
                    left: 8, right: 8, bottom: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 10, color: _gold),
                            const SizedBox(width: 2),
                            Text(s.rating?.toStringAsFixed(1) ?? '暂无', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                            const SizedBox(width: 6),
                            Text(s.priceLabel, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.85))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 无照片占位：深色实底 + 鱼种图标 + 明示文字。
  ///
  /// ⚠️ 绝不用通用示意图代替。宁可告诉用户「暂无实景照片」，
  ///    也不能让一张跟这个钓点无关的钓鱼照被当成它的实景。
  Widget _noPhotoTile(Spot s, {bool compact = false}) {
    return Container(
      color: _primary.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.typeEmoji,
                style: TextStyle(fontSize: compact ? 26 : 34)),
            SizedBox(height: compact ? 3 : 6),
            Text(
              '暂无实景照片',
              style: TextStyle(
                fontSize: compact ? 9.5 : 11,
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                '商家认领后可上传实拍',
                style: TextStyle(
                    fontSize: 9.5, color: Colors.white.withValues(alpha: 0.72)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textMain),
        ),
        const SizedBox(width: 8),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: _textWeak)),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎣', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text('${_selectedCity}暂无钓点', style: const TextStyle(fontSize: 16, color: _textWeak)),
          const SizedBox(height: 8),
          const Text('换个城市试试？', style: TextStyle(fontSize: 13, color: _textWeak)),
        ],
      ),
    );
  }

  void _addSpot() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SpotSubmitPage()),
    ).then((_) => setState(() {}));
  }

  // ── 搜索浮层 ────────────────────────────────────────
  void _openSearch() {
    final query = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('搜索钓点', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: query,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入钓点名称、鱼种或地址...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: _primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) => _doSearch(query.text, ctx),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => _doSearch(query.text, ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  void _doSearch(String q, BuildContext ctx) {
    Navigator.pop(ctx);
    if (q.trim().isEmpty) return;
    final results = SpotService.search(q.trim());
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未找到匹配钓点')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SearchResultsPage(query: q.trim(), results: results),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('筛选钓点', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textMain)),
            const SizedBox(height: 16),
            const Text('鱼种', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMain)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ['鲫鱼','鲤鱼','草鱼','鳜鱼','翘嘴','罗非','马口'].map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primary.withValues(alpha: 0.2)),
                ),
                child: Text(f, style: const TextStyle(fontSize: 13, color: _primary)),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('收费', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMain)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: ['免费','¥50以内','¥50-150','¥150以上'].map((f) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primary.withValues(alpha: 0.2)),
                ),
                child: Text(f, style: const TextStyle(fontSize: 13, color: _primary)),
              )).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('确定', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _primary : _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _primary : _primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: selected ? Colors.white : _primary),
        ),
      ),
    );
  }
}

/// 钓点卡片
class _SpotCard extends StatelessWidget {
  final Spot spot;
  final int index;
  final VoidCallback onTap;

  const _SpotCard({required this.spot, required this.index, required this.onTap});

  static List<Color> _fallbackColors(String type) {
    switch (type) {
      case '野钓':
        return const [Color(0xFF14564E), Color(0xFF0A7C74)];
      case '路亚':
        return const [Color(0xFF0F4C5C), Color(0xFF148F86)];
      case '黑坑':
        return const [Color(0xFF33383D), Color(0xFF5C6670)];
      case '斤塘':
        return const [Color(0xFF6B5230), Color(0xFFC49A5E)];
      case '农家乐':
        return const [Color(0xFF3F5A30), Color(0xFF7FA65A)];
      case '游钓基地':
        return const [Color(0xFF114A54), Color(0xFF2E8C99)];
      case '养殖塘':
        return const [Color(0xFF24503F), Color(0xFF5A9C7E)];
      default:
        return const [Color(0xFF0A7C74), Color(0xFF148F86)];
    }
  }

  static ImageProvider _imgProvider(String url) =>
      url.startsWith('assets/') ? AssetImage(url) : NetworkImage(url);

  /// 无照片占位（列表卡片版）
  Widget _noPhoto() {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: _fallbackColors(spot.type))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(spot.typeEmoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            '暂无实景照片',
            style: TextStyle(
              fontSize: 9.5,
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            // 封面图 / 无照片占位
            SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ⚠️ spot.displayImages 现在无图时返回空列表（不再回退通用图池）
                  if (spot.displayImages.isEmpty)
                    _noPhoto()
                  else
                    Image(
                      image: _imgProvider(spot.displayImages.first),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _noPhoto(),
                    ),
                  // 类型标签
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${spot.typeEmoji} ${spot.type}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                  // 左下角照片来源角标：有照片才显示
                  if (spot.photoBadge != null)
                    Positioned(
                      bottom: 6, left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              spot.imageSource == SpotImageSource.merchant
                                  ? Icons.storefront_outlined
                                  : (spot.imageSource == SpotImageSource.community
                                      ? Icons.groups_outlined
                                      : (spot.imageSource == SpotImageSource.platformShot
                                          ? Icons.photo_camera_back_outlined
                                          : Icons.public_outlined)),
                              size: 9, color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              spot.photoBadge!,
                              style: const TextStyle(
                                  fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 信息区
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名称 + 评分
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spot.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.star, size: 12, color: _gold),
                        const SizedBox(width: 2),
                        Text(
                          spot.rating?.toStringAsFixed(1) ?? '暂无',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMain),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 位置
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 11, color: _gold),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            spot.address,
                            style: const TextStyle(fontSize: 11, color: _textWeak),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // 鱼种（最多3个）
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: spot.fishSpecies.take(3).map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          f,
                          style: const TextStyle(fontSize: 10, color: _primary, fontWeight: FontWeight.w500),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 8),
                    // 底部：价格 + 热度
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: spot.price == 0
                                ? const Color(0xFFE8F5E9)
                                : _primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            spot.priceLabel,
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: spot.price == 0 ? const Color(0xFF2E7D32) : _primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '🔥 ${_fmtHot(spot.hotspotScore.toInt())}',
                          style: const TextStyle(fontSize: 11, color: _textWeak),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '📍 ${spot.postCount}帖',
                          style: const TextStyle(fontSize: 11, color: _textWeak),
                        ),
                      ],
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

  String _fmtHot(int n) {
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ── 搜索结果页 ────────────────────────────────────────
class _SearchResultsPage extends StatelessWidget {
  final String query;
  final List<Spot> results;
  const _SearchResultsPage({required this.query, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('"$query" 的搜索结果', style: const TextStyle(color: _textMain, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: _textMain),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (_, i) => _SpotCard(
          spot: results[i],
          index: i,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SpotDetailPage(spot: results[i])),
          ),
        ),
      ),
    );
  }
}
