import 'package:flutter/material.dart';
import 'moderation_service.dart';

/// UGC 举报 / 拉黑 的通用 UI 助手。
/// 统一弹窗样式，避免在多个页面重复写底部面板与确认框。

/// 弹出举报底部面板：选择原因 → 提交 → 成功提示。
Future<void> showReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
  String targetUserId = '',
  String title = '举报',
}) async {
  final reasons = const [
    '垃圾广告 / 垃圾信息',
    '色情低俗',
    '暴力血腥',
    '诈骗 / 虚假信息',
    '骚扰 / 辱骂',
    '其他违规',
  ];
  final picked = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _ReportSheetContent(reasons: reasons, title: title),
  );
  if (picked == null || !context.mounted) return;
  await ModerationService.instance.report(
    targetType: targetType,
    targetId: targetId,
    targetUserId: targetUserId,
    reason: picked,
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('举报已提交，我们会尽快处理')),
  );
}

class _ReportSheetContent extends StatelessWidget {
  final List<String> reasons;
  final String title;
  const _ReportSheetContent({required this.reasons, required this.title});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ...reasons.map(
            (r) => ListTile(
              title: Text(r, style: const TextStyle(fontSize: 14)),
              onTap: () => Navigator.pop(context, r),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 拉黑确认对话框。
Future<void> confirmBlock(
  BuildContext context, {
  required String userId,
  required String userName,
}) async {
  if (userId.isEmpty) return;
  if (ModerationService.instance.isBlocked(userId)) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已拉黑 $userName')));
    return;
  }
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('拉黑该用户？'),
      content: Text('拉黑后，你将不再看到 $userName 的内容。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('拉黑', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  ModerationService.instance.blockUser(userId);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text('已拉黑 $userName')));
}
