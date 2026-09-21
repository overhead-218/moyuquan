import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'tcb_rest_client.dart';

/// 钓点 UGC 提交服务。
///
/// 用户在小程序/App 提交新钓点或图片纠错 → 落云库待审核表 → 运营审核后入库。
/// 提交走匿名 Publishable Key（RLS 已放开 anon INSERT），不依赖登录态。
class SpotSubmissionService {
  /// 提交新钓点（status=pending，等待运营审核）。
  /// [data] 字段名与云库 spot_submissions 表列一致（snake_case）。
  static Future<void> submitSpot(Map<String, dynamic> data) async {
    await TcbRestClient.insert('spot_submissions', data);
    if (kDebugMode) debugPrint('[submission] spot submitted: ${data['spot_id']}');
  }

  /// 提交图片/信息纠错（status=pending，等待运营审核）。
  /// [data] 字段名与云库 spot_corrections 表列一致。
  static Future<void> submitCorrection(Map<String, dynamic> data) async {
    await TcbRestClient.insert('spot_corrections', data);
    if (kDebugMode) debugPrint('[submission] correction submitted: ${data['spot_id']}');
  }

  /// 把 List<String> 序列化为 JSON 文本（存 TEXT 列）。
  static String jsonList(List<String> items) => jsonEncode(items);

  /// 把 Map<String,String> 序列化为 JSON 文本。
  static String jsonMap(Map<String, String> map) => jsonEncode(map);
}
