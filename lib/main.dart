import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'services/spot_service.dart';
import 'services/post_service.dart';
import 'services/message_service.dart';
import 'services/user_profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 初始化 — 容错包。
  // PC 端 `identitytoolkit.googleapis.com` 被网络层阻断，初始化会抛 PlatformException；
  // 不阻塞启动，让 mock 数据能正常渲染。
  // iPhone 蜂窝网下正常时这里会成功。
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    // ignore: avoid_print
    print('[Firebase] 初始化失败，继续以 mock 模式启动：$e');
    // ignore: avoid_print
    print(st);
  }

  runApp(const FishingApp());

  // 启动后后台拉取云库数据（失败自动回退本地 mock，不打断首屏）
  SpotService.refreshFromCloud();
  PostService.refreshFromCloud();
  MessageService.refreshFromCloud();
  UserProfile.instance.refreshFromCloud();
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
      // 启动显示登录页
      home: const LoginPage(),
    );
  }
}
