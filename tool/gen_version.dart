// 从 pubspec.yaml 的 version 生成 lib/services/app_version.dart。
// 用途：让 App 内展示的版本号与 pubspec 保持单一数据源，避免手动同步出错。
// 用法：dart run tool/gen_version.dart
import 'dart:io';

void main() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('未找到 pubspec.yaml，请在工程根目录执行本脚本');
    exit(1);
  }

  final match = RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)',
          multiLine: true)
      .firstMatch(pubspec.readAsStringSync());
  if (match == null) {
    stderr.writeln('未能在 pubspec.yaml 中解析 version（格式需为 x.y.z+build）');
    exit(1);
  }

  final version = match.group(1)!;
  final build = match.group(2)!;

  File('lib/services/app_version.dart').writeAsStringSync('''
/// 应用版本信息。
///
/// ⚠️ 本文件由 `dart run tool/gen_version.dart` 自动生成，请勿手工编辑。
/// 唯一数据源是 pubspec.yaml 的 `version: $version+$build`。
class AppVersion {
  /// 版本号（不含 build 号），如 $version
  static const String version = '$version';

  /// 构建号，如 $build
  static const String build = '$build';

  /// 展示用完整版本号，如 $version ($build)
  static const String display = '\$version (\$build)';
}
''');

  stdout.writeln('已生成 lib/services/app_version.dart → $version ($build)');
}