import 'package:flutter/foundation.dart';

import 'backend_config.dart';
import 'tcb_rest_client.dart';
import 'user_profile.dart';

/// UGC 内容安全服务（Apple Guideline 1.2 合规三件套）：
/// 1. 举报机制   —— [report]
/// 2. 拉黑用户   —— [blockUser] / [isBlocked] / [unblockUser]
/// 3. 敏感词过滤 —— [filterText] / [containsSensitive]
///
/// 存储：云库 `blocks` / `reports` 表为权威，本地集合仅作即时 UI 缓存。
/// 启动时通过 [refreshFromCloud] 拉取，跨设备/重启均生效。
class ModerationService {
  static final ModerationService instance = ModerationService._();
  ModerationService._();

  final Set<String> _blockedUserIds = {};
  final List<Map<String, dynamic>> _reports = [];

  // ── 变更监听（feed 列表订阅后可在拉黑时即时刷新）────────
  final Set<void Function()> _listeners = {};
  void addListener(void Function() cb) => _listeners.add(cb);
  void removeListener(void Function() cb) => _listeners.remove(cb);
  void _notify() {
    for (final cb in List.of(_listeners)) {
      try {
        cb();
      } catch (_) {}
    }
  }

  bool isBlocked(String userId) =>
      userId.isNotEmpty && _blockedUserIds.contains(userId);

  List<String> get blockedUserIds => List.unmodifiable(_blockedUserIds);

  /// 启动时调用：从云库恢复拉黑名单。
  ///
  /// ⚠️ 原实现拉黑只存在内存里，重启 App 全部失效，
  ///    换设备更是完全看不到 —— 这意味着「拉黑」这个合规功能形同虚设。
  Future<void> refreshFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query('blocks', params: {
        'select': 'blockedId',
        'blockerId': 'eq.${UserProfile.id}',
        'limit': '1000',
      });
      _blockedUserIds
        ..clear()
        ..addAll(rows.map((r) => r['blockedId'] as String? ?? '').where((e) => e.isNotEmpty));
      _notify();
      debugPrint('[Moderation] 已同步拉黑名单 ${_blockedUserIds.length} 人');
    } catch (e) {
      // 表未建时降级：仍可在会话内使用，不阻断启动
      debugPrint('[Moderation] 拉黑名单同步失败（降级为会话内状态）：$e');
    }
  }

  static String _blockId(String blockerId, String blockedId) =>
      'b_${blockerId}_$blockedId';

  /// 拉黑用户。返回是否成功（云库写入失败会回滚本地态）。
  Future<bool> blockUser(String userId) async {
    if (userId.isEmpty || userId == UserProfile.id) return false;
    _blockedUserIds.add(userId);
    _notify();
    if (!BackendConfig.cloudEnabled) return true;

    try {
      await TcbRestClient.upsert('blocks', {
        'id': _blockId(UserProfile.id, userId),
        'blockerId': UserProfile.id,
        'blockedId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('[Moderation] 拉黑写入失败，已回滚：$e');
      _blockedUserIds.remove(userId);
      _notify();
      return false;
    }
  }

  /// 取消拉黑。
  Future<void> unblockUser(String userId) async {
    _blockedUserIds.remove(userId);
    _notify();
    if (!BackendConfig.cloudEnabled) return;
    try {
      await TcbRestClient.delete(
          'blocks', {'id': 'eq.${_blockId(UserProfile.id, userId)}'});
    } catch (e) {
      debugPrint('[Moderation] 取消拉黑同步失败：$e');
    }
  }

  /// 提交举报。targetType: post | user | comment | message
  ///
  /// ⚠️ 原实现在写库失败时静默吞掉异常，UI 仍然提示「举报已提交」，
  ///    用户以为举报生效了其实根本没上报 —— 这在App Store 审核里是硬伤。
  /// 现在把成功与否如实返回给调用方，由 UI 决定提示文案。
  Future<bool> report({
    required String targetType,
    required String targetId,
    String targetUserId = '',
    required String reason,
  }) async {
    final r = <String, dynamic>{
      'id': 'r_${UserProfile.id}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      'targetType': targetType,
      'targetId': targetId,
      'targetUserId': targetUserId,
      'reason': reason,
      'reporterId': UserProfile.id,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };
    if (!BackendConfig.cloudEnabled) {
      _reports.add(r);
      return true;
    }
    try {
      await TcbRestClient.insert('reports', r);
      _reports.add(r);
      return true;
    } catch (e) {
      debugPrint('[Moderation] 举报提交失败：$e');
      return false;
    }
  }

  // ── 敏感词过滤 ─────────────────────────────
  /// 基础词库。
  ///
  /// ⚠️ 这是一份本地兜底词库，仅覆盖明显违规内容。
  ///    合规上真正的内容安全应接入腾讯云内容安全（天御/CMS）云函数，
  ///    本地词库随包分发、可被绕过，只能作为第一层拦截。
  static const List<String> _sensitiveWords = [
    '法轮功', '台独', '疆独', '藏独', '港独',
    '色情', '裸聊', '约炮', '赌博', '博彩', '诈骗', '代开发票', '办证',
    '傻逼', '妈的', '操你', '废物', '垃圾玩意',
    'fuck', 'shit', 'porn',
  ];

  /// 将文本中的敏感词替换为等长 * 掩码。
  static String filterText(String text) {
    if (text.isEmpty) return text;
    var out = text;
    for (final w in _sensitiveWords) {
      if (w.isEmpty) continue;
      if (out.contains(w)) {
        out = out.replaceAll(w, '*' * w.length);
      }
    }
    return out;
  }

  /// 是否含敏感词。
  static bool containsSensitive(String text) =>
      _sensitiveWords.any((w) => w.isNotEmpty && text.contains(w));
}