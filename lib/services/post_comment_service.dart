import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'backend_config.dart';
import 'tcb_rest_client.dart';
import 'user_profile.dart';

/// 帖子评论。
///
/// 数据源：云库 `post_comments` 表。
/// ⚠️ 原实现在 post_detail_page.dart 里写了 3 条常量假评论
///    （海钓阿强/钓鱼王/菜鸟），所有帖子都显示这 3 条，
///    而且评论区没有输入框，用户根本无法发表评论。
///    更矛盾的是：页面顶部评论数用的是 `_comments.length`（恒为 3），
///    而帖子本身真实的 commentCount 字段（如 156）被完全忽略。
class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String content;
  final String parentId;
  final DateTime createdAt;
  final int likeCount;
  final List<String> images;

  /// 当前用户是否已赞（来自 comment_likes 表）
  final bool likedByMe;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.createdAt,
    this.parentId = '',
    this.likeCount = 0,
    this.images = const [],
    this.likedByMe = false,
  });

  String get relativeTime {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${createdAt.month}月${createdAt.day}日';
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content,
        'parentId': parentId,
        'likeCount': likeCount,
        'images': images.join(','),
        'createdAt': createdAt.toIso8601String(),
      };

  /// 解析云端可能存的多种图片格式：
  /// JSON 数组 / 逗号分隔 / 空串
  static List<String> _decodeImages(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) return raw.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    final s = raw.toString().trim();
    if (s.isEmpty || s == 'null') return const [];
    try {
      final d = jsonDecode(s);
      if (d is List) return d.map((e) => '$e').where((e) => e.isNotEmpty).toList();
    } catch (_) {
      // 非 JSON，按逗号分隔处理
    }
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  factory PostComment.fromRow(Map<String, dynamic> row) => PostComment(
        id: row['id'] as String? ?? '',
        postId: row['postId'] as String? ?? '',
        authorId: row['authorId'] as String? ?? 'anon',
        authorName: row['authorName'] as String? ?? '钓友',
        authorAvatar: row['authorAvatar'] as String? ?? '🎣',
        content: row['content'] as String? ?? '',
        parentId: row['parentId'] as String? ?? '',
        likeCount: (row['likeCount'] as num?)?.toInt() ?? 0,
        images: _decodeImages(row['images']),
        createdAt:
            DateTime.tryParse(row['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// 帖子评论服务：云库为主，本地内存兜底（保证离线也能看到已缓存的评论）。
class PostCommentService {
  static const _table = 'post_comments';

  /// 评论点赞表（需要与 post_comments 一起建）
  static const _likeTable = 'comment_likes';
  static final _ctrl = ChangeNotifier();

  /// postId -> 评论列表（时间倒序）
  static final Map<String, List<PostComment>> _cache = {};

  static ChangeNotifier get notifier => _ctrl;

  static List<PostComment> of(String postId) {
    final list = _cache[postId];
    if (list == null) return const [];
    return List.of(list)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 只取顶级评论（parentId 为空），楼中楼回复挂在它们下面。
  static List<PostComment> rootsOf(String postId) =>
      of(postId).where((c) => c.parentId.isEmpty).toList();

  /// 某条顶级评论下的所有回复
  static List<PostComment> repliesOf(String postId, String parentId) =>
      of(postId).where((c) => c.parentId == parentId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  static int countOf(String postId) => of(postId).length;

  /// 顶级评论数（小红书的「N条评论」指的是一级评论）
  static int rootCountOf(String postId) => rootsOf(postId).length;

  /// 评论点赞：写 comment_likes 表，并同步 likeCount。
  /// 返回是否成功。
  static Future<bool> toggleLike(String postId, String commentId) async {
    final me = UserProfile.id;
    if (commentId.isEmpty) return false;
    final before = _cache[postId]?.where((c) => c.id == commentId);
    if (before == null || before.isEmpty) return false;
    final old = before.first;

    if (!BackendConfig.cloudEnabled) return false;
    try {
      // 查我是否已赞过这条评论
      final mine = await TcbRestClient.query(_likeTable, params: {
        'select': 'id',
        'commentId': 'eq.$commentId',
        'userId': 'eq.$me',
        'limit': '1',
      });
      final liked = mine.isNotEmpty;
      final nowLiked = !liked;

      if (nowLiked) {
        await TcbRestClient.upsert(_likeTable, {
          'id': 'cl_${me}_$commentId',
          'commentId': commentId,
          'postId': postId,
          'userId': me,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        await TcbRestClient.delete(_likeTable, {
          'commentId': 'eq.$commentId',
          'userId': 'eq.$me',
        });
      }

      final newCount = (nowLiked ? old.likeCount + 1 : old.likeCount - 1)
          .clamp(0, 1 << 30);
      _replace(postId, commentId, (c) => PostComment(
            id: c.id,
            postId: c.postId,
            authorId: c.authorId,
            authorName: c.authorName,
            authorAvatar: c.authorAvatar,
            content: c.content,
            createdAt: c.createdAt,
            parentId: c.parentId,
            likeCount: newCount,
            images: c.images,
            likedByMe: nowLiked,
          ));
      await TcbRestClient.update(_table, {'id': 'eq.$commentId'},
          {'likeCount': newCount});
      _ctrl.notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[PostComment] 点赞失败：$e');
      return false;
    }
  }

  /// 就地替换缓存里的一条评论
  static void _replace(String postId, String commentId,
      PostComment Function(PostComment) fn) {
    final list = _cache[postId];
    if (list == null) return;
    final i = list.indexWhere((c) => c.id == commentId);
    if (i < 0) return;
    list[i] = fn(list[i]);
  }

  /// 拉取某帖子的评论。
  static Future<void> refreshFromCloud(String postId) async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query(_table, params: {
        'select': '*',
        'postId': 'eq.$postId',
        'limit': '300',
      });
      final list = _cache.putIfAbsent(postId, () => []);
      for (final r in rows) {
        final c = PostComment.fromRow(r);
        if (c.id.isEmpty) continue;
        list.removeWhere((e) => e.id == c.id);
        list.add(c);
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _ctrl.notifyListeners();
      debugPrint('[PostComment] ${postId} 同步 ${rows.length} 条');
      // 点赞态需要额外查一张表，异步补齐（失败不影响评论展示）
      _hydrateMyLikes(postId);
    } catch (e) {
      // 表未建时降级：页面显示空评论而不是假评论
      debugPrint('[PostComment] 同步失败：$e');
    }
  }

  /// 补齐「我赞过哪些评论」的标记。
  /// comment_likes 表未建时静默跳过，不影响评论本身的展示。
  static Future<void> _hydrateMyLikes(String postId) async {
    if (!BackendConfig.cloudEnabled) return;
    final me = UserProfile.id;
    try {
      final rows = await TcbRestClient.query(_likeTable, params: {
        'select': 'commentId',
        'postId': 'eq.$postId',
        'userId': 'eq.$me',
        'limit': '500',
      });
      final mine = rows.map((r) => r['commentId'] as String? ?? '').toSet();
      final list = _cache[postId];
      if (list == null) return;
      for (var i = 0; i < list.length; i++) {
        final c = list[i];
        final liked = mine.contains(c.id);
        if (liked == c.likedByMe) continue;
        list[i] = PostComment(
          id: c.id,
          postId: c.postId,
          authorId: c.authorId,
          authorName: c.authorName,
          authorAvatar: c.authorAvatar,
          content: c.content,
          createdAt: c.createdAt,
          parentId: c.parentId,
          likeCount: c.likeCount,
          images: c.images,
          likedByMe: liked,
        );
      }
      _ctrl.notifyListeners();
    } catch (e) {
      // 表未建 / 无权限：留空即可
    }
  }

  /// 发表评论（或回复），返回是否成功。
  static Future<bool> add({
    required String postId,
    required String authorName,
    required String authorAvatar,
    required String content,
    String parentId = '',
    List<String> images = const [],
  }) async {
    final text = content.trim();
    if (text.isEmpty && images.isEmpty) return false;

    final c = PostComment(
      id: 'pc_${UserProfile.id}_'
          '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      postId: postId,
      authorId: UserProfile.id,
      authorName: authorName,
      authorAvatar: authorAvatar,
      content: text,
      parentId: parentId,
      createdAt: DateTime.now(),
      images: images,
    );

    _cache.putIfAbsent(postId, () => []).add(c);
    _ctrl.notifyListeners();

    if (!BackendConfig.cloudEnabled) return true;
    try {
      await TcbRestClient.upsert(_table, c.toRow());
      return true;
    } catch (e) {
      debugPrint('[PostComment] 写入失败：$e');
      return false;
    }
  }

  /// 删除自己的评论。
  static Future<void> remove(String postId, String commentId) async {
    _cache[postId]?.removeWhere((c) => c.id == commentId);
    _ctrl.notifyListeners();
    if (!BackendConfig.cloudEnabled) return;
    try {
      await TcbRestClient.delete(_table, {'id': 'eq.$commentId'});
    } catch (e) {
      debugPrint('[PostComment] 删除失败：$e');
    }
  }
}