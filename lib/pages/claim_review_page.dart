import 'package:flutter/material.dart';
import '../models/claim_application.dart';
import '../services/claim_service.dart';

/// 商家认领审核页（运营专用）
///
/// 口令保护（第一版临时方案，正式版应改为云端管理员角色鉴权）。
/// 通过后才会写回钓点、点亮「商家认证价」；驳回不影响官方信息。
class ClaimReviewPage extends StatefulWidget {
  const ClaimReviewPage({super.key});

  /// 运营口令（可自行修改）
  static const String passcode = 'moyuquan2026';

  static const Color _primary = Color(0xFF0A7C74);
  static const Color _green = Color(0xFF1F8A4C);
  static const Color _red = Color(0xFFFF4757);
  static const Color _bg = Color(0xFFF7F3EE);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _textMain = Color(0xFF1A1A1A);
  static const Color _textWeak = Color(0xFF999999);

  @override
  State<ClaimReviewPage> createState() => _ClaimReviewPageState();
}

class _ClaimReviewPageState extends State<ClaimReviewPage> {
  bool _authed = false;
  final _passCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ClaimService.addListener(_onChange);
  }

  @override
  void dispose() {
    ClaimService.removeListener(_onChange);
    _passCtl.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _tryAuth() {
    if (_passCtl.text.trim() == ClaimReviewPage.passcode) {
      setState(() => _authed = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('口令错误'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _reject(ClaimApplication app) async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('驳回认领申请'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(hintText: '驳回理由（选填）'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确定驳回', style: TextStyle(color: ClaimReviewPage._red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      ClaimService.reject(app.id, reviewNote: ctl.text.trim().isEmpty ? null : ctl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已驳回'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  void _approve(ClaimApplication app) {
    ClaimService.approve(app.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已通过：${app.spotName} 现在展示「商家认证价」'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_authed) return _buildGate();
    final pending = ClaimService.pendingAll();
    final history = ClaimService.all().where((a) => !a.isPending).toList();

    return Scaffold(
      backgroundColor: ClaimReviewPage._bg,
      appBar: AppBar(
        backgroundColor: ClaimReviewPage._bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: ClaimReviewPage._primary),
        title: const Text(
          '认领审核',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ClaimReviewPage._primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '待审核 ${pending.length} 条',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF666666)),
            ),
            const SizedBox(height: 10),
            if (pending.isEmpty)
              _emptyCard('暂无待审申请')
            else
              for (final app in pending) _appCard(app, showActions: true),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                '已处理',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 10),
              for (final app in history) _appCard(app, showActions: false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGate() {
    return Scaffold(
      backgroundColor: ClaimReviewPage._bg,
      appBar: AppBar(
        backgroundColor: ClaimReviewPage._bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: ClaimReviewPage._primary),
        title: const Text(
          '认领审核',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: ClaimReviewPage._primary),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('运营专用', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ClaimReviewPage._textMain)),
            const SizedBox(height: 6),
            const Text('请输入运营口令进入审核后台', style: TextStyle(fontSize: 12, color: ClaimReviewPage._textWeak)),
            const SizedBox(height: 18),
            TextField(
              controller: _passCtl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '运营口令',
                filled: true,
                fillColor: ClaimReviewPage._surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _tryAuth(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _tryAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClaimReviewPage._primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('进入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(color: ClaimReviewPage._surface, borderRadius: BorderRadius.circular(16)),
      child: Center(child: Text(text, style: const TextStyle(fontSize: 13, color: ClaimReviewPage._textWeak))),
    );
  }

  Widget _appCard(ClaimApplication app, {required bool showActions}) {
    final statusLabel = app.isApproved
        ? '已通过'
        : app.isRejected
            ? '已驳回'
            : '待审核';
    final statusColor = app.isApproved
        ? ClaimReviewPage._green
        : app.isRejected
            ? ClaimReviewPage._red
            : ClaimReviewPage._primary;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClaimReviewPage._surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(app.spotName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ClaimReviewPage._textMain)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _row('钓点', app.spotId),
          _row('申请人', app.applicantName),
          if (app.contactPhone != null && app.contactPhone!.isNotEmpty) _row('电话', app.contactPhone!),
          if (app.wechat != null && app.wechat!.isNotEmpty) _row('微信', app.wechat!),
          if (app.note != null && app.note!.isNotEmpty) _row('说明', app.note!),
          _row('提交', _fmt(app.submittedAt)),
          if (app.reviewNote != null && app.reviewNote!.isNotEmpty) _row('审核备注', app.reviewNote!),
          if (showActions) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reject(app),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ClaimReviewPage._red,
                      side: const BorderSide(color: ClaimReviewPage._red),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('驳回'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approve(app),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClaimReviewPage._green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('通过'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(label, style: const TextStyle(fontSize: 12, color: ClaimReviewPage._textWeak)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: ClaimReviewPage._textMain)),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}
