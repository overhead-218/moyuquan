import 'package:flutter/material.dart';

/// 用户协议页（应用宝 / 小米 / App Store 上架必需）
class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  static const Color _kPrimary = Color(0xFF0A7C74);
  static const Color _kBackground = Color(0xFFF7F3EE);
  static const Color _kTextPrimary = Color(0xFF1A1A1A);
  static const Color _kTextWeak = Color(0xFF999999);

  static const String _updated = '2026 年 8 月 23 日';

  static const List<_DocSection> _sections = [
    _DocSection('一、服务条款的接受', [
      '欢迎使用摸鱼圈（以下简称"本应用"）。您注册、登录或使用本应用，即表示您已阅读、理解并同意本用户协议的全部内容。',
      '如您不同意本协议的任何条款，请勿使用本应用。',
    ]),
    _DocSection('二、账号注册与管理', [
      '1. 您需使用手机号或微信账号注册，并保证所提供信息真实、合法、有效。',
      '2. 您的账号仅供本人使用，请勿转让、出租或出借给他人。',
      '3. 我们有权对违规账号采取限制、封禁或注销等措施。',
    ]),
    _DocSection('三、内容发布规范', [
      '作为钓鱼垂类社区，您发布的内容应真实、健康。严禁发布以下信息：',
      '· 违法违规、暴力、色情、赌博或诈骗内容；',
      '· 虚假钓点、虚假渔获或误导他人的信息；',
      '· 侵犯他人知识产权、肖像权或隐私的内容；',
      '· 与本应用社区主题无关的商业广告或垃圾信息。',
      '我们会对违规内容进行处理，情节严重者将封禁账号。',
    ]),
    _DocSection('四、知识产权', [
      '本应用内的软件、界面、图文、商标等知识产权归运营方所有。',
      '您发布的内容，其知识产权仍归您所有，但您授予本应用在全球范围内免费、非独家的展示与传播许可。',
    ]),
    _DocSection('五、免责声明', [
      '1. 钓点信息由用户与平台整理提供，实际垂钓环境、收费、安全状况可能变化，请出行前自行核实，注意人身安全。',
      '2. 本应用尽力保障服务稳定，但不对不可抗力、网络故障或第三方服务中断承担责任。',
      '3. 因您自身行为导致的损失，由您自行承担。',
    ]),
    _DocSection('六、违约与争议处理', [
      '如您违反本协议，我们有权视情节采取警告、限制功能、封禁账号等措施。',
      '本协议的订立、执行与争议解决均适用中华人民共和国相关法律法规。',
    ]),
    _DocSection('七、协议的变更', [
      '我们可能根据业务调整更新本协议，更新后将以公告或弹窗形式告知。您继续使用即视为接受变更后的协议。',
    ]),
    _DocSection('八、联系方式', [
      '如您对本协议有任何疑问，可通过 privacy@moyuquan.com 与我们联系。',
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
          '用户协议',
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
                  const Text(
                    '摸鱼圈用户协议',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '最近更新：$_updated',
                    style: const TextStyle(fontSize: 12, color: _kTextWeak),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final s in _sections) ...[
              _DocBlock(section: s),
              const SizedBox(height: 14),
            ],
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
