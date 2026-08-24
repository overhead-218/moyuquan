/// 帖子数据模型
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
  final double height;      // 卡片高度（瀑布流用）
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.type,
    required this.title,
    required this.content,
    required this.location,
    required this.imageUrl,
    required this.height,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  // ── 云库序列化（字段名与 Postgres 列 1:1）─────────────────
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
  };

  static String? _asStr(dynamic v) => v == null ? null : v.toString();
  static double _asDouble(dynamic v, [double d = 0]) =>
      v is num ? v.toDouble() : double.tryParse(v.toString()) ?? d;
  static int _asInt(dynamic v, [int d = 0]) =>
      v is num ? v.toInt() : int.tryParse(v.toString()) ?? d;

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
    height: _asDouble(json['height'], 280),
    likeCount: _asInt(json['likeCount']),
    commentCount: _asInt(json['commentCount']),
    createdAt: json['createdAt'] == null
        ? DateTime.now()
        : DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
  );
}