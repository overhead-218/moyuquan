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

/// 钓点数据模型
/// type:野钓 | 斤塘 | 养殖塘 | 农家乐 | 游钓基地
/// fishPeakSeason: 鱼种 → 旺季月份范围（如 '5-10'），仅野钓/游钓基地有意义
/// lastStockingDate / stockingCycleDays: 放鱼提醒，斤塘/黑坑/农家乐等由商家维护
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
    required this.lastStockingDate,
    required this.stockingCycleDays,
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

  /// 综合热度分（越高越靠前）
  double get hotspotScore =>
      viewCount * 0.1 +
      favoriteCount * 3.0 +
      postCount * 10.0 +
      (rating ?? 0) * 20.0 +
      reviewCount * 5.0;

  /// 收费标签文字
  String get priceLabel {
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

  /// 默认实景图池（CC 授权的真实钓鱼/湖泊照，见 assets/images/spots/wm_*.jpg）
  /// 用于没有钓友上传图的钓点兜底，避免渐变占位
  static const List<String> _fallbackImages = [
    'assets/images/spots/wm_01.jpg',
    'assets/images/spots/wm_02.jpg',
    'assets/images/spots/wm_03.jpg',
    'assets/images/spots/wm_04.jpg',
    'assets/images/spots/wm_05.jpg',
    'assets/images/spots/wm_06.jpg',
    'assets/images/spots/wm_07.jpg',
    'assets/images/spots/wm_08.jpg',
    'assets/images/spots/wm_09.jpg',
    'assets/images/spots/wm_10.jpg',
    'assets/images/spots/wm_11.jpg',
    'assets/images/spots/wm_12.jpg',
    'assets/images/spots/wm_13.jpg',
    'assets/images/spots/wm_14.jpg',
    'assets/images/spots/wm_15.jpg',
    'assets/images/spots/wm_16.jpg',
    'assets/images/spots/wm_17.jpg',
    'assets/images/spots/wm_18.jpg',
    'assets/images/spots/wm_19.jpg',
    'assets/images/spots/wm_20.jpg',
    'assets/images/spots/wm_21.jpg',
    'assets/images/spots/wm_22.jpg',
    'assets/images/spots/wm_23.jpg',
    'assets/images/spots/wm_24.jpg',
    'assets/images/spots/wm_25.jpg',
    'assets/images/spots/wm_26.jpg',
    'assets/images/spots/wm_27.jpg',
    'assets/images/spots/wm_28.jpg',
    'assets/images/spots/wm_29.jpg',
    'assets/images/spots/wm_30.jpg',
    'assets/images/spots/wm_31.jpg',
    'assets/images/spots/wm_32.jpg',
    'assets/images/spots/wm_33.jpg',
    'assets/images/spots/wm_34.jpg',
    'assets/images/spots/wm_35.jpg',
    'assets/images/spots/wm_36.jpg',
    'assets/images/spots/wm_37.jpg',
    'assets/images/spots/wm_38.jpg',
    'assets/images/spots/wm_39.jpg',
    'assets/images/spots/wm_40.jpg',
  ];

  /// 展示用头图：有真实图用真实图，否则按 id 稳定取一张兜底实景图
  List<String> get displayImages => images.isNotEmpty
      ? images
      : [_fallbackImages[id.hashCode.abs() % _fallbackImages.length]];

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

  factory Spot.fromJson(Map<String, dynamic> json) {
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
      reviewCount: _asInt(json['reviewCount']) ?? 0,
      viewCount: _asInt(json['viewCount']) ?? 0,
      favoriteCount: _asInt(json['favoriteCount']) ?? 0,
      postCount: _asInt(json['postCount']) ?? 0,
      description: _asStr(json['description']) ?? '',
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'].toString()),
      submitter: SpotSubmitter.values.firstWhere(
        (e) => e.name == json['submitter'],
        orElse: () => SpotSubmitter.operator,
      ),
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
      imagesVerified: _asBool(json['imagesVerified'], false),
    );
  }
}
