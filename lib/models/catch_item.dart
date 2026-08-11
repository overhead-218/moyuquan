// No external imports needed

/// 钓友渔获 / 战绩
class CatchItem {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String fish;
  final double weight; // kg
  final double? length; // cm
  final String? spotId;
  final String? spotName;
  final String? city;
  final List<String> images;
  final String? note;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final bool verified; // 是否大鱼认证

  const CatchItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.fish,
    required this.weight,
    this.length,
    this.spotId,
    this.spotName,
    this.city,
    this.images = const [],
    this.note,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.verified = false,
  });

  /// 大鱼认证门槛（≥5kg）
  bool get isBigFish => weight >= 5.0;

  /// 新手判定（注册30天内 - 需配合用户注册时间）
  bool isNewcomer(DateTime userRegisteredAt) {
    final diff = createdAt.difference(userRegisteredAt);
    return diff.inDays <= 30;
  }

  /// 积分计算（赛季榜用）
  int get points {
    int p = 0;
    p += 1; // 发帖+1
    p += likes; // 获赞+1/次
    if (verified) p += 10; // 大鱼认证+10
    return p;
  }
}
