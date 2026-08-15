import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/spot.dart';
import '../services/spot_service.dart';
import 'share_card_page.dart';

/// 钓点详情页
class SpotDetailPage extends StatefulWidget {
  final Spot spot;
  // 兼容旧调用（单字段参数）
  const SpotDetailPage({super.key, required this.spot});

  @override
  State<SpotDetailPage> createState() => _SpotDetailPageState();
}

class _SpotDetailPageState extends State<SpotDetailPage> {
  bool _favorite = false;
  int _currentImageIndex = 0;
  late PageController _imageController;
  String _imgCat = '全部'; // 头图分类：全部/钓点/住宿/公共区域

  /// 图片分类标签（仅在有对应照片时显示）
  List<String> get _imgCats {
    final cats = <String>['全部'];
    if (spot.images.isNotEmpty) cats.add('钓点');
    if (spot.accommodationImages.isNotEmpty) cats.add('住宿');
    if (spot.commonAreaImages.isNotEmpty) cats.add('公共区域');
    return cats;
  }

  /// 当前分类下的图片列表
  List<String> get _catImages {
    switch (_imgCat) {
      case '钓点': return spot.images;
      case '住宿': return spot.accommodationImages;
      case '公共区域': return spot.commonAreaImages;
      default: return spot.galleryImages;
    }
  }

  static const _primary    = Color(0xFF0A7C74);
  static const _lightTeal  = Color(0xFF148F86);
  static const _bg         = Color(0xFFF7F3EE);
  static const _surface    = Color(0xFFFFFFFF);
  static const _gold       = Color(0xFFC49A5E);
  static const _red        = Color(0xFFFF4757);
  static const _textMain   = Color(0xFF1A1A1A);
  static const _textWeak   = Color(0xFF999999);

  late Spot spot;

  @override
  void initState() {
    super.initState();
    spot = widget.spot;
    _imageController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  void _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  void _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  void _openWechat(String wx) async {
    final url = 'https://u.weixin.qq.com/search?keyword=${Uri.encodeComponent(wx)}';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  /// 商家认领钓点：自助维护联系方式
  void _showClaimSheet() {
    final nameCtl = TextEditingController(text: spot.ownerName ?? '');
    final phoneCtl = TextEditingController(text: spot.contactPhone ?? '');
    final wxCtl = TextEditingController(text: spot.wechat ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('认领此钓点', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _textMain)),
            const SizedBox(height: 4),
            const Text('认领后可自助维护联系方式，让钓友准确找到你', style: TextStyle(fontSize: 12, color: _textWeak)),
            const SizedBox(height: 16),
            _ClaimField(label: '负责人 / 店名', hint: '如：老王钓场', controller: nameCtl),
            const SizedBox(height: 12),
            _ClaimField(label: '联系电话', hint: '公开管理电话', controller: phoneCtl, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _ClaimField(label: '微信号', hint: '便于钓友加微信咨询', controller: wxCtl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final name = nameCtl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('请填写负责人或店名'), duration: Duration(seconds: 2)),
                    );
                    return;
                  }
                  final updated = SpotService.claimSpot(
                    spot.id,
                    ownerName: name,
                    contactPhone: phoneCtl.text.trim().isEmpty ? null : phoneCtl.text.trim(),
                    wechat: wxCtl.text.trim().isEmpty ? null : wxCtl.text.trim(),
                  );
                  if (updated != null) setState(() => spot = updated);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('认领成功，联系方式已展示'), duration: Duration(seconds: 2)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('提交认领', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ClaimField({required String label, required String hint, required TextEditingController controller, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: _textWeak),
            filled: true,
            fillColor: _bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 顶部图片区
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: _primary,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _favorite ? Icons.favorite : Icons.favorite_border,
                        color: _favorite ? _red : Colors.white,
                        size: 18,
                      ),
                    ),
                    onPressed: () => setState(() => _favorite = !_favorite),
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.share, color: Colors.white, size: 18),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ShareCardPage.spot(spot.toShareData())),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 图片轮播
                      PageView.builder(
                        controller: _imageController,
                        onPageChanged: (i) => setState(() => _currentImageIndex = i),
                        itemCount: _catImages.isEmpty ? 1 : _catImages.length,
                        itemBuilder: (_, i) {
                          if (_catImages.isEmpty) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primary, _lightTeal],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(spot.typeEmoji, style: const TextStyle(fontSize: 80)),
                              ),
                            );
                          }
                          return Image.network(
                            _catImages[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _imgFallback(),
                          );
                        },
                      ),
                      // 底部渐变遮罩
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
                            ),
                          ),
                        ),
                      ),
                      // 指示器
                      if (spot.images.length > 1)
                        Positioned(
                          right: 16, bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1}/${_catImages.length}',
                              style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      // 类型标签
                      Positioned(
                        left: 16, bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${spot.typeEmoji} ${spot.type}',
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 主体内容
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  transform: Matrix4.translationValues(0, -16, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 名称 + 评分
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                spot.name,
                                style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w800,
                                  color: _textMain, letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 16, color: _gold),
                                    const SizedBox(width: 3),
                                    Text(
                                      spot.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w800, color: _textMain,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${spot.reviewCount}条评价',
                                  style: const TextStyle(fontSize: 11, color: _textWeak),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // 地址
                        GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 14, color: _gold),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  spot.address,
                                  style: const TextStyle(fontSize: 13, color: _textWeak),
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 16, color: _textWeak),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        // 营业时间
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: _textWeak),
                            const SizedBox(width: 4),
                            Text(
                              spot.businessHours,
                              style: const TextStyle(fontSize: 13, color: _textWeak),
                            ),
                          ],
                        ),

                        // ── 住宿信息（野钓/游钓基地常见）───────────────────
                        // ── 图片分类切换（携程/去哪儿风格）──────────────
                        if (_imgCats.length > 1) ...[
                          SizedBox(
                            height: 34,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _imgCats.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final cat = _imgCats[i];
                                final sel = _imgCat == cat;
                                return GestureDetector(
                                  onTap: () => setState(() {
                                    _imgCat = cat;
                                    _currentImageIndex = 0;
                                    _imageController.jumpToPage(0);
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: sel ? _primary : _bg,
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                    child: Text(cat, style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : _textWeak,
                                    )),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── 住宿 / 钓棚配套（携程/去哪儿风格）─────────────
                        if (spot.hasLodgingInfo) ...[
                          const SizedBox(height: 16),
                          _buildSectionTitle(
                            spot.type == '野钓' ? '🏠 钓棚 / 住宿配套' : '🏠 住宿 & 配套',
                            subtitle: spot.hasAccommodation ? null : '钓点公共区域与设施',
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (spot.facilityChips.isNotEmpty) ...[
                                  _buildSubLabel('设施服务'),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8, runSpacing: 8,
                                    children: spot.facilityChips.map((f) => _buildFacilityChip(f)).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (spot.roomType != null || spot.roomCapacity != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32, height: 32,
                                          decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.bed_outlined, size: 16, color: _primary),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (spot.roomType != null)
                                                Text(spot.roomType!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textMain)),
                                              if (spot.roomCapacity != null)
                                                Text('${spot.roomCapacity!}人/间', style: const TextStyle(fontSize: 11, color: _textWeak)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (spot.accommodationNote != null) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(8)),
                                    child: Text(spot.accommodationNote!, style: const TextStyle(fontSize: 12, color: _textMain, height: 1.5)),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (spot.accommodationImages.isNotEmpty) ...[
                                  _buildSubLabel('住宿照片'),
                                  const SizedBox(height: 8),
                                  _buildImageStrip(spot.accommodationImages),
                                  const SizedBox(height: 12),
                                ],
                                if (spot.commonAreaImages.isNotEmpty) ...[
                                  _buildSubLabel('公共区域'),
                                  const SizedBox(height: 8),
                                  _buildImageStrip(spot.commonAreaImages),
                                ],
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),

                        // ── 联系商家 ──────────────────────────────────────
                        _buildSectionTitle('📞 联系商家', subtitle: spot.ownerName != null ? '负责人：${spot.ownerName}' : null),
                        const SizedBox(height: 12),
                        _buildContactSection(),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),

                        // ── 鱼种窗口期 / 塘内鱼种 ───────────────────
                        if (spot.type == '野钓') ...[
                          _buildSectionTitle('🐟 鱼种窗口期', subtitle: '旺季月份范围 · 基于鱼种习性'),
                          const SizedBox(height: 12),
                          _buildFishSeason(),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 20),
                        ] else ...[
                          _buildSectionTitle('🐟 塘内主要鱼种'),
                          const SizedBox(height: 12),
                          _buildPondFishList(),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 20),
                        ],

                        // ── 放鱼提醒 ────────────────────────────────────
                        if (spot.hasStocking) ...[
                          _buildSectionTitle('🐟 放鱼提醒', subtitle: spot.ownerName != null ? '由 ${spot.ownerName} 维护' : '商家可认领维护'),
                          const SizedBox(height: 12),
                          _buildStockingReminder(),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                          const SizedBox(height: 20),
                        ],

                        // ── 收费信息 ────────────────────────────────────
                        _buildSectionTitle('💰 收费信息'),
                        const SizedBox(height: 12),
                        _buildPriceSection(),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),

                        // ── 钓点介绍 ────────────────────────────────────
                        _buildSectionTitle('📝 钓点介绍'),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Text(
                            spot.description,
                            style: const TextStyle(fontSize: 14, color: _textMain, height: 1.6),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        const SizedBox(height: 20),

                        // ── 近期鱼情 ────────────────────────────────────
                        _buildSectionTitle('📸 近期鱼情', subtitle: '${spot.postCount}条渔获分享'),
                        const SizedBox(height: 12),
                        _buildRecentPosts(),

                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 底部固定操作栏
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: _surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  // 收藏
                  GestureDetector(
                    onTap: () => setState(() => _favorite = !_favorite),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_favorite ? Icons.favorite : Icons.favorite_border, size: 18, color: _favorite ? _red : _primary),
                          const SizedBox(height: 2),
                          Text('收藏', style: TextStyle(fontSize: 9, color: _favorite ? _red : _primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 一键联系商家（CTA）
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showContactSheet(),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: _primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_in_talk, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text('联系商家', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textMain),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: _textWeak)),
        ],
      ],
    );
  }

  /// 小标题（设施服务 / 住宿照片 / 公共区域）
  Widget _buildSubLabel(String text) => Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textWeak),
      );

  /// 设施服务标签（携程/去哪儿风格 chip）
  Widget _buildFacilityChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_facilityIcon(label), size: 13, color: _primary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  IconData _facilityIcon(String label) {
    switch (label) {
      case 'WiFi': return Icons.wifi;
      case '停车场': return Icons.local_parking;
      case '餐厅': return Icons.restaurant;
      case '淋浴热水': return Icons.shower;
      case '空调': return Icons.ac_unit;
      case '充电': return Icons.electrical_services;
      case '渔具出租': return Icons.phishing;
      default: return Icons.check_circle_outline;
    }
  }

  /// 类型 → 占位渐变色（图片加载失败时的本地主题占位）
  static const _typeColors = <String, List<Color>>{
    '野钓': [Color(0xFF14564E), Color(0xFF0A7C74)],
    '路亚': [Color(0xFF0F4C5C), Color(0xFF148F86)],
    '黑坑': [Color(0xFF33383D), Color(0xFF5C6670)],
    '斤塘': [Color(0xFF6B5230), Color(0xFFC49A5E)],
    '农家乐': [Color(0xFF3F5A30), Color(0xFF7FA65A)],
    '游钓基地': [Color(0xFF114A54), Color(0xFF2E8C99)],
    '养殖塘': [Color(0xFF24503F), Color(0xFF5A9C7E)],
  };

  List<Color> get _fallbackColors =>
      _typeColors[spot.type] ?? const [Color(0xFF0A7C74), Color(0xFF148F86)];

  /// 轮播大图占位：渐变 + 圆底 emoji
  Widget _imgFallback() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _fallbackColors,
          ),
        ),
        child: Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(spot.typeEmoji, style: const TextStyle(fontSize: 46)),
            ),
          ),
        ),
      );

  /// 图廊小图占位：渐变 + emoji
  Widget _stripFallback() => Container(
        width: 150,
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _fallbackColors,
          ),
        ),
        child: Center(
          child: Text(spot.typeEmoji, style: const TextStyle(fontSize: 26)),
        ),
      );

  /// 横向图片条（住宿照片 / 公共区域）
  Widget _buildImageStrip(List<String> urls) => SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              urls[i],
              width: 150, height: 110, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _stripFallback(),
            ),
          ),
        ),
      );

  Widget _buildContactSection() {
    // 未认领：引导商家认领并自助维护联系方式
    if (!spot.isClaimed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: _gold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.verified_outlined, color: _gold, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('本钓点信息由平台整理', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textMain)),
                      SizedBox(height: 2),
                      Text('商家可认领并自助维护联系方式', style: TextStyle(fontSize: 11, color: _textWeak)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showClaimSheet,
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('认领此钓点'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // 老板信息
          if (spot.ownerName != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(spot.ownerName!.substring(0, 1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(spot.ownerName!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textMain)),
                        const Text('已认领 · 商家自助维护', style: TextStyle(fontSize: 11, color: _textWeak)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showClaimSheet,
                    child: const Text('编辑', style: TextStyle(fontSize: 12, color: _primary)),
                  ),
                ],
              ),
            ),
          // 联系方式
          Row(
            children: [
              if (spot.contactPhone != null)
                Expanded(
                  child: _ContactBtn(
                    icon: Icons.phone,
                    label: '拨打电话',
                    value: spot.contactPhone!,
                    color: _primary,
                    onTap: () => _callPhone(spot.contactPhone!),
                  ),
                ),
              if (spot.contactPhone != null && spot.wechat != null)
                const SizedBox(width: 10),
              if (spot.wechat != null)
                Expanded(
                  child: _ContactBtn(
                    icon: Icons.chat_bubble_outline,
                    label: '加微咨询',
                    value: spot.wechat!,
                    color: const Color(0xFF07C160),
                    onTap: () => _openWechat(spot.wechat!),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  bool _monthInRange(int month, String range) {
    if (range.isEmpty) return false;
    final parts = range.split('-');
    if (parts.length != 2) return false;
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    if (a == null || b == null) return false;
    if (a <= b) return month >= a && month <= b;
    return month >= a || month <= b; // 跨年，如 9-3
  }

  String _recommendText(int now) {
    final hot = spot.fishSpecies.where((f) {
      final r = spot.peakSeasonFor(f);
      return r.isNotEmpty && _monthInRange(now, r);
    }).toList();
    if (hot.isEmpty) return '📅 当前（${now}月）鱼情偏淡，建议早晚窗口期出钓';
    return '📅 当前（${now}月）推荐鱼种：${hot.join(' · ')}';
  }

  Widget _buildFishSeason() {
    final now = DateTime.now().month;
    final seasons = const [
      ('春', 3, 5),
      ('夏', 6, 8),
      ('秋', 9, 11),
      ('冬', 12, 2),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8, runSpacing: 8,
          children: seasons.map((s) {
            final active = _monthInRange(now, '${s.$2}-${s.$3}');
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? _primary : _bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${s.$1}季', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : _textWeak)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        ...spot.fishSpecies.map((fish) {
          final range = spot.peakSeasonFor(fish);
          final hot = range.isNotEmpty && _monthInRange(now, range);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(child: Text(fish, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hot ? _primary.withValues(alpha: 0.12) : _bg,
                    borderRadius: BorderRadius.circular(8),
                    border: hot ? Border.all(color: _primary.withValues(alpha: 0.4)) : null,
                  ),
                  child: Text(range.isEmpty ? '全年' : '${range}月', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: hot ? _primary : _textWeak)),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _primary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
          child: Text(_recommendText(now), style: const TextStyle(fontSize: 12.5, color: _textMain, height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildPondFishList() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: spot.fishSpecies.map((f) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
        child: Text(f, style: const TextStyle(fontSize: 13, color: _textMain)),
      )).toList(),
    );
  }

  Widget _buildStockingReminder() {
    final days = spot.daysSinceStocking;
    final next = spot.nextStocking;
    final claimed = spot.ownerName != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, size: 18, color: _primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '上次放鱼：${spot.lastStockingDate}（${days < 0 ? '—' : '${days}天前'}）',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain),
                ),
              ),
              if (!claimed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('商家可认领维护', style: TextStyle(fontSize: 10, color: _primary)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('放鱼周期：每${spot.stockingCycleDays}天', style: const TextStyle(fontSize: 12, color: _textWeak)),
              const Spacer(),
              Text('预计下次：${next == null ? '—' : '${next.month}月${next.day}日'}前后', style: const TextStyle(fontSize: 12, color: _textWeak)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _subscribeStocking,
              icon: const Icon(Icons.notifications_active_outlined, size: 16),
              label: const Text('订阅放鱼提醒'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primary,
                side: BorderSide(color: _primary.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _subscribeStocking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('放鱼提醒已订阅，开钓前会通知你 🔔'), duration: Duration(seconds: 2)),
    );
  }

  Widget _buildPriceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: spot.price == 0
                  ? const Color(0xFFE8F5E9)
                  : _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: spot.price == 0
                  ? const Text('免费', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32)))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('¥${spot.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _primary)),
                        Text('/人', style: TextStyle(fontSize: 11, color: _primary.withValues(alpha: 0.7))),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.price == 0 ? '免费野钓' : '钓费 ¥${spot.price.toStringAsFixed(0)}/人',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textMain),
                ),
                const SizedBox(height: 4),
                Text(spot.priceNote, style: const TextStyle(fontSize: 12, color: _textWeak, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, bool border) {
    return Row(
      children: [
        Container(
          width: 16, height: 12,
          decoration: BoxDecoration(
            color: border ? null : color,
            borderRadius: BorderRadius.circular(3),
            border: border ? Border.all(color: const Color(0xFFDDDDDD)) : null,
          ),
          child: border ? null : Center(
            child: Text('★', style: TextStyle(fontSize: 8, color: color == const Color(0xFFE8F5E9) ? const Color(0xFF2E7D32) : const Color(0xFF0A7C74))),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _textWeak)),
      ],
    );
  }

  Widget _buildRecentPosts() {
    final mockPosts = [
      {'user': '海钓阿强', 'avatar': '🎣', 'fish': '草鱼 3.2kg', 'text': '今天手感不错，连竿好几条！', 'likes': 24, 'time': '2小时前'},
      {'user': '野钓大叔', 'avatar': '🐟', 'fish': '鲫鱼 0.8kg', 'text': '这个钓点鲫鱼密度可以，建议早上去。', 'likes': 12, 'time': '昨天'},
    ];
    return Column(
      children: mockPosts.map((p) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(p['avatar'] as String, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(p['user'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(p['fish'] as String, style: const TextStyle(fontSize: 10, color: _primary, fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(p['time'] as String, style: const TextStyle(fontSize: 10, color: _textWeak)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(p['text'] as String, style: const TextStyle(fontSize: 13, color: _textMain, height: 1.4)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.favorite_border, size: 12, color: _textWeak),
                        const SizedBox(width: 4),
                        Text('${p['likes']}', style: const TextStyle(fontSize: 11, color: _textWeak)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showContactSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: _textWeak.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(spot.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textMain)),
            const SizedBox(height: 4),
            if (spot.ownerName != null) Text('负责人：${spot.ownerName}', style: const TextStyle(fontSize: 13, color: _textWeak)),
            const SizedBox(height: 20),
            if (spot.contactPhone != null)
              _SheetBtn(
                icon: Icons.phone,
                label: '拨打电话',
                sub: spot.contactPhone!,
                color: _primary,
                onTap: () { Navigator.pop(context); _callPhone(spot.contactPhone!); },
              ),
            if (spot.contactPhone != null && spot.wechat != null) const SizedBox(height: 12),
            if (spot.wechat != null)
              _SheetBtn(
                icon: Icons.chat_bubble_outline,
                label: '加微信咨询',
                sub: spot.wechat!,
                color: const Color(0xFF07C160),
                onTap: () { Navigator.pop(context); _openWechat(spot.wechat!); },
              ),
            const SizedBox(height: 12),
            _SheetBtn(
              icon: Icons.map_outlined,
              label: '导航前往',
              sub: spot.address,
              color: _gold,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _bg,
                  foregroundColor: _textWeak,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('取消', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;
  const _ContactBtn({required this.icon, required this.label, required this.value, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                children: [
                  Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                  Text(value, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;
  const _SheetBtn({required this.icon, required this.label, required this.sub, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
                  Text(sub, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

