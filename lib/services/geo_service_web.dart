// Web 平台实现：浏览器 Geolocation + localStorage。
// 全部基于 SDK 自带 dart:js_interop，零第三方依赖。
// 所有 JS 调用包 try-catch：浏览器拒绝定位 / 非安全上下文 / localStorage 被禁用
// 都会同步抛 SecurityError，未捕获会让整页灰屏（release ErrorWidget 吞掉）。
import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

const _cityKey = 'moyuquan_city';

/// 浏览器定位（navigator.geolocation.getCurrentPosition）。
/// 拒绝 / 超时 / 不支持 / 异常一律返回 null，绝不抛出。
Future<({double lat, double lon})?> locate() async {
  try {
    final nav = globalContext['navigator'] as JSObject?;
    final geoAny = nav?['geolocation'];
    if (geoAny == null || geoAny.isUndefinedOrNull) return null;
    final geo = geoAny as JSObject;

    final completer = Completer<({double lat, double lon})?>();
    void onSuccess(JSAny pos) {
      try {
        final coords = (pos as JSObject)['coords'] as JSObject;
        final lat = (coords['latitude'] as JSNumber).toDartDouble;
        final lon = (coords['longitude'] as JSNumber).toDartDouble;
        completer.complete((lat: lat, lon: lon));
      } catch (_) {
        completer.complete(null);
      }
    }
    void onError(JSAny _) {
      completer.complete(null);
    }

    final success = onSuccess.toJS;
    final error = onError.toJS;
    // callMethod 自身可能在某些上下文同步抛 SecurityError
    geo.callMethod<JSAny>( 'getCurrentPosition'.toJS, success, error );
    return completer.future;
  } catch (_) {
    return null;
  }
}

String? loadCity() {
  try {
    final ls = globalContext['localStorage'] as JSObject?;
    if (ls == null || ls.isUndefinedOrNull) return null;
    final v = ls.callMethod<JSAny>( 'getItem'.toJS, _cityKey.toJS );
    if (v == null || v.isUndefinedOrNull) return null;
    final d = v.dartify();
    return d is String ? d : null;
  } catch (_) {
    return null;
  }
}

void saveCity(String city) {
  try {
    final ls = globalContext['localStorage'] as JSObject?;
    if (ls == null || ls.isUndefinedOrNull) return;
    ls.callMethod<JSAny>( 'setItem'.toJS, _cityKey.toJS, city.toJS );
  } catch (_) {}
}