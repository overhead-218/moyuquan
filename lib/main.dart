import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/home_shell.dart';

void main() {
  runApp(const FishingApp());
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
