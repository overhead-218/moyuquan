import 'dart:typed_data';
import 'dart:html' as html;
import 'screenshot_base.dart';
export 'screenshot_base.dart' show ScreenshotService, WebSaveResult;

bool _isWeChatBrowser() {
  final ua = html.window.navigator.userAgent.toLowerCase();
  return ua.contains('micromessenger');
}

/// Web 平台保存入口。
/// - 普通浏览器：<a download> 触发下载
/// - 微信内置浏览器：屏蔽 <a download>，改为铺满屏的 <img> 蒙层，用户长按即可保存到相册
Future<WebSaveResult> webDownloadImpl(Uint8List png, String filename) async {
  if (_isWeChatBrowser()) {
    _showLongPressOverlay(png);
    return WebSaveResult.wechatLongPress;
  }
  _triggerBrowserDownload(png, filename);
  return WebSaveResult.browserDownload;
}

void _triggerBrowserDownload(Uint8List png, String filename) {
  final encoded = Uri.dataFromBytes(png, mimeType: 'image/png').toString();
  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.setAttribute('href', encoded);
  anchor.setAttribute('download', filename);
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}

void _showLongPressOverlay(Uint8List png) {
  // 清掉上一次残留的蒙层
  html.document.querySelector('#moyuquan-share-overlay')?.remove();
  final dataUri = Uri.dataFromBytes(png, mimeType: 'image/png').toString();

  final overlay = html.document.createElement('div') as html.DivElement;
  overlay.setAttribute('id', 'moyuquan-share-overlay');
  overlay.style
    ..position = 'fixed'
    ..top = '0'
    ..left = '0'
    ..right = '0'
    ..bottom = '0'
    ..zIndex = '2147483647'
    ..backgroundColor = 'rgba(0,0,0,0.92)'
    ..display = 'flex'
    ..flexDirection = 'column'
    ..alignItems = 'center'
    ..justifyContent = 'center'
    ..padding = '20px';

  final hint = html.document.createElement('div') as html.DivElement;
  hint.style
    ..color = '#ffffff'
    ..fontSize = '14px'
    ..marginBottom = '12px'
    ..textAlign = 'center'
    ..maxWidth = '80%';
  hint.text = '长按下方图片，即可保存到相册';

  final img = html.document.createElement('img') as html.ImageElement;
  img.setAttribute('src', dataUri);
  img.setAttribute('alt', '摸鱼圈分享图');
  img.style
    ..maxWidth = '92%'
    ..maxHeight = '72vh'
    ..borderRadius = '12px'
    ..boxShadow = '0 8px 32px rgba(0,0,0,0.45)';

  final close = html.document.createElement('div') as html.DivElement;
  close.style
    ..position = 'absolute'
    ..top = '16px'
    ..right = '16px'
    ..width = '36px'
    ..height = '36px'
    ..borderRadius = '50%'
    ..backgroundColor = 'rgba(255,255,255,0.18)'
    ..color = '#ffffff'
    ..textAlign = 'center'
    ..lineHeight = '36px'
    ..fontSize = '24px'
    ..cursor = 'pointer';
  close.text = '×';
  close.onClick.listen((_) => overlay.remove());

  overlay
    ..append(hint)
    ..append(img)
    ..append(close);

  // 点遮罩空白处关闭
  overlay.onClick.listen((e) {
    if (e.target == overlay) overlay.remove();
  });

  html.document.body?.append(overlay);
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
