import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Post(
      id: doc.id,
      authorId: (d['authorId'] ?? '') as String,
      authorName: (d['authorName'] ?? '') as String,
      authorAvatar: (d['authorAvatar'] ?? '🎣') as String,
      type: (d['type'] ?? 'spot') as String,
      title: (d['title'] ?? '') as String,
      content: (d['content'] ?? '') as String,
      location: (d['location'] ?? '') as String,
      imageUrl: (d['imageUrl'] ?? '') as String,
      height: (d['height'] is num) ? (d['height'] as num).toDouble() : 280.0,
      likeCount: (d['likeCount'] is num) ? (d['likeCount'] as num).toInt() : 0,
      commentCount: (d['commentCount'] is num) ? (d['commentCount'] as num).toInt() : 0,
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}