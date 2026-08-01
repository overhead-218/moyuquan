import 'package:flutter/material.dart';
import 'followers_page.dart';
import 'following_page.dart';

/// 他人主页
class UserProfilePage extends StatelessWidget {
  final String name;
  final String avatar;
  final String bio;
  final int posts;
  final int followers;
  final int following;

  const UserProfilePage({
    super.key,
    required this.name,
    required this.avatar,
    required this.bio,
    required this.posts,
    required this.followers,
    required this.following,
  });

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kLightTeal = Color(0xFF148F86);
  static const Color _kDarkTeal = Color(0xFF075C56);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kGold = Color(0xFFC49A5E);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _images = [
    'https://picsum.photos/seed/user1a/400/300.jpg',
    'https://picsum.photos/seed/user1b/400/280.jpg',
    'https://picsum.photos/seed/user1c/400/320.jpg',
  ];

  @override
  Widget build(BuildContext context) {
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
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                        child: Text(avatar, style: const TextStyle(fontSize: 40)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        bio,
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
          // 粉丝数据栏
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 数据栏
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
                        _StatCol(value: '$posts', label: '帖子'),
                        _buildDivider(),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FollowersPage(),
                            ),
                          ),
                          child: _StatCol(value: '$followers', label: '粉丝'),
                        ),
                        _buildDivider(),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FollowingPage(),
                            ),
                          ),
                          child: _StatCol(value: '$following', label: '关注'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text(
                            '+ 关注',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {},
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
                  const SizedBox(height: 20),
                  // 作品标题
                  const Row(
                    children: [
                      Icon(Icons.grid_on, size: 18, color: _kPrimary),
                      SizedBox(width: 6),
                      Text(
                        '作品',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          // 作品网格
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
                  return GestureDetector(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: _kTealBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        _images[i % _images.length],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, st) => Container(
                          color: _kTealBg,
                          child: const Center(
                            child: Text('📷', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: 9,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
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
