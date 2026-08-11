import 'package:flutter/material.dart';
import '../models/spot.dart';
import '../services/spot_service.dart';

/// 添加钓点 / 钓友投稿
class SpotSubmitPage extends StatefulWidget {
  const SpotSubmitPage({super.key});

  @override
  State<SpotSubmitPage> createState() => _SpotSubmitPageState();
}

class _SpotSubmitPageState extends State<SpotSubmitPage> {
  static const Color _primary = Color(0xFF0A7C74);
  static const Color _bg = Color(0xFFF7F3EE);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _textWeak = Color(0xFF999999);
  static const Color _textMain = Color(0xFF1A1A1A);

  static const List<String> _types = ['野钓', '路亚', '斤塘', '黑坑', '养殖塘', '农家乐', '游钓基地'];
  static const List<String> _typeEmojis = ['🌿', '🎮', '🐟', '🏴\u200d☠️', '🐟', '🏡', '🏞'];
  static const List<String> _fishPresets = [
    '鲫鱼', '鲤鱼', '草鱼', '青鱼', '鳜鱼', '翘嘴', '鳙鱼', '鲢鱼',
    '罗非', '马口', '黄颡鱼', '鲈鱼', '黑鱼', '鳊鱼', '鲶鱼', '军鱼',
    '溪石斑', '金线鱼', '黄鳍鲷', '螺蛳青',
  ];

  static const List<String> _facilityPresets = [
    'WiFi', '停车场', '餐厅', '淋浴热水', '空调', '充电', '渔具出租',
  ];

  final _nameCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _priceNoteCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _wechatCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _roomTypeCtrl = TextEditingController();
  final _roomCapacityCtrl = TextEditingController();
  final _roomNoteCtrl = TextEditingController();
  final _accImgCtrl = TextEditingController();
  final _commonImgCtrl = TextEditingController();

  bool _hasLodging = false;
  final Set<String> _facilities = {};

  String _type = '野钓';
  String _city = '南京';
  final Set<String> _fish = {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _districtCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _priceNoteCtrl.dispose();
    _hoursCtrl.dispose();
    _phoneCtrl.dispose();
    _wechatCtrl.dispose();
    _ownerCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    _roomTypeCtrl.dispose();
    _roomCapacityCtrl.dispose();
    _roomNoteCtrl.dispose();
    _accImgCtrl.dispose();
    _commonImgCtrl.dispose();
    super.dispose();
  }

  String get _typeEmoji {
    final i = _types.indexOf(_type);
    return i >= 0 && i < _typeEmojis.length ? _typeEmojis[i] : '🎣';
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写钓点名称'), backgroundColor: _primary),
      );
      return;
    }
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;

    // 鱼种旺季月份范围（野钓/游钓按常识推导；其他类型留空由商家补放养信息）
    final Map<String, String> peakSeason;
    if (_type == '野钓' || _type == '游钓基地') {
      const lut = <String, String>{
        '鲫鱼': '3-11', '鲤鱼': '4-11', '草鱼': '4-10', '青鱼': '5-10',
        '鳜鱼': '5-10', '翘嘴': '6-9', '鲈鱼': '5-10', '大口黑鲈': '5-10',
        '加州鲈': '5-10', '鳙鱼': '5-9', '鲢鱼': '5-9', '鲢鳙': '5-9',
        '鳊鱼': '4-10', '黄颡鱼': '4-10', '黄辣丁': '4-10', '鲶鱼': '5-9',
        '黑鱼': '5-9', '罗非': '5-10', '马口鱼': '4-10', '溪石斑': '4-10',
        '光唇鱼': '4-10', '军鱼': '5-10', '丁桂鱼': '5-9',
      };
      peakSeason = { for (final f in _fish) f: lut[f] ?? '4-10' };
    } else {
      peakSeason = const {};
    }
    final bool isStockingType = _type == '斤塘' || _type == '黑坑' ||
        _type == '养殖塘' || _type == '农家乐';

    final imgRaw = _imageCtrl.text.trim();
    final List<String> images;
    if (imgRaw.isEmpty) {
      images = ['https://picsum.photos/seed/u${DateTime.now().millisecondsSinceEpoch}/800/500'];
    } else {
      images = imgRaw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final accImages = _parseList(_accImgCtrl.text);
    final commonImages = _parseList(_commonImgCtrl.text);
    final facilities = _facilities.toList();
    final roomCapacity = int.tryParse(_roomCapacityCtrl.text.trim());
    final spot = Spot(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: _type,
      typeEmoji: _typeEmoji,
      city: _city,
      district: _districtCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      latitude: 0.0,
      longitude: 0.0,
      images: images,
      fishSpecies: _fish.toList(),
      fishPeakSeason: peakSeason,
      lastStockingDate: isStockingType ? '${DateTime.now().subtract(const Duration(days: 3)).toString().substring(0, 10)}' : null,
      stockingCycleDays: isStockingType ? (_type == '斤塘' || _type == '黑坑' ? 7 : 30) : 0,
      price: price,
      priceNote: _priceNoteCtrl.text.trim(),
      businessHours: _hoursCtrl.text.trim(),
      contactPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      wechat: _wechatCtrl.text.trim().isEmpty ? null : _wechatCtrl.text.trim(),
      ownerName: _ownerCtrl.text.trim().isEmpty ? null : _ownerCtrl.text.trim(),
      rating: 0.0,
      reviewCount: 0,
      viewCount: 0,
      favoriteCount: 0,
      postCount: 0,
      description: _descCtrl.text.trim(),
      hasAccommodation: _hasLodging,
      roomType: _hasLodging ? (_roomTypeCtrl.text.trim().isEmpty ? null : _roomTypeCtrl.text.trim()) : null,
      roomCapacity: _hasLodging ? roomCapacity : null,
      hasWifi: _facilities.contains('WiFi'),
      accommodationNote: _roomNoteCtrl.text.trim().isEmpty ? null : _roomNoteCtrl.text.trim(),
      accommodationImages: accImages,
      commonAreaImages: commonImages,
      facilities: facilities,
      updatedAt: DateTime.now(),
      submitter: SpotSubmitter.ugc,
    );

    SpotService.addSpot(spot);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('钓点已提交，感谢分享！'),
        backgroundColor: _primary,
      ),
    );
    Navigator.pop(context);
  }

  List<String> _parseList(String raw) =>
      raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _primary),
        title: const Text('添加钓点',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _primary)),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('提交',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard([
              _buildField(label: '钓点名称', ctrl: _nameCtrl, hint: '如：千岛湖西南湖区'),
              _buildDivider(),
              _buildTypeSelector(),
              _buildDivider(),
              _buildCitySelector(),
              _buildDivider(),
              _buildField(label: '区县', ctrl: _districtCtrl, hint: '如：淳安'),
              _buildDivider(),
              _buildField(label: '详细地址', ctrl: _addressCtrl, hint: '如：西南湖区码头'),
            ]),
            const SizedBox(height: 16),
            _buildCard([
              _buildField(label: '钓费(元)', ctrl: _priceCtrl, hint: '0=免费', keyboard: TextInputType.number),
              _buildDivider(),
              _buildField(label: '计费说明', ctrl: _priceNoteCtrl, hint: '如：按天¥200含船费'),
              _buildDivider(),
              _buildField(label: '营业时间', ctrl: _hoursCtrl, hint: '如：06:00-18:00'),
            ]),
            const SizedBox(height: 16),
            _buildCard([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('鱼种（可多选）', style: TextStyle(fontSize: 14, color: _textWeak)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _fishPresets.map((f) {
                        final sel = _fish.contains(f);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (sel) _fish.remove(f); else _fish.add(f);
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? _primary : _bg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: sel ? _primary : _primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(f, style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? Colors.white : _primary,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // ── 钓棚 / 住宿配套（携程/去哪儿风格）──────────────
            _buildCard([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('钓棚 / 住宿配套', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textMain)),
                        GestureDetector(
                          onTap: () => setState(() => _hasLodging = !_hasLodging),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _hasLodging ? _primary : _bg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(_hasLodging ? '有' : '无', style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: _hasLodging ? Colors.white : _primary,
                            )),
                          ),
                        ),
                      ],
                    ),
                    if (_hasLodging) ...[
                      const SizedBox(height: 14),
                      _buildField(label: '房型', ctrl: _roomTypeCtrl, hint: '如：钓棚木屋/标间'),
                      _buildDivider(),
                      _buildField(label: '几人/间', ctrl: _roomCapacityCtrl, hint: '选填', keyboard: TextInputType.number),
                      _buildDivider(),
                      _buildField(label: '住宿说明', ctrl: _roomNoteCtrl, hint: '价格/预约方式', maxLines: 2),
                    ],
                    const SizedBox(height: 14),
                    const Text('设施服务（可多选）', style: TextStyle(fontSize: 14, color: _textWeak)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _facilityPresets.map((f) {
                        final sel = _facilities.contains(f);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (sel) _facilities.remove(f); else _facilities.add(f);
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: sel ? _primary : _bg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: sel ? _primary : _primary.withValues(alpha: 0.2)),
                            ),
                            child: Text(f, style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                              color: sel ? Colors.white : _primary,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    _buildField(label: '住宿照片', ctrl: _accImgCtrl, hint: '图片URL，多个逗号分隔', maxLines: 2),
                    _buildDivider(),
                    _buildField(label: '公共区域', ctrl: _commonImgCtrl, hint: '餐厅/钓位棚/庭院等，多个逗号分隔', maxLines: 2),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            _buildCard([
              _buildField(label: '联系电话', ctrl: _phoneCtrl, hint: '选填', keyboard: TextInputType.phone),
              _buildDivider(),
              _buildField(label: '微信', ctrl: _wechatCtrl, hint: '选填'),
              _buildDivider(),
              _buildField(label: '负责人', ctrl: _ownerCtrl, hint: '选填'),
              _buildDivider(),
              _buildField(label: '图片URL', ctrl: _imageCtrl, hint: '选填，多个用逗号分隔'),
              _buildDivider(),
              _buildField(label: '简介', ctrl: _descCtrl, hint: '介绍一下这个钓点', maxLines: 3),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '提交后将以「钓友投稿」形式展示，商家可后续认领并维护信息。',
                style: TextStyle(fontSize: 12, color: _primary),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(width: 76, child: Text(label, style: const TextStyle(fontSize: 14, color: _textWeak))),
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: maxLines,
              keyboardType: keyboard,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _textWeak),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() =>
      Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 16), color: const Color(0xFFF0EEE9));

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('类型', style: TextStyle(fontSize: 14, color: _textWeak)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: List.generate(_types.length, (i) {
              final t = _types[i];
              final sel = _type == t;
              final emoji = _typeEmojis[i];
              return GestureDetector(
                onTap: () => setState(() => _type = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? _primary : _bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? _primary : _primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(t, style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? Colors.white : _primary,
                      )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCitySelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(width: 76, child: Text('城市', style: TextStyle(fontSize: 14, color: _textWeak))),
          Expanded(
            child: DropdownButton<String>(
              value: _city,
              isExpanded: true,
              underline: const SizedBox(),
              items: SpotService.cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _city = v!),
            ),
          ),
        ],
      ),
    );
  }
}
