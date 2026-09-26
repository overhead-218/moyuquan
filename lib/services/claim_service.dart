import 'package:flutter/foundation.dart';
import '../models/claim_application.dart';
import 'backend_config.dart';
import 'spot_service.dart';
import 'tcb_rest_client.dart';

/// 商家认领申请服务（本地内存 + 云库 best-effort 同步，零回归）
///
/// 审核闸：商家 `submit()` 落 pending 申请 → 运营 `approve()` 通过后
/// 才调 `SpotService.claimSpot()` 写回 `claimedBy`，此刻才点亮「商家认证价」绿标。
/// 审核期间不覆盖官方联系方式、不显示认证价徽章。
class ClaimService {
  ClaimService._();

  static final List<ClaimApplication> _cache = <ClaimApplication>[];
  static final Set<void Function()> _listeners = {};

  static void addListener(void Function() cb) => _listeners.add(cb);
  static void removeListener(void Function() cb) => _listeners.remove(cb);

  static void _notify() {
    for (final cb in List.of(_listeners)) {
      try {
        cb();
      } catch (_) {}
    }
  }

  /// 全部申请（新提交在前）
  static List<ClaimApplication> all() => List.unmodifiable(_cache);

  /// 待审申请（审核页用）
  static List<ClaimApplication> pendingAll() =>
      _cache.where((a) => a.isPending).toList();

  /// 当前 App 会话内已提交的「我的申请」（按钓点）
  static ClaimApplication? pendingForSpot(String spotId) {
    for (final a in _cache) {
      if (a.spotId == spotId && a.isPending) return a;
    }
    return null;
  }

  static bool hasPending(String spotId) => pendingForSpot(spotId) != null;

  /// 提交认领申请：落 pending，**不**立即生效。
  /// 同一钓点已有待审申请时不重复创建，直接返回已有申请。
  static ClaimApplication submit({
    required String spotId,
    required String spotName,
    required String applicantName,
    String? contactPhone,
    String? wechat,
    String? note,
  }) {
    final existing = pendingForSpot(spotId);
    if (existing != null) return existing;

    final app = ClaimApplication(
      id: 'ca_${spotId}_${DateTime.now().millisecondsSinceEpoch}',
      spotId: spotId,
      spotName: spotName,
      applicantName: applicantName,
      contactPhone: contactPhone,
      wechat: wechat,
      note: note,
      status: ClaimStatus.pending,
      submittedAt: DateTime.now(),
    );
    _cache.insert(0, app);
    _notify();
    _pushUpsert(app);
    return app;
  }

  /// 运营审核通过：写回 Spot.claimedBy（点亮认证价绿标）。
  static ClaimApplication? approve(String id, {String? reviewNote}) {
    final idx = _cache.indexWhere((a) => a.id == id);
    if (idx < 0) return null;
    final app = _cache[idx];
    final updated = app.copyWith(
      status: ClaimStatus.approved,
      reviewedAt: DateTime.now(),
      reviewNote: reviewNote,
    );
    _cache[idx] = updated;
    // 此刻才把认领信息写入钓点
    SpotService.claimSpot(
      app.spotId,
      ownerName: app.applicantName,
      contactPhone: app.contactPhone,
      wechat: app.wechat,
    );
    _notify();
    _pushStatus(updated);
    return updated;
  }

  /// 运营驳回：不写回钓点，官方信息不受影响。
  static ClaimApplication? reject(String id, {String? reviewNote}) {
    final idx = _cache.indexWhere((a) => a.id == id);
    if (idx < 0) return null;
    final updated = _cache[idx].copyWith(
      status: ClaimStatus.rejected,
      reviewedAt: DateTime.now(),
      reviewNote: reviewNote,
    );
    _cache[idx] = updated;
    _notify();
    _pushStatus(updated);
    return updated;
  }

  /// 登出时清空本机会话内的申请。
  static void clearAll() {
    _cache.clear();
    _notify();
  }

  /// 启动后调用：从云库拉取认领申请；失败保留本地，永不白屏。
  static Future<void> refreshFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query('claim_applications', params: {
        'select': '*',
        'limit': '1000',
        'order': 'submittedAt.desc',
      });
      if (rows.isNotEmpty) {
        final cloud = rows
            .map((r) => ClaimApplication.fromJson(r))
            .toList();
        _cache
          ..clear()
          ..addAll(cloud);
        _notify();
        debugPrint('[ClaimService] 已从云库同步 ${cloud.length} 条认领申请');
      }
    } catch (e) {
      debugPrint('[ClaimService] 云库同步失败，使用本地数据：$e');
    }
  }

  static void _pushUpsert(ClaimApplication app) {
    if (!BackendConfig.cloudEnabled) return;
    TcbRestClient.upsert('claim_applications', app.toJson()).catchError((e) {
      debugPrint('[ClaimService] 写入云库失败（本地已记录）：$e');
    });
  }

  static void _pushStatus(ClaimApplication app) {
    if (!BackendConfig.cloudEnabled) return;
    TcbRestClient.update(
      'claim_applications',
      {'id': 'eq.${app.id}'},
      {
        'status': app.status.name,
        'reviewedAt': app.reviewedAt?.toIso8601String(),
        'reviewNote': app.reviewNote,
      },
    ).catchError((e) {
      debugPrint('[ClaimService] 审核状态写云库失败（本地已更新）：$e');
    });
  }
}
