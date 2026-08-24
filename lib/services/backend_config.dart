/// 云开发（CloudBase）接入配置
///
/// 模式：PG（PostgreSQL + PostgREST）。前端使用匿名 `Publishable Key`（JWT，role=anon）。
/// 鉴权头：Authorization: Bearer <publishableKey>
/// REST 端点（国内上海）：https://{envId}.api.tcloudbasegateway.com/v1/rdb/rest/{table}
///
/// ⚠️ publishableKey 是前端可暴露的「匿名客户端密钥」，配合数据库 RLS 使用，
///    绝不要在此放账号级 SecretId/SecretKey（那等于把整个腾讯云账号交出去）。
class BackendConfig {
  /// 总开关：设为 false 即全程走本地 mock，云库完全不触碰。
  static const bool cloudEnabled = true;

  /// 环境 ID（上海区）
  static const String envId = 'moyuquan-d5g0pvpcw55f8a62e';

  /// 匿名客户端密钥（Publishable Key / JWT，role=anon，长期有效）
  /// 👉 把你在云开发控制台「应用凭证 → 客户端 Publishable Key」生成后复制的值粘到这里。
  static const String publishableKey = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjA1OTQwNWE4LTk5YmQtNDU0Zi1iMWU0LWEwZTBjMTExODAyMyJ9.eyJpc3MiOiJodHRwczovL21veXVxdWFuLWQ1ZzBwdnBjdzU1ZjhhNjJlLmFwLXNoYW5naGFpLnRjYi1hcGkudGVuY2VudGNsb3VkYXBpLmNvbSIsInN1YiI6ImFub24iLCJhdWQiOiJtb3l1cXVhbi1kNWcwcHZwY3c1NWY4YTYyZSIsImV4cCI6NDA5MTE1MTI2OSwiaWF0IjoxNzg3NDY4MDY5LCJub25jZSI6Ik1VMjk1TGwyU2tDUkdIdXZhQmUzd1EiLCJhdF9oYXNoIjoiTVUyOTVMbDJTa0NSR0h1dmFCZTN3USIsIm5hbWUiOiJBbm9ueW1vdXMiLCJzY29wZSI6ImFub255bW91cyIsInByb2plY3RfaWQiOiJtb3l1cXVhbi1kNWcwcHZwY3c1NWY4YTYyZSIsIm1ldGEiOnsicGxhdGZvcm0iOiJQdWJsaXNoYWJsZUtleSJ9LCJyb2xlIjoiYW5vbiIsImlzX2Fub255bW91cyI6dHJ1ZSwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiYW5vbnltb3VzIiwicHJvdmlkZXJzIjpbImFub255bW91cyJdfSwidXNlcl9tZXRhZGF0YSI6eyJuYW1lIjoiQW5vbnltb3VzIn0sInVzZXJfdHlwZSI6IiIsImNsaWVudF90eXBlIjoiY2xpZW50X3VzZXIiLCJpc19zeXN0ZW1fYWRtaW4iOmZhbHNlfQ.ptpY4PVVH3IiPPqHMZdW7PZecbWvT1SstH8mQhU1tT7dnlUBaRDzaTt-X6eoRHSuut43pXT2IB65YTG5mg8xj06JL3ACqooNtC5r3VsInPD-rKjsMIdv0HRtvRW41_mfirqCy5JvAaE9BlCrKYpwvvAmsavhD4EOq5-dVJmW4tHONpZ-wxSbUw0mYvYrxSavsqUgN9d_qOrNErFGxQL8R2m1ndp2_dluOqyYCh9PsX7TZGIaYbV6aOo972nNdZQdhJpJPjUsZv0Yy65QjmI4jTEXWUqrYZLmtRixk6ZKtdiBxOX7AJVGJwgmLaAb6XgmHV8wf9B1haSpMB5PFswPhw';

  /// 网关 REST 基地址
  static String get gatewayBase =>
      'https://$envId.api.tcloudbasegateway.com';

  /// PostgREST 数据库端点
  static String get restBase => '$gatewayBase/v1/rdb/rest';
}
