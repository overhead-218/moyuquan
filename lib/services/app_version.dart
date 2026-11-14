/// 应用版本信息。
///
/// 单一数据源：pubspec.yaml 的 `version: 1.1.0+11`。
/// ⚠️ 之前版本号在 settings_page.dart 里写死成 'v1.0.0'，与 pubspec 的 1.1.0+11
///    已经不一致，每次发版都要手动改 App 里这处，容易漏。
///
/// 这里的常量由 `tool/gen_version.dart` 从 pubspec.yaml 自动生成，
/// 改版本只需改 pubspec 并重跑生成脚本，App 内不再有第二份。
class AppVersion {
  /// 版本号（不含 build 号），如 1.1.0
  static const String version = '1.1.0';

  /// 构建号，如 11
  static const String build = '11';

  /// 展示用完整版本号，如 1.1.0 (11)
  static const String display = '$version ($build)';
}