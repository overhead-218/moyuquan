import 'package:flutter/material.dart';

/// 设置页
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kRed = Color(0xFFFF4757);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _sections = [
    {
      'title': '账号设置',
      'items': [
        {'icon': Icons.person_outline, 'label': '编辑资料', 'trailing': ''},
        {'icon': Icons.lock_outline, 'label': '修改密码', 'trailing': ''},
        {'icon': Icons.phone_android, 'label': '更换手机', 'trailing': ''},
        {'icon': Icons.qr_code, 'label': '微信绑定', 'trailing': '已绑定'},
      ],
    },
    {
      'title': '偏好设置',
      'items': [
        {'icon': Icons.notifications_outlined, 'label': '消息通知', 'trailing': '已开启'},
        {'icon': Icons.location_on_outlined, 'label': '位置权限', 'trailing': '已授权'},
        {'icon': Icons.palette_outlined, 'label': '深色模式', 'trailing': '关闭'},
        {'icon': Icons.language, 'label': '语言', 'trailing': '简体中文'},
      ],
    },
    {
      'title': '隐私与安全',
      'items': [
        {'icon': Icons.visibility_off_outlined, 'label': '隐私政策', 'trailing': ''},
        {'icon': Icons.description_outlined, 'label': '用户协议', 'trailing': ''},
        {'icon': Icons.delete_outline, 'label': '注销账号', 'trailing': '', 'danger': true},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            for (final section in _sections) ...[
              // 分组标题
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 4),
                child: Row(
                  children: [
                    Text(
                      section['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              // 设置项列表
              Container(
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
                child: Column(
                  children: List.generate(
                    (section['items'] as List).length,
                    (i) {
                      final item =
                          (section['items'] as List)[i] as Map<String, dynamic>;
                      final isLast =
                          i == (section['items'] as List).length - 1;
                      final isDanger = item['danger'] == true;
                      return Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              item['icon'] as IconData,
                              color:
                                  isDanger ? _kRed : const Color(0xFF0A7C74),
                              size: 22,
                            ),
                            title: Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                color: isDanger
                                    ? _kRed
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if ((item['trailing'] as String).isNotEmpty)
                                  Text(
                                    item['trailing'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  color: isDanger
                                      ? _kRed.withValues(alpha: 0.5)
                                      : const Color(0xFF999999),
                                  size: 20,
                                ),
                              ],
                            ),
                            onTap: () {
                              if (isDanger) {
                                _showDangerDialog(context);
                              }
                            },
                          ),
                          if (!isLast)
                            Container(
                              height: 1,
                              margin: const EdgeInsets.only(left: 56),
                              color: const Color(0xFFF0EEE9),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            // 版本信息
            Center(
              child: Column(
                children: [
                  const Text(
                    '摸鱼圈 v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '检查更新',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0A7C74),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 退出登录
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text('确认退出登录？'),
                      content: const Text('退出后将断开与服务器的连接'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            '取消',
                            style: TextStyle(color: Color(0xFF999999)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: const Text('退出'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kRed,
                  side: const BorderSide(color: Color(0xFFFF4757)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '退出登录',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDangerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('注销账号'),
        content: const Text(
          '注销后将永久删除您的账号数据，此操作不可恢复。确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '取消',
              style: TextStyle(color: Color(0xFF999999)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('确认注销'),
          ),
        ],
      ),
    );
  }
}
