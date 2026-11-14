import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/message_service.dart';
import '../services/chat_service.dart';
import '../services/user_profile.dart';
import '../services/geo_service.dart';
import '../services/post_service.dart';
import '../services/moderation_actions.dart';

/// 聊天详情页：与某个用户的私聊界面
/// 参考小红书：支持文字/图片/拍照/位置/相册发送
class ChatDetailPage extends StatefulWidget {
  final String name;
  final String avatar;
  final String userId;

  const ChatDetailPage({
    super.key,
    required this.name,
    required this.avatar,
    this.userId = '',
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();

  // Stitch 调色板
  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kPrimaryLight = Color(0xFF148F86);
  static const Color _kTealBg = Color(0xFFE6F2F0);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);
  static const Color _kGold = Color(0xFFC49A5E);
  static const Color _kRed = Color(0xFFFF4757);

  // 真实聊天记录（来源：云库 chat_messages 表，见 chat_service.dart）
  final List<Map<String, dynamic>> _messages = [];

  /// 当前会话 id（由双方 uid 派生，与顺序无关）
  late final String _conversationId;

  /// 对方 uid。
  ///
  /// ⚠️ 原实现存在真实 bug：会话 id 用 `widget.userId.isNotEmpty ? widget.userId
  ///    : 'peer_${widget.name}'` 兜底，但所有 ChatService.send 调用传的都是裸的
  ///    `peerId: widget.userId`。当 userId 为空时，会话 id 落到了 peer_昵称这个
  ///    伪造 uid 上，而发给云库的 userBId 却是空字符串 → 会话列表在对方端不会出现。
  /// 现在统一用 [peerId]，会话 id 与写库用同一个值。
  late final String peerId;

  /// 接收对方消息的轮询定时器
  Timer? _pollTimer;

  // 工具栏展开状态
  bool _toolPanelVisible = false;

  @override
  void initState() {
    super.initState();
    final me = UserProfile.id;
    // 没有稳定 uid 时用「昵称派生」兜底，保证会话 id 稳定可复现
    peerId = widget.userId.isNotEmpty
        ? widget.userId
        : 'peer_${Uri.encodeComponent(widget.name)}';
    _conversationId = ChatService.conversationId(me, peerId);

    // 真实消息：进入页面拉取云库历史记录
    ChatService.loadConversation(_conversationId).then((_) {
      if (!mounted) return;
      setState(_syncMessagesFromService);
      _scrollToBottom();
    });

    // 接收对方消息：CloudBase PG 暂无实时推送，用轮询实现
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final added = await ChatService.pollNew(_conversationId);
      if (added > 0 && mounted) {
        setState(_syncMessagesFromService);
        _scrollToBottom();
      }
    });
  }

  /// 把 ChatService 的消息模型转成页面气泡用的 Map
  void _syncMessagesFromService() {
    final me = UserProfile.id;
    _messages
      ..clear()
      ..addAll(ChatService.messagesOf(_conversationId).map((m) {
        final isMe = m.senderId == me;
        final base = <String, dynamic>{
          'isMe': isMe,
          'text': m.isImage ? '' : m.content,
          'time': m.timeLabel,
        };
        if (m.isImage) {
          base['isImage'] = true;
          base['imagePath'] = m.mediaUrl;
        } else if (m.isLocation) {
          base['isLocation'] = true;
          base['locationName'] = m.content;
          base['locationAddr'] = m.content;
        } else if (m.isCatchCard) {
          base['isCatchCard'] = true;
          final parts = m.content.split(' ');
          base['fishName'] = parts.isNotEmpty ? parts[0] : '';
          base['fishWeight'] = parts.length > 1 ? parts[1] : '';
          base['fishSpot'] = parts.length > 2 ? parts[2] : '';
          base['fishImage'] = m.mediaUrl;
        }
        return base;
      }));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleToolPanel() {
    setState(() => _toolPanelVisible = !_toolPanelVisible);
    if (_toolPanelVisible) _focusNode.unfocus();
  }

  /// 从相册选图
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return;
      await _sendImage(File(image.path));
    } catch (e) {
      // Web / mobile fallback: show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请从相册选择图片'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  /// 拍照
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image == null) return;
      await _sendImage(File(image.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('摄像头不可用，请检查权限设置'), duration: Duration(seconds: 2)),
        );
      }
    }
  }

  /// 发图片消息
  Future<void> _sendImage(File imageFile) async {
    setState(() {
      _messages.add({
        'isMe': true,
        'text': '',
        'time': '刚刚',
        'isImage': true,
        'imagePath': imageFile.path,
      });
      _toolPanelVisible = false;
    });
    _pushConversation('[图片]');
    _scrollToBottom();
    // ⚠️ 说明：图片本身暂存本地路径，未上传对象存储，
    //    因此对方端暂时无法看到真实图片（消息文本已入库）。
    //    接通 CloudBase 存储桶后，把 imageFile 换成上传后的 CDN URL 即可。
    ChatService.send(
      conversationId: _conversationId,
      peerId: peerId,
      type: 'image',
      content: '[图片]',
      mediaUrl: '',
    );
  }

  /// 发位置
  ///
  /// ⚠️ 原实现写死「东江湖·白廊镇/ 湖南省郴州市资兴市白廊镇」，
  ///    无论用户在哪都发同一个假位置。现在读取真实定位结果。
  Future<void> _sendLocation() async {
    final loc = await GeoService.locate();
    String name;
    if (loc == null) {
      name = widget.name.isEmpty ? '未知位置' : '当前位置附近';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('未获取到定位，已标注为「当前位置附近」'),
        ));
      }
    } else {
      // 有坐标就展示坐标，逆地理编码接腾讯位置服务后可显示地名
      name = '${loc.lat.toStringAsFixed(5)}, ${loc.lon.toStringAsFixed(5)}';
    }
    if (!mounted) return;
    setState(() {
      _messages.add({
        'isMe': true,
        'text': '',
        'time': '刚刚',
        'isLocation': true,
        'locationName': name,
        'locationAddr': name,
      });
      _toolPanelVisible = false;
    });
    _pushConversation('[位置] $name');
    _scrollToBottom();
    ChatService.send(
      conversationId: _conversationId,
      peerId: peerId,
      type: 'location',
      content: name,
    );
  }

  /// 发渔获卡片
  ///
  /// ⚠️ 原实现写死「大翘嘴3.8斤 / 升钟湖·凤凰岛」+ 一张 picsum 随机图，
  ///    无论用户实际发了什么渔获都推这张假卡片。
  /// 现在从用户自己的真实渔获里选择。
  Future<void> _sendCatchCard() async {
    // 从当前用户真实渔获里挑一条（无渔获则提示先发布）
    final mine = PostService.myCatchPosts();
    if (mine.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('你还没有发布过渔获，先去发一条吧'),
      ));
      return;
    }
    // 取最新一条渔获帖作为卡片内容
    final post = mine.first;
    final fishName = post.title.isNotEmpty ? post.title : '我的渔获';
    final summary = '$fishName ${post.location}';

    if (!mounted) return;
    setState(() {
      _messages.add({
        'isMe': true,
        'text': '',
        'time': '刚刚',
        'isCatchCard': true,
        'fishName': fishName,
        'fishWeight': '',
        'fishSpot': post.location,
        'fishImage': post.imageUrl.isNotEmpty ? post.imageUrl : '',
      });
      _toolPanelVisible = false;
    });
    _pushConversation('[渔获] $summary');
    _scrollToBottom();
    ChatService.send(
      conversationId: _conversationId,
      peerId: peerId,
      type: 'catchCard',
      content: summary,
      mediaUrl: post.imageUrl,
    );
  }


  void _showEmojiPicker() {
    final emojis = ['🎣', '🐟', '🐠', '🐡', '🦀', '🍤', '🌊', '☀️', '😂', '👍'];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('插入表情'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: emojis
              .map(
                (e) => GestureDetector(
                  onTap: () {
                    final t = _controller.text;
                    final sel = _controller.selection.baseOffset;
                    final pos = sel < 0 ? t.length : sel;
                    _controller.text = t.substring(0, pos) + e + t.substring(pos);
                    _controller.selection = TextSelection.collapsed(offset: pos + e.length);
                    Navigator.of(context).pop();
                  },
                  child: Text(e, style: const TextStyle(fontSize: 28)),
                ),
              )
              .toList(),
        ),
      ),
    );
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
    _pushConversation(text);
    _scrollToBottom();
    // 真实入库（chat_messages 表），对方才能收到
    ChatService.send(
      conversationId: _conversationId,
      peerId: peerId,
      type: 'text',
      content: text,
    );
  }

  /// 发出消息后同步到会话列表（MessageService），并置顶该会话。
  void _pushConversation(String summary) {
    MessageService.upsertConversation(
      name: widget.name,
      avatar: widget.avatar,
      userId: widget.userId,
      last: summary,
      time: '刚刚',
      unread: 0,
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
            child: GestureDetector(
              onTap: () {
                _focusNode.unfocus();
                if (_toolPanelVisible) setState(() => _toolPanelVisible = false);
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),
          ),

          // 工具栏（小红书风格，展开后浮在键盘上方）
          _buildToolPanel(),

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
              left: 12,
              right: 12,
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // + 扩展按钮（小红书风格）
                  GestureDetector(
                    onTap: _toggleToolPanel,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _toolPanelVisible ? _kPrimary : _kTealBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: AnimatedRotation(
                        turns: _toolPanelVisible ? 0.125 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.add,
                          color: _toolPanelVisible ? Colors.white : _kPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 输入框
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
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
                        onTap: () {
                          if (_toolPanelVisible) setState(() => _toolPanelVisible = false);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 表情按钮
                  GestureDetector(
                    onTap: _showEmojiPicker,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _kTealBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.emoji_emotions_outlined,
                        color: _kPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 发送按钮
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_kPrimary, _kPrimaryLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
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

  /// 工具面板（小红书风格：相册/拍照/位置/渔获）
  Widget _buildToolPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: _toolPanelVisible ? 140 : 0,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -4),
            blurRadius: 16,
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: _toolPanelVisible
          ? Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildToolItem(
                    icon: Icons.photo_library_outlined,
                    label: '相册',
                    color: const Color(0xFF4CAF50),
                    onTap: _pickImage,
                  ),
                  _buildToolItem(
                    icon: Icons.camera_alt_outlined,
                    label: '拍照',
                    color: const Color(0xFF2196F3),
                    onTap: _takePhoto,
                  ),
                  _buildToolItem(
                    icon: Icons.location_on_outlined,
                    label: '位置',
                    color: const Color(0xFFFF7043),
                    onTap: _sendLocation,
                  ),
                  _buildToolItem(
                    icon: Icons.emoji_events_outlined,
                    label: '渔获',
                    color: _kGold,
                    onTap: _sendCatchCard,
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: _kTextWeak,
            ),
          ),
        ],
      ),
    );
  }

  /// 通用消息气泡（根据类型渲染文字/图片/位置/渔获卡片）
  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['isMe'] as bool;
    final isImage = msg['isImage'] == true;
    final isLocation = msg['isLocation'] == true;
    final isCatchCard = msg['isCatchCard'] == true;
    final text = msg['text'] as String;
    final time = msg['time'] as String;

    if (isImage) {
      return _buildImageBubble(msg, isMe);
    }
    if (isLocation) {
      return _buildLocationBubble(msg, isMe);
    }
    if (isCatchCard) {
      return _buildCatchCardBubble(msg, isMe);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(widget.avatar, 16),
            const SizedBox(width: 8),
          ],
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
            _buildAvatar(null, 16),
          ],
        ],
      ),
    );
  }

  /// 图片消息气泡
  Widget _buildImageBubble(Map<String, dynamic> msg, bool isMe) {
    final imagePath = msg['imagePath'] as String? ?? '';
    final time = msg['time'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(widget.avatar, 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 200, maxHeight: 260),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 图片内容（web: NetworkImage, mobile: FileImage）
                    _buildMessageImage(imagePath),
                    // 底部时间戳
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(null, 16),
          ],
        ],
      ),
    );
  }

  /// 发图时渲染图片（Web 先显示网络图预览）
  Widget _buildMessageImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 200,
          height: 200,
          color: _kTealBg,
          child: const Icon(Icons.broken_image, color: _kTextWeak, size: 40),
        ),
      );
    }
    // 本地文件路径
    return Image.file(
      File(path),
      width: 200,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 200,
        height: 200,
        color: _kTealBg,
        child: const Icon(Icons.image, color: _kTextWeak, size: 40),
      ),
    );
  }

  /// 位置消息气泡（小红书风格卡片）
  Widget _buildLocationBubble(Map<String, dynamic> msg, bool isMe) {
    final name = msg['locationName'] as String? ?? '位置';
    final addr = msg['locationAddr'] as String? ?? '';
    final time = msg['time'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(widget.avatar, 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 240),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kRed.withValues(alpha: 0.3), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 位置预览区（纯色占位，真实接入高德/腾讯地图 SDK 时替换）
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          const Color(0xFF8BC34A).withValues(alpha: 0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.location_on, color: _kRed, size: 32),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emoji_nature, color: _kRed, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (addr.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            addr,
                            style: const TextStyle(fontSize: 11, color: _kTextWeak),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 10,
                                color: _kTextWeak.withValues(alpha: 0.8),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _kRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.directions, color: _kRed, size: 10),
                                  SizedBox(width: 2),
                                  Text(
                                    '导航',
                                    style: TextStyle(fontSize: 10, color: _kRed, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(null, 16),
          ],
        ],
      ),
    );
  }

  /// 渔获分享卡片气泡
  Widget _buildCatchCardBubble(Map<String, dynamic> msg, bool isMe) {
    final fishName = msg['fishName'] as String? ?? '渔获';
    final weight = msg['fishWeight'] as String? ?? '';
    final spot = msg['fishSpot'] as String? ?? '';
    final imageUrl = msg['fishImage'] as String? ?? '';
    final time = msg['time'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            _buildAvatar(widget.avatar, 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kGold.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: _kTealBg,
                        child: const Icon(Icons.emoji_events, color: _kGold, size: 40),
                      ),
                    ),
                  ),
                  // 渔获信息
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_kGold, Color(0xFFE0B670)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '🏆 渔获',
                                style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fishName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _kTextPrimary,
                          ),
                        ),
                        if (weight.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            weight,
                            style: TextStyle(
                              fontSize: 13,
                              color: _kGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (spot.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: _kTextWeak, size: 11),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  spot,
                                  style: const TextStyle(fontSize: 11, color: _kTextWeak),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          time,
                          style: TextStyle(fontSize: 10, color: _kTextWeak.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(null, 16),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(String? emoji, double size) {
    if (emoji != null) {
      return Container(
        width: size * 2.25,
        height: size * 2.25,
        decoration: const BoxDecoration(
          color: _kTealBg,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: size)),
        ),
      );
    }
    return Container(
      width: size * 2.25,
      height: size * 2.25,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGold, Color(0xFFE0B670)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '我',
          style: TextStyle(
            fontSize: size * 0.85,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
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
          _buildMenuItem(Icons.flag_outlined, '举报此人', isDestructive: true,
              onTap: () {
            Navigator.pop(context);
            showReportSheet(
              context,
              targetType: 'user',
              targetId: widget.userId.isEmpty ? widget.name : widget.userId,
              targetUserId: widget.userId,
              title: '举报用户',
            );
          }),
          _buildMenuItem(Icons.block, '拉黑此人', isDestructive: true,
              onTap: () {
            Navigator.pop(context);
            confirmBlock(
              context,
              userId: widget.userId.isEmpty ? widget.name : widget.userId,
              userName: widget.name,
            );
          }),
          _buildMenuItem(Icons.delete_outline, '清空聊天记录',
              isDestructive: true, onTap: () {
            Navigator.pop(context);
            setState(() => _messages.clear());
            MessageService.removeConversation(widget.name);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('聊天记录已清空'), duration: Duration(seconds: 2)),
            );
          }),
          const Divider(height: 1),
          _buildMenuItem(null, '取消', isCancel: true),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData? icon, String text,
      {bool isDestructive = false,
      bool isCancel = false,
      VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: isDestructive ? Colors.red : _kPrimary, size: 22),
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
