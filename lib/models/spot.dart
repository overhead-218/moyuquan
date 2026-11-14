/// 钓点来源类型
enum SpotSubmitter {
  operator, // 平台运营录入（种子数据）
  ugc,      // 钓友分享/投稿
  owner,    // 商家认领后自助维护
}

/// 钓点审核状态
enum SpotStatus {
  active,   // 已核实：有具体联系方式/地点/在经营
  pending,  // 待核实：缺联系方式或搜不到公开信息，先隐藏
}

/// 钓点图片来源
///
/// ⚠️ 2026-10-18 之前，详情页/首页对没有图片的钓点直接回退到工程内置的
///    `wm_*.jpg` 兜底图池（40 张通用钓鱼照）。结果同一张图会被分配给几十个
///    完全不同的钓点 —— 用户看到「阳宗海滩双基地」配了一张通用钓鱼剪影，
///    以为那就是这个钓点的实景。这是**用假图冒充实景**，必须停掉。
///
///    现在改为如实分级：只有商家/钓友真的上传过的照片才算这个钓点的实景；
///    平台采集的公共图库照单独标为「平台实景」，与商家实拍区分开；
///    两者都没有时**不显示任何照片**，只给占位和上传引导。
enum SpotImageSource {
  none,       // 无照片：显示占位，不配图
  merchant,   // 商家认领后上传的实拍 —— 最高优先级
  community,  // 钓友投稿上传
  platform,   // 平台采集的公共图库照（Wikimedia 等，非本钓点专属实景）
  platformShot, // 平台方实地拍摄/提供的该钓点专属实景照片（imagesVerified=true）
}

/// 钓点数据模型
/// type:野钓 | 斤塘 | 养殖塘 | 农家乐 | 游钓基地
/// fishPeakSeason: 鱼种 → 旺季月份范围（如 '5-10'），仅野钓/游钓基地有意义
/// lastStockingDate / stockingCycleDays: 放鱼提醒，斤塘/黑坑/农家乐等由商家维护
/// 多档收费：同一钓点的不同房型 / 钓法价格（如老棚 / 新棚 / 筏钓 / 路亚带艇）
class PriceTier {
  final String label;   // 房型 / 类型，如「老棚」「新棚」「筏钓」「路亚带艇」
  final double price;   // 价格（元），0=免费
  final String unit;    // 计费单位，如「人/天」「位/天」「4小时」「间/晚」
  final String? note;   // 补充说明（含三餐 / 定金 / 其他）

  const PriceTier({
    required this.label,
    required this.price,
    this.unit = '',
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'price': price,
    'unit': unit,
    'note': note,
  };

  factory PriceTier.fromJson(Map<String, dynamic> json) => PriceTier(
    label: json['label']?.toString() ?? '',
    price: json['price'] is num ? (json['price'] as num).toDouble() : 0,
    unit: json['unit']?.toString() ?? '',
    note: json['note']?.toString(),
  );
}

class Spot {
  final String id;
  final String name;
  final String type;              // 野钓 | 斤塘 | 养殖塘 | 农家乐 | 游钓基地
  final String typeEmoji;
  final String city;              // 所在城市
  final String district;          // 区县
  final String address;
  final double latitude;
  final double longitude;
  final List<String> images;      // 图片列表（最多6张）
  final List<String> fishSpecies; // 鱼种列表
  final Map<String, String> fishPeakSeason; // {鱼种: '5-10'} 旺季月份范围（野钓/游钓用）
  final String? lastStockingDate;            // 上次放鱼日 yyyy-MM-dd（商家维护，null=天然水域）
  final int stockingCycleDays;               // 放鱼周期（天），0=天然水域无需放鱼
  final double price;             // 钓费（元），0=免费
  final String priceNote;         // 计费说明
  final String businessHours;     // 营业时间
  final String? contactPhone;     // 联系电话
  final String? wechat;           // 微信
  final String? ownerName;        // 老板/负责人
  final double? rating;           // 评分 0-5（可空：暂无评分时为 null）
  final int reviewCount;          // 评价数
  final int viewCount;            // 浏览数（热度用）
  final int favoriteCount;        // 收藏数（热度用）
  final int postCount;            // 关联渔获帖数（热度用）
  final String description;       // 简介
  final DateTime? updatedAt;      // 最后更新
  final SpotSubmitter submitter; // 来源类型（operator/ugc/owner）
  final SpotStatus status;       // 审核状态（active/pending）
  final String? claimedBy;        // 认领商家/用户昵称（null=未认领）
  final DateTime? claimedAt;      // 认领时间

  // ── 住宿信息（野钓/游钓基地常见）───────────────────────
  final bool hasAccommodation;    // 是否有住宿
  final String? roomType;         // 房型："空调标间" | "普通间" | "多人间" | "帐篷位" 等
  final int? roomCapacity;        // 几人/间，null=不区分
  final bool hasWifi;            // 是否有WiFi
  final String? accommodationNote; // 住宿补充说明（价格区间、订房方式等）
  final List<String> accommodationImages; // 住宿照片（客房/钓棚）
  final List<String> commonAreaImages;   // 公共区域照片（餐厅/钓位棚/庭院）
  final List<String> facilities;         // 设施服务标签（WiFi/停车场/餐厅/淋浴热水…）
  final Map<String, String> imageCaptions; // 图片路径→分类说明（如「豪华筏钓房」「路亚艇60匹」「钓货：米级翘嘴」），详情页在图右上加 chip
  final bool imagesVerified; // true=有钓点专属真实照片；false=仅用示意图/兜底图（非实景）
  final SpotImageSource imageSource; // 图片来源（none/merchant/community/platform）
  final List<PriceTier> priceTiers; // 多档收费（房型/钓法不同价），空=用 price/priceNote 单档

  const Spot({
    required this.id,
    required this.name,
    required this.type,
    required this.typeEmoji,
    required this.city,
    required this.district,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.images,
    required this.fishSpecies,
    required this.fishPeakSeason,
    this.lastStockingDate,
    this.stockingCycleDays = 0,
    required this.price,
    required this.priceNote,
    required this.businessHours,
    this.contactPhone,
    this.wechat,
    this.ownerName,
    this.rating,
    this.reviewCount = 0,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.postCount = 0,
    required this.description,
    this.updatedAt,
    this.submitter = SpotSubmitter.operator,
    this.claimedBy,
    this.claimedAt,
    this.status = SpotStatus.active,
    this.hasAccommodation = false,
    this.roomType,
    this.roomCapacity,
    this.hasWifi = false,
    this.accommodationNote,
    this.accommodationImages = const <String>[],
    this.commonAreaImages = const <String>[],
    this.facilities = const <String>[],
    this.imageCaptions = const <String, String>{},
    this.imagesVerified = false,
    this.imageSource = SpotImageSource.none,
    this.priceTiers = const <PriceTier>[],
  });

  /// 单张图获取分类说明（null = 无说明，不渲染 chip）
  String? captionFor(String imagePath) {
    if (imageCaptions.isEmpty) return null;
    if (imageCaptions.containsKey(imagePath)) return imageCaptions[imagePath];
    // 也匹配 basename（如「assets/images/spots/s251_01.png」→「s251_01.png」）
    final base = imagePath.split('/').last;
    if (imageCaptions.containsKey(base)) return imageCaptions[base];
    return null;
  }

  /// 是否已认领（商家自助维护）
  bool get isClaimed => claimedBy != null;

  /// 来源标签（短）：详情页顶部信息条用
  String get sourceLabel {
    if (isClaimed) return '已认领 · 商家';
    switch (submitter) {
      case SpotSubmitter.ugc:
        return '钓友分享';
      case SpotSubmitter.owner:
        return '商家自营';
      case SpotSubmitter.operator:
        return '平台采集 · 商家入驻中';
    }
  }

  /// 价格出处标签：价格区块徽章用
  String get priceSourceLabel {
    if (isClaimed) return '商家认证价';
    switch (submitter) {
      case SpotSubmitter.ugc:
        return '钓友分享价（以商家实际为准）';
      case SpotSubmitter.owner:
        return '商家自营价';
      case SpotSubmitter.operator:
        return '平台采集参考价（商家入驻中）';
    }
  }

  /// 综合热度分（越高越靠前）
  double get hotspotScore =>
      viewCount * 0.1 +
      favoriteCount * 3.0 +
      postCount * 10.0 +
      (rating ?? 0) * 20.0 +
      reviewCount * 5.0;

  /// 收费标签文字（有多档时显示最低起价）
  String get priceLabel {
    if (priceTiers.isNotEmpty) {
      final min = priceTiers.map((t) => t.price).reduce((a, b) => a < b ? a : b);
      if (min == 0) return '免费起';
      return '¥${min.toStringAsFixed(0)}起';
    }
    if (price == 0) return '免费';
    return '¥${price.toStringAsFixed(0)}/人';
  }

  /// 类型标签文字
  String get typeLabel => type;

  /// 鱼种旺季月份范围（如 '5-10'，空串=无数据）
  String peakSeasonFor(String fish) => fishPeakSeason[fish] ?? '';

  /// 是否需展示放鱼提醒（斤塘/黑坑/农家乐等，天然水域为 false）
  bool get hasStocking => stockingCycleDays > 0 && lastStockingDate != null;

  /// 上次放鱼日（解析失败返回 null）
  DateTime? get lastStocking {
    if (lastStockingDate == null) return null;
    return DateTime.tryParse(lastStockingDate!);
  }

  /// 距上次放鱼天数（-1=无数据）
  int get daysSinceStocking {
    final l = lastStocking;
    if (l == null) return -1;
    return DateTime.now().difference(l).inDays;
  }

  /// 预计下次放鱼日
  DateTime? get nextStocking {
    final l = lastStocking;
    if (l == null || stockingCycleDays <= 0) return null;
    return l.add(Duration(days: stockingCycleDays));
  }

  /// 是否展示「住宿 / 钓棚配套」区块（任一住宿信息存在即展示）
  bool get hasLodgingInfo =>
      hasAccommodation ||
      accommodationImages.isNotEmpty ||
      commonAreaImages.isNotEmpty ||
      facilities.isNotEmpty;

  /// 头图轮播「全部」分类的图片顺序：钓点 > 住宿 > 公共区域
  List<String> get galleryImages =>
      [...images, ...accommodationImages, ...commonAreaImages];

  /// 展示用头图。
  ///
  /// ⚠️ 2026-10-18 重大行为变更：这里**只保留真实网络照片**。
  ///    旧实现按 `id.hashCode % 40` 给每个钓点随机分配一张 `wm_*.jpg`
  ///    通用钓鱼照，导致「阳宗海滩双基地」这种具体钓点配了一张毫不相关的示意图。
  ///
  /// 云库实测（597 行）还发现两类假数据已在前端被当作实景展示：
  ///    · 250 行 images 写的是 `assets/images/spots/wm_02.jpg` 通用图池
  ///    · 其余行写的是 `assets/images/spots/spot_001.jpg`，但抽查文件内容发现
  ///      与钓点毫无关系（spot_001 是菠萝、spot_025 是东京街道、spot_060 是洛杉矶夕阳）
  ///
  /// 现在规则：**只有 http(s) 开头的真实网络照片才展示**，
  /// 工程内置的本地 asset 一律视为非实景。
  /// 商家/钓友上传照片后写入 http(s) URL，会自动成为该钓点的实景并优先展示。
  List<String> get displayImages => images
      .where((u) => u.trim().isNotEmpty)
      .where((u) => u.startsWith('http'))
      .toList(growable: false);

  /// 是否有可用照片。false 时 UI 必须显示占位，不能配任何示意/兜底图。
  bool get hasPhoto => displayImages.isNotEmpty;

  /// 照片角标文案（右上/左下角显示，如「商家实拍」「平台实景」）。
  /// 无照片时返回 null（不显示角标）。
  String? get photoBadge {
    switch (imageSource) {
      case SpotImageSource.merchant:
        return '商家实拍';
      case SpotImageSource.community:
        return '钓友上传';
      case SpotImageSource.platformShot:
        // 该钓点的专属实景照片（平台方实地拍摄/提供），不是公共图库照
        return '平台实拍';
      case SpotImageSource.platform:
        // 平台采集的是景区/湖泊公共图库照，不等于这个钓点的实景，必须说清楚
        return '平台实景 · 非本钓点专属';
      case SpotImageSource.none:
        return null;
    }
  }

  /// 设施服务标签（合并 WiFi 标识）
  List<String> get facilityChips {
    final s = <String>{...facilities};
    if (hasWifi) s.add('WiFi');
    return s.toList();
  }

  // ── 云库序列化（字段名与数据库列名 1:1，避免映射错配）────────
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'typeEmoji': typeEmoji,
    'city': city,
    'district': district,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'images': images,
    'fishSpecies': fishSpecies,
    'fishPeakSeason': fishPeakSeason,
    'lastStockingDate': lastStockingDate,
    'stockingCycleDays': stockingCycleDays,
    'price': price,
    'priceNote': priceNote,
    'businessHours': businessHours,
    'contactPhone': contactPhone,
    'wechat': wechat,
    'ownerName': ownerName,
    'rating': rating,
    'reviewCount': reviewCount,
    'viewCount': viewCount,
    'favoriteCount': favoriteCount,
    'postCount': postCount,
    'description': description,
    'updatedAt': updatedAt?.toIso8601String(),
    'submitter': submitter.name,
    'status': status.name,
    'claimedBy': claimedBy,
    'claimedAt': claimedAt?.toIso8601String(),
    'hasAccommodation': hasAccommodation,
    'roomType': roomType,
    'roomCapacity': roomCapacity,
    'hasWifi': hasWifi,
    'accommodationNote': accommodationNote,
    'accommodationImages': accommodationImages,
    'commonAreaImages': commonAreaImages,
    'facilities': facilities,
    'imageCaptions': imageCaptions,
    'imagesVerified': imagesVerified,
    // ⚠️ imageSource 是派生字段（由 images/submitter/imagesVerified 实时算出），
    //    云库 spots 表【没有】imageSource 列。写进去会导致 insert/upsert 整条
    //    报 PGRST204（unknown column），连带商家提交/编辑钓点全部失败。
    'priceTiers': priceTiers.map((t) => t.toJson()).toList(),
  };

  static List<String> _asList(dynamic v) {
    if (v == null) return const <String>[];
    if (v is List) return v.map((e) => e?.toString() ?? '').toList();
    return const <String>[];
  }

  static Map<String, String> _asMap(dynamic v) {
    if (v == null) return const <String, String>{};
    if (v is Map) {
      return v.map((k, e) => MapEntry(k.toString(), e?.toString() ?? ''));
    }
    return const <String, String>{};
  }

  static List<PriceTier> _asTiers(dynamic v) {
    if (v == null) return const <PriceTier>[];
    if (v is List) {
      return v.whereType<Map>().map((e) => PriceTier.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return const <PriceTier>[];
  }

  static double _asDouble(dynamic v, [double d = 0]) {
    if (v == null) return d;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? d;
  }

  static int _asInt(dynamic v, [int d = 0]) {
    if (v == null) return d;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? d;
  }

  static bool _asBool(dynamic v, [bool d = false]) {
    if (v == null) return d;
    if (v is bool) return v;
    if (v is num) return v != 0;
    return d;
  }

  static String? _asStr(dynamic v) => v == null ? null : v.toString();

  /// 判定图片来源。
  ///
  /// 优先级：商家认领 > 平台实拍 > 钓友投稿 > 平台采集。
  /// 云库里 `images` 为 http 开头的是平台采集的公共图库照（Wikimedia 等），
  /// 它们是真实存在的湖泊/景区照片，但**不是这个钓点的实景**，只能标「平台实景」。
  ///
  /// imagesVerified=true 表示「这个钓点确实有专属实拍照片」。
  /// 此时再按 submitter 细分：
  ///   owner    → 商家实拍（商家自己拍的）
  ///   operator → 平台实拍（平台方实地拍到/提供的该钓点专属照片）
  ///   ugc      → 钓友上传
  static SpotImageSource _resolveImageSource(
      List<String> rawImages, SpotSubmitter submitter, bool verified) {
    // 只认 http(s) 真实照片：本地 asset 全是假图/通用图池
    final images = rawImages.where((u) => u.startsWith('http')).toList();
    if (images.isEmpty) return SpotImageSource.none;
    if (verified) {
      switch (submitter) {
        case SpotSubmitter.owner:
          return SpotImageSource.merchant;
        case SpotSubmitter.operator:
          return SpotImageSource.platformShot;
        case SpotSubmitter.ugc:
          return SpotImageSource.community;
      }
    }
    // 非认领来源一律视为平台采集（含 Wikimedia 公共图库照）
    return submitter == SpotSubmitter.owner
        ? SpotImageSource.merchant
        : SpotImageSource.platform;
  }

  factory Spot.fromJson(Map<String, dynamic> json) {
    final submitter = SpotSubmitter.values.firstWhere(
      (e) => e.name == json['submitter'],
      orElse: () => SpotSubmitter.operator,
    );
    final images = _asList(json['images']);
    final verified = _asBool(json['imagesVerified'], false);
    return Spot(
      id: _asStr(json['id']) ?? '',
      name: _asStr(json['name']) ?? '',
      type: _asStr(json['type']) ?? '野钓',
      typeEmoji: _asStr(json['typeEmoji']) ?? '🐟',
      city: _asStr(json['city']) ?? '',
      district: _asStr(json['district']) ?? '',
      address: _asStr(json['address']) ?? '',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      images: _asList(json['images']),
      fishSpecies: _asList(json['fishSpecies']),
      fishPeakSeason: _asMap(json['fishPeakSeason']),
      lastStockingDate: _asStr(json['lastStockingDate']),
      stockingCycleDays: _asInt(json['stockingCycleDays']),
      price: _asDouble(json['price']),
      priceNote: _asStr(json['priceNote']) ?? '',
      businessHours: _asStr(json['businessHours']) ?? '',
      contactPhone: _asStr(json['contactPhone']),
      wechat: _asStr(json['wechat']),
      ownerName: _asStr(json['ownerName']),
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : null,
      // _asInt 已带默认值，这里的 ?? 0 永远走不到
      reviewCount: _asInt(json['reviewCount']),
      viewCount: _asInt(json['viewCount']),
      favoriteCount: _asInt(json['favoriteCount']),
      postCount: _asInt(json['postCount']),
      description: _asStr(json['description']) ?? '',
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
      submitter: submitter,
      status: SpotStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SpotStatus.active,
      ),
      claimedBy: _asStr(json['claimedBy']),
      claimedAt: json['claimedAt'] == null
          ? null
          : DateTime.tryParse(json['claimedAt'].toString()),
      hasAccommodation: _asBool(json['hasAccommodation']),
      roomType: _asStr(json['roomType']),
      roomCapacity: json['roomCapacity'] == null
          ? null
          : _asInt(json['roomCapacity']),
      hasWifi: _asBool(json['hasWifi']),
      accommodationNote: _asStr(json['accommodationNote']),
      accommodationImages: _asList(json['accommodationImages']),
      commonAreaImages: _asList(json['commonAreaImages']),
      facilities: _asList(json['facilities']),
      imageCaptions: _asMap(json['imageCaptions']),
      imagesVerified: verified,
      imageSource: _resolveImageSource(images, submitter, verified),
      priceTiers: _asTiers(json['priceTiers']),
    );
  }
}
