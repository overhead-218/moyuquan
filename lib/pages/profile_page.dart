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

/// 我的
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                ),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '老李',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '已钓鱼 3 年 · 钓获 128 种',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
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
            // 数据栏：帖子/粉丝/关注
            _AnimatedEntry(
              index: 1,
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
              index: 2,
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
              index: 3,
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
  final VoidCallback? onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
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
        leading: Icon(icon, color: const Color(0xFF0A7C74)),
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
