import 'package:flutter/material.dart';
import '../models/spot.dart';
import 'spot_detail_page.dart';
import 'user_profile_page.dart';

/// 地图：全屏找钓点 / 钓友（小红书风）
/// 说明：地图底图为高保真模拟占位，待接入地图 SDK 后替换 _buildMapBackground
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  int _tab = 0; // 0 钓点 / 1 钓友
  static const _accent = Color(0xFFFF4458);

  static const _spots = <Map<String, dynamic>>[
    {'emoji': '🎣', 'name': '青龙湖野钓点', 'meta': '鲈鱼 · 鲫鱼', 'dist': '1.2km', 'x': 0.30, 'y': 0.30},
    {'emoji': '🐟', 'name': '东海岸矶钓区', 'meta': '海鲈 · 黑鲷', 'dist': '3.5km', 'x': 0.72, 'y': 0.22},
    {'emoji': '🦑', 'name': '西山溪流水域', 'meta': '溪哥 · 马口', 'dist': '5.0km', 'x': 0.46, 'y': 0.55},
    {'emoji': '🐠', 'name': '城南护城河', 'meta': '鲤鱼 · 草鱼', 'dist': '800m', 'x': 0.78, 'y': 0.60},
    {'emoji': '🎣', 'name': '北郊野塘', 'meta': '鲫鱼 · 白条', 'dist': '2.1km', 'x': 0.22, 'y': 0.66},
  ];

  static const _anglers = <Map<String, dynamic>>[
    {'emoji': '🧑', 'name': '老李', 'meta': '正在青龙湖', 'dist': '1.2km', 'x': 0.32, 'y': 0.34},
    {'emoji': '👨', 'name': '阿飞', 'meta': '正在东海岸', 'dist': '3.5km', 'x': 0.70, 'y': 0.26},
    {'emoji': '🧔', 'name': '钓鱼王', 'meta': '正在西山', 'dist': '5.0km', 'x': 0.48, 'y': 0.58},
    {'emoji': '👩', 'name': '海钓阿强', 'meta': '正在城南河', 'dist': '800m', 'x': 0.80, 'y': 0.56},
    {'emoji': '🧓', 'name': '野钓大叔', 'meta': '正在北郊', 'dist': '2.1km', 'x': 0.24, 'y': 0.62},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final list = _tab == 0 ? _spots : _anglers;
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0EC),
      body: Stack(
        children: [
          // 地图底图（模拟）
          SizedBox.expand(child: _buildMapBackground()),
          // 标记
          for (final m in list) _buildMarker(size, m),
          // 顶部栏
          _buildTopBar(),
          // 定位 FAB
          Positioned(
            right: 12,
            bottom: 284,
            child: _buildFab(),
          ),
          // 底部浮层
          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF1ED), Color(0xFFDCE9E4)],
        ),
      ),
      child: Stack(
        children: [
          // 水域块
          Positioned(left: -40, top: 70, child: _blob(190, 130, const Color(0xFFBFE0E6))),
          Positioned(right: -30, top: 190, child: _blob(230, 170, const Color(0xFFC7E3E8))),
          Positioned(left: 40, bottom: 60, child: _blob(210, 160, const Color(0xFFC2E0E6))),
          // 绿地块
          Positioned(right: 70, top: 40, child: _blob(95, 75, const Color(0xFFD7E8CE))),
          // 道路
          _road(40, 240, 0.35),
          _road(120, 110, -0.55),
          _road(220, 360, 0.15),
        ],
      ),
    );
  }

  Widget _blob(double w, double h, Color c) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(40),
        ),
      );

  Widget _road(double left, double top, double rot) => Positioned(
        left: left,
        top: top,
        child: Transform.rotate(
          angle: rot,
          child: Container(
            width: 420,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      );

  Widget _buildMarker(Size size, Map<String, dynamic> m) {
    final left = size.width * (m['x'] as double) - 16;
    final top = size.height * (m['y'] as double) - 18;
    final isSpot = _tab == 0;
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          if (isSpot) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SpotDetailPage(
                  spot: const Spot(
                    id:'', name:'钓点',
                    type:'野钓',typeEmoji:'🎣',
                    city:'南京',district:'南京',
                    address:'待完善',
                    latitude:0,longitude:0,
                    images:[],fishSpecies:[],
                    fishPeakSeason:const{},lastStockingDate:null,stockingCycleDays:0,price:0,priceNote:'',businessHours:'',rating:0,
                    reviewCount:0,viewCount:0,favoriteCount:0,postCount:0,
                    description:'待完善',
                  ),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfilePage(
                  name: m['name'] as String,
                  avatar: m['emoji'] as String,
                  bio: m['meta'] as String,
                  posts: 12,
                  followers: 230,
                  following: 88,
                ),
              ),
            );
          }
        },
        child: isSpot ? _spotPin(m) : _anglerPin(m),
      ),
    );
  }

  Widget _spotPin(Map<String, dynamic> m) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _accent, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Text(m['emoji'] as String, style: const TextStyle(fontSize: 16)),
      );

  Widget _anglerPin(Map<String, dynamic> m) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Color(0xFF1F6F8B), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Text(m['emoji'] as String, style: const TextStyle(fontSize: 16)),
      );

  Widget _buildTopBar() => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Icon(Icons.expand_more, color: Colors.white, size: 18),
                const SizedBox(width: 2),
                const Text(
                  '南京',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 22),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildFab() => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: const Icon(Icons.my_location, color: Color(0xFF333333), size: 22),
      );

  Widget _buildBottomSheet() => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          height: 264,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4)),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _sheetTab('附近钓点', 0),
                  _sheetTab('附近钓友', 1),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: (_tab == 0 ? _spots : _anglers)
                      .map((m) => _listItem(m))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _sheetTab(String label, int idx) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tab = idx),
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _tab == idx ? FontWeight.w700 : FontWeight.w400,
                    color: _tab == idx
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFF999999),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 2,
                width: _tab == idx ? 28 : 0,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _listItem(Map<String, dynamic> m) {
    final isSpot = _tab == 0;
    return GestureDetector(
      onTap: () {
        if (isSpot) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpotDetailPage(
                spot: const Spot(
                  id:'', name:'钓点',
                  type:'野钓',typeEmoji:'🎣',
                  city:'南京',district:'南京',
                  address:'待完善',
                  latitude:0,longitude:0,
                  images:[],fishSpecies:[],
                  fishPeakSeason:const{},lastStockingDate:null,stockingCycleDays:0,price:0,priceNote:'',businessHours:'',rating:0,
                  reviewCount:0,viewCount:0,favoriteCount:0,postCount:0,
                  description:'待完善',
                ),
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UserProfilePage(
                name: m['name'] as String,
                avatar: m['emoji'] as String,
                bio: m['meta'] as String,
                posts: 12,
                followers: 230,
                following: 88,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F3EE),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(m['emoji'] as String, style: const TextStyle(fontSize: 22)),
              ),
            ),
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
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${m['meta']} · ${m['dist']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }
}
