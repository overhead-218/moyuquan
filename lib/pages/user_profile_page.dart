import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/follow_service.dart';
import '../services/post_service.dart';
import 'chat_detail_page.dart';
import 'post_detail_page.dart';

/// 他人主页
/// - 数据动态：帖子数/作品网格 = PostService 该作者真实帖子
/// - 关注/私信：仅演示作者池（FollowService）内用户可用；池外隐藏操作按钮
class UserProfilePage extends StatefulWidget {
  final String name;
  final String avatar;
  final String bio;
  final int posts; // 兼容旧调用（不再直接展示，改动态计数）
  final int followers;
  final int following;
  final String userId;

  const UserProfilePage({
    super.key,
    required this.name,
    required this.avatar,
    required this.bio,
    this.posts = 0,
    this.followers = 0,
    this.following = 0,
    this.userId = '',
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kLightTeal = Color(0xFF148F86);
  static const Color _kDarkTeal = Color(0xFF075C56);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kGold = Color(0xFFC49A5E);
  static const Color _kShadow = Color(0xFF1A1A1A);

  /// 该用户有稳定标识即可关注/私信（演示池或帖子作者均可）
  String get _uid {
    if (widget.userId.isNotEmpty) return widget.userId;
    return FollowService.userIdByName(widget.name);
  }

  bool get _canAct => _uid.isNotEmpty && _uid != 'me';

  List<Post> get _works => PostService.postsByAuthorName(widget.name);

  @override
  void initState() {
    super.initState();
    PostService.addListener(_refresh);
    FollowService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    PostService.removeListener(_refresh);
    FollowService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final works = _works;
    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        slivers: [
          // 渐变头部
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: _kPrimary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kSurface.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kDarkTeal, _kLightTeal, _kPrimary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // 头像
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _kSurface.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kGold.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(widget.avatar,
                            style: const TextStyle(fontSize: 40)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.bio,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 数据栏
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 4),
                          blurRadius: 16,
                          color: _kShadow.withValues(alpha: 0.06),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StatCol(value: '${works.length}', label: '帖子'),
                        _buildDivider(),
                        const _StatCol(value: '0', label: '粉丝'),
                        _buildDivider(),
                        const _StatCol(value: '0', label: '关注'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 操作按钮
                  if (_canAct)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                FollowService.instance.toggleFollow(
                                  _uid,
                                  name: widget.name,
                                  avatar: widget.avatar,
                                  bio: widget.bio,
                                );
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FollowService.instance
                                      .isFollowing(_uid)
                                  ? _kTealBg
                                  : _kPrimary,
                              foregroundColor: FollowService.instance
                                      .isFollowing(_uid)
                                  ? _kPrimary
                                  : Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              FollowService.instance.isFollowing(_uid)
                                  ? '已关注'
                                  : '+ 关注',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatDetailPage(
                                  name: widget.name,
                                  avatar: widget.avatar,
                                  userId: _uid,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimary,
                            side: const BorderSide(color: Color(0xFF0A7C74)),
                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            '私信',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (!_canAct) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _kTealBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events,
                              size: 16, color: _kPrimary),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '榜单展示用户',
                              style: TextStyle(
                                fontSize: 12,
                                color: _kPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.grid_on, size: 18, color: _kPrimary),
                      SizedBox(width: 6),
                      Text(
                        '作品',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // 作品网格（该作者真实帖子）
          if (works.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final p = works[i];
                    return GestureDetector(
                      onTap: () => _openPost(context, p),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kTealBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: p.imageUrl.isEmpty
                            ? const Center(
                                child: Text('🎣',
                                    style: TextStyle(fontSize: 26)),
                              )
                            : Image.network(
                                p.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, st) =>
                                    const Center(
                                  child: Text('🎣',
                                      style: TextStyle(fontSize: 26)),
                                ),
                              ),
                      ),
                    );
                  },
                  childCount: works.length,
                ),
              ),
            ),
          if (works.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 8, bottom: 40),
                child: Center(
                  child: Text(
                    '暂未发布内容',
                    style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  void _openPost(BuildContext context, Post p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          authorName: p.authorName,
          authorAvatar: p.authorAvatar,
          imageUrl: p.imageUrl,
          imageHeight: 300,
          likeCount: PostService.likeCountOf(p),
          index: 0,
          title: p.title,
          content: p.content,
          location: p.location,
          postType: p.type,
          commentCount: p.commentCount,
          postId: p.id,
          authorId: p.authorId,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFEDEAE3),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String value;
  final String label;

  const _StatCol({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0A7C74),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}
