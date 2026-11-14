/// 帖子数据模型
import 'dart:convert';

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final String type;        // spot | catch | diary
  final String title;
  final String content;
  final String location;
  final String imageUrl;
  final List<String> images; // 多图（封面取第一张；缺省空）
  final double height;      // 卡片配图高度（瀑布流用）；无图帖子不给，0 表示不占图
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final List<PostSection> sections;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    this.imageUrl = '',
    this.images = const <String>[],
    this.height = 0,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.sections = const <PostSection>[],
  });

  // ── 云库序列化（字段名与 Postgres 列 1:1）─────────────────
  /// ⚠️ posts 表**没有 images 列**（实测列：id/authorId/authorName/
  ///    authorAvatar/type/title/content/location/imageUrl/height/
  ///    likeCount/commentCount/createdAt/sections）。
  ///    这里以前多写一个 'images': images，用户发帖时 PostgREST 直接报
  ///    PGRST204（column not found），整条帖子写不进库、还会在本地假装成功。
  ///    多图字段要等真加列（sql/part8.sql）后再放开，这里先只落 imageUrl。
  Map<String, dynamic> toJson() => {
    'id': id,
    'authorId': authorId,
    'authorName': authorName,
    'authorAvatar': authorAvatar,
    'type': type,
    'title': title,
    'content': content,
    'location': location,
    'imageUrl': imageUrl,
    'height': height,
    'likeCount': likeCount,
    'commentCount': commentCount,
    'createdAt': createdAt.toIso8601String(),
    'sections': sections.map((e) => e.toJson()).toList(),
  };

  static String? _asStr(dynamic v) => v == null ? null : v.toString();
  static double _asDouble(dynamic v, [double d = 0]) =>
      v is num ? v.toDouble() : double.tryParse(v.toString()) ?? d;
  static int _asInt(dynamic v, [int d = 0]) =>
      v is num ? v.toInt() : int.tryParse(v.toString()) ?? d;

  static List<String> _asListStr(dynamic v) {
    if (v == null) return const <String>[];
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String) {
      try {
        final d = jsonDecode(v);
        if (d is List) return d.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return const <String>[];
  }

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: _asStr(json['id']) ?? '',
    authorId: _asStr(json['authorId']) ?? '',
    authorName: _asStr(json['authorName']) ?? '',
    authorAvatar: _asStr(json['authorAvatar']) ?? '🎣',
    type: _asStr(json['type']) ?? 'spot',
    title: _asStr(json['title']) ?? '',
    content: _asStr(json['content']) ?? '',
    location: _asStr(json['location']) ?? '',
    imageUrl: _asStr(json['imageUrl']) ?? '',
    // posts 表没有 images 列，多图字段要等真加列后再放开
    images: _asListStr(json['images']),
    // 无图帖子 height=0，UI 据此完全不占图区高度
    height: _asDouble(json['height'], 0),
    likeCount: _asInt(json['likeCount']),
    commentCount: _asInt(json['commentCount']),
    createdAt: json['createdAt'] == null
        ? DateTime.now()
        : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
    sections: json['sections'] is List
        ? (json['sections'] as List)
            .map((e) => PostSection.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : const <PostSection>[],
  );
}

/// 帖子章节（讲解目录用）
class PostSection {
  final String title;
  final String body;
  const PostSection({required this.title, required this.body});
  Map<String, dynamic> toJson() => {'title': title, 'body': body};
  factory PostSection.fromJson(Map<String, dynamic> json) => PostSection(
    title: json['title']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
  );
}