import 'dart:convert';
import 'package:http/http.dart' as http;
import 'backend_config.dart';

/// 云开发 PG 模式（PostgREST）REST 客户端。
///
/// 端点：https://{envId}.api.tcloudbasegateway.com/v1/rdb/rest/{table}
/// 鉴权：Authorization: Bearer <PublishableKey>（anon 角色）
/// 查询参数遵循 PostgREST 语法：
///   select=*&limit=1000&order=hotspotScore.desc
///   city=eq.上海   rating=gte.4.5   name=like.%千岛湖%
class TcbRestClient {
  static Map<String, String> _auth() => {
        'Authorization': 'Bearer ${BackendConfig.publishableKey}',
        'Accept': 'application/json',
      };

  /// 查询表。params 直接映射 PostgREST 查询参数（select/limit/order/列=op.值）。
  static Future<List<Map<String, dynamic>>> query(
    String table, {
    Map<String, String> params = const {},
  }) async {
    final uri = Uri.parse('${BackendConfig.restBase}/$table')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _auth());
    _assertOk(res, 'GET $table');
    final body = jsonDecode(res.body);
    if (body is List) {
      return body.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  /// 新增一行。returnRepr=true 时返回刚插入的行。
  static Future<Map<String, dynamic>?> insert(
    String table,
    Map<String, dynamic> row, {
    bool returnRepr = true,
  }) async {
    final uri = Uri.parse('${BackendConfig.restBase}/$table');
    final headers = <String, String>{
      ..._auth(),
      'Content-Type': 'application/json',
    };
    if (returnRepr) headers['Prefer'] = 'return=representation';
    final res = await http.post(uri, headers: headers, body: jsonEncode(row));
    _assertOk(res, 'POST $table');
    final body = jsonDecode(res.body);
    if (body is List && body.isNotEmpty) {
      return Map<String, dynamic>.from(body.first as Map);
    }
    return null;
  }

  /// upsert（按主键冲突时忽略重复行），用于幂等种子导入。
  static Future<void> upsert(String table, Map<String, dynamic> row) async {
    final uri = Uri.parse('${BackendConfig.restBase}/$table');
    final headers = <String, String>{
      ..._auth(),
      'Content-Type': 'application/json',
      'Prefer': 'resolution=ignore-duplicates,return=minimal',
    };
    final res = await http.post(uri, headers: headers, body: jsonEncode(row));
    _assertOk(res, 'UPSERT $table');
  }

  /// 按 match（如 {'id': 'eq.s001'}）更新 patch 字段。
  static Future<void> update(
    String table,
    Map<String, String> match,
    Map<String, dynamic> patch,
  ) async {
    final uri = Uri.parse('${BackendConfig.restBase}/$table')
        .replace(queryParameters: match);
    final headers = <String, String>{
      ..._auth(),
      'Content-Type': 'application/json',
      'Prefer': 'return=minimal',
    };
    final res = await http.patch(uri, headers: headers, body: jsonEncode(patch));
    _assertOk(res, 'PATCH $table');
  }

  /// 删除匹配行。
  static Future<void> delete(String table, Map<String, String> match) async {
    final uri = Uri.parse('${BackendConfig.restBase}/$table')
        .replace(queryParameters: match);
    final res = await http.delete(uri, headers: _auth());
    _assertOk(res, 'DELETE $table');
  }

  static void _assertOk(http.Response res, String label) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('$label 失败 [${res.statusCode}]: ${res.body}');
    }
  }
}
