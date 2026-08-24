import 'dart:convert';
import 'dart:io';
import '../lib/services/spot_service.dart';
import '../lib/services/post_service.dart';
import '../lib/services/message_service.dart';
import '../lib/services/user_profile.dart';

/// 把四类本地 mock 数据序列化为 JSON，供 seed_app_to_tcb.py 一次性灌入云库。
/// 运行：dart run tool/dump_app.dart
void main() {
  final payload = {
    'spots': SpotService.all.map((s) => s.toJson()).toList(),
    'posts': PostService.mockAll().map((p) => p.toJson()).toList(),
    'messages': MessageService.messages
        .map((m) => <String, dynamic>{'id': m['name'], ...m})
        .toList(),
    'profiles': [UserProfile.instance.toJson()],
  };
  final out = File(r'C:\Dev\app_dump.json');
  out.writeAsStringSync(jsonEncode(payload), encoding: utf8);
  // ignore: avoid_print
  print('dumped -> ${out.path}  '
      'spots=${payload['spots']!.length} '
      'posts=${payload['posts']!.length} '
      'messages=${payload['messages']!.length} '
      'profiles=${payload['profiles']!.length}');
}
