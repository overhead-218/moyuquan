import 'package:flutter/material.dart';
import 'profile_edit_page.dart';
import 'my_posts_page.dart';
import 'followers_page.dart';
import 'following_page.dart';
import 'my_catch_page.dart';
import 'favorites_page.dart';
import 'settings_page.dart';
import 'message_page.dart';
import 'login_page.dart';
import '../services/message_service.dart';
import '../services/user_profile.dart';
import '../services/post_service.dart';
import '../services/follow_service.dart';
import '../services/favorite_service.dart';

/// 我的
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = UserProfile.instance.name;
  String _bio = UserProfile.instance.bio;
  String _city = UserProfile.instance.city;
  String _avatar = UserProfile.instance.avatarEmoji;
  bool _loggedIn = UserProfile.instance.isLoggedIn;

  @override
  void initState() {
    super.initState();
    UserProfile.instance.addListener(_refresh);
    PostService.addListener(_refresh);
    FollowService.instance.addListener(_refresh);
    FavoriteService.instance.addListener(_refresh);
    MessageService.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    UserProfile.instance.removeListener(_refresh);
    PostService.removeListener(_refresh);
    FollowService.instance.removeListener(_refresh);
    FavoriteService.instance.removeListener(_refresh);
    MessageService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {
      _name = UserProfile.instance.name;
      _bio = UserProfile.instance.bio;
      _city = UserProfile.instance.city;
      _avatar = UserProfile.instance.avatarEmoji;
      _loggedIn = UserProfile.instance.isLoggedIn;
    });
  }

  /// 编辑资料页返回后同步一次
  void _load() => _refresh();

  @override
  Widget build(BuildContext context) {
    final unread = MessageService.totalUnread;
    final hasUnread = unread > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '我的',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A7C74),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF0A7C74)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          children: [
            // 头像卡片（渐变）：跳转编辑资料
            _AnimatedEntry(
              index: 0,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileEditPage()),
                ).then((_) => _load()),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A7C74), Color(0xFF148F86)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A7C74).withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'avatar',
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2.5),
                          ),
                          alignment: Alignment.center,
                          child: Text(_avatar, style: const TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _bio,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white70, size: 13),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    _city,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 消息入口（显眼位：头像下方独立卡）
            _AnimatedEntry(
              index: 1,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MessagePage()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4458).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.notifications_none,
                              color: Color(0xFFFF4458),
                              size: 26,
                            ),
                          ),
                          if (hasUnread)
                            Positioned(
                              right: -3,
                              top: -3,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF4458),
                                  shape: BoxShape.circle,
                                  border: Border.fromBorderSide(
                                    BorderSide(color: Colors.white, width: 2),
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    unread > 99 ? '99+' : '$unread',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '消息',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasUnread ? '$unread 条新消息' : '暂无新消息',
                              style: TextStyle(
                                fontSize: 12,
                                color: hasUnread
                                    ? const Color(0xFF999999)
                                    : const Color(0xFFBBBBBB),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF999999),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 数据栏：帖子/粉丝/关注
            _AnimatedEntry(
              index: 2,
              child: Row(
                children: [
                  _StatBlock(
                    label: '帖子',
                    value: '${PostService.myPosts().length}',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyPostsPage()),
                    ),
                  ),
                  _StatBlock(
                    label: '粉丝',
                    value: '${FollowService.instance.followerCount}',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FollowersPage()),
                    ),
                  ),
                  _StatBlock(
                    label: '关注',
                    value: '${FollowService.instance.followingCount}',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FollowingPage()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 身份/等级卡片：登录态联动（无积分体系时展示真实登录状态）
            _AnimatedEntry(
              index: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: _loggedIn
                    ? const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFC49A5E), Color(0xFFE0B670)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      )
                    : BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF0A7C74).withValues(alpha: 0.25),
                        ),
                      ),
                child: Row(
                  children: [
                    Icon(
                      _loggedIn ? Icons.verified : Icons.person_outline,
                      color: _loggedIn
                          ? Colors.white
                          : const Color(0xFF0A7C74),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _loggedIn ? '已登录' : '游客模式',
                            style: TextStyle(
                              color:
                                  _loggedIn ? Colors.white : const Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _loggedIn
                                ? (UserProfile.instance.loginMethod == 'apple'
                                    ? 'Apple 登录 · 资料会话内有效'
                                    : '资料已保存')
                                : '登录后体验完整功能',
                            style: TextStyle(
                              color: _loggedIn
                                  ? Colors.white70
                                  : const Color(0xFF999999),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_loggedIn)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A7C74),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '去登录',
                            style: TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 菜单列表
            _AnimatedEntry(
              index: 4,
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.emoji_events,
                    label: '我的鱼获',
                    trailing: '${PostService.myCatchPosts().length}',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyCatchPage()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.bookmark,
                    label: '收藏',
                    trailing: '${FavoriteService.instance.postCount}',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesPage()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.settings,
                    label: '设置',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsPage()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 滑入动效包装组件
class _AnimatedEntry extends StatelessWidget {
  final Widget child;
  final int index;

  const _AnimatedEntry({required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// 数据栏：白底中卡，数字主色
class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _StatBlock({
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0A7C74),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF666666), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 菜单项：图标+标签+右箭头，白底大圆角柔阴影
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final int? badge;
  final VoidCallback? onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: const Color(0xFF0A7C74)),
            if (badge != null)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: badge! > 0 ? 16 : 9,
                  height: badge! > 0 ? 16 : 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4458),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: badge! > 0
                      ? Center(
                          child: Text(
                            badge! > 9 ? '9+' : badge!.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        )
                      : null,
                ),
              ),
          ],
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))),
        trailing: trailing != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(trailing!,
                      style: const TextStyle(
                          color: Color(0xFF999999), fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Color(0xFF999999)),
                ],
              )
            : const Icon(Icons.chevron_right, color: Color(0xFF999999)),
      ),
    );
  }
}
