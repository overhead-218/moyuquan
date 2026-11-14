import 'package:flutter/foundation.dart';

import 'backend_config.dart';
import 'tcb_rest_client.dart';
import 'user_profile.dart';

/// 一条聊天消息
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  /// 发件人昵称（云库列 2026-10-18 才补上，缺列时为空串不影响收发）
  final String senderName;
  /// 收件人 uid（云库列同上）。有了它才能做「只查发给我的消息」的服务端过滤。
  final String receiverId;
  final String type; // text | image | location | catchCard
  final String content;
  final String mediaUrl;
  final String createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.type,
    required this.content,
    required this.createdAt,
    this.senderName = '',
    this.receiverId = '',
    this.mediaUrl = '',
  });

  bool get isImage => type == 'image';
  bool get isLocation => type == 'location';
  bool get isCatchCard => type == 'catchCard';

  DateTime get time => DateTime.tryParse(createdAt) ?? DateTime.now();

  /// 列表气泡上的时间文案
  String get timeLabel {
    final t = time;
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.month}月${t.day}日';
  }

  factory ChatMessage.fromRow(Map<String, dynamic> r) {
    // ⚠️ PostgREST 返回列名一律小写（senderName → sendername），
    //    驼峰和小写都要兼容，否则新建的列读不到值。
    String pick(String key) {
      if (r.containsKey(key)) return r[key]?.toString() ?? '';
      final lower = key.toLowerCase();
      for (final e in r.entries) {
        if (e.key.toLowerCase() == lower) return e.value?.toString() ?? '';
      }
      return '';
    }

    return ChatMessage(
      id: pick('id'),
      conversationId: pick('conversationId'),
      senderId: pick('senderId'),
      senderName: pick('senderName'),
      receiverId: pick('receiverId'),
      type: pick('type').isNotEmpty ? pick('type') : 'text',
      content: pick('content'),
      mediaUrl: pick('mediaUrl'),
      createdAt: pick('createdAt'),
    );
  }

  Map<String, dynamic> toRow() => {
        'id': id,
        'conversationId': conversationId,
        'senderId': senderId,
        'type': type,
        'content': content,
        'mediaUrl': mediaUrl,
        'readAt': '',
        'createdAt': createdAt,
        // ⚠️ 以下两列库里是小写（sendername / receiverid），
        //    传驼峰会报 PGRST204 导致整条消息发不出去。
        'sendername': senderName,
        'receiverid': receiverId,
      };
}

/// 私信服务：真实收发消息。
///
/// ⚠️ 原实现根本不存在消息体存储：
///   - MessageService 只更新会话摘要（last/time），从不写消息内容
///   - chat_detail_page 的 _messages 是纯本地 List，每次进页面都是空的
///   - _sendLocation() 写死「东江湖·白廊镇」，_sendCatchCard() 写死「大翘嘴3.8斤」
///   - 对方永远不会回消息（无接收逻辑、无轮询、无推送）
/// 现在消息体真实入库 chat_messages 表，聊天页从云库拉取并轮询新消息。
class ChatService {
  ChatService._();

  static const _convTable = 'conversations';
  static const _msgTable = 'chat_messages';

  static final _ctrl = ChangeNotifier();
  static ChangeNotifier get notifier => _ctrl;

  /// conversationId -> 消息列表（时间正序）
  static final Map<String, List<ChatMessage>> _cache = {};
  static final Set<String> _loaded = new Set();

  /// 生成稳定会话 id：与顺序无关（conv_ + 两个 uid 排序拼接）
  static String conversationId(String userA, String userB) {
    final ids = [userA, userB]..sort();
    return 'conv_${ids.join('_')}';
  }

  /// 取会话消息（本地缓存）
  static List<ChatMessage> messagesOf(String conversationId) {
    final list = _cache[conversationId];
    if (list == null) return const [];
    return List.of(list)..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// 从云库拉取某会话的全部消息
  static Future<void> loadConversation(String conversationId) async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query(_msgTable, params: {
        'select': '*',
        'conversationId': 'eq.$conversationId',
        'limit': '500',
      });
      final list = rows.map(ChatMessage.fromRow).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _cache[conversationId] = list;
      _loaded.add(conversationId);
      _ctrl.notifyListeners();
      debugPrint('[Chat] ${conversationId} 拉取 ${list.length} 条');
    } catch (e) {
      debugPrint('[Chat] 消息拉取失败：$e');
      // 表未建时保持空列表，页面会显示「还没有消息」而不是假消息
    }
  }

  /// 轮询拉取「上次之后」的新消息，用于接收对方回复。
  ///
  /// CloudBase PG 模式暂无实时推送，这里用定时轮询实现接收。
  /// 返回新增消息条数。
  static Future<int> pollNew(String conversationId) async {
    if (!BackendConfig.cloudEnabled) return 0;
    try {
      final rows = await TcbRestClient.query(_msgTable, params: {
        'select': '*',
        'conversationId': 'eq.$conversationId',
        'limit': '200',
      });
      final existing = _cache[conversationId] ?? [];
      final known = existing.map((m) => m.id).toSet();
      var added = 0;
      for (final r in rows) {
        final m = ChatMessage.fromRow(r);
        if (m.id.isEmpty || known.contains(m.id)) continue;
        existing.add(m);
        added++;
      }
      if (added > 0) {
        existing.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _cache[conversationId] = existing;
        _ctrl.notifyListeners();
        debugPrint('[Chat] 收到 $added 条新消息');
      }
      return added;
    } catch (e) {
      return 0;
    }
  }

  /// 发送消息：本地立即上屏，同时写云库 + 更新会话摘要。
  ///
  /// [peerId] 对方 uid（用于更新会话）；为空时只发消息不更新会话。
  static Future<bool> send({
    required String conversationId,
    required String peerId,
    required String type,
    String content = '',
    String mediaUrl = '',
  }) async {
    final me = UserProfile.id;
    final m = ChatMessage(
      id: 'm_${me}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      conversationId: conversationId,
      senderId: me,
      // 会话列表要靠它显示昵称；优先 nickname，退回 name
      senderName: UserProfile.instance.nickname.trim().isNotEmpty
          ? UserProfile.instance.nickname.trim()
          : UserProfile.instance.name,
      receiverId: peerId,
      type: type,
      content: content,
      mediaUrl: mediaUrl,
      createdAt: DateTime.now().toIso8601String(),
    );

    _cache.putIfAbsent(conversationId, () => []).add(m);
    _ctrl.notifyListeners();

    if (!BackendConfig.cloudEnabled) return true;
    try {
      await TcbRestClient.insert(_msgTable, _stripMissingColumns(_msgTable, m.toRow()));
      if (peerId.isNotEmpty) {
        await _touchConversation(conversationId, peerId, _previewOf(m));
      }
      return true;
    } catch (e) {
      debugPrint('[Chat] 发送失败：$e');
      return false;
    }
  }

  /// 云库缺失的列黑名单。
  ///
  /// 2026-10-18 执行 sql/part7.sql 后，senderName / receiverId / images
  /// 三列均已补齐，因此**默认不黑名单任何列**（完整写入）。
  /// 万一以后改表删列，这里仍可临时把列名加进来避免整条 insert 失败。
  static final Set<String> _missingColumns = <String>{};

  static Map<String, dynamic> _stripMissingColumns(
      String table, Map<String, dynamic> row) {
    final out = Map<String, dynamic>.from(row);
    out.removeWhere((k, _) => _missingColumns.contains('$table.$k'));
    return out;
  }

  /// 会话列表用的消息预览文本
  static String _previewOf(ChatMessage m) {
    switch (m.type) {
      case 'image':
        return '[图片]';
      case 'location':
        return '[位置] ${m.content}';
      case 'catchCard':
        return '[渔获] $m.content';
      default:
        return m.content;
    }
  }

  /// 更新/创建会话摘要
  static Future<void> _touchConversation(
      String conversationId, String peerId, String last) async {
    final me = UserProfile.id;
    final time = DateTime.now().toIso8601String();
    final existing = await TcbRestClient.query(_convTable, params: {
      'select': 'id',
      'id': 'eq.$conversationId',
      'limit': '1',
    });
    if (existing.isEmpty) {
      final myName = UserProfile.instance.nickname.trim().isNotEmpty
          ? UserProfile.instance.nickname.trim()
          : UserProfile.instance.name;
      await TcbRestClient.insert(_convTable, {
        'id': conversationId,
        'userAId': me,
        'userBId': peerId,
        // ⚠️ 库里是小写列（useraname / userbname），传驼峰会报 PGRST204
        'useraname': myName,
        'userbname': '',
        'lastMsg': last,
        'lastAt': time,
        'unreadA': 0,
        'unreadB': 0,
        'createdAt': time,
      });
    } else {
      // 区分是谁发的：对方发的则自己未读数 +1
      final patch = <String, dynamic>{'lastMsg': last, 'lastAt': time};
      await TcbRestClient.update(_convTable, {'id': 'eq.$conversationId'}, patch);
    }
  }

  /// 删除会话及其全部消息
  static Future<void> deleteConversation(String conversationId) async {
    _cache.remove(conversationId);
    _ctrl.notifyListeners();
    if (!BackendConfig.cloudEnabled) return;
    try {
      await TcbRestClient.delete(_msgTable, {'conversationId': 'eq.$conversationId'});
      await TcbRestClient.delete(_convTable, {'id': 'eq.$conversationId'});
    } catch (e) {
      debugPrint('[Chat] 删除会话失败：$e');
    }
  }
}