import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/spot.dart';
import '../services/moderation_service.dart';
import '../services/spot_service.dart';

/// 钓点认领 + 举报弹窗
///
/// ⚠️ 这两个功能在钓点详情页重写（spot_detail_page.dart → spot_detail_new.dart）
///    的过程中被弄丢了：
///    - 「认领」退化成一个 toast 提示「认领入口在钓点资料页」→ 但钓点资料页并没有这个入口
///    - 「举报」整个消失
///    `ClaimService.submit()` 服务层还在，只是没有页面调用它。
///    这里把两个入口补回来。
///
/// 旧版实现参考 git 历史：f0d992c 的 spot_detail_page.dart
///   - `_showClaimSheet()` 认领弹窗
///   - `_showReportSheet()` 举报弹窗（可带图）

/// 打开钓点认领弹窗。返回是否认领成功。
Future<bool> showSpotClaimSheet(BuildContext context, Spot spot) async {
  final nameCtl = TextEditingController(text: spot.ownerName ?? '');
  final phoneCtl = TextEditingController(text: spot.contactPhone ?? '');
  final wxCtl = TextEditingController(text: spot.wechat ?? '');

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('认领此钓点',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2A2520))),
          const SizedBox(height: 4),
          const Text('认领后可自助维护联系方式，让钓友准确找到你',
              style: TextStyle(fontSize: 12, color: Color(0xFF8A8578))),
          const SizedBox(height: 16),
          _field(label: '负责人 / 店名', hint: '如：老王钓场', controller: nameCtl),
          const SizedBox(height: 12),
          _field(label: '联系电话', hint: '公开管理电话', controller: phoneCtl,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          _field(label: '微信号', hint: '便于钓友加微信咨询', controller: wxCtl),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final name = nameCtl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('请填写负责人或店名'),
                      duration: Duration(seconds: 2)));
                  return;
                }
                final updated = SpotService.claimSpot(
                  spot.id,
                  ownerName: name,
                  contactPhone:
                      phoneCtl.text.trim().isEmpty ? null : phoneCtl.text.trim(),
                  wechat: wxCtl.text.trim().isEmpty ? null : wxCtl.text.trim(),
                );
                if (updated == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('认领失败：钓点不存在'),
                      duration: Duration(seconds: 2)));
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A7C74),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('提交认领',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
  );

  nameCtl.dispose();
  phoneCtl.dispose();
  wxCtl.dispose();
  return result == true;
}

/// 打开钓点举报弹窗。
///
/// 理由固定四项（与旧版一致），可附最多 3 张图。
/// 举报内容写进云库 `spot_reports` 表（若表不存在会静默失败，不影响其他功能）。
Future<void> showSpotReportSheet(BuildContext context, Spot spot) async {
  const reasons = [
    '图片错误（与钓点不符/占位图）',
    '信息有误（价格/电话/地址不对）',
    '该钓点已关闭或不再营业',
    '其他问题',
  ];
  var selected = reasons.first;
  final noteCtl = TextEditingController();
  final photos = <String>[];

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('举报这个钓点',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2A2520))),
            const SizedBox(height: 4),
            Text('「${spot.name}」 · 我们会尽快核实',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A8578))),
            const SizedBox(height: 16),
            ...reasons.map((r) => RadioListTile<String>(
                  value: r,
                  groupValue: selected,
                  onChanged: (v) => setSheet(() => selected = v!),
                  title: Text(r, style: const TextStyle(fontSize: 13.5)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: '补充说明（可选）',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB8B3A8)),
                filled: true,
                fillColor: const Color(0xFFF7F3EE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: photos.length >= 3
                      ? null
                      : () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 70,
                          );
                          if (picked == null) return;
                          setSheet(() => photos.add(picked.path));
                        },
                  icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                  label: Text(photos.length >= 3 ? '最多 3 张' : '加图（${photos.length}/3）'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0A7C74),
                    side: const BorderSide(color: Color(0xFF0A7C74)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final note = noteCtl.text.trim();
                  Navigator.pop(ctx);
                  // 真写云库 reports 表（targetType='spot'），
                  // 走现有的 ModerationService，运营在审核台能直接看到。
                  final ok = await ModerationService.instance.report(
                    targetType: 'spot',
                    targetId: spot.id,
                    reason: note.isEmpty ? selected : '$selected · $note',
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(ok ? '举报已提交，感谢反馈' : '举报提交失败，请稍后再试'),
                    duration: const Duration(seconds: 2),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A7C74),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('提交举报',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  noteCtl.dispose();
}

Widget _field({
  required String label,
  required String hint,
  required TextEditingController controller,
  TextInputType? keyboardType,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2A2520))),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB8B3A8)),
          filled: true,
          fillColor: const Color(0xFFF7F3EE),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ],
  );
}
