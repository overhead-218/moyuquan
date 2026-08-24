import 'package:flutter/material.dart';

/// 隐私政策页（应用宝 / 小米 / App Store 上架必需）
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kSurface = Color(0xFFFFFFFF);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);

  static const String _updated = '2026 年 8 月 23 日';

  static const List<_DocSection> _sections = [
    _DocSection('一、我们如何收集您的信息', [
      '为保障您正常使用摸鱼圈（以下简称"本应用"）的服务，我们会在您授权的前提下收集以下信息：',
      '1. 账号信息：您通过手机号注册或微信授权登录时，我们会收集您的手机号、微信昵称、头像及唯一标识。',
      '2. 发布内容：您发布的钓点、鱼获、动态、评论及图片会被存储并公开展示。',
      '3. 位置信息：为向您推荐附近钓点与钓友，我们会申请位置权限，您可随时在系统中关闭。',
      '4. 设备信息：设备型号、系统版本、网络环境等用于保障服务安全与统计分析。',
    ]),
    _DocSection('二、我们如何使用您的信息', [
      '我们收集的信息仅用于：提供并维护核心功能（如钓点推荐、同城约钓、内容发布）；保障账号与交易安全；改进产品体验与必要统计分析。',
      '我们不会将您的个人信息用于与上述目的无关的场景，亦不会在未经您明示同意的情况下用于商业营销推送。',
    ]),
    _DocSection('三、信息的共享与第三方 SDK', [
      '除法律法规要求或为您提供服务所必需外，我们不会向第三方提供您的个人信息。',
      '为运行地图、消息推送、崩溃统计等必要功能，本应用可能集成第三方 SDK（如地图服务、统计分析服务）。相关 SDK 会在各自隐私政策约束下处理必要信息，我们已要求其遵守最小必要原则。',
    ]),
    _DocSection('四、信息的存储与保护', [
      '您的个人信息存储于境内合规的云服务平台，我们采取加密传输、访问控制等技术措施保护您的信息安全。',
      '我们仅在为您提供服务所需的期限内保留您的信息；您注销账号后，我们将在合理期限内删除或匿名化处理您的个人信息。',
    ]),
    _DocSection('五、您的权利', [
      '您有权查询、更正、补充您的个人信息，并可在设置中撤回授权或注销账号。',
      '如您对个人信息处理有任何疑问，可通过下方联系方式与我们联系，我们将在合理期限内响应。',
    ]),
    _DocSection('六、未成年人保护', [
      '本应用主要面向钓鱼爱好者。我们高度重视未成年人保护，不会主动收集未成年人的个人信息；若发现误收集，我们将及时删除。',
    ]),
    _DocSection('七、隐私政策的变更', [
      '我们可能根据法律法规或服务调整更新本政策，重大变更将以弹窗或公告形式告知您。您继续使用本应用即视为接受更新后的政策。',
    ]),
    _DocSection('八、联系方式', [
      '如您对本隐私政策有任何疑问或投诉，可通过以下方式联系我们：',
      '邮箱：privacy@moyuquan.com',
      '我们将在收到请求后 15 个工作日内回复处理。',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text(
          '隐私政策',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 4),
                    blurRadius: 16,
                    color: _kTextPrimary.withValues(alpha: 0.06),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '摸鱼圈隐私政策',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '最近更新：$_updated',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kTextWeak,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final s in _sections) ...[
              _DocBlock(section: s),
              const SizedBox(height: 14),
            ],
            const SizedBox(height: 8),
            const Text(
              '本页面为应用内版本，完整网页版将托管于 moyuquan.com。',
              style: TextStyle(fontSize: 11, color: _kTextWeak, height: 1.5),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DocBlock extends StatelessWidget {
  final _DocSection section;
  const _DocBlock({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 16,
            color: Color(0x111A1A1A),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0A7C74),
            ),
          ),
          const SizedBox(height: 10),
          for (final p in section.paragraphs) ...[
            Text(
              p,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.7,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _DocSection {
  final String title;
  final List<String> paragraphs;
  const _DocSection(this.title, this.paragraphs);
}
