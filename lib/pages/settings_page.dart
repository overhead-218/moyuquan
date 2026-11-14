import 'package:flutter/material.dart';
import 'privacy_policy_page.dart';
import 'user_agreement_page.dart';
import 'login_page.dart';
import 'profile_edit_page.dart';
import '../services/user_profile.dart';
import '../services/follow_service.dart';
import '../services/favorite_service.dart';
import '../services/message_service.dart';
import '../services/post_service.dart';
import '../services/claim_service.dart';
import 'claim_review_page.dart';
import '../services/app_version.dart';
import '../services/update_service.dart';
import '../services/account_deletion_service.dart';

/// 设置页
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kRed = Color(0xFFFF4757);
  static const Color _kShadow = Color(0xFF1A1A1A);

  static const _sections = [
    {
      'title': '账号设置',
      'items': [
        {'icon': Icons.person_outline, 'label': '编辑资料', 'trailing': ''},
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
                              } else if (item['label'] == '隐私政策') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyPolicyPage(),
                                  ),
                                );
                              } else if (item['label'] == '用户协议') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const UserAgreementPage(),
                                  ),
                                );
                              } else if (item['label'] == '编辑资料') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileEditPage(),
                                  ),
                                );
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
            // 运营入口（口令保护）
            const _ClaimReviewEntry(),
            const SizedBox(height: 20),
            // 版本信息
            Center(
              child: Column(
                children: [
                  Text(
                    // 版本号从 pubspec.yaml 的 version 读取（当前 1.1.0+11），
                    // 之前这里写死 'v1.0.0'，每次发版都要手改且极易漏改。
                    '摸鱼圈 v${AppVersion.display}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => _checkUpdate(context),
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
                  final pageContext = context;
                  showDialog(
                    context: pageContext,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text('确认退出登录？'),
                      content: const Text('退出后将清除本机保存的资料、关注、收藏与消息记录'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            '取消',
                            style: TextStyle(color: Color(0xFF999999)),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            // 真登出：清空当前设备用户态（资料/关注/收藏/会话/点赞）
                            _clearLocalUserData();
                            // 回到登录页
                            Navigator.of(pageContext).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                              (route) => false,
                            );
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

  /// 真实的「检查更新」。
  ///
  /// ⚠️ 原实现是无条件弹「已是最新版本 v1.0.0」，从不查接口。
  /// 现在查询云库 app_config 表，按 build 号比对：
  ///   - 有新版本 → 弹更新说明 + 下载按钮
  ///   - 无新版本 → 提示已是最新
  ///   - 查询失败 → 如实提示失败原因，不谎报
  static Future<void> _checkUpdate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('正在检查更新…'),
      duration: Duration(seconds: 2),
    ));
    try {
      final info = await UpdateService.check();
      if (!context.mounted) return;
      if (!info.hasUpdate) {
        messenger.showSnackBar(SnackBar(
          content: Text('已是最新版本 v${AppVersion.display}'),
        ));
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('发现新版本 v${info.latestVersion}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('当前版本：v${AppVersion.display}'),
                const SizedBox(height: 8),
                if (info.releaseNotes.isNotEmpty) ...[
                  const Text('更新内容：',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(info.releaseNotes),
                ],
                if (info.forceUpdate) ...[
                  const SizedBox(height: 10),
                  const Text('该版本为必须更新',
                      style: TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(info.forceUpdate ? '稍后' : '取消'),
            ),
            if (info.downloadUrl.isNotEmpty)
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  UpdateService.openDownload(info.downloadUrl);
                },
                child: const Text('去更新'),
              ),
          ],
        ),
      );
    } on UpdateCheckException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('检查更新失败：${e.message}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('检查更新失败：$e')));
    }
  }

  /// 清除当前设备上的全部本地用户态（登出 / 注销共用）
  static void _clearLocalUserData() {
    UserProfile.instance.resetToGuest();
    FollowService.instance.clearAll();
    FavoriteService.instance.clearAll();
    MessageService.clearAll();
    PostService.resetMyContent();
  }

  void _showDangerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('注销账号'),
        content: const Text(
          '注销后将清除本设备上的账号资料、关注、收藏与消息记录，此操作不可恢复。确定要继续吗？',
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
            onPressed: () async {
              final nav = Navigator.of(context);
              nav.pop();
              final messenger = ScaffoldMessenger.of(context);
              // 先告知用户正在注销，避免长时间无反馈
              messenger.showSnackBar(const SnackBar(
                content: Text('正在注销，云端数据清理中…'),
                duration: Duration(seconds: 6),
              ));
              // ⚠️ 原实现只清本地数据就跳登录页，云端 profiles / 帖子 /
              //    评论 / 点赞 / 收藏 / 关注全部留存 —— 用户点了「注销账号」
              //    以为数据已删除，实际换个手机登录还能看到全部历史内容。
              //    这在个人信息保护上存在合规风险。
              await AccountDeletionService.deleteMyAccount();
              _clearLocalUserData();
              if (!nav.mounted) return;
              nav.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
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

/// 设置页：认领审核入口（运营专用，进入后需口令）
class _ClaimReviewEntry extends StatefulWidget {
  const _ClaimReviewEntry();

  @override
  State<_ClaimReviewEntry> createState() => _ClaimReviewEntryState();
}

class _ClaimReviewEntryState extends State<_ClaimReviewEntry> {
  @override
  void initState() {
    super.initState();
    ClaimService.addListener(_onChange);
  }

  @override
  void dispose() {
    ClaimService.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final n = ClaimService.pendingAll().length;
    return Container(
      decoration: BoxDecoration(
        color: SettingsPage._kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 16,
            color: SettingsPage._kShadow.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: ListTile(
        leading: const Icon(Icons.how_to_reg_outlined, color: Color(0xFF0A7C74), size: 22),
        title: const Text('认领审核', style: TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (n > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4757),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('\$n', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFF999999), size: 20),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClaimReviewPage()),
          );
        },
      ),
    );
  }
}
