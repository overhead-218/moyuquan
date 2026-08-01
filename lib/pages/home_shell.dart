import 'package:flutter/material.dart';
import 'feed_page.dart';
import 'catch_page.dart';
import 'map_page.dart';
import 'message_page.dart';
import 'profile_page.dart';

/// 主 Shell：底部导航 + 5 个 Tab
/// Stitch 风格：Material 3 Expressive，暖白背景、青绿主色、金色点缀
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _kPrimary = Color(0xFF0A7C74);
  static const _kTealBg = Color(0xFFE6F2F0);
  static const _kBackground = Color(0xFFF7F3EE);

  final _pages = const [
    FeedPage(),
    CatchPage(),
    MapPage(),
    MessagePage(),
    ProfilePage(),
  ];

  static const _items = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': '首页'},
    {'icon': Icons.emoji_events_outlined, 'activeIcon': Icons.emoji_events, 'label': '鱼获'},
    {'icon': Icons.map_outlined, 'activeIcon': Icons.map, 'label': '地图'},
    {'icon': Icons.mail_outline, 'activeIcon': Icons.mail, 'label': '消息'},
    {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': '我的'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      // 底部导航栏：白底 + 圆角顶部 + lg 柔阴影
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1A1A).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final selected = _currentIndex == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? _kTealBg
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected
                                ? (item['activeIcon'] as IconData)
                                : (item['icon'] as IconData),
                            color: selected
                                ? _kPrimary
                                : const Color(0xFF999999),
                            size: 24,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item['label'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected
                                  ? _kPrimary
                                  : const Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
