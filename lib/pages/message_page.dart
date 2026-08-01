import 'package:flutter/material.dart';
import 'chat_detail_page.dart';

/// 消息
class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kRed = Color(0xFFFF4757);
  static const Color _kShadow = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> messages = [
      {'name': '海钓阿强', 'last': '明天出发钓鱼？', 'time': '刚刚', 'avatar': '🎣', 'unread': 2},
      {'name': '钓鱼王', 'last': '这个饵料配方很赞', 'time': '12:30', 'avatar': '🐟', 'unread': 0},
      {'name': '野钓大叔', 'last': '[图片]', 'time': '昨天', 'avatar': '🎣', 'unread': 1},
      {'name': '江南老饕', 'last': '好的，到时见', 'time': '昨天', 'avatar': '🦑', 'unread': 0},
      {'name': '老李', 'last': '上次那个钓点还有?', 'time': '周一', 'avatar': '🐠', 'unread': 0},
      {'name': '渔民小张', 'last': '今天收获不错', 'time': '周日', 'avatar': '🐟', 'unread': 0},
      {'name': '菜鸟', 'last': '新手求带', 'time': '周日', 'avatar': '🎣', 'unread': 5},
    ];

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          '消息',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        tween: Tween<double>(begin: 0.9, end: 1),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          tween: Tween<double>(begin: 0, end: 1),
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final m = messages[i];
              final unread = m['unread'] as int;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailPage(
                        name: m['name'] as String,
                        avatar: m['avatar'] as String,
                      ),
                    ),
                  );
                },
                child: Container(
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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 56),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildAvatar(m['avatar'] as String, unread),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _kTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m['last'] as String,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kTextWeak,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            m['time'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kTextWeak,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 圆形头像（极浅青底）+ 未读小红点（#FF4757）
  Widget _buildAvatar(String emoji, int unread) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: _kTealBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        if (unread > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kRed,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    color: _kShadow.withValues(alpha: 0.04),
                  ),
                ],
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
