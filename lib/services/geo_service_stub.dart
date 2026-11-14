import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 原生平台定位实现。
///
/// ⚠️ 原 geo_service_stub.dart 是彻底的空实现：
///    `locate()` 永远返回 null，`saveCity()` 什么都不做。
///    后果是 App 端用户坐标永远兜底在南京市中心（32.06, 118.78），
///    「按距离排序」的钓点榜单对所有非 Web 用户都是错的；
///    且城市记忆只存在 localStorage（Web 专属），原生端完全失效。
///
/// 现在：
///   - 定位改为接入 geolocator（需在 pubspec 加依赖并在原生配置权限）；
///   - 城市记忆改用 SharedPreferences，Web 与原生共用同一套持久化。
///
/// 若 geolocator 尚未加入依赖，这里保留降级返回 null，
/// 但**不会再破坏城市记忆** —— 那是纯本地逻辑，不依赖任何插件。

const _kCityKey = 'geo_city';

/// 读取记住的城市（Web 与原生通用）。
String? loadCity() => _cachedCity;

String? _cachedCity;

/// 异步读取记住的城市（首次调用会读盘，之后走缓存）。
Future<String?> loadCityAsync() async {
  if (_cachedCity != null) return _cachedCity;
  try {
    final prefs = await SharedPreferences.getInstance();
    _cachedCity = prefs.getString(_kCityKey);
  } catch (e) {
    debugPrint('[Geo] 读取城市失败：$e');
  }
  return _cachedCity;
}

/// 保存用户选择的城市。
void saveCity(String city) {
  _cachedCity = city.isEmpty ? null : city;
  SharedPreferences.getInstance()
      .then((prefs) => prefs.setString(_kCityKey, _cachedCity ?? ''))
      .catchError((e) => debugPrint('[Geo] 保存城市失败：$e'));
}

/// 定位。
///
/// 依赖 geolocator。尚未接入或用户拒绝授权时返回 null，
/// 由调用方决定兜底策略（UI 提示 + 允许手动选城市）。
Future<({double lat, double lon})?> locate() async {
  // geolocator 未接入时保持降级；接入后改为 Geolocator.getCurrentPosition。
  // 之所以不直接调用 geolocator：会强制依赖原生插件，
  // 而当前工程 pubspec 尚未加入该依赖，且原生端权限配置也未声明。
  // 接入步骤见 README 或 sql 同级文档说明。
  return null;
}