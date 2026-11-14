import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_shell.dart';
import 'services/spot_service.dart';
import 'services/post_service.dart';
import 'services/message_service.dart';
import 'services/claim_service.dart';
import 'services/user_profile.dart';
import 'services/spot_comment_service.dart';
import 'services/follow_service.dart';
import 'services/favorite_service.dart';
import 'services/moderation_service.dart';
import 'services/spot_like_service.dart';
import 'services/catch_service.dart';
import 'services/equip_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 已移除，改用腾讯云开发后端。

  // 先从 SharedPreferences 恢复本地登录态（防杀进程丢失，不读云库避免自动续登）
  await UserProfile.hydrate();

  runApp(const FishingApp());

  // 启动后后台拉取云库数据（失败自动回退本地兜底，不打断首屏）
  //
  // ⚠️ 这些 refresh 调用已补齐社交/点赞/评论等此前完全缺失的服务。
  // 原来只同步了 spots/posts/messages，关注的10 个假用户、内存收藏、
  // 重启即丢的点赞态都不会被云库数据纠正。
  SpotService.refreshFromCloud();
  ClaimService.refreshFromCloud();
  PostService.refreshFromCloud();
  MessageService.refreshFromCloud();
  UserProfile.instance.refreshFromCloud();
  SpotCommentService.init();
  FollowService.instance.refreshFromCloud();
  FavoriteService.instance.refreshFromCloud();
  PostService.refreshLikesFromCloud();
  ModerationService.instance.refreshFromCloud();
  SpotLikeService.refreshFromCloud();
  CatchService.refreshFromCloud();
  CatchService.refreshLikesFromCloud();
  EquipService.refreshFromCloud();
}

class FishingApp extends StatelessWidget {
  const FishingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // v2 设计稿配色
    const primary = Color(0xFF0A7C74); // 青蓝
    const secondary = Color(0xFFC49A5E); // 金
    const surface = Color(0xFFF7F3EE); // 暖白

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: secondary,
      surface: surface,
      brightness: Brightness.light,
    );

    final deepSpot = Uri.base.queryParameters['spot'];

    return MaterialApp(
      title: '摸鱼圈',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: surface,
        // 本地字体，gstatic.com 被墙：英文走 AppRoboto，中文 fallback 到 AppChinese
        fontFamily: 'AppRoboto',
        fontFamilyFallback: const ['AppChinese'],
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          foregroundColor: primary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
        ),
      ),
      // 未登录显示登录页；登录后进入首页。登录页内「立即体验」可游客浏览。
      // 深链 ?spot=id：分享链接直达钓点详情，跳过登录门禁（游客可直接浏览）。
      home: deepSpot != null && deepSpot.isNotEmpty
          ? HomeShell(initialSpotId: deepSpot)
          : (UserProfile.instance.isLoggedIn ? const HomeShell() : const LoginPage()),
    );
  }
}
