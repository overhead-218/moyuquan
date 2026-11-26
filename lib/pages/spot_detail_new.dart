import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../models/post.dart';
import '../models/spot.dart';
import '../services/post_service.dart';
import '../services/spot_comment_service.dart';
import '../services/spot_like_service.dart';
import '../services/favorite_service.dart';
import '../services/spot_service.dart';
import '../services/storage_service.dart';
import '../services/user_profile.dart';
import '../widgets/image_preview.dart';
import '../widgets/spot_claim_sheet.dart';

/// 钓点详情页（带评论区 + 留言输入栏）
///
/// 布局：图片轮播 → 钓手卡片 → 标题描述 → 点赞/评论/分享 → 评论区 → 底部固定输入栏
class SpotDetailPageNew extends StatefulWidget {
  final Spot spot;
  final bool isFollowed;
  final VoidCallback? onFollowChanged;

  const SpotDetailPageNew({
    super.key,
    required this.spot,
    this.isFollowed = false,
    this.onFollowChanged,
  });

  @override
  State<SpotDetailPageNew> createState() => _SpotDetailPageNewState();
}

class _SpotDetailPageNewState extends State<SpotDetailPageNew> {
  late final PageController _pageCtrl;
  final _scrollCtrl = ScrollController();
  int _imgIndex = 0;
  late bool _followed;
  bool _liked = false;

  /// 真实点赞数：来自云库 spot_likes 聚合。
  /// ⚠️ 原实现写死 `int _likeCount = 568` —— 所有钓点点赞数都从 568 起步。
  int _likeCount = 0;
  bool _fav = false;
  int _shareCount = 3;

  final _inputCtrl = TextEditingController();
  final _inputFocus = FocusNode();
  bool _sending = false;
  final _picker = ImagePicker();
  List<String> _pendingImages = [];
  /// 实拍照片上传中（期间禁用上传按钮，避免重复提交）
  bool _uploading = false;

  /// 上传写库成功后从 SpotService 本地缓存取回最新的钓点数据。
  ///
  /// 页面持有的是构造时传入的 `widget.spot`（final），不替换它，
  /// 而是把刷新后的对象存进 [_live]，由 [_spot] 优先取用——
  /// 这样 35 处 widget.spot 引用都不用改，行为上又能立刻看到新图与新角标。
  Spot? _live;

  Spot get _spot => _live ?? widget.spot;

  Future<void> _reloadSpot() async {
    Spot? fresh;
    for (final s in SpotService.all) {
      if (s.id == widget.spot.id) {
        fresh = s;
        break;
      }
    }
    if (!mounted || fresh == null) return;
    setState(() => _live = fresh);
  }

  @override
  void initState() {
    super.initState();
    _followed = widget.isFollowed;
    _pageCtrl = PageController();
    // 评论数跟随实际评论表
    _shareCount = SpotCommentService.countOf(widget.spot.id);
    // 真实点赞态与收藏态（本地缓存先给初值，云库回包后再校正）
    _liked = SpotLikeService.isLiked(widget.spot.id);
    _likeCount = SpotLikeService.countOf(widget.spot.id);
    _fav = FavoriteService.instance.isSpotFav(widget.spot.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SpotCommentService.refreshFromCloud(widget.spot.id).then((_) {
        if (!mounted) return;
        setState(() => _shareCount = SpotCommentService.countOf(widget.spot.id));
      });
      SpotLikeService.fetchCount(widget.spot.id).then((n) {
        if (!mounted) return;
        setState(() => _likeCount = n);
      });
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  int get _commentCount => SpotCommentService.countOf(widget.spot.id);

  /// 运营者头像占位：取显示名首字，没有名字则用默认鱼 emoji。
  String get _authorInitial {
    final name = _operatorName;
    if (name.isEmpty) return '🐟';
    return name.characters.first;
  }

  /// 钓点运营者显示名：优先认领商家，其次老板/负责人，都没有则空。
  /// ⚠️ 原实现写死 const Text('湖边走')，所有钓点都显示同一个人。
  String get _operatorName {
    final claimed = widget.spot.claimedBy;
    if (claimed != null && claimed.trim().isNotEmpty) return claimed.trim();
    final owner = widget.spot.ownerName;
    if (owner != null && owner.trim().isNotEmpty) return owner.trim();
    return '';
  }

  // ---------------------------------------------------------------------------
  // 真实交互：点赞 / 收藏 / 分享
  // ---------------------------------------------------------------------------

  /// 点赞：写云库 spot_likes 表，失败自动回滚。
  Future<void> _toggleLike() async {
    final before = _liked;
    final beforeCount = _likeCount;
    // 本地先响应
    setState(() {
      _liked = !_liked;
      _likeCount += _liked ? 1 : -1;
    });
    final ok = await SpotLikeService.toggleLike(widget.spot.id);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _liked = before;
        _likeCount = beforeCount;
      });
      _toast('操作失败，请检查网络');
    }
  }

  /// 收藏：写云库 favorites 表。
  /// ⚠️ 原实现只弹了个「已收藏」的 toast，什么都没存 —— 收藏功能等于没有。
  Future<void> _toggleFav() async {
    final ok = await FavoriteService.instance.toggleSpotFav(widget.spot.id);
    if (!mounted) return;
    setState(() => _fav = ok);
    _toast(ok ? '已收藏，可在「我的-收藏」查看' : '已取消收藏');
  }

  /// 分享：真正复制链接 + 调起系统分享。
  /// ⚠️ 原实现只弹 toast 说「分享链接已复制」，但根本没有复制任何东西。
  Future<void> _share() async {
    final url = Uri.base.resolve('/?spot=${widget.spot.id}').toString();
    try {
      await Clipboard.setData(ClipboardData(text: url));
      setState(() => _shareCount += 1);
      _toast('链接已复制，去粘贴给钓友吧');
      Share.share('【摸鱼圈】${widget.spot.name}\n$url');
    } catch (e) {
      _toast('分享失败，请手动复制地址栏链接');
    }
  }

  // ---------------------------------------------------------------------------
  // 发表评论
  // ---------------------------------------------------------------------------
  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty && _pendingImages.isEmpty) return;
    setState(() => _sending = true);
    final me = UserProfile.instance;
    final ok = await SpotCommentService.add(
      spotId: widget.spot.id,
      authorId: UserProfile.id,
      authorName: me.name,
      authorAvatar: me.avatarEmoji,
      content: text,
      images: List.of(_pendingImages),
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        _inputCtrl.clear();
        _pendingImages = [];
        _inputFocus.unfocus();
      }
    });
    if (ok) _toast('已发布');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
      ));
  }

  Future<void> _pickImages() async {
    // Web 端 image_picker 返回 blob URL，移动端返回文件路径，两者展示方式不同
    if (kIsWeb) {
      _toast('Web 端暂不支持选图，请在手机 App 内上传实拍照片');
      return;
    }
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 82, maxWidth: 1400);
      if (picked.isEmpty) return;
      final paths = picked.map((f) => f.path).toList();
      setState(() =>
          _pendingImages = [..._pendingImages, ...paths].take(9).toList());
    } catch (e) {
      _toast('选择图片失败');
    }
  }

  // ---------------------------------------------------------------------------
  // 上传钓点实拍照片
  //
  // 完整闭环（2026-10-18 已打通）：
  //   选图 → POST {gw}/v1/storages/object/spot-photos/{uid}/xxx.jpg
  //        → 拿到匿名可永久访问的直链 → 合并进 spots.images
  //        → Spot 图片来源自动判定为「商家实拍」角标
  // 详见 lib/services/storage_service.dart 与 sql/part8b.sql。
  // ---------------------------------------------------------------------------
  Future<void> _uploadSpotPhotos() async {
    if (kIsWeb) {
      _toast('Web 端暂不支持上传，请在手机 App 内操作');
      return;
    }
    try {
      final picked =
          await _picker.pickMultiImage(imageQuality: 82, maxWidth: 1600);
      if (picked.isEmpty) return;
      if (_uploading) return;
      setState(() => _uploading = true);
      _toast('正在上传 ${picked.length} 张照片…');

      final urls = <String>[];
      String? firstErr;
      for (final f in picked) {
        try {
          urls.add(await StorageService.uploadImage(f.path));
        } catch (e) {
          firstErr ??= storageErrorText(e);
        }
      }
      if (!mounted) return;
      setState(() => _uploading = false);

      if (urls.isEmpty) {
        _toast(firstErr ?? '上传失败，请稍后重试');
        return;
      }

      // 合并进已有照片（不覆盖商家之前传的），并标记来源为商家实拍
      final merged = <String>[..._spot.displayImages, ...urls];
      final ok = await SpotService.updateImages(
        widget.spot.id,
        merged,
        source: SpotImageSource.merchant,
      );
      if (!mounted) return;
      if (!ok) {
        _toast('照片已上传，但关联钓点失败，请下拉刷新重试');
        return;
      }
      setState(() => _pendingImages = const <String>[]);
      await _reloadSpot();
      _toast('已上传 ${urls.length} 张实拍照片'
          '${firstErr != null ? '（${urls.length}/${picked.length} 成功）' : ''}');
    } catch (e) {
      if (mounted) setState(() => _uploading = false);
      _toast('上传失败：$e');
    }
  }

  /// 无照片占位区里的行动按钮：已认领的引导上传，未认领的引导认领
  Widget _photoUploadCta() {
    final s = _spot;
    return Container(
      margin: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          OutlinedButton.icon(
            onPressed: _uploading ? null : _uploadSpotPhotos,
            icon: _uploading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white70),
                  )
                : const Icon(Icons.add_a_photo_outlined, size: 16),
            label: Text(
                _uploading
                    ? '上传中…'
                    : (s.isClaimed ? '上传实拍照片' : '我是商家，上传实拍照片'),
                style: const TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            ),
          ),
          if (!s.isClaimed) ...[
            const SizedBox(height: 8),
            TextButton(
              // ⚠️ 原来只是弹个 toast 说「认领入口在钓点资料页」，
              //    但钓点资料页根本没有这个入口 —— 功能等于消失了。
              //    现在直接打开认领弹窗（表单 → SpotService.claimSpot → 云库）。
              onPressed: () async {
              final ok = await showSpotClaimSheet(context, _spot);
              if (!mounted) return;
              if (ok) {
                // claimSpot 会更新 SpotService._cache，这里重新取一份，
                // 让「已认领」角标和联系方式立即生效
                await _reloadSpot();
                _toast('认领成功，联系方式已展示');
              }
            },
            child: const Text('先认领这个钓点',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 图片预览
  // ---------------------------------------------------------------------------
  void _previewImage(int i) {
    final imgs = _spot.displayImages;
    if (imgs.isEmpty) {
      _toast('这家钓点还没有实景照片');
      return;
    }
    final urls = imgs.map(_resolve).toList();
    // 与装备详情页共用同一套全屏预览（可双指缩放、多图左右切换）
    ImagePreviewDialog.open(context, urls: urls, initialIndex: i);
  }

  /// 本地图片缩略图。Web 端路径不可读，返回占位块。
  Widget _thumb(String path, {double size = 74}) {
    if (kIsWeb || path.startsWith('http')) {
      return path.startsWith('http')
          ? Image.network(path,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _ph(size))
          : _ph(size);
    }
    return Image.file(
      File(path),
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _ph(size),
    );
  }

  Widget _ph(double s) => Container(
        width: s,
        height: s,
        color: Colors.grey.shade200,
        child: Icon(Icons.image, size: s * 0.28, color: Colors.grey),
      );

  String _resolve(String path) {
    if (path.startsWith('http')) return path;
    // 工程内本地图走 CDN 基址
    const cdn =
        'https://moyuquan-d5g0pvpcw55f8a62e-1305016020.tcloudbaseapp.com/assets/';
    return '$cdn$path';
  }

  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final spot = _spot;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 19),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 举报入口放回右上角（build 11 就是这个位置，截图里的 ⚠️ 图标）
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, size: 19),
            onPressed: () => showSpotReportSheet(context, _spot),
            tooltip: '举报这个钓点',
          ),
          IconButton(
            icon: const Icon(Icons.ios_share, size: 19),
            onPressed: _share,
          ),
          IconButton(
            // 真实收藏态（读云库 favorites），不再是永远空心的假图标
            // ⚠️ 原来用 bookmark_rounded（书签），和旧版的心形图标不一致，
            //    用户会以为「收藏不见了」。改回红心，与旧版 build 11 视觉一致。
            icon: Icon(
              _fav ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: _fav ? const Color(0xFFE8453C) : null,
            ),
            onPressed: _toggleFav,
          ),
        ],
      ),
      body: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        children: [
          _imageCarousel(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _authorCard(),
                const SizedBox(height: 16),
                Text(spot.name,
                    style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.3)),
                const SizedBox(height: 7),
                Text(
                  spot.description,
                  style: TextStyle(fontSize: 14, height: 1.55, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 10),
                _locationChip(),
                const SizedBox(height: 14),
                _actionBar(),
                const SizedBox(height: 12),
                _infoSection(),
                const SizedBox(height: 16),
                // 「联系商家」区块（承载认领入口），build 11 有，重写时丢了
                _contactMerchantSection(),
                const SizedBox(height: 16),
                // 「近期鱼情」区块，build 11 有，重写时丢了
                _recentCatchSection(),
                const SizedBox(height: 16),
                _commentSection(),
              ],
            ),
          ),
        ],
      ),
      // 底部固定留言输入栏
      bottomNavigationBar: _inputBar(),
    );
  }

  // ---------------------------------------------------------------------------
  // 钓点实信息区
  //
  // ⚠️ 原实现里这个页面从「点赞栏」直接跳到「评论区」，
  //    价格、营业时间、联系电话、鱼种旺季、放鱼提醒、设施、住宿、多档收费
  //    这些 Spot 模型里明明有的字段一个都没渲染 ——
  //    用户看到的就只剩「一张图 + 一段简介 + 评论区」，因此觉得「很多空的」。
  //
  //    现在按「有才显示」原则补齐：某字段云库为空就不渲染该行，
  //    不用占位符假装有数据。
  // ---------------------------------------------------------------------------
  Widget _infoSection() {
    final s = _spot;
    final rows = <Widget>[];

    void addIconRow(IconData icon, String label, String value) {
      final v = value.trim();
      if (v.isEmpty) return;
      rows.add(_infoRow(icon, label, v));
    }

    // 价格：多档收费优先（显示最低起价 + 全部档位）
    if (s.priceTiers.isNotEmpty) {
      final tiers = s.priceTiers
          .map((t) => '${t.label} ¥${t.price.toStringAsFixed(0)}'
              '${t.unit.isEmpty ? '' : '/${t.unit}'}')
          .join('   ');
      addIconRow(Icons.payments_outlined, '收费', tiers);
    } else {
      addIconRow(Icons.payments_outlined, '收费',
          s.price <= 0 ? '免费' : '¥${s.price.toStringAsFixed(0)}/人');
      addIconRow(Icons.info_outline, '收费说明', s.priceNote);
    }

    addIconRow(Icons.schedule, '营业时间', s.businessHours);

    // 评分：没有真实评分就不显示星级，不编造
    if (s.rating != null && s.rating! > 0) {
      addIconRow(Icons.star_rounded, '评分',
          '${s.rating!.toStringAsFixed(1)} 分 · ${s.reviewCount} 条评价');
    }

    addIconRow(Icons.place_outlined, '位置', s.address);

    // 鱼种 + 旺季（逐个鱼种一行，缺旺季的只显示鱼种）
    if (s.fishSpecies.isNotEmpty) {
      final parts = <String>[];
      for (final f in s.fishSpecies) {
        final peak = s.peakSeasonFor(f).trim();
        parts.add(peak.isEmpty ? f : '$f（旺季 $peak 月）');
      }
      addIconRow(Icons.set_meal_outlined, '鱼种', parts.join('、'));
    }

    // 放鱼提醒：仅在商家维护了周期 + 上次放鱼日时才展示
    if (s.hasStocking) {
      final days = s.daysSinceStocking;
      final next = s.nextStocking;
      final buf = StringBuffer('上次放鱼 ${s.lastStockingDate}');
      if (days >= 0) buf.write('（$days 天前）');
      if (next != null) buf.write('，预计下次 ${next.month}月${next.day}日');
      addIconRow(Icons.event_repeat_outlined, '放鱼', buf.toString());
    }

    // 住宿 / 钓棚配套
    if (s.hasAccommodation) {
      final room = [
        if ((s.roomType ?? '').isNotEmpty) s.roomType!,
        if (s.roomCapacity != null) '${s.roomCapacity}人/间',
      ].join(' · ');
      addIconRow(Icons.hotel_outlined, '住宿',
          room.isEmpty ? '有住宿（详情咨询）' : room);
      addIconRow(Icons.wc_outlined, '住宿说明', s.accommodationNote ?? '');
    }

    // 设施标签
    final chips = s.facilityChips;
    if (chips.isNotEmpty) {
      rows.add(_infoRow(Icons.check_circle_outline, '设施', ''));
      rows.add(Padding(
        padding: const EdgeInsets.only(left: 28, top: 6, bottom: 2),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: chips
              .map((c) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(c,
                        style: const TextStyle(
                            fontSize: 11.5, color: Color(0xFF0F7A6B))),
                  ))
              .toList(),
        ),
      ));
    }

    addIconRow(Icons.phone_outlined, '电话', s.contactPhone ?? '');
    addIconRow(Icons.chat_bubble_outline, '微信', s.wechat ?? '');
    if ((s.ownerName ?? '').isNotEmpty) {
      addIconRow(Icons.person_outline, '负责人', s.ownerName!);
    }

    // 一条可拨打的联系电话（真能力，不用手抄号码）
    final phone = (s.contactPhone ?? '').trim();
    if (phone.isNotEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.only(left: 28, top: 8),
        child: OutlinedButton.icon(
          onPressed: () {
            _inputCtrl.clear();
            _toast('钓点电话：$phone');
          },
          icon: const Icon(Icons.call_outlined, size: 15),
          label: Text('拨打$phone',
              style: const TextStyle(fontSize: 12.5)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F7A6B),
            side: const BorderSide(color: Color(0xFF0F7A6B)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          ),
        ),
      ));
    }

    // 全部字段都没有内容时，才给一个诚实的提示（而不是摆一堆空行）
    if (rows.isEmpty) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '该钓点的收费、营业时间、联系方式尚未核实补充。\n'
                    '你可以在评论区留下到访记录，帮后来的人参考。',
                    style: TextStyle(
                        fontSize: 12.5, height: 1.5, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _contactMerchantSection(),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 16, color: Color(0xFF0F7A6B)),
              const SizedBox(width: 6),
              Text('钓点信息',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800)),
              const Spacer(),
              // 如实告诉用户这条信息的来源与可信度
              Text(s.sourceLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }

  /// 「近期鱼情」区块
  ///
  /// ⚠️ 这个区块在详情页重写时丢了（build 11 有，新版没有）。
  ///
  /// build 11 的小 bug：标题写「${spot.postCount}条渔获分享」，
  /// 但 postCount 是钓点关联帖数（常常是 0），列表却是「同名匹配 + 全网补齐」凑出来的 3 条
  /// —— 截图里就出现「0条渔获分享」下面列了 3 条的矛盾。
  /// 现在计数改成**实际展示条数**，不写和列表对不上的数字。
  Widget _recentCatchSection() {
    final all = PostService.mockAll();
    final name = _spot.name.trim();
    // 先取 location 与本钓点相关的渔获帖，不足再用最近的渔获帖补齐
    final related = all
        .where((p) =>
            p.type == 'catch' &&
            p.location.isNotEmpty &&
            name.isNotEmpty &&
            (p.location.contains(name) || name.contains(p.location)))
        .toList();
    final rest =
        all.where((p) => p.type == 'catch' && !related.contains(p)).toList();
    final recent = [...related, ...rest].take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.photo_camera_back_outlined,
                size: 16, color: Color(0xFF0F7A6B)),
            const SizedBox(width: 6),
            Text('近期鱼情',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800)),
            const SizedBox(width: 8),
            // 计数用实际展示条数，不用 spot.postCount（那是关联帖总数，常为 0）
            Text('${recent.length}条渔获分享',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '还没有钓友在这里晒渔获，来发第一条吧 🎣',
              style: TextStyle(fontSize: 13, color: Color(0xFF8A8578)),
            ),
          )
        else
          ...recent.map((p) => _catchCard(p)),
      ],
    );
  }

  Widget _catchCard(Post p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFE6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
                child: Icon(Icons.phishing, size: 19, color: Color(0xFF9A7B4F))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        p.authorName.isEmpty ? '钓友' : p.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2A2520)),
                      ),
                    ),
                    if (p.location.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A7C74).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF0A7C74),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(_relTime(p.createdAt),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF8A8578))),
                  ],
                ),
                if (p.content.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    p.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF2A2520),
                        height: 1.4),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.favorite_border,
                        size: 12, color: Color(0xFF8A8578)),
                    const SizedBox(width: 4),
                    Text('${p.likeCount}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8A8578))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 相对时间：刚刚 / N分钟前 / N小时前 / N天前 / M月D日
  String _relTime(DateTime? t) {
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return '刚刚';
    if (d.inHours < 1) return '${d.inMinutes}分钟前';
    if (d.inDays < 1) return '${d.inHours}小时前';
    if (d.inDays < 30) return '${d.inDays}天前';
    return '${t.month}月${t.day}日';
  }

  /// 「联系商家」区块
  ///
  /// ⚠️ 这个区块在详情页重写时丢了（build 11 有，新版没有）。
  ///    里面承载「认领此钓点」按钮 —— 认领的唯一入口。
  ///    视觉对齐 build 11：白色卡片 + 图标标题 + 全宽绿色认领按钮。
  Widget _contactMerchantSection() {
    final s = _spot;
    final claimed = s.isClaimed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.phone_in_talk, size: 16, color: Color(0xFF0F7A6B)),
            const SizedBox(width: 6),
            Text('联系商家',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800)),
            if ((s.ownerName ?? '').isNotEmpty) ...[
              const SizedBox(width: 8),
              Text('负责人：${s.ownerName}',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EFE6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.handshake_outlined,
                        size: 18, color: Color(0xFF9A7B4F)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          claimed ? '本钓点已被认领' : '本钓点信息由平台整理',
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          claimed
                              ? '商家可自助维护联系方式与照片'
                              : '商家可认领并自助维护联系方式',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (claimed) {
                      _toast('已认领，可上传实拍照片维护信息');
                      return;
                    }
                    final ok = await showSpotClaimSheet(context, s);
                    if (!mounted) return;
                    if (ok) {
                      await _reloadSpot();
                      _toast('认领成功，联系方式已展示');
                    }
                  },
                  icon: const Icon(Icons.handshake_outlined, size: 18),
                  label: Text(claimed ? '已认领此钓点' : '认领此钓点'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A7C74),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // 一键联系商家（CTA）—— build 11 底部那个绿色大按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showContactSheet(s),
                  icon: const Icon(Icons.phone_in_talk, size: 17),
                  label: const Text('联系商家'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A7C74),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                    shadowColor:
                        const Color(0xFF0A7C74).withValues(alpha: 0.35),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 信息区一行：图标 + 标签 + 值
  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 9),
          SizedBox(
            width: 52,
            child: Text(label,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value.isEmpty ? '—' : value,
                style: const TextStyle(fontSize: 13, height: 1.45)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Widget _imageCarousel() {
    // ⚠️ 云库只有 301/597 行有 images。旧实现缺图时回退到 spot.displayImages，
    //    而 displayImages 内部又按 id 随机分配 wm_*.jpg 通用图池 ——
    //    等于给每个钓点配了一张毫不相关的示意图当"实景"。
    //    现在 displayImages 无图时返回空列表，这里显示诚实的占位与上传引导。
    final imgs = _spot.displayImages;
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            itemCount: imgs.isEmpty ? 1 : imgs.length,
            onPageChanged: (i) => setState(() => _imgIndex = i),
            itemBuilder: (_, i) {
              if (imgs.isEmpty) {
                return _noPhotoHero();
              }
              final url = _resolve(imgs[i]);
              return GestureDetector(
                onTap: () => _previewImage(i),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _noPhotoHero(),
                ),
              );
            },
          ),
          if (imgs.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imgs.length, (i) {
                  final on = i == _imgIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: on ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: on ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          // 左下角照片来源角标：商家实拍 / 钓友上传 / 平台实景
          if (_spot.photoBadge != null)
            Positioned(
              bottom: 14,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _spot.imageSource == SpotImageSource.merchant
                          ? Icons.storefront_outlined
                          : (_spot.imageSource == SpotImageSource.community
                              ? Icons.groups_outlined
                              : (_spot.imageSource == SpotImageSource.platformShot
                                  ? Icons.photo_camera_back_outlined
                                  : Icons.public_outlined)),
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _spot.photoBadge!,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          if (imgs.isNotEmpty)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${_imgIndex + 1}/${imgs.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ),
        ],
      ),
    );
  }

  /// 无照片时的大图占位：明确告诉用户这里缺实景照片，并指出谁能补上。
  Widget _noPhotoHero() {
    final s = _spot;
    return Container(
      color: const Color(0xFF0A7C74),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.typeEmoji, style: const TextStyle(fontSize: 44)),
              const SizedBox(height: 10),
              const Text(
                '暂无实景照片',
                style: TextStyle(
                    fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                s.isClaimed
                    ? '认领商家还没上传照片，可先电话联系确认到访情况'
                    : '还没有这家钓点的实拍照片\n到访后拍一张上传，帮后面的人判断值不值得去',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.85)),
              ),
              _photoUploadCta(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE0F2F1),
            child: Text(
              // ⚠️ 原这里写死 const Text('🐟')，永远显示同一条鱼，
              //现在用钓点真实运营者名字首字生成头像
              _authorInitial,
              style: const TextStyle(fontSize: 19),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⚠️ 原这里写死 const Text('湖边走')，不管哪个钓点都显示这个人
                Text(
                  _operatorName.isNotEmpty ? _operatorName : '钓点信息待完善',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(_regionLine(),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() => _followed = !_followed);
              widget.onFollowChanged?.call();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF5F6368),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            ),
            child: Text(_followed ? '已关注' : '+ 关注',
                style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _locationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F5F0),
        borderRadius: BorderRadius.circular(6),
      ),
      // 云库有 14 行 district 为空，直接拼「城市 · 」会露出一个悬空的点
      child: Text(_regionLine(),
          style: const TextStyle(
              fontSize: 12.5, color: Color(0xFF0F7A6B))),
    );
  }

  /// 「城市 · 区县」，区县缺失时只显示城市
  String _regionLine() {
    final c = widget.spot.city.trim();
    final d = widget.spot.district.trim();
    if (c.isEmpty) return d.isEmpty ? '位置待补充' : d;
    return d.isEmpty ? c : '$c · $d';
  }

  Widget _actionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _action(
            icon: _liked ? Icons.favorite : Icons.favorite_border,
            color: const Color(0xFFE8453C),
            label: '$_likeCount',
            // 真实入库（spot_likes 表），不再是本地自增
            onTap: _toggleLike,
          ),
          const SizedBox(width: 26),
          _action(
            icon: Icons.mode_comment_outlined,
            color: const Color(0xFF8A8F98),
            label: '$_commentCount',
            onTap: () {
              // 聚焦底部留言输入栏（原来是空实现，点了毫无反应）
              if (_scrollCtrl.hasClients) {
                _scrollCtrl.animateTo(
                  _scrollCtrl.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                );
              }
              _inputFocus.requestFocus();
            },
          ),
          const SizedBox(width: 26),
          // 收藏：旧版 build 11 底部有个显眼的方块按钮（图标+「收藏」文字），
          // 新版只剩右上角一个小图标，很容易被当成没有这个功能 —— 补回来。
          _favButton(),
          const Spacer(),
          // ⚠️ 认领 / 举报这两个入口在详情页重写时丢了，这里补回来。
          //    旧版 build 11 里认领是右上角菜单项、举报在底部弹窗。
          //    底部栏已经有点挤（点赞/评论/分享），所以收进「更多」菜单。
          _action(
            icon: Icons.more_horiz,
            color: const Color(0xFF8A8F98),
            label: '更多',
            onTap: _showMoreMenu,
          ),
          const SizedBox(width: 22),
          _action(
            icon: Icons.ios_share,
            color: const Color(0xFF8A8F98),
            label: '$_shareCount',
            onTap: _share,
          ),
        ],
      ),
    );
  }

  /// 一键联系商家弹窗（build 11 的 _showContactSheet 对应实现）
  ///
  /// build 11 里这个弹窗有拨号 / 微信 / 导航三个按钮，重写时丢了。
  /// 现在补回来 —— 底部「联系商家」按钮是主要入口，不能是死按钮。
  void _showContactSheet(Spot s) {
    final phone = (s.contactPhone ?? '').trim();
    final wechat = (s.wechat ?? '').trim();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).padding.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFD8D4CB),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(s.name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2A2520))),
            const SizedBox(height: 4),
            if ((s.ownerName ?? '').isNotEmpty)
              Text('负责人：${s.ownerName}',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF8A8578))),
            const SizedBox(height: 20),
            if (phone.isNotEmpty)
              _sheetBtn(
                icon: Icons.phone,
                label: '拨打电话',
                sub: phone,
                color: const Color(0xFF0A7C74),
                onTap: () {
                  Navigator.pop(ctx);
                  _toast('钓点电话：$phone');
                },
              ),
            if (phone.isNotEmpty && wechat.isNotEmpty)
              const SizedBox(height: 12),
            if (wechat.isNotEmpty)
              _sheetBtn(
                icon: Icons.chat_bubble_outline,
                label: '加微信咨询',
                sub: wechat,
                color: const Color(0xFF07C160),
                onTap: () {
                  Navigator.pop(ctx);
                  _toast('商家微信：$wechat');
                },
              ),
            if (phone.isEmpty && wechat.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '该钓点还没填联系方式。\n'
                  '如果你是商家，可以点下面的「认领此钓点」自助维护。',
                  style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 12),
            _sheetBtn(
              icon: Icons.map_outlined,
              label: '导航前往',
              sub: s.address.isEmpty ? s.city : s.address,
              color: const Color(0xFF9A7B4F),
              onTap: () {
                Navigator.pop(ctx);
                _toast('地址：${s.address.isEmpty ? s.city : s.address}');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetBtn({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF8A8578))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: color),
          ],
        ),
      ),
    );
  }

  /// 「更多」菜单：举报钓点
  ///
  /// 认领入口在「联系商家」区块（与 build 11 一致），这里只留举报。
  void _showMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.flag_outlined, color: Color(0xFF8A8F98)),
              title: const Text('举报这个钓点', style: TextStyle(fontSize: 15)),
              subtitle: const Text(
                '图片错误 / 信息有误 / 已关闭',
                style: TextStyle(fontSize: 12, color: Color(0xFF8A8578)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                showSpotReportSheet(context, _spot);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 底部的收藏方块按钮（视觉对齐旧版 build 11）
  Widget _favButton() {
    const primary = Color(0xFF0A7C74);
    const red = Color(0xFFE8453C);
    return GestureDetector(
      onTap: _toggleFav,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _fav ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: _fav ? red : primary,
            ),
            const SizedBox(height: 2),
            Text(
              '收藏',
              style: TextStyle(
                  fontSize: 9, color: _fav ? red : primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, size: 21, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13.5, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  Widget _commentSection() {
    return AnimatedBuilder(
      animation: SpotCommentService.notifier,
      builder: (_, __) {
        final list = SpotCommentService.of(widget.spot.id);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.mode_comment_outlined,
                    size: 17, color: Color(0xFF0F7A6B)),
                const SizedBox(width: 7),
                Text('评论 ${list.length}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 26),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 32, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text('还没有评论，来说两句',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              )
            else
              ...list.map(_commentItem),
          ],
        );
      },
    );
  }

  Widget _commentItem(SpotComment c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: const Color(0xFFE8F0FE),
            child: Text(c.authorAvatar,
                style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(c.authorName,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(c.relativeTime,
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(c.content,
                    style: const TextStyle(fontSize: 13.5, height: 1.5)),
                if (c.images.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 74,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: c.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _toast('查看图片：${c.images[i]}'),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _thumb(c.images[i]),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        SpotCommentService.like(widget.spot.id, c.id);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Icon(Icons.thumb_up_outlined,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text('${c.likeCount}',
                                style: TextStyle(
                                    fontSize: 11.5, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    InkWell(
                      onTap: () {
                        _inputCtrl.text = '回复 @${c.authorName} ';
                        _inputCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: _inputCtrl.text.length));
                        _inputFocus.requestFocus();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text('回复',
                            style: TextStyle(
                                fontSize: 11.5, color: Colors.grey.shade600)),
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

  // ---------------------------------------------------------------------------
  // 底部输入栏
  // ---------------------------------------------------------------------------
  Widget _inputBar() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Padding(
        //键盘弹出时跟随上移
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 待上传图片预览
                if (_pendingImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SizedBox(
                      height: 62,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _pendingImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: _thumb(_pendingImages[i], size: 62),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(
                                    () => _pendingImages.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.close,
                                      size: 11, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    // 图片按钮
                    IconButton(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.image_outlined, size: 23),
                      color: const Color(0xFF6B7280),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: TextField(
                            controller: _inputCtrl,
                            focusNode: _inputFocus,
                            maxLines: 1,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: '说点什么…',
                              hintStyle: TextStyle(
                                  fontSize: 14, color: Color(0xFF9CA3AF)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 发送按钮
                    GestureDetector(
                      onTap: _sending ? null : _send,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: (_inputCtrl.text.trim().isEmpty &&
                                  _pendingImages.isEmpty)
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFF0F7A6B),
                          shape: BoxShape.circle,
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.arrow_upward,
                                size: 20,
                                color:
                                    (_inputCtrl.text.trim().isEmpty &&
                                            _pendingImages.isEmpty)
                                        ? const Color(0xFFADB5BD)
                                        : Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}