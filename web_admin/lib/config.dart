// 后端配置（与 fishing_app 保持一致）
class BackendConfig {
  static const bool cloudEnabled = true;
  static const String envId = 'moyuquan-d5g0pvpcw55f8a62e';
  // Publishable Key：role=anon，匿名可读四张表
  static const String publishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHAiOiJtb3l1cXVhbi1kNWcwcHZwY3c1NWY4YTYyZSIsInBlcm1pc3Npb24iOiJhbm9uIiwicm9sZSI6ImFub24iLCJleHAiOjQwOTExNTEyNjl9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
  static String get restBase =>
      'https://$envId.api.tcloudbasegateway.com/v1/rdb/rest';
  // 管理后台口令
  static const String adminPasscode = 'moyuquan2026';
}
