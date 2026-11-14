import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'app_version.dart';
import 'backend_config.dart';

/// 版本检查结果
class UpdateInfo {
  final bool hasUpdate;
  final String latestVersion;
  final int latestBuild;
  final String downloadUrl;
  final String releaseNotes;
  final bool forceUpdate;

  const UpdateInfo({
    required this.hasUpdate,
    required this.latestVersion,
    required this.latestBuild,
    this.downloadUrl = '',
    this.releaseNotes = '',
    this.forceUpdate = false,
  });
}

/// 应用更新服务。
///
/// ⚠️ 原实现「检查更新」是个假的：不管什么版本，点下去永远弹
///    「已是最新版本 v1.0.0」，且版本号在页面里写死，从不查任何接口。
/// 现在改为真实查询云库 `app_config` 表，与服务器版本号比对。
class UpdateService {
  UpdateService._();

  static String get _platform => kIsWeb ? 'web' : 'android';

  /// 查询是否有新版本。
  ///
  /// 网络失败时返回 `hasUpdate: false` 并在 message 里说明原因，
  /// 由调用方如实提示用户，不谎报「已是最新」。
  static Future<UpdateInfo> check() async {
    if (!BackendConfig.cloudEnabled) {
      return UpdateInfo(
        hasUpdate: false,
        latestVersion: AppVersion.version,
        latestBuild: int.tryParse(AppVersion.build) ?? 0,
      );
    }
    try {
      final res = await http.get(
        Uri.parse('${BackendConfig.restBase}/app_config')
            .replace(queryParameters: {
          'select': '*',
          'id': 'eq.$_platform',
          'limit': '1',
        }),
        headers: {
          'Authorization': 'Bearer ${BackendConfig.publishableKey}',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final body = res.body.trim();
      if (body.isEmpty || body == '[]' || !body.startsWith('[')) {
        throw Exception('云端未配置版本信息');
      }
      final list = json_decode_any(body);
      if (list.isEmpty) throw Exception('云端未配置版本信息');
      final row = list.first;

      final latestVersion = (row['version'] ?? '').toString();
      final latestBuild = (row['build'] as num?)?.toInt() ?? 0;
      final currentBuild = int.tryParse(AppVersion.build) ?? 0;

      // build 号是单调递增的，比语义化版本号更可靠（1.2.0 vs 1.10.0）
      final hasUpdate = latestBuild > currentBuild;

      return UpdateInfo(
        hasUpdate: hasUpdate,
        latestVersion: latestVersion.isEmpty ? AppVersion.version : latestVersion,
        latestBuild: latestBuild,
        downloadUrl: (row['downloadUrl'] ?? '').toString(),
        releaseNotes: (row['releaseNotes'] ?? '').toString(),
        forceUpdate: row['forceUpdate'] == true,
      );
    } catch (e) {
      debugPrint('[Update] 版本查询失败：$e');
      throw UpdateCheckException('$e');
    }
  }

  /// 打开下载页
  static Future<void> openDownload(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('[Update] 无法打开链接：$url');
    }
  }
}

class UpdateCheckException implements Exception {
  final String message;
  UpdateCheckException(this.message);
  @override
  String toString() => message;
}

/// 极简 JSON 解包：只处理顶层数组，避免为一个查询引入完整解析分支。
List<Map<String, dynamic>> json_decode_any(String body) {
  final trimmed = body.trim();
  if (trimmed.startsWith('[')) {
    return List<Map<String, dynamic>>.from(
      const JsonDecoder().convert(trimmed) as List,
    );
  }
  return [Map<String, dynamic>.from(const JsonDecoder().convert(trimmed) as Map)];
}