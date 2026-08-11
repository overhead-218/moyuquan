// 条件导入：Web 平台用 dart:html 实现下载，非 Web 平台用空实现
import 'screenshot_service_stub.dart'
    if (dart.library.html) 'screenshot_service_web.dart';
