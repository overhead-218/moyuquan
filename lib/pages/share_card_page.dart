import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/spot.dart';
import '../services/screenshot_base.dart';
import '../services/screenshot_service_stub.dart'
    if (dart.library.html) '../services/screenshot_service_web.dart';

// ── 共享颜色 / 渐变 ──────────────────────────────────────
const Color _kPrimary = Color(0xFF0A7C74);
const Color _kGold = Color(0xFFC49A5E);
const Color _kBackground = Color(0xFFF7F3EE);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kTextPrimary = Color(0xFF1A1A1A);
const Color _kTextWeak = Color(0xFF888888);
const Color _kRed = Color(0xFFFF4757);
const List<List<Color>> _gradients = [
  [Color(0xFF0A7C74), Color(0xFF148F86)],
  [Color(0xFFC49A5E), Color(0xFFE0B670)],
  [Color(0xFF0E7C7B), Color(0xFF4FA8A8)],
  [Color(0xFF2E8B7B), Color(0xFF5BAE9C)],
  [Color(0xFF1F6F8B), Color(0xFF4A90B8)],
  [Color(0xFF8B5A3C), Color(0xFFB8845C)],
];
const List<Color> _goldGradient = [Color(0xFFC49A5E), Color(0xFFE0B670)];

// ── 分享数据模型 ────────────────────────────────────────
enum ShareKind { post, spot, catchItem }

class PostShareData {
  final String authorName, authorAvatar, title, content, location, imageUrl;
  final int likeCount, commentCount;
  final String postType; // catch | spot | diary
  final int index;
  const PostShareData({
    required this.authorName, required this.authorAvatar, required this.title,
    required this.content, required this.location, required this.imageUrl,
    required this.likeCount, required this.commentCount,
    required this.postType, required this.index,
  });
}

class SpotShareData {
  final String name, typeEmoji, typeLabel, city, district, address, imageUrl;
  final String priceLabel, priceNote;
  final double rating;
  final int reviewCount, hotspotScore;
  final List<String> fishSpecies;
  final bool isClaimed;
  final String? ownerName, contactPhone, wechat;
  const SpotShareData({
    required this.name, required this.typeEmoji, required this.typeLabel,
    required this.city, required this.district, required this.address,
    required this.imageUrl, required this.priceLabel, required this.priceNote,
    required this.rating, required this.reviewCount, required this.hotspotScore,
    required this.fishSpecies, required this.isClaimed,
    this.ownerName, this.contactPhone, this.wechat,
  });
}

extension SpotToShare on Spot {
  SpotShareData toShareData() => SpotShareData(
    name: name, typeEmoji: typeEmoji, typeLabel: type, city: city, district: district,
    address: address, imageUrl: images.isNotEmpty ? images.first : '',
    priceLabel: priceLabel, priceNote: priceNote, rating: rating ?? 0.0,
    reviewCount: reviewCount, hotspotScore: hotspotScore.round(),
    fishSpecies: fishSpecies, isClaimed: isClaimed,
    ownerName: ownerName, contactPhone: contactPhone, wechat: wechat,
  );
}

class CatchShareData {
  final String name, avatar, fish, weight;
  final int rank;
  final String? imageUrl, location;
  const CatchShareData({
    required this.name, required this.avatar, required this.fish,
    required this.weight, required this.rank, this.imageUrl, this.location,
  });
}

String _fmt(int n) =>
    n >= 10000 ? '${(n / 10000).toStringAsFixed(1)}w'
    : n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k'
    : '$n';

Widget _brandBadge(Color bg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.water_drop, size: 11, color: Colors.white),
      SizedBox(width: 3),
      Text('摸鱼圈', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
    ],
  ),
);

// ── 分享页（按类型渲染不同卡片）─────────────────────────
class ShareCardPage extends StatefulWidget {
  final ShareKind kind;
  final Object data;
  const ShareCardPage._(this.kind, this.data);
  ShareCardPage.post(PostShareData d) : this._(ShareKind.post, d);
  ShareCardPage.spot(SpotShareData d) : this._(ShareKind.spot, d);
  ShareCardPage.catchItem(CatchShareData d) : this._(ShareKind.catchItem, d);

  @override
  State<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<ShareCardPage> {
  final GlobalKey _cardKey = GlobalKey();
  bool _saving = false, _sharing = false, _saved = false;

  String get _shareText {
    switch (widget.kind) {
      case ShareKind.spot: return '发现一个宝藏钓点，来摸鱼圈看看～';
      case ShareKind.catchItem: return '我在摸鱼圈钓到大鱼啦！来比比谁的大鱼多';
      case ShareKind.post: return '我在摸鱼圈发现了一个好帖子，快来看看！';
    }
  }

  Future<void> _onSave() async {
    if (_saving) return;
    setState(() => _saving = true);
    final png = await ScreenshotService.capture(_cardKey);
    if (!mounted) return;
    if (png == null) { setState(() => _saving = false); _showMsg('截图失败，请重试'); return; }
    await webDownloadImpl(png, 'moyuquan_${DateTime.now().millisecondsSinceEpoch}.png');
    setState(() { _saving = false; _saved = true; });
    _showMsg('长按图片保存，或截图后通过微信发送');
  }

  Future<void> _onShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final png = await ScreenshotService.capture(_cardKey);
    if (!mounted) return;
    if (png == null) { setState(() => _sharing = false); _showMsg('截图失败，请重试'); return; }
    final xFile = XFile.fromData(png, mimeType: 'image/png', name: 'moyuquan_share.png');
    try {
      await Share.shareXFiles([xFile], text: _shareText);
    } catch (_) {
      await webDownloadImpl(png, 'moyuquan_share.png');
      _showMsg('图片已下载，可通过相册分享');
    }
    if (mounted) setState(() => _sharing = false);
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: _kPrimary, duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardH = screenW * 1.778;
    final imageH = cardH * 0.63;
    final infoH = cardH * 0.37;

    late final Widget cardBody;
    switch (widget.kind) {
      case ShareKind.post:
        final d = widget.data as PostShareData;
        cardBody = _PostShareCard(d: d, screenW: screenW, cardH: cardH, imageH: imageH, infoH: infoH);
        break;
      case ShareKind.spot:
        final d = widget.data as SpotShareData;
        cardBody = _SpotShareCard(d: d, screenW: screenW, cardH: cardH, imageH: imageH, infoH: infoH);
        break;
      case ShareKind.catchItem:
        final d = widget.data as CatchShareData;
        cardBody = _CatchShareCard(d: d, screenW: screenW, cardH: cardH, imageH: imageH, infoH: infoH);
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          Center(child: RepaintBoundary(key: _cardKey, child: cardBody)),
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      ),
                    ),
                    const Spacer(),
                    const Text('保存图片', style: TextStyle(color: Color(0xDDFFFFFF), fontSize: 15, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    const SizedBox(width: 32),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, -4))],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _BottomBtn(icon: _saved ? Icons.check_circle : Icons.download_rounded, label: _saved ? '已保存' : '保存图片', loading: _saving, onTap: _saved ? null : _onSave, primary: false, primaryColor: _kPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _BottomBtn(icon: Icons.share, label: '分享', loading: _sharing, onTap: _onShare, primary: true, primaryColor: _kPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 动态卡（图文流）──────────────────────────────────────
class _PostShareCard extends StatelessWidget {
  final PostShareData d;
  final double screenW, cardH, imageH, infoH;
  const _PostShareCard({required this.d, required this.screenW, required this.cardH, required this.imageH, required this.infoH});

  String get _typeEmoji => d.postType == 'catch' ? '🐟' : d.postType == 'spot' ? '📍' : '📖';
  String get _typeLabel => d.postType == 'catch' ? '渔获' : d.postType == 'spot' ? '钓点' : '日记';

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[d.index % _gradients.length];
    return Container(
      width: screenW, height: cardH, color: _kBackground,
      child: Column(
        children: [
          SizedBox(
            width: screenW, height: imageH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  d.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)), child: Center(child: Text(_typeEmoji, style: const TextStyle(fontSize: 80)))),
                  loadingBuilder: (_, child, prog) => prog == null
                      ? child
                      : Container(decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)), child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))),
                ),
                Positioned(bottom: 0, left: 0, right: 0, height: 70, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _kBackground.withValues(alpha: 0.7)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
                Positioned(top: 14, left: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _kSurface.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(_typeEmoji, style: const TextStyle(fontSize: 13)), const SizedBox(width: 4), Text(_typeLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary))]))),
                Positioned(top: 14, right: 14, child: _brandBadge(_kPrimary)),
                Positioned(bottom: 14, right: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(14)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.favorite, size: 12, color: Colors.white), const SizedBox(width: 3), Text(_fmt(d.likeCount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))]))),
              ],
            ),
          ),
          Container(
            width: screenW, height: infoH, padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Text(d.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kTextPrimary, height: 1.3, letterSpacing: -0.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(d.content, style: const TextStyle(fontSize: 13, color: _kTextWeak, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: _kTextWeak.withValues(alpha: 0.12), width: 0.5))),
                  child: Row(
                    children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: _kPrimary.withValues(alpha: 0.2), width: 1.5)), child: Center(child: Text(d.authorAvatar, style: const TextStyle(fontSize: 18)))),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.authorName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Row(children: [Icon(Icons.location_on_outlined, size: 11, color: _kGold), const SizedBox(width: 2), Expanded(child: Text(d.location, style: const TextStyle(fontSize: 11, color: _kGold, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis))])])),
                      Row(mainAxisSize: MainAxisSize.min, children: [const _Stat(Icons.favorite, _kRed), const SizedBox(width: 10), _Stat(Icons.chat_bubble_outline, _kTextWeak)]),
                    ],
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

// ── 钓点卡（信息卡：价格 / 评分 / 鱼种 / 联系）────────────
class _SpotShareCard extends StatelessWidget {
  final SpotShareData d;
  final double screenW, cardH, imageH, infoH;
  const _SpotShareCard({required this.d, required this.screenW, required this.cardH, required this.imageH, required this.infoH});

  @override
  Widget build(BuildContext context) {
    final fish = d.fishSpecies.take(4).toList();
    final placeholder = Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF0A7C74), const Color(0xFF148F86)])),
      child: Center(child: Text(d.typeEmoji, style: const TextStyle(fontSize: 80))),
    );
    return Container(
      width: screenW, height: cardH, color: _kBackground,
      child: Column(
        children: [
          SizedBox(
            width: screenW, height: imageH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                d.imageUrl.isNotEmpty
                    ? Image.network(d.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
                    : placeholder,
                Positioned(bottom: 0, left: 0, right: 0, height: 70, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, _kBackground.withValues(alpha: 0.7)], begin: Alignment.topCenter, end: Alignment.bottomCenter)))),
                Positioned(top: 14, left: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _kSurface.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Text(d.typeEmoji, style: const TextStyle(fontSize: 13)), const SizedBox(width: 4), Text(d.typeLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary))]))),
                Positioned(top: 14, right: 14, child: _brandBadge(_kPrimary)),
                Positioned(bottom: 14, left: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _kGold, borderRadius: BorderRadius.circular(14)), child: Text(d.priceLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)))),
              ],
            ),
          ),
          Container(
            width: screenW, height: infoH, padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Text(d.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kTextPrimary, height: 1.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [Icon(Icons.location_on_outlined, size: 13, color: _kGold), const SizedBox(width: 3), Expanded(child: Text('${d.city}·${d.district}', style: const TextStyle(fontSize: 12, color: _kGold, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                const SizedBox(height: 10),
                if (fish.isNotEmpty)
                  Wrap(spacing: 8, runSpacing: 8, children: fish.map((f) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)), child: Text(f, style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w500)))).toList()),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: _kTextWeak.withValues(alpha: 0.12), width: 0.5))),
                  child: Row(
                    children: [
                      const _Stat(Icons.star, const Color(0xFFFFB020)),
                      const SizedBox(width: 14),
                      _Stat(Icons.local_fire_department, _kGold),
                      const Spacer(),
                      _contactMini(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('来摸鱼圈，发现更多好钓点', style: TextStyle(fontSize: 11, color: _kTextWeak)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contactMini() {
    if (d.isClaimed && d.contactPhone != null) {
      return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.phone, size: 12, color: Colors.white), SizedBox(width: 3), Text('电话', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))]));
    }
    if (d.isClaimed && d.wechat != null) {
      return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF07C160), borderRadius: BorderRadius.circular(12)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.chat_bubble_outline, size: 12, color: Colors.white), SizedBox(width: 3), Text('微信', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))]));
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: _kTextWeak.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Text('商家可认领', style: TextStyle(fontSize: 11, color: _kTextWeak)));
  }
}

// ── 渔获卡（战绩大字报）──────────────────────────────────
class _CatchShareCard extends StatelessWidget {
  final CatchShareData d;
  final double screenW, cardH, imageH, infoH;
  const _CatchShareCard({required this.d, required this.screenW, required this.cardH, required this.imageH, required this.infoH});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: screenW, height: cardH, color: _kBackground,
      child: Column(
        children: [
          SizedBox(
            width: screenW, height: imageH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(decoration: BoxDecoration(gradient: LinearGradient(colors: _goldGradient, begin: Alignment.topLeft, end: Alignment.bottomRight))),
                Positioned(top: 14, left: 14, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.emoji_events, size: 13, color: _kGold), const SizedBox(width: 4), Text('大鱼榜 第${d.rank}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8A6D1F)))]))),
                Positioned(top: 14, right: 14, child: _brandBadge(const Color(0xFFB8845C))),
                Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(d.weight, style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white, height: 1, shadows: [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))])), const SizedBox(height: 6), Text(d.fish, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white))])),
              ],
            ),
          ),
          Container(
            width: screenW, height: infoH, padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _kGold.withValues(alpha: 0.4))), child: Center(child: Text(d.avatar, style: const TextStyle(fontSize: 20)))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kTextPrimary)), d.location != null && d.location!.isNotEmpty ? Text(d.location!, style: const TextStyle(fontSize: 12, color: _kTextWeak)) : const Text('晒出今日渔获', style: TextStyle(fontSize: 12, color: _kTextWeak))])),
                  ],
                ),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(border: Border(top: BorderSide(color: _kTextWeak.withValues(alpha: 0.12), width: 0.5))), child: const Center(child: Text('来摸鱼圈，晒渔获上大鱼榜', style: TextStyle(fontSize: 12, color: _kTextWeak, fontWeight: FontWeight.w500)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon; final String count; final Color color;
  const _Stat(this.icon, this.color, [this.count = '']);
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      if (count.isNotEmpty) ...[
        const SizedBox(width: 3),
        Text(count, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    ],
  );
}

class _BottomBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final bool primary;
  final Color primaryColor;

  const _BottomBtn({required this.icon, required this.label, this.loading = false, this.onTap, required this.primary, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: primary ? primaryColor : const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(14),
          border: primary ? null : Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 7),
                    Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  ],
                ),
        ),
      ),
    );
  }
}
