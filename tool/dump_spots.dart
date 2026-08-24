import 'dart:convert';
import 'dart:io';
import '../lib/services/spot_service.dart';

/// 把本地 mock 钓点序列化为 JSON，供 seed_spots_to_tcb.py 一次性灌入云库。
/// 运行：dart run tool/dump_spots.dart
void main() {
  final list = SpotService.all.map((s) => s.toJson()).toList();
  final out = File(r'C:\Dev\spots_dump.json');
  out.writeAsStringSync(jsonEncode(list), encoding: utf8);
  // ignore: avoid_print
  print('dumped ${list.length} spots -> ${out.path}');
}
