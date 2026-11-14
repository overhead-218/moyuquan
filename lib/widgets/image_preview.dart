import 'package:flutter/material.dart';

import 'smart_image.dart';

/// 全屏图片预览：黑色背景 + 可双指缩放 + 点击任意处关闭。
///
/// 抽出来是为了让「钓点实景图」和「装备实景图集」共用同一套预览交互
/// —— 之前装备详情页的图集压根没绑点击手势，点了是死图。
class ImagePreviewDialog {
  /// 打开预览。[urls] 为可渲染的图片地址（http / data URI）。
  /// [initialIndex] 打开时定位到第几张。
  ///
  /// 传空列表时直接返回，不会弹出空白黑屏。
  static Future<void> open(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
  }) async {
    final renderable =
        urls.where((u) => SmartImage.isRenderable(u)).toList(growable: false);
    if (renderable.isEmpty) return;

    final index = initialIndex.clamp(0, renderable.length - 1);
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _Viewer(urls: renderable, initial: index),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }
}

class _Viewer extends StatefulWidget {
  final List<String> urls;
  final int initial;
  const _Viewer({required this.urls, required this.initial});

  @override
  State<_Viewer> createState() => _ViewerState();
}

class _ViewerState extends State<_Viewer> {
  late final PageController _ctrl =
      PageController(initialPage: widget.initial);
  late int _i = widget.initial;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 点击空白处关闭（点图片不关，避免误触）
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: SmartImage(
                    url: widget.urls[i],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 44,
                    ),
                  ),
                ),
              ),
            ),
            // 左上角页码，多图时告诉用户能左右滑
            if (widget.urls.length > 1)
              Positioned(
                left: 16,
                top: 40,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_i + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
