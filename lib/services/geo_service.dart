import 'geo_service_stub.dart'
    if (dart.library.js_interop) 'geo_service_web.dart' as impl;

/// 定位 + 城市记忆服务（条件导入）
/// - Web: 浏览器 Geolocation + localStorage
/// - 非 Web: geolocator 定位 + SharedPreferences 城市记忆
class GeoService {
  /// 浏览器/原生定位。返回 null 表示失败或平台不支持。
  static Future<({double lat, double lon})?> locate() => impl.locate();

  /// 同步读取记住的城市（读缓存，首次为空）。
  static String? loadCity() => impl.loadCity();

  /// 异步读取记住的城市（会读盘），启动时调用。
  static Future<String?> loadCityAsync() => impl.loadCityAsync();

  /// 保存用户选择的城市。
  static void saveCity(String city) => impl.saveCity(city);
}
