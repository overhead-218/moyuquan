import 'dart:typed_data';
export 'screenshot_base.dart' show ScreenshotService;

/// 非 Web 平台：downloadWeb 空实现
Future<void> webDownloadImpl(Uint8List png, String filename) async {}
