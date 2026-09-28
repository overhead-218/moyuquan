import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// 统一 REST 客户端（复用 fishing_app 同款 CloudBase PostgREST 端点）
class ApiService {
  static final ApiService _i = ApiService._();
  factory ApiService() => _i;
  ApiService._();

  String? _adminToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${BackendConfig.publishableKey}',
      };

  // ── 登录（纯客户端校验，不碰云库）
  bool login(String password) {
    if (password == BackendConfig.adminPasscode) {
      _adminToken = 'admin_moyuquan_2026';
      return true;
    }
    return false;
  }

  void logout() => _adminToken = null;
  bool get isLoggedIn => _adminToken != null;

  // ── 通用查询
  Future<List<dynamic>> query(String table,
      {String select = '*',
      int limit = 1000,
      String? order,
      Map<String, String>? filter}) async {
    final params = <String, String>{'select': select, 'limit': '$limit'};
    if (order != null) params['order'] = order;
    if (filter != null) params.addAll(filter);
    final uri = Uri.parse('${BackendConfig.restBase}/$table')
        .replace(queryParameters: params);
    final r = await http.get(uri, headers: _headers);
    if (r.statusCode == 404) return [];
    if (r.statusCode != 200) throw Exception('HTTP $r.statusCode: $r.body');
    final body = jsonDecode(r.body);
    return body is List ? body : [];
  }

  // ── 通用插入
  Future<Map<String, dynamic>?> insert(
      String table, Map<String, dynamic> row) async {
    final uri = Uri.parse('${BackendConfig.restBase}/$table');
    final r = await http.post(uri,
        headers: _headers, body: jsonEncode(row));
    if (r.statusCode == 404) return null;
    if (r.statusCode != 201) throw Exception('HTTP $r.statusCode: $r.body');
    try { return jsonDecode(r.body) as Map<String, dynamic>; }
    catch (_) { return null; }
  }

  // ── 通用更新
  Future<void> update(String table, String matchCol, dynamic matchVal,
      Map<String, dynamic> patch) async {
    final uri = Uri.parse(
        '${BackendConfig.restBase}/$table?${matchCol}=eq.$matchVal');
    final r = await http.patch(uri,
        headers: _headers, body: jsonEncode(patch));
    if (r.statusCode != 200 && r.statusCode != 204) {
      throw Exception('HTTP $r.statusCode: $r.body');
    }
  }

  // ── 通用删除
  Future<void> delete(String table, String matchCol, dynamic matchVal) async {
    final uri = Uri.parse(
        '${BackendConfig.restBase}/$table?${matchCol}=eq.$matchVal');
    final r = await http.delete(uri, headers: _headers);
    if (r.statusCode != 200 && r.statusCode != 204) {
      throw Exception('HTTP $r.statusCode: $r.body');
    }
  }

  // ── 高频便捷方法
  Future<List<dynamic>> spots() => query('spots', order: 'id');
  Future<List<dynamic>> posts() => query('posts', order: 'createdAt.desc');
  Future<List<dynamic>> profiles() => query('profiles', order: 'id');
  Future<List<dynamic>> claims({String? status}) {
    if (status == null) return query('claim_applications', order: 'submittedAt.desc');
    return query('claim_applications',
        filter: {'status': 'eq.$status'}, order: 'submittedAt.desc');
  }

  Future<void> approveClaim(String id, {String? note}) =>
      update('claim_applications', 'id', id, {
        'status': 'approved',
        'reviewedAt': DateTime.now().toUtc().toIso8601String(),
        if (note != null) 'reviewNote': note,
      });

  Future<void> rejectClaim(String id, {String? note}) =>
      update('claim_applications', 'id', id, {
        'status': 'rejected',
        'reviewedAt': DateTime.now().toUtc().toIso8601String(),
        if (note != null) 'reviewNote': note,
      });
}
