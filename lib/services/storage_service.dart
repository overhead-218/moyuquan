import 'dart:io';

import 'package:http/http.dart' as http;

import 'backend_config.dart';
import 'user_profile.dart';

/// 云存储服务 —— 把本地图片上传到 CloudBase PG 云存储，换回可公开访问的 URL。
///
/// ## 通道（2026-10-18 实测打通）
///
/// PG 模式的 REST 网关（`{envId}.api.tcloudbasegateway.com`）**只服务 PostgREST**
/// （`/v1/rdb/rest/*`），没有任何裸上传端点。存储走同一网关下的另一组路径：
///
///   上传  POST {gw}/v1/storages/object/{bucket}/{key}      body=图片字节
///   读取  GET  {gw}/v1/storages/object/{bucket}/{key}      → 图片字节
///
/// 鉴权统一用 `Authorization: Bearer {publishableKey}`（与数据库同一个匿名
/// 客户端密钥）。bucket 建为 `public = true`，所以读链接**无需签名、永久有效**，
/// 正好适合存进 `spots.images` 这种长期字段。
///
/// ## 权限（对应 sql/part8b.sql 的 RLS）
///
/// anon 角色下 `auth.uid()` 取不到可信值（实测 403 STORAGE_ACCESS_DENIED），
/// 所以策略不按 uid 绑定身份，改为约束路径形态：
///
///     {uid}/{filename}
///
///   · bucket 必须是 spot-photos / post-photos
///   · 路径恰好两段，`storage.foldername(name)` 长度为 1
///   · 首段必须匹配 `^(guest_|u_)[A-Za-z0-9_]{1,64}$`
///
/// ⚠️ 剩余风险（如实告知）：anon 可以在自己 uid 目录里反复上传消耗存储。
///   等 CloudBase 用户身份认证接上后，把策略收紧回"仅本人目录"即可，
///   本文件的调用方式不用改。
///
/// ## MIME 白名单
///
/// bucket 的 `allowed_mime_types` 只放行 jpeg/png/webp。实测传
/// `application/octet-stream` 会返回 400 STORAGE_MIME_TYPE_NOT_ALLOWED，
/// 所以这里必须按真实扩展名给 Content-Type，不能糊弄。
class StorageService {
  static const String _bucketSpots = 'spot-photos';
  static const String _bucketPosts = 'post-photos';

  /// 单文件上限，与 bucket 的 file_size_limit 对齐（10MB）
  static const int maxBytes = 10 * 1024 * 1024;

  /// 存储网关基地址（与数据库网关同域，只是路径前缀不同）
  static String get _storageBase =>
      '${BackendConfig.gatewayBase}/v1/storages/object';

  // ---------------------------------------------------------------------------
  // 对外方法
  // ---------------------------------------------------------------------------

  /// 钓点实景照片桶
  static String get spotBucket => _bucketSpots;

  /// 帖子配图桶
  static String get postBucket => _bucketPosts;

  /// 上传一张本地图片，返回可公开访问的 https URL。
  ///
  /// [localPath] 本地文件路径（原生端）
  /// [bucket]    目标桶，默认钓点照片桶
  /// [prefix]    路径首段（用户 uid），默认当前登录用户
  ///
  /// 返回的 URL 匿名可读、永久有效，可直接写进 spots.images。
  static Future<String> uploadImage(
    String localPath, {
    String bucket = _bucketSpots,
    String? prefix,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw StorageException('文件不存在：${file.path.split(RegExp(r'[/\\]')).last}');
    }
    final len = await file.length();
    if (len == 0) throw StorageException('图片为空文件');
    if (len > maxBytes) {
      throw StorageException(
          '图片 ${(len / 1024 / 1024).toStringAsFixed(1)}MB，超过 ${maxBytes ~/ 1024 ~/ 1024}MB 上限');
    }

    final uid = _sanitizeUid(prefix ?? UserProfile.id);
    final mime = mimeOf(localPath);
    if (mime == null) {
      throw StorageException('只支持 JPG / PNG / WebP 格式');
    }
    final ext = mime == 'image/jpeg' ? 'jpg' : mime.split('/').last;
    // 加时间戳避免同名覆盖，也避免缓存命中导致商家换了图还显示旧图
    final key = '$uid/spot_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final bytes = await file.readAsBytes();
    return uploadBytes(
      bytes,
      key: key,
      mime: mime,
      bucket: bucket,
    );
  }

  /// 直接上传字节（测试与无文件系统场景用）。
  static Future<String> uploadBytes(
    List<int> bytes, {
    required String key,
    required String mime,
    String bucket = _bucketSpots,
  }) async {
    final url = '$_storageBase/$bucket/$key';
    final resp = await http
        .post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer ${BackendConfig.publishableKey}',
            'Content-Type': mime,
          },
          body: bytes,
        )
        .timeout(const Duration(seconds: 60));

    if (resp.statusCode == 200) {
      // 返回体形如 {"Id":"uuid","Key":"spot-photos/u_xxx/spot_123.jpg"}
      return url;
    }
    // 把网关的原始错误翻成能给人看的话
    throw StorageException(_explain(resp.statusCode, resp.body));
  }

  /// 判断一个 URL 是否为本项目云存储的直链（用于图片来源分级）
  static bool isStorageUrl(String url) =>
      url.startsWith('http') && url.contains('/v1/storages/object/');

  // ---------------------------------------------------------------------------
  // 内部工具
  // ---------------------------------------------------------------------------

  /// 路径首段必须是合法 uid —— 与 RLS 策略里的正则保持一致
  static String _sanitizeUid(String raw) {
    var s = raw.trim();
    if (s.isEmpty) s = 'guest_anonymous';
    if (!s.startsWith('guest_') && !s.startsWith('u_')) s = 'u_$s';
    s = s.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    if (s.length > 65) s = s.substring(0, 65);
    return s;
  }

  /// 按扩展名判定 MIME。必须与 bucket 的 allowed_mime_types 一致，
  /// 否则网关返回 400 STORAGE_MIME_TYPE_NOT_ALLOWED。
  static String? mimeOf(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    return null;
  }

  static String _explain(int code, String body) {
    if (code == 400 && body.contains('MIME_TYPE_NOT_ALLOWED')) {
      return '图片格式不被接受，请用 JPG / PNG / WebP';
    }
    if (code == 400 && body.contains('FILE_TOO_LARGE')) {
      return '图片超过 10MB 上限';
    }
    if (code == 401) return '未登录或凭证已过期，请重新进入 App';
    if (code == 403) {
      // RLS 拒绝：99% 是 uid 形态不合规
      return '上传被权限校验拒绝（路径格式不合法），请反馈给运营';
    }
    if (code == 404) return '存储桶不存在，请联系运营确认已开通对象存储';
    if (code >= 500) return '存储服务暂时不可用，请稍后重试';
    return '上传失败（$code）';
  }
}

/// 上传失败时抛出，message 是可直接展示给用户的中文说明
class StorageException implements Exception {
  final String message;
  const StorageException(this.message);
  @override
  String toString() => message;
}

/// 便于统一处理：把 StorageException 转成 toast 文案
String storageErrorText(Object e) =>
    e is StorageException ? e.message : '上传失败，请稍后重试';
