import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import '../pages/post_detail_page.dart';

/// 简洁帖子卡片：供「我的帖子 / 我的鱼获 / 收藏」等列表复用。
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onRemove; // 收藏页的取消收藏动作（null 则不显示）

  const PostCard({super.key, required this.post, this.onRemove});

  static const _kPrimary = Color(0xFF0A7C74);

  String get _typeLabel => switch (post.type) {
        'spot' => '钓点',
        'catch' => '鱼获',
        _ => '日记',
      };

  bool get _canShowImage =>
      post.imageUrl.isNotEmpty &&
      !post.imageUrl.startsWith('/') &&
      post.imageUrl.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：作者 + 类型标签 + 时间
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F2F0),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    alignment: Alignment.center,
                    child: Text(post.authorAvatar,
                        style: const TextStyle(fontSize: 17)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Text(
                          fmtTime(post.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFBBBBBB)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F2F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _typeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 图片
            SizedBox(
              height: 170,
              width: double.infinity,
              child: !_canShowImage
                  ? _placeholder()
                  : Image.network(
                      post.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    ),
            ),
            // 正文
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.title.isNotEmpty)
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  if (post.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      post.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.favorite,
                          size: 15, color: Color(0xFFFF4757)),
                      const SizedBox(width: 4),
                      Text(
                        '${PostService.likeCountOf(post)}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF999999)),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.chat_bubble_outline,
                          size: 14, color: Color(0xFF999999)),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF999999)),
                      ),
                      const Spacer(),
                      if (onRemove != null)
                        GestureDetector(
                          onTap: onRemove,
                          child: const Row(
                            children: [
                              Icon(Icons.bookmark_remove_outlined,
                                  size: 15, color: Color(0xFF999999)),
                              SizedBox(width: 3),
                              Text(
                                '取消收藏',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF999999)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A7C74), Color(0xFF148F86)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Text('🎣', style: TextStyle(fontSize: 40)),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          authorName: post.authorName,
          authorAvatar: post.authorAvatar,
          imageUrl: post.imageUrl,
          imageHeight: 300,
          likeCount: PostService.likeCountOf(post),
          index: 0,
          title: post.title,
          content: post.content,
          location: post.location,
          postType: post.type,
          commentCount: post.commentCount,
          postId: post.id,
          authorId: post.authorId,
        ),
      ),
    );
  }
}

/// 空态视图：图标 + 说明 + 可选动作
class EmptyView extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyView({
    super.key,
    this.emoji = '🎣',
    this.title = '这里还空空的',
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF999999), height: 1.5),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0A7C74),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 时间格式化：刚刚 / x分钟前 / x小时前 / 昨天 / MM-DD / yyyy-MM-DD
String fmtTime(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
  if (diff.inHours < 24) return '${diff.inHours}小时前';
  if (diff.inDays == 1) return '昨天';
  if (t.year == now.year) {
    return '${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}
