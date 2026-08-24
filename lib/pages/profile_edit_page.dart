import 'package:flutter/material.dart';
import '../services/user_profile.dart';

/// 编辑资料页
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kLightTeal = Color(0xFF148F86);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kShadow = Color(0xFF1A1A1A);

  final _nicknameCtrl =
      TextEditingController(text: UserProfile.instance.name);
  final _bioCtrl = TextEditingController(text: UserProfile.instance.bio);
  final _locationCtrl =
      TextEditingController(text: UserProfile.instance.city);
  String _gender = UserProfile.instance.gender;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
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
          '编辑资料',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              UserProfile.instance.name = _nicknameCtrl.text.trim();
              UserProfile.instance.bio = _bioCtrl.text.trim();
              UserProfile.instance.city = _locationCtrl.text.trim();
              UserProfile.instance.gender = _gender;
              UserProfile.instance.save();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('资料已保存'),
                  backgroundColor: _kPrimary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Navigator.pop(context);
            },
            child: const Text(
              '保存',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 头像编辑区
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 16,
                    color: _kShadow.withValues(alpha: 0.06),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: _kTealBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _kPrimary.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                        child: const Center(
                          child: Text('🎣', style: TextStyle(fontSize: 44)),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _kPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(color: _kSurface, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '点击更换头像',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kTextWeak,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 基本信息表单
            _buildFormCard([
              _buildTextField(
                label: '昵称',
                controller: _nicknameCtrl,
                hint: '请输入昵称',
              ),
              _buildDivider(),
              _buildTextField(
                label: '个性签名',
                controller: _bioCtrl,
                hint: '介绍一下自己',
                maxLines: 3,
              ),
              _buildDivider(),
              _buildTextField(
                label: '所在地',
                controller: _locationCtrl,
                hint: '如：南京、杭州',
              ),
              _buildDivider(),
              _buildGenderSelector(),
            ]),
            const SizedBox(height: 16),
            // 账号信息
            _buildFormCard([
              _buildInfoRow('手机号', '138****8888'),
              _buildDivider(),
              _buildInfoRow('绑定微信', '已绑定'),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 16,
            color: _kShadow.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: _kTextWeak,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(
                fontSize: 14,
                color: _kTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: _kTextWeak),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(
            width: 80,
            child: Text(
              '性别',
              style: TextStyle(fontSize: 14, color: _kTextWeak),
            ),
          ),
          _GenderChip(
            label: '男',
            selected: _gender == '男',
            onTap: () => setState(() => _gender = '男'),
          ),
          const SizedBox(width: 12),
          _GenderChip(
            label: '女',
            selected: _gender == '女',
            onTap: () => setState(() => _gender = '女'),
          ),
          const SizedBox(width: 12),
          _GenderChip(
            label: '保密',
            selected: _gender == '保密',
            onTap: () => setState(() => _gender = '保密'),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFF0EEE9),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: _kTextWeak),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: _kTextPrimary),
              ),
              if (label == '手机号')
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    '更换',
                    style: TextStyle(fontSize: 13, color: _kPrimary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0A7C74) : const Color(0xFFE6F2F0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF0A7C74),
          ),
        ),
      ),
    );
  }
}
