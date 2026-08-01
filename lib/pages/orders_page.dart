import 'package:flutter/material.dart';

/// 我的订单页
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _tabs = ['全部', '待付款', '待发货', '已完成', '已取消'];

  static const _orders = [
    {
      'id': 'ORD20260728001',
      'shop': '摸鱼圈装备旗舰店',
      'items': [
        {'name': '碳素海钓竿 3.6m', 'qty': 1, 'price': '¥398'},
      ],
      'total': '¥398',
      'status': '待付款',
      'time': '2026-07-28 10:30',
    },
    {
      'id': 'ORD20260725002',
      'shop': '渔具城官方店',
      'items': [
        {'name': '钓鱼饵料套装', 'qty': 2, 'price': '¥128'},
      ],
      'total': '¥256',
      'status': '待发货',
      'time': '2026-07-25 14:22',
    },
    {
      'id': 'ORD20260720003',
      'shop': '户外装备专营店',
      'items': [
        {'name': '钓鱼防晒帽', 'qty': 1, 'price': '¥89'},
      ],
      'total': '¥89',
      'status': '已完成',
      'time': '2026-07-20 09:15',
    },
    {
      'id': 'ORD20260715004',
      'shop': '摸鱼圈装备旗舰店',
      'items': [
        {'name': '专业钓鱼手套', 'qty': 1, 'price': '¥68'},
      ],
      'total': '¥68',
      'status': '已取消',
      'time': '2026-07-15 16:40',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          '我的订单',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: _kPrimary,
          unselectedLabelColor: _kTextWeak,
          indicatorColor: _kPrimary,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final order = _orders[i];
          return _OrderCard(
            id: order['id'] as String,
            shop: order['shop'] as String,
            items: (order['items'] as List)
                .map((e) => {
                      'name': e['name'] as String,
                      'qty': e['qty'] as int,
                      'price': e['price'] as String,
                    })
                .toList(),
            total: order['total'] as String,
            status: order['status'] as String,
            time: order['time'] as String,
          );
        },
      ),
    );
  }
}

// Top-level constants
const _kPrimaryOrd = Color(0xFF0A7C74);
const _kSurfaceOrd = Color(0xFFFFFFFF);
const _kTextPrimaryOrd = Color(0xFF1A1A1A);
const _kTextWeakOrd = Color(0xFF999999);
const _kShadowOrd = Color(0xFF1A1A1A);

class _OrderCard extends StatelessWidget {
  final String id;
  final String shop;
  final List<Map<String, dynamic>> items;
  final String total;
  final String status;
  final String time;

  const _OrderCard({
    required this.id,
    required this.shop,
    required this.items,
    required this.total,
    required this.status,
    required this.time,
  });

  Color _statusColor() {
    switch (status) {
      case '待付款':
        return const Color(0xFFFF4757);
      case '待发货':
        return _kPrimaryOrd;
      case '已完成':
        return _kTextWeakOrd;
      case '已取消':
        return const Color(0xFF999999);
      default:
        return _kTextWeakOrd;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurfaceOrd,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 16,
            color: _kShadowOrd.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Column(
        children: [
          // 店铺信息栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(Icons.store, size: 16, color: _kPrimaryOrd),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shop,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimaryOrd,
                    ),
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0EEE9)),
          // 商品列表
          ...items.map((item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F2F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('📦', style: TextStyle(fontSize: 26)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _kTextPrimaryOrd,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'x${item['qty']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _kTextWeakOrd,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item['price'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kTextPrimaryOrd,
                      ),
                    ),
                  ],
                ),
              )),
          // 底部操作栏
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '订单号: $id',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kTextWeakOrd,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kTextWeakOrd,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '合计: $total',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kTextPrimaryOrd,
                  ),
                ),
                if (status == '待付款') ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4757),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      '去付款',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
