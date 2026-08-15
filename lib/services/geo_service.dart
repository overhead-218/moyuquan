import 'geo_service_stub.dart'
    if (dart.library.js_interop) 'geo_service_web.dart' as impl;

/// 定位 + 城市记忆服务（条件导入）
/// - Web: 浏览器 Geolocation + localStorage
/// - 非 Web: 降级为 null / 无操作
class GeoService {
  /// 浏览器定位。返回 null 表示失败或平台不支持。
  static Future<({double lat, double lon})?> locate() => impl.locate();

  /// 读取记住的城市（localStorage）。无则 null。
  static String? loadCity() => impl.loadCity();

  /// 保存用户选择的城市。
  static void saveCity(String city) => impl.saveCity(city);
}
