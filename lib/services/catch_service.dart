import '../models/catch_item.dart';

/// 渔获服务 / 榜单数据源
class CatchService {
  static final List<CatchItem> _mockCatches = [
    // 重量榜 TOP 数据（大鱼认证）
    CatchItem(
      id: 'c001',
      userId: 'u001',
      userName: '海钓阿强',
      fish: '蓝鳍金枪鱼',
      weight: 164.25, // 328.5斤
      spotName: '万山群岛',
      city: '珠海',
      images: ['https://picsum.photos/seed/c001/800/500'],
      note: '搏斗了2小时才上岸！',
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      likes: 328,
      verified: true,
    ),
    CatchItem(
      id: 'c002',
      userId: 'u002',
      userName: '钓鱼王',
      fish: '青鱼',
      weight: 64.3, // 128.6斤
      spotName: '升钟湖',
      city: '南充',
      images: ['https://picsum.photos/seed/c002/800/500'],
      note: '守了三天终于来了！',
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      likes: 186,
      verified: true,
    ),
    CatchItem(
      id: 'c003',
      userId: 'u003',
      userName: '老李',
      fish: '草鱼',
      weight: 48.1, // 96.2斤
      spotName: '千岛湖',
      city: '杭州',
      images: ['https://picsum.photos/seed/c003/800/500'],
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      likes: 142,
      verified: true,
    ),
    CatchItem(
      id: 'c004',
      userId: 'u004',
      userName: '阿飞',
      fish: '鲶鱼',
      weight: 41.15, // 82.3斤
      spotName: '丹江口',
      city: '十堰',
      images: ['https://picsum.photos/seed/c004/800/500'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      likes: 98,
      verified: true,
    ),
    CatchItem(
      id: 'c005',
      userId: 'u005',
      userName: '菜鸟',
      fish: '鲤鱼',
      weight: 34.4, // 68.8斤
      spotName: '云鹏水库',
      city: '昆明',
      images: ['https://picsum.photos/seed/c005/800/500'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      likes: 67,
      verified: true,
    ),
    CatchItem(
      id: 'c006',
      userId: 'u006',
      userName: '野钓大叔',
      fish: '黑鱼',
      weight: 27.05, // 54.1斤
      spotName: '柴石滩',
      city: '昆明',
      images: ['https://picsum.photos/seed/c006/800/500'],
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      likes: 54,
    ),
    CatchItem(
      id: 'c007',
      userId: 'u007',
      userName: '江南老饕',
      fish: '鳜鱼',
      weight: 21.35, // 42.7斤
      spotName: '西溪湿地',
      city: '杭州',
      images: ['https://picsum.photos/seed/c007/800/500'],
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      likes: 43,
    ),
    CatchItem(
      id: 'c008',
      userId: 'u008',
      userName: '渔民小张',
      fish: '鲈鱼',
      weight: 19.45, // 38.9斤
      spotName: '玉龙湾',
      city: '昆明',
      images: ['https://picsum.photos/seed/c008/800/500'],
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      likes: 38,
    ),
    // 更多渔获（用于数量榜）
    CatchItem(
      id: 'c009',
      userId: 'u001',
      userName: '海钓阿强',
      fish: '黄鳍鲷',
      weight: 2.3,
      spotName: '万山群岛',
      city: '珠海',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      likes: 23,
    ),
    CatchItem(
      id: 'c010',
      userId: 'u001',
      userName: '海钓阿强',
      fish: '石斑鱼',
      weight: 1.8,
      spotName: '万山群岛',
      city: '珠海',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likes: 18,
    ),
    CatchItem(
      id: 'c011',
      userId: 'u003',
      userName: '老李',
      fish: '鲫鱼',
      weight: 0.8,
      spotName: '千岛湖',
      city: '杭州',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      likes: 12,
    ),
    CatchItem(
      id: 'c012',
      userId: 'u003',
      userName: '老李',
      fish: '鲤鱼',
      weight: 3.2,
      spotName: '千岛湖',
      city: '杭州',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      likes: 15,
    ),
    CatchItem(
      id: 'c013',
      userId: 'u005',
      userName: '菜鸟',
      fish: '草鱼',
      weight: 4.1,
      spotName: '云鹏水库',
      city: '昆明',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likes: 8,
    ),
    // 新手渔获（注册30天内）
    CatchItem(
      id: 'c014',
      userId: 'u009',
      userName: '路亚新手',
      fish: '鲈鱼',
      weight: 1.5,
      spotName: '玉龙湾',
      city: '昆明',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      likes: 6,
    ),
    CatchItem(
      id: 'c015',
      userId: 'u009',
      userName: '路亚新手',
      fish: '翘嘴',
      weight: 2.2,
      spotName: '玉龙湾',
      city: '昆明',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likes: 9,
    ),
    CatchItem(
      id: 'c016',
      userId: 'u010',
      userName: '钓鱼小白',
      fish: '鲫鱼',
      weight: 0.5,
      spotName: '玄武湖',
      city: '南京',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      likes: 3,
    ),
  ];

  /// 获取所有渔获
  static List<CatchItem> get all => _mockCatches;

  /// 重量榜（单尾最重，前50）
  static List<CatchItem> weightRanking({int limit = 50}) {
    final sorted = List<CatchItem>.from(_mockCatches)
      ..sort((a, b) => b.weight.compareTo(a.weight));
    return sorted.take(limit).toList();
  }

  /// 数量榜（本周累计尾数）
  static List<Map<String, dynamic>> countRanking({int limit = 20}) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    final counts = <String, int>{};
    final userInfo = <String, CatchItem>{};
    
    for (final c in _mockCatches) {
      if (c.createdAt.isAfter(weekStart)) {
        counts[c.userId] = (counts[c.userId] ?? 0) + 1;
        userInfo[c.userId] = c;
      }
    }
    
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => {
      'userId': e.key,
      'userName': userInfo[e.key]!.userName,
      'count': e.value,
      'latestCatch': userInfo[e.key],
    }).toList();
  }

  /// 赛季榜（积分累计）
  static List<Map<String, dynamic>> seasonRanking({int limit = 50}) {
    final points = <String, int>{};
    final userInfo = <String, CatchItem>{};
    
    for (final c in _mockCatches) {
      points[c.userId] = (points[c.userId] ?? 0) + c.points;
      userInfo[c.userId] = c;
    }
    
    final sorted = points.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => {
      'userId': e.key,
      'userName': userInfo[e.key]!.userName,
      'points': e.value,
      'topCatch': userInfo[e.key],
    }).toList();
  }

  /// 新秀榜（注册30天内，按积分）
  static List<Map<String, dynamic>> rookieRanking({
    int limit = 20,
  }) {
    final newcomerIds = <String>{};
    final points = <String, int>{};
    final userInfo = <String, CatchItem>{};
    
    // 假设新用户注册时间为首次发帖前7天内
    for (final c in _mockCatches) {
      if (!newcomerIds.contains(c.userId)) {
        // 模拟：前两个用户(u009, u010)是新用户
        if (c.userId == 'u009' || c.userId == 'u010') {
          newcomerIds.add(c.userId);
        }
      }
      
      if (newcomerIds.contains(c.userId)) {
        points[c.userId] = (points[c.userId] ?? 0) + c.points;
        userInfo[c.userId] = c;
      }
    }
    
    final sorted = points.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => {
      'userId': e.key,
      'userName': userInfo[e.key]!.userName,
      'points': e.value,
      'topCatch': userInfo[e.key],
    }).toList();
  }

  /// 同城榜（指定城市，按重量）
  static List<CatchItem> cityRanking(String city, {int limit = 20}) {
    final filtered = _mockCatches.where((c) => c.city == city).toList()
      ..sort((a, b) => b.weight.compareTo(a.weight));
    return filtered.take(limit).toList();
  }

  /// 月度赛（指定月份+鱼种）
  static List<CatchItem> monthlyRanking({
    required int year,
    required int month,
    String? targetFish,
    double? minWeight,
    int limit = 50,
  }) {
    var filtered = _mockCatches.where((c) {
      if (c.createdAt.year != year || c.createdAt.month != month) return false;
      if (targetFish != null && c.fish != targetFish) return false;
      if (minWeight != null && c.weight < minWeight) return false;
      return true;
    }).toList();
    
    filtered.sort((a, b) => b.weight.compareTo(a.weight));
    return filtered.take(limit).toList();
  }
}
