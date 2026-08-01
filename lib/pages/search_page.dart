import 'package:flutter/material.dart';

/// 搜索页：综合搜索 + 热门发现
/// Stitch 风格：Material 3 Expressive，暖白背景、青绿主色、金色点缀
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';

  static const _history = ['鲤鱼 饵料', '南京 野钓', '海钓 路线', '夜钓 安全'];
  static const _hotTopics = [
    {'tag': '🔥 本周热帖', 'title': '野钓空军的十大原因', 'count': '2.3万'},
    {'tag': '💰 活动', 'title': '摸鱼圈钓友交流会·南京站', 'count': '1568'},
    {'tag': '📖 攻略', 'title': '夏季夜钓选位指南', 'count': '9804'},
    {'tag': '🎣 新手', 'title': '第一次海钓需要准备什么？', 'count': '8762'},
    {'tag': '🏆 赛事', 'title': '2026全国钓鱼锦标赛报名开启', 'count': '5431'},
    {'tag': '🌊 海钓', 'title': '舟山矶钓圣地合集', 'count': '4321'},
  ];
  static const _users = [
    {'name': '钓鱼王老李', 'avatar': '🎣', 'bio': '专注野钓15年，抖音粉丝12万'},
    {'name': '海钓阿强', 'avatar': '🚤', 'bio': '舟山专业海钓船长，带队8年'},
    {'name': '鱼妹儿', 'avatar': '🐟', 'bio': '钓鱼美食博主，爱分享渔获菜谱'},
  ];
  static const _posts = [
    {'title': '周末两天狂拉20斤鲤鱼，饵料配方分享', 'author': '老李', 'likes': '892'},
    {'title': '清晨5点出发，大板鲫连竿上岸全过程', 'author': '阿飞', 'likes': '645'},
    {'title': '海钓初体验，石斑鱼爆箱！', 'author': '菜鸟', 'likes': '1203'},
  ];
  static const _places = [
    {'name': '南京·紫金山野钓点', 'dist': '1.2km', 'stars': '★4.8'},
    {'name': '扬州·邵伯湖休闲钓', 'dist': '38km', 'stars': '★4.5'},
    {'name': '苏州·阳澄湖蟹塘', 'dist': '95km', 'stars': '★4.3'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String q) {
    setState(() => _query = q.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F3EE),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0A7C74)),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
          decoration: InputDecoration(
            hintText: '搜索用户、帖子、钓点...',
            hintStyle: const TextStyle(color: Color(0xFF999999)),
            filled: true,
            fillColor: const Color(0xFFF0EEE9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF0A7C74),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear,
                        size: 18, color: Color(0xFF999999)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (v) => setState(() {}),
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.search, color: Color(0xFF0A7C74)),
              onPressed: () => _search(_searchController.text),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0A7C74),
          unselectedLabelColor: const Color(0xFF999999),
          indicatorColor: const Color(0xFF0A7C74),
          indicatorWeight: 2.5,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: '综合搜索'),
            Tab(text: '热门发现'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab1：综合搜索
          _query.isEmpty ? _buildEmptyState() : _buildSearchResults(),
          // Tab2：热门发现
          _buildHotDiscover(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_history.isNotEmpty) ...[
            // 搜索历史标题
            const Text(
              '搜索历史',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
            // 搜索历史 chips：全圆浅青底
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _history.map((h) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = h;
                    _search(h);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F2F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history,
                            size: 14, color: Color(0xFF0A7C74)),
                        const SizedBox(width: 6),
                        Text(
                          h,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF0A7C74)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  '清空历史',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户
          _SectionTitle('用户', Icons.person),
          ..._users.map((u) => _UserTile(
                name: u['name']!,
                avatar: u['avatar']!,
                bio: u['bio']!,
              )),
          const SizedBox(height: 8),
          // 帖子
          _SectionTitle('帖子', Icons.article),
          ..._posts.map((p) => _PostTile(
                title: p['title']!,
                author: p['author']!,
                likes: p['likes']!,
              )),
          const SizedBox(height: 8),
          // 钓点
          _SectionTitle('钓点', Icons.location_on),
          ..._places.map((p) => _PlaceTile(
                name: p['name']!,
                dist: p['dist']!,
                stars: p['stars']!,
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHotDiscover() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 热门话题标题
          const Text(
            '🔥 热门话题',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 12),
          ..._hotTopics.map((t) => _HotTopicTile(
                tag: t['tag']!,
                title: t['title']!,
                count: t['count']!,
              )),
          const SizedBox(height: 24),
          // 搜索历史
          if (_history.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF666666),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    '清空',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 搜索历史 chips：全圆浅青底
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _history.map((h) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = h;
                    _search(h);
                    _tabController.animateTo(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F2F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      h,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF0A7C74)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionTitle(this.label, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0A7C74)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A7C74),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final String name, avatar, bio;
  const _UserTile({
    required this.name,
    required this.avatar,
    required this.bio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(avatar, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  bio,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0A7C74).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '+ 关注',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0A7C74),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  final String title, author, likes;
  const _PostTile({
    required this.title,
    required this.author,
    required this.likes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Text(
                      '@$author',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0A7C74),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.favorite,
                        size: 12, color: Color(0xFF999999)),
                    const SizedBox(width: 3),
                    Text(
                      likes,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0A7C74).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('📷', style: TextStyle(fontSize: 28)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceTile extends StatelessWidget {
  final String name, dist, stars;
  const _PlaceTile({
    required this.name,
    required this.dist,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF0A7C74).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('📍', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      dist,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      stars,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC49A5E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF999999)),
        ],
      ),
    );
  }
}

class _HotTopicTile extends StatelessWidget {
  final String tag, title, count;
  const _HotTopicTile({
    required this.tag,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final isHot = tag.contains('🔥');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isHot
                  ? const Color(0xFFFF4757).withValues(alpha: 0.1)
                  : const Color(0xFF0A7C74).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isHot ? const Color(0xFFFF4757) : const Color(0xFF0A7C74),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }
}
