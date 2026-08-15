/// 非 Web 平台降级实现：无定位能力，无本地存储。
Future<({double lat, double lon})?> locate() async => null;

String? loadCity() => null;

void saveCity(String city) {}
