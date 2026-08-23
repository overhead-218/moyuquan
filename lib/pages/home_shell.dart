import 'package:flutter/material.dart';
import 'feed_page.dart';
import 'catch_page.dart';
import 'profile_page.dart';
import 'spot_discovery_page.dart';
import 'spot_submit_page.dart';
import 'post_publish_page.dart';

/// 主 Shell：小红书风底部导航
/// 顺序：首页 / 钓点 / ➕(发布) / 榜单 / 我（➕ 居中）
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  static const _kAccent = Color(0xFFFF4458); // 小红书红

  // 5 个槽位：0首页 / 1钓点 / 2发布占位 / 3榜单 / 4我的
  final _pages = const [
    FeedPage(),
    SpotDiscoveryPage(),
    SizedBox.shrink(), // 发布占位，不渲染
    CatchPage(),
    ProfilePage(),
  ];

  static const _items = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': '首页'},
    {'icon': Icons.place_outlined, 'activeIcon': Icons.place, 'label': '钓点'},
    null, // 发布占位（居中 ➕）
    {'icon': Icons.leaderboard_outlined, 'activeIcon': Icons.leaderboard, 'label': '榜单'},
    {'icon': Icons.person_outline, 'activeIcon': Icons.person, 'label': '我的'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _XhsBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 2) {
            _showPublishSheet();
          } else {
            setState(() => _currentIndex = i);
          }
        },
        items: _items,
        accent: _kAccent,
      ),
    );
  }

  void _showPublishSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('发布', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _publishItem('发布钓点', Icons.place_outlined, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SpotSubmitPage()));
              }),
              _publishItem('晒渔获', Icons.photo_camera_outlined, () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PostPublishPage()));
              }),
              _publishItem('写渔获日记', Icons.edit_outlined, () { Navigator.pop(context); }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _publishItem(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF333333)),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
          ],
        ),
      ),
    );
  }
}

/// 小红书风格底部 TabBar
/// 中间第 3 个槽位(index=2)为悬浮的红色 ➕ 按钮
class _XhsBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<Map<String, dynamic>?> items;
  final Color accent;

  const _XhsBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              // 第 3 个槽位（index=2）渲染红色 ➕ 按钮
              if (i == 2) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(2),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 32,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                );
              }

              final item = items[i]!;
              final selected = currentIndex == i;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    height: 64,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selected
                              ? (item['activeIcon'] as IconData)
                              : (item['icon'] as IconData),
                          color: selected
                              ? const Color(0xFF333333)
                              : const Color(0xFF999999),
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? const Color(0xFF333333)
                                : const Color(0xFF999999),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.only(top: 4),
                          height: 2,
                          width: selected ? 18 : 0,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(1),
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
    );
  }
}
