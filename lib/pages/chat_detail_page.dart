import 'package:flutter/material.dart';

/// 聊天详情页：与某个用户的私聊界面
class ChatDetailPage extends StatefulWidget {
  final String name;
  final String avatar;

  const ChatDetailPage({
    super.key,
    required this.name,
    required this.avatar,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kPrimaryLight = Color(0xFF148F86);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kGold = Color(0xFFC49A5E);

  // 模拟聊天记录
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // 模拟初始消息
    _messages.addAll([
      {
        'isMe': false,
        'text': '在吗？明天一起去钓鱼？',
        'time': '12:30',
      },
      {
        'isMe': true,
        'text': '可以啊，去哪里？',
        'time': '12:35',
      },
      {
        'isMe': false,
        'text': '老地方，东江湖那边，听说最近鱼情不错',
        'time': '12:36',
      },
      {
        'isMe': true,
        'text': '好，几点出发？',
        'time': '刚刚',
      },
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'isMe': true,
        'text': text,
        'time': '刚刚',
      });
    });
    _controller.clear();

    // 滚动到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 模拟对方回复
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isMe': false,
          'text': '收到！明天见',
          'time': '刚刚',
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _kTealBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(widget.avatar, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _kTextPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: _kPrimary),
            onPressed: () {
              // 更多操作菜单
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => _buildMoreMenu(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 聊天内容区
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(
                  isMe: msg['isMe'] as bool,
                  text: msg['text'] as String,
                  time: msg['time'] as String,
                );
              },
            ),
          ),

          // 输入区
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                  color: Colors.black.withValues(alpha: 0.04),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).padding.bottom,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // 语音按钮
                  IconButton(
                    icon: const Icon(Icons.mic, color: _kPrimary),
                    onPressed: () {},
                  ),
                  // 输入框
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _kTealBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: '发送消息...',
                          hintStyle: TextStyle(
                            color: _kTextWeak.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: _kTextPrimary,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  // 表情按钮
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, color: _kPrimary),
                    onPressed: () {},
                  ),
                  // 发送按钮
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPrimary, _kPrimaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 消息气泡
  Widget _buildMessageBubble({
    required bool isMe,
    required String text,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // 对方头像
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _kTealBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(widget.avatar, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // 消息内容
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _kPrimary : _kSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black.withValues(alpha: 0.04),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : _kTextPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : _kTextWeak,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            // 我的头像（简化版，实际应该用当前用户头像）
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kGold, Color(0xFFE0B670)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('我', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 更多操作菜单
  Widget _buildMoreMenu() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(Icons.person_outline, '查看主页'),
          _buildMenuItem(Icons.notifications_off_outlined, '消息免打扰'),
          _buildMenuItem(Icons.delete_outline, '清空聊天记录', isDestructive: true),
          _buildMenuItem(Icons.block, '屏蔽此人', isDestructive: true),
          const Divider(height: 1),
          _buildMenuItem(null, '取消', isCancel: true),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData? icon, String text, {bool isDestructive = false, bool isCancel = false}) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isDestructive ? Colors.red : _kPrimary,
                size: 22,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCancel ? FontWeight.w600 : FontWeight.normal,
                color: isDestructive
                    ? Colors.red
                    : isCancel
                        ? _kTextWeak
                        : _kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
