import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/post_service.dart';
import '../services/spot_service.dart';
import '../models/post.dart';
import '../models/spot.dart';

/// 发布帖子页面（晒渔获 / 写渔获日记）
class PostPublishPage extends StatefulWidget {
  final String initialType; // 'catch' | 'diary'

  const PostPublishPage({super.key, this.initialType = 'catch'});

  @override
  State<PostPublishPage> createState() => _PostPublishPageState();
}

class _PostPublishPageState extends State<PostPublishPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _locationController = TextEditingController();
  final _picker = ImagePicker();
  
  List<XFile> _images = [];
  Spot? _selectedSpot;
  bool _isSubmitting = false;
  late final String _postType = widget.initialType;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> selected = await _picker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (selected.isNotEmpty) {
      setState(() {
        _images = selected;
      });
    }
  }

  void _showSpotSelector() {
    final spots = SpotService.all;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('选择钓点（可选）', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                itemCount: spots.length,
                itemBuilder: (context, i) {
                  final spot = spots[i];
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: spot.images.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(spot.images.first, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.place, color: Color(0xFF999999)),
                    ),
                    title: Text(spot.name),
                    subtitle: Text(
                      '${spot.city} · ${spot.type}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                    trailing: _selectedSpot?.id == spot.id
                      ? const Icon(Icons.check_circle, color: Color(0xFF0A7C74))
                      : null,
                    onTap: () {
                      setState(() => _selectedSpot = spot);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写标题')),
      );
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少上传一张图片')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // TODO: 上传图片到云端，这里先用本地路径模拟
      final imageUrls = _images.map((f) => f.path).toList();

      final post = Post(
        id: 'post_${DateTime.now().millisecondsSinceEpoch}',
        authorId: 'me',
        authorName: '钓鱼人',
        authorAvatar: '',
        type: _postType,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        location: _selectedSpot?.name ?? _locationController.text.trim(),
        imageUrl: imageUrls.first,
        height: 0.0,
        likeCount: 0,
        commentCount: 0,
        createdAt: DateTime.now(),
      );

      PostService.addPost(post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('发布成功')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_postType == 'diary' ? '写渔获日记' : '晒渔获', 
          style: const TextStyle(color: Color(0xFF333333), fontSize: 17)),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submit,
            child: Text(
              '发布',
              style: TextStyle(
                color: _isSubmitting ? const Color(0xFF999999) : const Color(0xFF0A7C74),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图片上传区
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F3EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: _images.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, 
                              size: 32, color: Color(0xFF999999)),
                            SizedBox(height: 8),
                            Text('点击上传图片', 
                              style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: _images.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                              ? Image.network(
                                  _images[i].path,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_images[i].path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                          ),
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 16),
              
              // 标题输入
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '标题（必填）',
                  hintStyle: TextStyle(color: Color(0xFF999999)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Divider(height: 32),
              
              // 内容输入
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: '分享你的渔获故事...',
                  hintStyle: TextStyle(color: Color(0xFF999999)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 6,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 16),
              
              // 位置/钓点选择
              InkWell(
                onTap: _showSpotSelector,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 20, color: Color(0xFF999999)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedSpot?.name ?? '添加钓点（可选）',
                          style: TextStyle(
                            fontSize: 15,
                            color: _selectedSpot != null 
                              ? const Color(0xFF333333) 
                              : const Color(0xFF999999),
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 20, color: Color(0xFF999999)),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              
              // 手动输入位置
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: '或手动输入位置',
                    hintStyle: TextStyle(color: Color(0xFF999999)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    prefixIcon: Icon(Icons.edit_location_outlined, 
                      size: 20, color: Color(0xFF999999)),
                    prefixIconConstraints: BoxConstraints(minWidth: 28),
                  ),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
