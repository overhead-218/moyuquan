/// 钓点来源类型
enum SpotSubmitter {
  operator, // 平台运营录入（种子数据）
  ugc,      // 钓友分享/投稿
  owner,    // 商家认领后自助维护
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
  final double rating;            // 评分 0-5
  final int reviewCount;          // 评价数
  final int viewCount;            // 浏览数（热度用）
  final int favoriteCount;        // 收藏数（热度用）
  final int postCount;            // 关联渔获帖数（热度用）
  final String description;       // 简介
  final DateTime? updatedAt;      // 最后更新
  final SpotSubmitter submitter; // 来源类型（operator/ugc/owner）
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
    required this.rating,
    required this.reviewCount,
    required this.viewCount,
    required this.favoriteCount,
    required this.postCount,
    required this.description,
    this.updatedAt,
    this.submitter = SpotSubmitter.operator,
    this.claimedBy,
    this.claimedAt,
    this.hasAccommodation = false,
    this.roomType,
    this.roomCapacity,
    this.hasWifi = false,
    this.accommodationNote,
    this.accommodationImages = const <String>[],
    this.commonAreaImages = const <String>[],
    this.facilities = const <String>[],
  });

  /// 是否已认领（商家自助维护）
  bool get isClaimed => claimedBy != null;

  /// 综合热度分（越高越靠前）
  double get hotspotScore =>
      viewCount * 0.1 +
      favoriteCount * 3.0 +
      postCount * 10.0 +
      rating * 20.0 +
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

  /// 设施服务标签（合并 WiFi 标识）
  List<String> get facilityChips {
    final s = <String>{...facilities};
    if (hasWifi) s.add('WiFi');
    return s.toList();
  }
}
