import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'backend_config.dart';
import 'tcb_rest_client.dart';

/// 钓点评论模型
class SpotComment {
  final String id;
  final String spotId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final List<String> images;   // 现场图URL
  final String parentId;       // 回复的评论 id，'' 表示顶层评论
  final DateTime createdAt;
  final int likeCount;

  const SpotComment({
    required this.id,
    required this.spotId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.images,
    required this.createdAt,
    this.parentId = '',
    this.likeCount = 0,
  });

  /// 相对时间：刚刚 / N分钟前 / N小时前 / N天前 / MM-DD
  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${createdAt.month}月${createdAt.day}日';
  }

  /// 云端列为 TEXT（逗号分隔），本地缓存为 List，故序列化时分两种形态。
  /// ⚠️ 这是之前「评论能显示但云端读不回来」的根因之一：
  ///    写入时传的是 List，PostgREST 会序列化成 JSON 文本，
  ///    读回时 `(row['images'] as List?)` 却拿到 String，静默变成空列表。
  static String _encodeImages(List<String> images) => images.join(',');

  static List<String> _decodeImages(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    final s = raw.toString().trim();
    if (s.isEmpty) return const [];
    // 兼容历史上误写入的 JSON 数组字符串
    if (s.startsWith('[')) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is List) {
          return decoded.map((e) => '$e').where((e) => e.isNotEmpty).toList();
        }
      } catch (_) {
        // 不是合法 JSON，按逗号分隔处理
      }
    }
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'spotId': spotId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content,
        'images': _encodeImages(images),
        'parentId': parentId,
        'createdAt': createdAt.toIso8601String(),
        'likeCount': likeCount,
      };

  factory SpotComment.fromRow(Map<String, dynamic> row) => SpotComment(
        id: row['id'] as String? ?? '',
        spotId: row['spotId'] as String? ?? '',
        authorId: row['authorId'] as String? ?? 'anon',
        authorName: row['authorName'] as String? ?? '钓友',
        authorAvatar: row['authorAvatar'] as String? ?? '🎣',
        content: row['content'] as String? ?? '',
        images: _decodeImages(row['images']),
        parentId: row['parentId'] as String? ?? '',
        createdAt:
            DateTime.tryParse(row['createdAt'] as String? ?? '') ?? DateTime.now(),
        likeCount: (row['likeCount'] as num?)?.toInt() ?? 0,
      );
}

/// 钓点评论服务
///
/// 云端为主（腾讯云数据库 spot_comments 表），本地 SharedPreferences 兜底。
/// 设计原则与工程内其他服务一致：**云库失败绝不白屏**，本地数据继续可用。
class SpotCommentService {
  static const _table = 'spot_comments';
  static const _localKey = 'spot_comments_v1';
  static final _ctrl = ChangeNotifier();

  /// spotId -> 评论列表（按时间倒序）
  static final Map<String, List<SpotComment>> _cache = {};
  static bool _cloudSynced = false;

  static ChangeNotifier get notifier => _ctrl;

  static List<SpotComment> of(String spotId) {
    final list = _cache[spotId];
    if (list == null) return const [];
    final c = List.of(list)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return c;
  }

  static int countOf(String spotId) => of(spotId).length;

  // ---------------------------------------------------------------------------
  // 启动时加载：先本地立刻可用，再异步拉云库
  // ---------------------------------------------------------------------------
  static Future<void> init() async {
    await _loadLocal();
    _notify();
    await refreshFromCloud();
  }

  /// 从云库同步某钓点的评论
  static Future<void> refreshFromCloud([String? spotId]) async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final params = {
        'select': '*',
        'limit': '300',
        if (spotId != null) 'spotId': 'eq.$spotId',
      };
      final rows = await TcbRestClient.query(_table, params: params);
      // 按返回结果合并进缓存
      for (final r in rows) {
        final c = SpotComment.fromRow(r);
        if (c.id.isEmpty || c.spotId.isEmpty) continue;
        final list = _cache.putIfAbsent(c.spotId, () => []);
        list.removeWhere((e) => e.id == c.id);
        list.add(c);
      }
      _cloudSynced = true;
      await _saveLocal();
      _notify();
      debugPrint('[SpotComment] 云库同步 ${rows.length} 条');
    } catch (e) {
      debugPrint('[SpotComment] 云库同步失败，用本地数据：$e');
    }
  }

  // ---------------------------------------------------------------------------
  // 发表评论：先落本地（保证用户立刻看到），再同步云库
  // ---------------------------------------------------------------------------
  /// 跨设备唯一评论 id。
  /// ⚠️ 原实现只用 microsecondsSinceEpoch，两台设备同一微秒发评论会撞主键。
  ///   追加用户 id 片段 + 时间戳，保证跨设备不冲突。
  static String _newId(String authorId) {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final uid = authorId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return 'c_${uid}_$ts';
  }

  static Future<bool> add({
    required String spotId,
    required String authorId,
    required String authorName,
    required String authorAvatar,
    required String content,
    List<String> images = const [],
    String parentId = '',
  }) async {
    final text = content.trim();
    if (text.isEmpty && images.isEmpty) return false;

    final c = SpotComment(
      id: _newId(authorId),
      spotId: spotId,
      authorId: authorId,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: text,
      images: images,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    // 本地立即生效
    _cache.putIfAbsent(spotId, () => []).insert(0, c);
    _notify();
    await _saveLocal();

    // 同步云库（失败只记录，不影响用户）
    if (BackendConfig.cloudEnabled) {
      try {
        await TcbRestClient.upsert(_table, c.toRow());
      } catch (e) {
        debugPrint('[SpotComment] 云端写入失败（本地已存）：$e');
      }
    }
    return true;
  }

  /// 删除评论（仅本人或运营）
  static Future<bool> remove(String spotId, String commentId) async {
    final list = _cache[spotId];
    if (list == null) return false;
    final before = list.length;
    list.removeWhere((c) => c.id == commentId);
    if (list.length == before) return false;
    _notify();
    await _saveLocal();
    if (BackendConfig.cloudEnabled) {
      try {
        await TcbRestClient.delete(_table, {'id': commentId});
      } catch (e) {
        debugPrint('[SpotComment] 云端删除失败（本地已删）：$e');
      }
    }
    return true;
  }

  /// 点赞
  static Future<void> like(String spotId, String commentId) async {
    final list = _cache[spotId];
    if (list == null) return;
    final i = list.indexWhere((c) => c.id == commentId);
    if (i < 0) return;
    final old = list[i];
    list[i] = SpotComment(
      id: old.id,
      spotId: old.spotId,
      authorId: old.authorId,
      authorName: old.authorName,
      authorAvatar: old.authorAvatar,
      content: old.content,
      images: old.images,
      parentId: old.parentId,
      createdAt: old.createdAt,
      likeCount: old.likeCount + 1,
    );
    _notify();
    await _saveLocal();
    if (BackendConfig.cloudEnabled) {
      // ⚠️ 修复：TcbRestClient.update 的第二个参数签名是 Map<String,String>，
      //    原代码传了 String 'eq.$commentId'，运行时 uri.replace(queryParameters: String)
      //    会抛 ArgumentError，导致点赞数永远同步不到云库（还被 catchError 静默吞掉）。
      TcbRestClient
          .update(_table, {'id': 'eq.$commentId'}, {'likeCount': list[i].likeCount})
          .catchError((e) => debugPrint('[SpotComment] 点赞同步失败：$e'));
    }
  }

  static void _notify() => _ctrl.notifyListeners();

  // ---------------------------------------------------------------------------
  // 本地持久化
  // ---------------------------------------------------------------------------
  static Future<void> _saveLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = <String, dynamic>{};
      _cache.forEach((k, v) => raw[k] = v.map((e) => e.toRow()).toList());
      await prefs.setString(_localKey, jsonEncode(raw));
    } catch (e) {
      debugPrint('[SpotComment] 本地保存失败：$e');
    }
  }

  static Future<void> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_localKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cache.clear();
      decoded.forEach((spotId, list) {
        _cache[spotId] = ((list as List)
                .map((e) => SpotComment.fromRow((e as Map).cast<String, dynamic>()))
                .toList())
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
    } catch (e) {
      debugPrint('[SpotComment] 本地读取失败：$e');
    }
  }
}
