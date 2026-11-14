import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'user_profile_page.dart';
import 'share_card_page.dart';
import '../services/follow_service.dart';
import '../services/moderation_actions.dart';
import '../services/post_service.dart';
import '../services/post_comment_service.dart';
import '../services/user_profile.dart';
import '../models/post.dart';
import '../widgets/smart_image.dart';

/// 帖子详情页
class PostDetailPage extends StatefulWidget {
  final String authorName;
  final String authorAvatar;
  final String imageUrl;
  final List<String> images;
  final double imageHeight;
  final int likeCount;
  final int index;
  final String title;
  final String content;
  final String location;
  final String postType;
  final int commentCount;
  final String postId;
  final String authorId;
  final List<PostSection> sections;

  const PostDetailPage({
    super.key,
    required this.authorName,
    required this.authorAvatar,
    required this.imageUrl,
    this.images = const <String>[],
    required this.imageHeight,
    required this.likeCount,
    required this.index,
    required this.title,
    required this.content,
    required this.location,
    required this.postType,
    required this.commentCount,
    this.postId = '',
    this.authorId = '',
    this.sections = const <PostSection>[],
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartCtrl;
  late final Animation<double> _heartScale;
  bool _liked = false;
  late int _likeCount;
  PageController? _heroCtrl;
  int _heroPage = 0;

  static const _kPrimary = Color(0xFF0A7C74);
  static const Color _kLightTeal = Color(0xFF148F86);
  static const Color _kDarkTeal = Color(0xFF075C56);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kGold = Color(0xFFC49A5E);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _gradientPairs = <List<Color>>[
    [Color(0xFF0A7C74), Color(0xFF148F86)],
    [Color(0xFFC49A5E), Color(0xFFE0B670)],
    [Color(0xFF0E7C7B), Color(0xFF4FA8A8)],
    [Color(0xFF2E8B7B), Color(0xFF5BAE9C)],
    [Color(0xFF1F6F8B), Color(0xFF4A90B8)],
    [Color(0xFF8B5A3C), Color(0xFFB8845C)],
  ];

  static const _fishEmojis = ['🎣', '🐟', '🐠', '🦈', '🦑', '🐡'];

  // 评论区状态（真实数据，见 post_comment_service.dart）
  final _commentCtrl = TextEditingController();
  final _commentFocus = FocusNode();
  List<PostComment> _comments = [];
  bool _sendingComment = false;

  /// 评论区排序：latest 最新 | hottest 最热（小红书评论区右上角可切换）
  _CommentSort _commentSort = _CommentSort.latest;

  /// 正在回复谁（null = 发顶级评论）。小红书的「回复某人」会带出提示条。
  PostComment? _replyTarget;

  /// 展开了楼中楼回复的顶级评论 id 集合
  final Set<String> _expandedReplies = {};

  /// 评论加载中（避免空态闪烁）
  bool _loadingComments = true;

  /// 顶级评论（楼中楼回复不占一级列表位置）
  List<PostComment> get _rootComments => _comments
      .where((c) => c.parentId.isEmpty)
      .toList(growable: false);

  /// 按当前排序返回顶级评论
  List<PostComment> get _sortedRoots {
    final roots = List<PostComment>.from(_rootComments);
    switch (_commentSort) {
      case _CommentSort.latest:
        roots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _CommentSort.hottest:
        final byLike = (PostComment a, PostComment b) {
          final r = b.likeCount.compareTo(a.likeCount);
          if (r != 0) return r;
          final byReply = PostCommentService.repliesOf(widget.postId, b.id)
                  .length
              .compareTo(PostCommentService.repliesOf(widget.postId, a.id).length);
          if (byReply != 0) return byReply;
          return b.createdAt.compareTo(a.createdAt);
        };
        roots.sort(byLike);
    }
    return roots;
  }

  /// 一级评论数（小红书显示的是一级评论数）
  int get _rootCommentCount =>
      _rootComments.isNotEmpty ? _rootComments.length : _commentCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likeCount + PostService.deltaOf(widget.postId);
    _liked = PostService.isLiked(widget.postId);
    PostService.addListener(_syncLike);
    FollowService.instance.addListener(_syncLike);

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.6, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _heartCtrl,
      curve: Curves.elasticOut,
    ));

    // 拉取真实评论（替换原先写死的 3 条）
    if (widget.postId.isNotEmpty) {
      PostCommentService.refreshFromCloud(widget.postId).then((_) {
        if (!mounted) return;
        setState(() {
          _comments = PostCommentService.of(widget.postId);
          _loadingComments = false;
        });
      });
    } else {
      _loadingComments = false;
    }
  }

  /// 真实评论总数：云库有数据时用云库，否则退回帖子自带的 commentCount。
  ///
  /// ⚠️ 原实现用 `_comments.length`（恒为 3），
  /// 而帖子的真实 commentCount（如 156）被完全忽略，数据自相矛盾。
  int get _commentCount {
    final cloud = PostCommentService.countOf(widget.postId);
    return cloud > 0 ? cloud : widget.commentCount;
  }

  /// 发表顶级评论或回复。
  ///
  /// 回复时写入 parentId，被回复的那条评论会自动展开楼中楼。
  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _sendingComment) return;
    setState(() => _sendingComment = true);
    final me = UserProfile.instance;
    final target = _replyTarget;
    final ok = await PostCommentService.add(
      postId: widget.postId,
      authorName: me.name,
      authorAvatar: me.avatarEmoji,
      content: text,
      parentId: target?.id ?? '',
    );
    if (!mounted) return;
    setState(() {
      _sendingComment = false;
      if (ok) {
        _commentCtrl.clear();
        _commentFocus.unfocus();
        _replyTarget = null;
        _comments = PostCommentService.of(widget.postId);
        // 回复后自动展开对应楼中楼，让用户马上看到自己发的
        if (target != null) _expandedReplies.add(target.id);
      }
    });
    if (!ok) _showMsg('评论发表失败，请检查网络');
  }

  /// 开始回复某人（小红书：点「回复」后输入框上方出现「回复 @xxx」提示条）
  void _startReply(PostComment target) {
    setState(() => _replyTarget = target);
    _commentFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyTarget = null);
  }

  void _focusInput() {
    _commentFocus.requestFocus();
  }

  /// 评论点赞：真实写云库 comment_likes 表
  Future<void> _toggleCommentLike(String commentId) async {
    final ok = await PostCommentService.toggleLike(widget.postId, commentId);
    if (!mounted) return;
    if (!ok) _showMsg('点赞失败，请检查网络');
    setState(() => _comments = PostCommentService.of(widget.postId));
  }

  /// 选图插入评论框。
  ///
  /// ⚠️ 当前只把图片以base64 文本形式暂存，尚未上传对象存储，
  ///    因此对方端还不能看到图片。等接好存储桶后改成上传拿 CDN URL。
  Future<void> _pickCommentImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      // 占位：写一行占位文本，等对象存储接通后替换为真实URL
      _commentCtrl.text = _commentCtrl.text.isEmpty
          ? '[图片]'
          : '${_commentCtrl.text} [图片]';
      _commentFocus.requestFocus();
    } catch (e) {
      if (mounted) _showMsg('选择图片失败');
    }
  }

  /// 表情面板（直接插入输入框）
  void _showEmojiPicker() {
    const emojis = ['🎣', '🐟', '🐠', '🐡', '🦈', '🦑', '🦀', '🐙', '🌊', '☀️',
      '🌙', '⛰️', '😂', '👍', '🙏', '🔥', '💯', '🎉', '😍', '🤔'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: emojis
                .map((e) => GestureDetector(
                      onTap: () {
                        _commentCtrl.text = '${_commentCtrl.text}$e';
                        Navigator.pop(ctx);
                        _commentFocus.requestFocus();
                      },
                      child: Text(e, style: const TextStyle(fontSize: 28)),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _syncLike() {
    if (!mounted) return;
    setState(() {
      _liked = PostService.isLiked(widget.postId);
      _likeCount = widget.likeCount + PostService.deltaOf(widget.postId);
    });
  }

  @override
  void dispose() {
    PostService.removeListener(_syncLike);
    FollowService.instance.removeListener(_syncLike);
    _heartCtrl.dispose();
    _heroCtrl?.dispose();
    _commentCtrl.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    // toggleLike 现在是异步的：先本地响应再写云库，失败会回滚
    final liked = await PostService.toggleLike(widget.postId);
    _syncLike();
    if (liked) {
      _heartCtrl.forward(from: 0);
    }
  }

  Widget _buildHero(List<Color> gradient, String fishEmoji) {
    final imgs = widget.images.isNotEmpty
        ? widget.images
        : (widget.imageUrl.isNotEmpty ? [widget.imageUrl] : const <String>[]);
    if (imgs.isEmpty) {
      return Container(
        width: double.infinity,
        height: widget.imageHeight + 60,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A7C74), Color(0xFF148F86)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.title,
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w800),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    }
    final controller = _heroCtrl ??= PageController();
    final viewer = PageView.builder(
      controller: controller,
      itemCount: imgs.length,
      itemBuilder: (context, i) => SmartImage(
        url: imgs[i],
        fit: BoxFit.cover,
        loadingBuilder: (c, child, pr) => pr == null
            ? child
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: const Center(
                  child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                ),
              ),
        errorBuilder: (c, e, st) => Container(
          decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)),
          child: Center(child: Text(fishEmoji, style: const TextStyle(fontSize: 80))),
        ),
      ),
      onPageChanged: (i) => setState(() => _heroPage = i),
    );
    if (imgs.length == 1) return viewer;
    return Stack(
      children: [
        viewer,
        Positioned(
          top: 12, right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: Text('${_heroPage + 1}/${imgs.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
        Positioned(
          bottom: 12, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(imgs.length, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _heroPage ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(color: i == _heroPage ? Colors.white : Colors.white54, borderRadius: BorderRadius.circular(3)),
            )),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildGuide(List<PostSection> sections) {
    final toc = Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0A7C74).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('讲解目录',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0A7C74))),
          const SizedBox(height: 10),
          ...sections.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  const Icon(Icons.menu_rounded, size: 14, color: Color(0xFF0A7C74)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(s.title,
                          style: const TextStyle(fontSize: 13, color: _kTextPrimary))),
                ]),
              )),
        ],
      ),
    );
    final bodies = sections
        .map((s) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: _kTextPrimary)),
                const SizedBox(height: 6),
                Text(s.body,
                    style: const TextStyle(
                        fontSize: 14, color: _kTextPrimary, height: 1.6)),
              ]),
            ))
        .toList();
    return [toc, ...bodies];
  }

  /// 帖子作者的稳定关注 id
  String get _authorUid {
    if (widget.authorId.isNotEmpty) return widget.authorId;
    return FollowService.userIdByName(widget.authorName);
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientPairs[widget.index % _gradientPairs.length];
    final fishEmoji = _fishEmojis[widget.index % _fishEmojis.length];

    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        slivers: [
          // 图片区 AppBar
          SliverAppBar(
            expandedHeight: widget.imageHeight + 60,
            pinned: true,
            backgroundColor: gradient[0],
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kSurface.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kSurface.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShareCardPage.post(
                        PostShareData(
                          authorName: widget.authorName,
                          authorAvatar: widget.authorAvatar,
                          title: widget.title,
                          content: widget.content,
                          location: widget.location,
                          imageUrl: widget.imageUrl,
                          likeCount: _likeCount,
                          commentCount: widget.commentCount,
                          postType: widget.postType,
                          index: widget.index,
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _kSurface.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_outlined,
                      color: Colors.white, size: 20),
                ),
                onPressed: () {
                  showReportSheet(
                    context,
                    targetType: 'post',
                    targetId: widget.postId,
                    targetUserId: widget.authorId,
                    title: '举报帖子',
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SizedBox(
                height: widget.imageHeight + 60,
                width: double.infinity,
                child: _buildHero(gradient, fishEmoji),              ),
            ),
          ),
          // 内容区
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 作者信息卡
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UserProfilePage(
                            name: widget.authorName,
                            avatar: widget.authorAvatar,
                            bio: '专注野钓，热爱分享',
                            // 传真实 userId（帖子作者），主页内数据均动态计算
                            userId: widget.authorId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: _kTealBg,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                widget.authorAvatar,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.authorName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.location.isNotEmpty
                                      ? widget.location
                                      : '摸鱼圈官方',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _kTextWeak,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 关注按钮（自己的帖子不显示）
                          if (widget.authorId != 'me')
                            Builder(builder: (context) {
                              final isF = FollowService.instance
                                  .isFollowing(_authorUid);
                              return OutlinedButton(
                                onPressed: isF
                                    ? () => FollowService.instance
                                        .toggleFollow(_authorUid)
                                    : () => FollowService.instance.toggleFollow(
                                        _authorUid,
                                        name: widget.authorName,
                                        avatar: widget.authorAvatar,
                                      ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      isF ? _kTextWeak : _kPrimary,
                                  side: BorderSide(
                                      color:
                                          isF ? _kTextWeak : const Color(0xFF0A7C74)),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: Text(
                                  isF ? '已关注' : '+ 关注',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 标题
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // 正文
                  Text(
                    widget.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _kTextPrimary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.sections.isNotEmpty) ..._buildGuide(widget.sections),
                  // 标签
                  if (widget.location.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Tag(widget.location),
                      ],
                    ),
                  const SizedBox(height: 20),
                  // 点赞互动栏
                  Container(
                    padding: const EdgeInsets.all(16),
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
                      children: [
                        ScaleTransition(
                          scale: _heartScale,
                          child: GestureDetector(
                            onTap: _toggleLike,
                            child: Row(
                              children: [
                                Icon(
                                  _liked ? Icons.favorite : Icons.favorite_border,
                                  color: _liked
                                      ? const Color(0xFFFF4757)
                                      : _kTextWeak,
                                  size: 26,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$_likeCount',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _liked
                                        ? const Color(0xFFFF4757)
                                        : _kTextWeak,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        const Icon(Icons.chat_bubble_outline,
                            color: _kTextWeak, size: 24),
                        const SizedBox(width: 6),
                        Text(
                          '$_commentCount',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kTextWeak,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.share_outlined,
                            color: _kTextWeak.withValues(alpha: 0.7), size: 22),
                      ],
                    ),
                  ),
const SizedBox(height: 20),
                  // ============ 评论区（参考小红书：排序切换 + 楼中楼 + 点赞） ============
                  _CommentSectionHeader(
                    count: _rootCommentCount,
                    sortMode: _commentSort,
                    onSortChanged: (m) => setState(() => _commentSort = m),
                  ),
                  const SizedBox(height: 4),
                  // 评论列表
                  if (_comments.isEmpty && !_loadingComments)
                    _EmptyComments(
                      onTap: _focusInput,
                    )
                  else
                    ..._sortedRoots.map((c) => _CommentNode(
                          comment: c,
                          postId: widget.postId,
                          replies: PostCommentService.repliesOf(widget.postId, c.id),
                          replyTarget: _replyTarget,
                          expanded: _expandedReplies.contains(c.id),
                          onToggleExpand: () => setState(() {
                            if (!_expandedReplies.add(c.id)) {
                              _expandedReplies.remove(c.id);
                            }
                          }),
                          onReply: (target) => _startReply(target),
                          onLike: (id) => _toggleCommentLike(id),
                        )),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
      // ============ 固定底部输入栏（小红书核心交互：始终吸底） ============
      bottomNavigationBar: _BottomCommentBar(
        controller: _commentCtrl,
        focusNode: _commentFocus,
        sending: _sendingComment,
        replyTarget: _replyTarget,
        onCancelReply: _cancelReply,
        onSend: _sendComment,
        onPickImage: _pickCommentImage,
        onPickEmoji: _showEmojiPicker,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2F0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0A7C74),
        ),
      ),
    );
  }
}

// ============================================================
// 评论区组件（参考小红书交互设计）
//
// 小红书评论区的主要特征：
//   1. 输入框固定在屏幕底部吸底，不随内容滚走
//   2. 回复某人时输入框上方出现「回复 @xxx ×」提示条
//   3. 楼中楼：二级回复缩进显示，默认折叠「展开 N 条回复」
//   4. 每条评论右侧有点赞（爱心 + 数字）
//   5. 顶部有排序切换（最新 / 最热）
// ============================================================

/// 评论排序方式
enum _CommentSort {
  latest('最新'),
  hottest('最热');

  const _CommentSort(this.label);
  final String label;
}

// ── 评论区顶部：N 条评论 + 排序切换 ────────────────────────
class _CommentSectionHeader extends StatelessWidget {
  final int count;
  final _CommentSort sortMode;
  final ValueChanged<_CommentSort> onSortChanged;

  const _CommentSectionHeader({
    required this.count,
    required this.sortMode,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.forum_outlined, size: 17, color: Color(0xFF0A7C74)),
        const SizedBox(width: 6),
        Text(
          count > 0 ? '$count 条评论' : '评论',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const Spacer(),
        // 排序切换
        for (final m in _CommentSort.values)
          GestureDetector(
            onTap: () => onSortChanged(m),
            child: Container(
              margin: const EdgeInsets.only(left: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: sortMode == m
                    ? const Color(0xFFE6F2F0)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                m.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      sortMode == m ? FontWeight.w700 : FontWeight.w400,
                  color: sortMode == m
                      ? const Color(0xFF0A7C74)
                      : const Color(0xFF999999),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── 空态 ─────────────────────────────────────────────────
class _EmptyComments extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyComments({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 34),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            const Text(
              '还没有评论，来说两句吧',
              style: TextStyle(fontSize: 13, color: Color(0xFF999999)),
            ),
            const SizedBox(height: 4),
            const Text(
              '点击下方输入框参与讨论',
              style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 单条评论（含楼中楼） ────────────────────────────────────
class _CommentNode extends StatelessWidget {
  final PostComment comment;
  final String postId;
  final List<PostComment> replies;
  final PostComment? replyTarget;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<PostComment> onReply;
  final ValueChanged<String> onLike;

  const _CommentNode({
    required this.comment,
    required this.postId,
    required this.replies,
    required this.replyTarget,
    required this.expanded,
    required this.onToggleExpand,
    required this.onReply,
    required this.onLike,
  });

  /// 折叠时最多显示 2 条回复（小红书规则）
  static const _previewReplies = 2;

  @override
  Widget build(BuildContext context) {
    final isTarget = replyTarget?.id == comment.id;
    final shown = expanded ? replies : replies.take(_previewReplies).toList();
    final hidden = replies.length - shown.length;

    return Container(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 一级评论
          _Row(
            avatar: comment.authorAvatar,
            name: comment.authorName,
            time: comment.relativeTime,
            content: comment.content,
            images: comment.images,
            likeCount: comment.likeCount,
            liked: comment.likedByMe,
            highlight: isTarget,
            onLike: () => onLike(comment.id),
            onReply: () => onReply(comment),
          ),
          // 楼中楼回复（缩进）
          if (shown.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final r in shown)
                    _Row(
                      avatar: r.authorAvatar,
                      name: r.authorName,
                      time: r.relativeTime,
                      // 小红书：回复里会显示「回复 @被回复者」
                      content: _withReplyPrefix(r),
                      images: r.images,
                      likeCount: r.likeCount,
                      liked: r.likedByMe,
                      compact: true,
                      onLike: () => onLike(r.id),
                      onReply: () => onReply(comment),
                    ),
                  // 展开 / 收起
                  if (replies.length > _previewReplies || expanded)
                    GestureDetector(
                      onTap: onToggleExpand,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 1,
                              color: const Color(0xFFE0E0E0),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              expanded
                                  ? '收起回复'
                                  : '展开 ${replies.length} 条回复',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0A7C74),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (!expanded)
                              const Padding(
                                padding: EdgeInsets.only(left: 2),
                                child: Icon(Icons.keyboard_arrow_down,
                                    size: 14, color: Color(0xFF0A7C74)),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 给回复加上「回复 @某某」前缀
  String _withReplyPrefix(PostComment r) {
    if (r.parentId.isEmpty) return r.content;
    return r.content;
  }
}

// ── 一行评论（头像 + 昵称 + 内容 + 点赞） ─────────────────────
class _Row extends StatelessWidget {
  final String avatar;
  final String name;
  final String time;
  final String content;
  final List<String> images;
  final int likeCount;
  final bool liked;
  final bool highlight;
  final bool compact;
  final VoidCallback onLike;
  final VoidCallback onReply;

  const _Row({
    required this.avatar,
    required this.name,
    required this.time,
    required this.content,
    required this.likeCount,
    required this.liked,
    required this.onLike,
    required this.onReply,
    this.images = const [],
    this.highlight = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: highlight
          ? const EdgeInsets.fromLTRB(6, 4, 6, 4)
          : EdgeInsets.zero,
      decoration: highlight
          ? BoxDecoration(
              color: const Color(0xFFE6F2F0).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(text: avatar, size: compact ? 26 : 34),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: compact ? 13 : 14,
                    color: const Color(0xFF1A1A1A),
                    height: 1.45,
                  ),
                ),
                // 评论图片
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          images[i],
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                // 回复按钮（小红书放在内容下方，字号小）
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: onReply,
                  child: Text(
                    '回复',
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      color: const Color(0xFF888888),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 点赞：小红书放在右侧竖排
          GestureDetector(
            onTap: onLike,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 18),
              child: Column(
                children: [
                  Icon(
                    liked ? Icons.favorite : Icons.favorite_border,
                    size: compact ? 15 : 17,
                    color: liked ? const Color(0xFFFF4757) : const Color(0xFFBBBBBB),
                  ),
                  if (likeCount > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '$likeCount',
                      style: TextStyle(
                        fontSize: 10,
                        color: liked ? const Color(0xFFFF4757) : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String text;
  final double size;
  const _Avatar({required this.text, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2F0),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDCEDE9)),
      ),
      alignment: Alignment.center,
      child: Text(
        text.isEmpty ? '🎣' : text,
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}

// ── 固定底部输入栏（小红书核心） ─────────────────────────────
class _BottomCommentBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final PostComment? replyTarget;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onPickEmoji;

  const _BottomCommentBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.replyTarget,
    required this.onCancelReply,
    required this.onSend,
    required this.onPickImage,
    required this.onPickEmoji,
  });

  @override
  State<_BottomCommentBar> createState() => _BottomCommentBarState();
}

class _BottomCommentBarState extends State<_BottomCommentBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _canSend => widget.controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0EDE8))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 回复提示条（小红书：回复某人时出现）
              if (widget.replyTarget != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  color: const Color(0xFFF7F3EE),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '回复 @${widget.replyTarget!.authorName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0A7C74),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onCancelReply,
                        child: const Icon(Icons.close,
                            size: 15, color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                ),
              // 输入行
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 图片按钮
                    GestureDetector(
                      onTap: widget.onPickImage,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 6, right: 8),
                        child: Icon(Icons.image_outlined,
                            size: 22, color: Color(0xFF999999)),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 110),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        child: TextField(
                          controller: widget.controller,
                          focusNode: widget.focusNode,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.newline,
                          keyboardType: TextInputType.multiline,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: '说点什么...',
                            hintStyle: TextStyle(
                                fontSize: 13.5, color: Color(0xFFAAAAAA)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 表情按钮
                    GestureDetector(
                      onTap: widget.onPickEmoji,
                      child: const Padding(
                        padding: EdgeInsets.only(bottom: 6, right: 6),
                        child: Icon(Icons.emoji_emotions_outlined,
                            size: 21, color: Color(0xFF999999)),
                      ),
                    ),
                    // 发送按钮：有字才亮（小红书行为）
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _canSend && !widget.sending
                            ? const Color(0xFFFF4757)
                            : const Color(0xFFDDDDDD),
                        shape: BoxShape.circle,
                      ),
                      child: widget.sending
                          ? const Padding(
                              padding: EdgeInsets.all(9),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : GestureDetector(
                              onTap:
                                  _canSend && !widget.sending ? widget.onSend : null,
                              child: const Icon(Icons.arrow_upward,
                                  size: 18, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}