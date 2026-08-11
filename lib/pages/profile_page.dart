import 'package:flutter/material.dart';
import 'profile_edit_page.dart';
import 'my_posts_page.dart';
import 'followers_page.dart';
import 'following_page.dart';
import 'my_catch_page.dart';
import 'favorites_page.dart';
import 'history_places_page.dart';
import 'member_center_page.dart';
import 'orders_page.dart';
import 'settings_page.dart';
import 'message_page.dart';
import '../services/message_service.dart';
import '../services/user_profile.dart';

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

  @override
  void initState() {
    super.initState();
  }

  void _load() {
    setState(() {
      _name = UserProfile.instance.name;
      _bio = UserProfile.instance.bio;
      _city = UserProfile.instance.city;
    });
  }

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
                          child:
                              const Text('🎣', style: TextStyle(fontSize: 36)),
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
                    value: '12',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyPostsPage()),
                    ),
                  ),
                  _StatBlock(
                    label: '粉丝',
                    value: '356',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FollowersPage()),
                    ),
                  ),
                  _StatBlock(
                    label: '关注',
                    value: '89',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FollowingPage()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 等级卡片（金色渐变）
            _AnimatedEntry(
              index: 3,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFC49A5E), Color(0xFFE0B670)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.white, size: 36),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('黄金钓手 Lv.5',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              )),
                          SizedBox(height: 6),
                          Text('距离下一级还需 1,243 经验值',
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
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
                    trailing: '128',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyCatchPage()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.bookmark,
                    label: '收藏',
                    trailing: '56',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FavoritesPage()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.history,
                    label: '历史钓点',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryPlacesPage()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.card_giftcard,
                    label: '会员中心',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MemberCenterPage()),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.shopping_bag,
                    label: '我的订单',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrdersPage()),
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
