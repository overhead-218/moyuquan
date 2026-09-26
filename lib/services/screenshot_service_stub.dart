import 'dart:typed_data';
import 'screenshot_base.dart';
export 'screenshot_base.dart' show ScreenshotService, WebSaveResult;

/// 非 Web 平台：downloadWeb 空实现
Future<WebSaveResult> webDownloadImpl(Uint8List png, String filename) async => WebSaveResult.browserDownload;

/// 非 Web 平台：复制文本空实现
Future<void> webCopyText(String text) async {}
