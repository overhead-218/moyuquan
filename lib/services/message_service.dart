/// 消息数据源（mock）。
/// 后续接 Firebase 时只需替换本文件实现，profile 页与消息页均通过此入口读取，
/// 未读数由会话列表动态统计，无需写死。
class MessageService {
  static const List<Map<String, dynamic>> messages = [
    {'name': '海钓阿强', 'last': '明天出发钓鱼？', 'time': '刚刚', 'avatar': '🎣', 'unread': 2},
    {'name': '钓鱼王', 'last': '这个饵料配方很赞', 'time': '12:30', 'avatar': '🐟', 'unread': 0},
    {'name': '野钓大叔', 'last': '[图片]', 'time': '昨天', 'avatar': '🎣', 'unread': 1},
    {'name': '江南老饕', 'last': '好的，到时见', 'time': '昨天', 'avatar': '🦑', 'unread': 0},
    {'name': '老李', 'last': '上次那个钓点还有?', 'time': '周一', 'avatar': '🐠', 'unread': 0},
    {'name': '渔民小张', 'last': '今天收获不错', 'time': '周日', 'avatar': '🐟', 'unread': 0},
    {'name': '菜鸟', 'last': '新手求带', 'time': '周日', 'avatar': '🎣', 'unread': 5},
  ];

  /// 总未读数（所有会话未读之和）
  static int get totalUnread =>
      messages.fold(0, (sum, m) => sum + (m['unread'] as int));
}
