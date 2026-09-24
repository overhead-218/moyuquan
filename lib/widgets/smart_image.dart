import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// 统一图片渲染器：一个 url 字符串可以是三种来源——
///  1. `data:image/...;base64,xxxx`  → UGC 用户上传图（压缩后 base64 直接存库）
///  2. `http(s)://...`               → 网络图（官方封面 / 图库）
///  3. 其它（空串、iOS/Android 本地临时路径等）→ 视为不可用，走 errorBuilder 兜底
///
/// 背景：此前发布页把 image_picker 返回的手机本地路径
/// （如 /private/var/mobile/Containers/.../tmp/image_picker_xxx.jpg）当成 URL 存库，
/// 换设备/重启后必然加载失败，只会看到兜底 emoji。这里统一收口渲染逻辑。
class SmartImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;

  const SmartImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingBuilder,
    this.errorBuilder,
  });

  /// 解析 base64 data URI → 原始字节；非 data URI 返回 null。
  static Uint8List? decodeDataUri(String s) {
    if (!s.startsWith('data:')) return null;
    final comma = s.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(s.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  /// 是否是可渲染的来源（data URI 或 http/https）。
  static bool isRenderable(String s) =>
      s.startsWith('data:') ||
      s.startsWith('http://') ||
      s.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final bytes = decodeDataUri(url);
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
        errorBuilder: errorBuilder,
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
      );
    }
    // 本地路径 / 空串 / 未知协议 → 交给调用方的兜底样式
    return errorBuilder?.call(context, 'unsupported-image-source', null) ??
        const SizedBox.shrink();
  }
}
