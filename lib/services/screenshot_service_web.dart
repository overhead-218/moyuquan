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

/// Web 平台：复制文本到剪贴板（安全上下文用 Clipboard API，否则 execCommand 兜底）
Future<void> webCopyText(String text) async {
  try {
    await html.window.navigator.clipboard?.writeText(text);
  } catch (_) {
    final ta = html.document.createElement('textarea') as html.TextAreaElement;
    ta.value = text;
    html.document.body?.append(ta);
    ta.select();
    html.document.execCommand('copy');
    ta.remove();
  }
}
