import 'package:flutter/material.dart';

import '../models/spot.dart';
import 'spot_detail_new.dart';

/// 钓点详情页（转发入口）。
///
/// 旧实现保留在 spot_detail_page_legacy.dart.bak，
/// 新的带评论区 + 留言输入栏的实现见 spot_detail_new.dart。
/// 本文件只做转发，避免改动 8 处调用点（home_shell / map / search / catch /
/// spot_discovery 等）。
class SpotDetailPage extends StatelessWidget {
  final Spot spot;
  final bool isFollowed;
  final VoidCallback? onFollowChanged;

  const SpotDetailPage({
    super.key,
    required this.spot,
    this.isFollowed = false,
    this.onFollowChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SpotDetailPageNew(
      spot: spot,
      isFollowed: isFollowed,
      onFollowChanged: onFollowChanged,
    );
  }
}
