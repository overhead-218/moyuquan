/// 商家认领：数据模型
///
/// 认领不再「提交即生效」。商家提交后进入 [ClaimStatus.pending] 待审状态；
/// 运营审核通过（[ClaimStatus.approved]）后才写回 `Spot.claimedBy`，
/// 详情页才点亮「已认领·商家」标签与绿色「商家认证价」徽章。
library;

/// 认领申请状态
enum ClaimStatus { pending, approved, rejected }

/// 商家认领申请
class ClaimApplication {
  final String id;
  final String spotId;
  final String spotName;
  final String applicantName;
  final String? contactPhone;
  final String? wechat;

  /// 补充说明：资质 / 现场照片链接等（第一版仅文本，后续补上传）
  final String? note;

  final ClaimStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewNote;

  const ClaimApplication({
    required this.id,
    required this.spotId,
    required this.spotName,
    required this.applicantName,
    this.contactPhone,
    this.wechat,
    this.note,
    this.status = ClaimStatus.pending,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewNote,
  });

  bool get isPending => status == ClaimStatus.pending;
  bool get isApproved => status == ClaimStatus.approved;
  bool get isRejected => status == ClaimStatus.rejected;

  ClaimApplication copyWith({
    ClaimStatus? status,
    DateTime? reviewedAt,
    String? reviewNote,
  }) =>
      ClaimApplication(
        id: id,
        spotId: spotId,
        spotName: spotName,
        applicantName: applicantName,
        contactPhone: contactPhone,
        wechat: wechat,
        note: note,
        status: status ?? this.status,
        submittedAt: submittedAt,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        reviewNote: reviewNote ?? this.reviewNote,
      );

  // ── 云库序列化（字段名与数据库列名 1:1）──────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'spotId': spotId,
        'spotName': spotName,
        'applicantName': applicantName,
        'contactPhone': contactPhone,
        'wechat': wechat,
        'note': note,
        'status': status.name,
        'submittedAt': submittedAt.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
        'reviewNote': reviewNote,
      };

  static String? _asStr(dynamic v) => v?.toString();

  factory ClaimApplication.fromJson(Map<String, dynamic> json) {
    return ClaimApplication(
      id: _asStr(json['id']) ?? '',
      spotId: _asStr(json['spotId']) ?? '',
      spotName: _asStr(json['spotName']) ?? '',
      applicantName: _asStr(json['applicantName']) ?? '',
      contactPhone: _asStr(json['contactPhone']),
      wechat: _asStr(json['wechat']),
      note: _asStr(json['note']),
      status: ClaimStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ClaimStatus.pending,
      ),
      submittedAt: DateTime.tryParse(json['submittedAt']?.toString() ?? '') ??
          DateTime.now(),
      reviewedAt: DateTime.tryParse(json['reviewedAt']?.toString() ?? ''),
      reviewNote: _asStr(json['reviewNote']),
    );
  }
}
