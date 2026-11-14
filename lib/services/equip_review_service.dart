import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'backend_config.dart';
import 'tcb_rest_client.dart';

/// 装备评价（对应云库 equip_reviews 表）
class EquipReview {
  final String id;
  final String equipId;
  final String authorId;
  final String authorName;
  final int rating; // 1~5 星
  final String content;
  final String createdAt;
  final int likeCount;

  const EquipReview({
    required this.id,
    required this.equipId,
    required this.authorId,
    required this.authorName,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
  });

  /// 相对时间，如「3天前」
  String get timeAgo {
    final t = DateTime.tryParse(createdAt.replaceFirst(' ', 'T'));
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}分钟前';
    if (d.inHours < 24) return '${d.inHours}小时前';
    if (d.inDays < 30) return '${d.inDays}天前';
    return '${d.inDays ~/ 30}个月前';
  }

  factory EquipReview.fromRow(Map<String, dynamic> r) => EquipReview(
        id: r['id'] as String? ?? '',
        equipId: r['equipId'] as String? ?? '',
        authorId: r['authorId'] as String? ?? '',
        authorName: (r['authorName'] as String? ?? '').trim(),
        rating: (r['rating'] as num?)?.toInt() ?? 5,
        content: r['content'] as String? ?? '',
        createdAt: r['createdAt'] as String? ?? '',
        likeCount: (r['likeCount'] as num?)?.toInt() ?? 0,
      );
}

/// 装备评价服务。
///
/// ⚠️ 原实现是 3 条用标签拼接生成的模板评价（「这款${type}真的不错，${tags.first}
///    是最大亮点」），所有装备的评价文字完全一样，且星级写死 5/4/4。
///    现在改为读写云库 `equip_reviews` 表，无真实评价时显示空态。
class EquipReviewService {
  static const _table = 'equip_reviews';

  static String _newId(String authorId) {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final uid = authorId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return 'er_${uid}_$ts';
  }

  /// 拉取某件装备的真实评价
  static Future<List<EquipReview>> fetch(String equipId) async {
    if (!BackendConfig.cloudEnabled || equipId.isEmpty) return const [];
    try {
      final rows = await TcbRestClient.query(_table, params: {
        'select': '*',
        'equipId': 'eq.$equipId',
        'order': 'createdAt.desc',
        'limit': '50',
      });
      return rows.map(EquipReview.fromRow).where((r) => r.id.isNotEmpty).toList();
    } catch (e) {
      debugPrint('[EquipReview] 读取失败：$e');
      return const [];
    }
  }

  /// 写入评价
  static Future<bool> submit({
    required String equipId,
    required String authorId,
    required String authorName,
    required int rating,
    required String content,
  }) async {
    if (!BackendConfig.cloudEnabled) return false;
    final text = content.trim();
    if (text.isEmpty) return false;
    final id = _newId(authorId);
    try {
      // TcbRestClient.insert 抛异常才算失败：
      // 返回 null 也可能是「正常插入但未要求回传行数据」（returnRepr: false）。
      await TcbRestClient.insert(
        _table,
        {
          'id': id,
          'equipId': equipId,
          'authorId': authorId,
          'authorName': authorName,
          'rating': rating.clamp(1, 5),
          'content': text,
          'likeCount': 0,
          'createdAt': DateTime.now()
              .toIso8601String()
              .replaceFirst('T', ' ')
              .substring(0, 19),
        },
        returnRepr: false,
      );
      return true;
    } catch (e) {
      debugPrint('[EquipReview] 写入失败：$e');
      return false;
    }
  }

  /// 解析可能的 JSON 字符串字段（兼容云端 TEXT 存储）
  static List<String> decodeTags(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final d = jsonDecode(raw);
      if (d is List) return d.map((e) => '$e').toList();
    } catch (_) {}
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
}