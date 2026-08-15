// Web 平台实现：浏览器 Geolocation + localStorage。
// 全部基于 SDK 自带 dart:js_interop，零第三方依赖。
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const _cityKey = 'moyuquan_city';

/// 浏览器定位（navigator.geolocation.getCurrentPosition）。
/// 用户拒绝 / 超时 / 平台不支持时返回 null。
Future<({double lat, double lon})?> locate() async {
  final nav = globalContext['navigator'] as JSObject?;
  final geoAny = nav?['geolocation'];
  if (geoAny == null || geoAny.isUndefinedOrNull) return null;
  final geo = geoAny as JSObject;

  final completer = Completer<({double lat, double lon})?>();
  final success = ((JSAny pos) {
    final coords = (pos as JSObject)['coords'] as JSObject;
    final lat = (coords['latitude'] as JSNumber).toDartDouble;
    final lon = (coords['longitude'] as JSNumber).toDartDouble;
    completer.complete((lat: lat, lon: lon));
  }).toJS;

  final error = ((JSAny _) {
    completer.complete(null);
  }).toJS;

  geo.callMethod('getCurrentPosition'.toJS, success, error);
  return completer.future;
}

String? loadCity() {
  final ls = globalContext['localStorage'] as JSObject?;
  if (ls == null || ls.isUndefinedOrNull) return null;
  final v = ls.callMethod('getItem'.toJS);
  if (v == null || v.isUndefinedOrNull) return null;
  final d = v.dartify();
  return d is String ? d : null;
}

void saveCity(String city) {
  final ls = globalContext['localStorage'] as JSObject?;
  if (ls == null || ls.isUndefinedOrNull) return;
  ls.callMethod('setItem'.toJS, _cityKey.toJS, city.toJS);
}
