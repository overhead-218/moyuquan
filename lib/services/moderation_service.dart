import 'tcb_rest_client.dart';

/// UGC 内容安全服务（Apple Guideline 1.2 合规三件套）：
/// 1. 举报机制   —— [report]
/// 2. 拉黑用户   —— [blockUser] / [isBlocked] / [unblockUser]
/// 3. 敏感词过滤 —— [filterText] / [containsSensitive]
///
/// 存储策略：当前为内存态（会话内有效），并 best-effort 推送云库 `reports` / `blocks` 表。
/// 后续在电脑上执行建表 SQL（见 `C:\Dev\sql\schema_moderation.sql`）后即可持久化。
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

  void blockUser(String userId) {
    if (userId.isEmpty) return;
    _blockedUserIds.add(userId);
    _notify();
    _pushBlock(userId);
  }

  void unblockUser(String userId) {
    _blockedUserIds.remove(userId);
    _notify();
  }

  /// 提交举报。targetType: post | user | comment | message
  Future<void> report({
    required String targetType,
    required String targetId,
    String targetUserId = '',
    required String reason,
  }) async {
    final r = <String, dynamic>{
      'targetType': targetType,
      'targetId': targetId,
      'targetUserId': targetUserId,
      'reason': reason,
      'reporterId': 'me',
      'createdAt': DateTime.now().toIso8601String(),
    };
    _reports.add(r);
    try {
      await TcbRestClient.insert('reports', r);
    } catch (_) {
      // 表可能未建，忽略（UI 仍提示成功）
    }
  }

  void _pushBlock(String userId) {
    try {
      TcbRestClient.insert('blocks', {
        'blockerId': 'me',
        'blockedId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ── 敏感词过滤（基础词库，可按需扩充）─────────────────
  static const List<String> _sensitiveWords = [
    '习近平', '毛泽东', '法轮功', '台独', '疆独', '藏独', '港独',
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
