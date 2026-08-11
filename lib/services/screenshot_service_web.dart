import 'dart:typed_data';
import 'dart:html' as html;
import 'screenshot_base.dart';
export 'screenshot_base.dart' show ScreenshotService;

// Web 平台下载：Base64 data URL → <a download>
Future<void> webDownloadImpl(Uint8List png, String filename) async {
  final encoded = Uri.dataFromBytes(png, mimeType: 'image/png').toString();
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.setAttribute('href', encoded);
  anchor.setAttribute('download', filename);
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
