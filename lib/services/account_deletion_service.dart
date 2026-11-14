import 'package:flutter/foundation.dart';

import 'backend_config.dart';
import 'tcb_rest_client.dart';
import 'user_profile.dart';

/// 账号注销服务。
///
/// ⚠️ 原「注销账号」只清了本地缓存就跳登录页，云端数据一行没删。
///    用户以为数据已删除，实际上换个手机登录，
///    自己发过的帖子、评论、点赞、收藏、关注、私信全都还在 —— 属于个人信息保护违规。
///
/// 现在按用户真实 uid 清理云端数据。
/// 说明：PostgREST 侧没有存储过程，逐表按条件删除；
/// 正式环境若数据量大，应改为云函数批量执行并加软删除过渡期。
class AccountDeletionService {
  AccountDeletionService._();

  /// 待清理的表及匹配方式。
  /// (表名, 用哪一列匹配当前用户)
  static const _tables = <String, String>{
    'spot_comments': 'authorId',
    'post_comments': 'authorId',
    'catches': 'userId',
    'catch_likes': 'userId',
    'follows': 'followerId',
    'favorites': 'userId',
    'post_likes': 'userId',
    'spot_likes': 'userId',
    'chat_messages': 'senderId',
    'blocks': 'blockerId',
    'reports': 'reporterId',
    'user_locations': 'userId',
  };

  /// 关注关系是双向的：还要清掉「别人关注我」的记录
  static const _tablesByFollowee = <String>['follows'];

  /// 会话表按 userAId / userBId 匹配
  static const _conversations = 'conversations';

  /// 执行注销：删除当前用户在云端的全部个人数据。
  ///
  /// 返回未能清理的表名列表（空列表表示全部清理成功）。
  static Future<List<String>> deleteMyAccount() async {
    final uid = UserProfile.id;
    final failed = <String>[];

    if (!BackendConfig.cloudEnabled) {
      debugPrint('[注销] 云库未启用，仅清理本地');
      return failed;
    }

    for (final entry in _tables.entries) {
      try {
        await TcbRestClient.delete(entry.key, {entry.value: 'eq.$uid'});
      } catch (e) {
        // 表可能未建：不算失败，但要记下来便于排查
        debugPrint('[注销] 清理 ${entry.key} 失败：$e');
        failed.add(entry.key);
      }
    }

    // 清掉「别人关注我」的记录（followeeId 方向）
    for (final table in _tablesByFollowee) {
      try {
        await TcbRestClient.delete(table, {'followeeId': 'eq.$uid'});
      } catch (e) {
        debugPrint('[注销] 清理 $table(followee) 失败：$e');
      }
    }

    // 会话：两个方向都要清
    try {
      await TcbRestClient.delete(_conversations, {'userAId': 'eq.$uid'});
      await TcbRestClient.delete(_conversations, {'userBId': 'eq.$uid'});
    } catch (e) {
      debugPrint('[注销] 清理会话失败：$e');
      failed.add(_conversations);
    }

    // 自己的发帖：属于用户创作内容，按合规要求也应删除
    try {
      await TcbRestClient.delete('posts', {'authorId': 'eq.$uid'});
    } catch (e) {
      debugPrint('[注销] 清理 posts 失败：$e');
      failed.add('posts');
    }

    // 最后删 profile 本人行
    try {
      await TcbRestClient.delete('profiles', {'id': 'eq.$uid'});
    } catch (e) {
      debugPrint('[注销] 清理 profiles 失败：$e');
      failed.add('profiles');
    }

    if (failed.isEmpty) {
      debugPrint('[注销] 云端数据清理完成 uid=$uid');
    } else {
      debugPrint('[注销] 部分表清理失败：$failed');
    }
    return failed;
  }
}