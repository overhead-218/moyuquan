import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'backend_config.dart';
import 'tcb_rest_client.dart';

/// 装备图鉴条目（对应云库 equips 表）
class EquipItem {
  final String id;
  final String brand;
  final String name;
  final String model;

  /// 分类：rod_spin | rod_bait | rod_casting | reel | lure | line
  final String category;

  /// 对应装备栏槽位：rod | reel | line | bait
  final String slot;

  /// 海水 |淡水 | 通用
  final String waterType;

  /// 直柄 | 枪柄（路亚竿柄型）
  final String handle;

  /// 独节 | 两节 | 一本半
  final String sections;

  /// 纺车轮 | 水滴轮 | 鼓轮
  final String reelType;

  /// 左 | 右（卷线器左右手）
  final String hand;

  /// 解析出的规格：{键: 值}
  final Map<String, String> specs;

  final List<String> tags;
  final String description;
  final String imageUrl;
  final List<String> gallery;
  final double? price;
  final String brandSeries;
  final int score;
  final int heat;
  final int replyCount;

  const EquipItem({
    required this.id,
    required this.brand,
    required this.name,
    this.model = '',
    required this.category,
    this.slot = '',
    this.waterType = '',
    this.handle = '',
    this.sections = '',
    this.reelType = '',
    this.hand = '',
    this.specs = const {},
    this.tags = const [],
    this.description = '',
    this.imageUrl = '',
    this.gallery = const [],
    this.price,
    this.brandSeries = '',
    this.score = 0,
    this.heat = 0,
    this.replyCount = 0,
  });

  /// 完整名称（品牌 + 型号），用于列表标题
  String get fullName =>
      (brand.isNotEmpty && !name.startsWith(brand)) ? '$brand $name' : name;

  /// 规格展示文本
  String get specText => specs.entries.map((e) => '${e.key} ${e.value}').join(' · ');

  // ---------------------------------------------------------------------------
  // 序列化
  // ---------------------------------------------------------------------------
  static Map<String, String> _decodeSpecs(dynamic raw) {
    if (raw == null) return const {};
    if (raw is Map) return raw.map((k, v) => MapEntry('$k', '$v'));
    final s = raw.toString().trim();
    if (s.isEmpty || s == 'null') return const {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry('$k', '$v'));
      }
      if (decoded is List) {
        // 兼容 gear.json 的 [['键','值'], ...] 结构
        final out = <String, String>{};
        for (final item in decoded) {
          if (item is List && item.length >= 2) {
            out['${item[0]}'] = '${item[1]}';
          }
        }
        return out;
      }
    } catch (_) {
      // 非 JSON，忽略
    }
    return const {};
  }

  static List<String> _decodeList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    final s = raw.toString().trim();
    if (s.isEmpty || s == 'null') return const [];
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        return decoded.map((e) => '$e').where((e) => e.isNotEmpty).toList();
      }
    } catch (_) {}
    // 逗号分隔
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  factory EquipItem.fromRow(Map<String, dynamic> r) => EquipItem(
        id: r['id'] as String? ?? '',
        brand: r['brand'] as String? ?? '',
        name: r['name'] as String? ?? '',
        model: r['model'] as String? ?? '',
        category: r['category'] as String? ?? '',
        slot: r['slot'] as String? ?? '',
        waterType: r['waterType'] as String? ?? '',
        handle: r['handle'] as String? ?? '',
        sections: r['sections'] as String? ?? '',
        reelType: r['reelType'] as String? ?? '',
        hand: r['hand'] as String? ?? '',
        specs: _decodeSpecs(r['specs']),
        tags: _decodeList(r['tags']),
        description: r['description'] as String? ?? '',
        imageUrl: r['imageUrl'] as String? ?? '',
        gallery: _decodeList(r['gallery']),
        price: (r['price'] as num?)?.toDouble(),
        brandSeries: r['brandSeries'] as String? ?? '',
        score: (r['score'] as num?)?.toInt() ?? 0,
        heat: (r['heat'] as num?)?.toInt() ?? 0,
        replyCount: (r['replyCount'] as num?)?.toInt() ?? 0,
      );
}

/// 装备服务。
///
/// ⚠️ 原实现是 183 条装备硬编码在 `catch_page.dart` 里（`_rods` / `_reels` /
///    `_lures` / `_baits` 四个列表），带编造的分数与热度；
///    装备详情页的3 条评价更是用标签拼接生成的模板，所有装备评价长得一样。
/// 现在改为读云库 `equips` 表（真实商品数据，由 tool/import_gear.py 导入）。
class EquipService {
  static const _table = 'equips';
  static final _ctrl = ChangeNotifier();

  static List<EquipItem> _cache = [];
  static final Map<String, List<EquipItem>> _byCategory = {};
  static bool _loaded = false;

  static ChangeNotifier get notifier => _ctrl;
  static bool get isLoaded => _loaded;
  static List<EquipItem> get all => List.unmodifiable(_cache);

  /// 按分类取装备（category 见 EquipItem.category）
  static List<EquipItem> byCategory(String category) {
    final list = _byCategory[category];
    if (list == null) return const [];
    return List.of(list)
      ..sort((a, b) {
        // 先按热度降序，同热度按口碑分降序
        final byHeat = b.heat.compareTo(a.heat);
        return byHeat != 0 ? byHeat : b.score.compareTo(a.score);
      });
  }

  /// 全部竿类（三个子类型合并）
  static List<EquipItem> allRods() {
    final list = <EquipItem>[
      ...byCategory('rod_spin'),
      ...byCategory('rod_bait'),
      ...byCategory('rod_casting'),
    ];
    list.sort((a, b) {
      final byHeat = b.heat.compareTo(a.heat);
      return byHeat != 0 ? byHeat : b.score.compareTo(a.score);
    });
    return list;
  }

  /// 全部卷线器
  static List<EquipItem> allReels() => byCategory('reel');

  /// 按品牌过滤
  static List<EquipItem> search(String keyword) {
    if (keyword.trim().isEmpty) return _cache;
    final q = keyword.trim().toLowerCase();
    return _cache
        .where((e) =>
            e.name.toLowerCase().contains(q) ||
            e.brand.toLowerCase().contains(q) ||
            e.model.toLowerCase().contains(q) ||
            e.brandSeries.toLowerCase().contains(q))
        .toList();
  }

  static EquipItem? byId(String id) {
    for (final e in _cache) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// 启动时调用：从云库拉取装备。
  ///
  /// 云库为空（未执行 schema_social.sql 或未导入数据）时返回空列表，
  /// 页面显示空态，而不是回落到183 条编造数据。
  ///
  /// ⚠️ PostgREST 单次响应上限 1000 行，传 limit=2000 也会被截断在 1000
  ///    （实测 Content-Range: 0-999/1548），所以必须分页拉取再合并，
  ///    否则 1548 件装备会静默丢掉后面 548 件。
  static Future<void> refreshFromCloud({int pageSize = 500}) async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final collected = <EquipItem>[];
      final seen = <String>{};
      var offset = 0;
      while (true) {
        final rows = await TcbRestClient.query(_table, params: {
          'select': '*',
          'limit': '$pageSize',
          'offset': '$offset',
          // 必须按主键排序：按 heat 排序时大量装备 heat 值相同（星级都是 4/5），
          // 排序结果不稳定，分页会出现跨页重复（实测 1548 行去重后只剩 1508）。
          'order': 'id.asc',
        });
        for (final r in rows) {
          final e = EquipItem.fromRow(r);
          if (e.id.isEmpty || e.name.isEmpty) continue;
          if (!seen.add(e.id)) continue;
          collected.add(e);
        }
        // 不足一页说明已到末尾
        if (rows.length < pageSize) break;
        offset += pageSize;
      }

      _cache = collected;

      _byCategory.clear();
      for (final e in _cache) {
        _byCategory.putIfAbsent(e.category, () => []).add(e);
      }
      _loaded = true;
      _ctrl.notifyListeners();
      debugPrint('[Equip] 云库同步 ${_cache.length} 件装备，'
          '${_byCategory.length} 个分类');
    } catch (e) {
      debugPrint('[Equip] 云库同步失败（装备列表为空）：$e');
      _cache = [];
      _byCategory.clear();
      _loaded = true;
      _ctrl.notifyListeners();
    }
  }
}