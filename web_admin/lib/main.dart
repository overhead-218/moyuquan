import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() => runApp(const MoyuquanAdminApp());

class MoyuquanAdminApp extends StatelessWidget {
  const MoyuquanAdminApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: '摸鱼圈管理后台',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0A7C74),
            surface: const Color(0xFFF7F3EE),
          ),
          fontFamily: 'PingFang SC',
          useMaterial3: true,
        ),
        home: const LoginPage(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 登录页
// ─────────────────────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _ctrl = TextEditingController();
  String? _error;
  bool _loading = false;

  void _login() async {
    if (_loading) return;
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 400));
    final ok = ApiService().login(_ctrl.text.trim());
    if (!mounted) return;
    setState(() { _loading = false; });
    if (ok) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardPage()));
    } else {
      setState(() => _error = '口令错误');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: Center(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎣', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              const Text('摸鱼圈管理后台',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: Color(0xFF0A7C74))),
              const SizedBox(height: 8),
              Text('内部工具，请勿传播',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 28),
              TextField(
                controller: _ctrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '管理口令',
                  hintText: '输入后台口令',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => _login(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: _loading ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0A7C74),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('进入后台', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 主页框架
// ─────────────────────────────────────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tab = 0;
  final _api = ApiService();

  final _tabs = const ['钓点', '帖子', '用户', '认领审核'];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F3EE),
    appBar: AppBar(
      backgroundColor: const Color(0xFF0A7C74),
      foregroundColor: Colors.white,
      title: Row(
        children: [
          const Text('🎣', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          const Text('摸鱼圈管理后台',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: '退出',
            onPressed: () {
              _api.logout();
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          ),
        ],
      ),
    ),
    body: Row(children: [
      NavigationRail(
        backgroundColor: Colors.white,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        labelType: NavigationRailLabelType.all,
        selectedIconTheme: const IconThemeData(color: Color(0xFF0A7C74)),
        destinations: _tabs
            .map((t) => NavigationRailDestination(
                icon: const Icon(Icons.chevron_right), label: Text(t)))
            .toList(),
      ),
      const VerticalDivider(width: 1),
      Expanded(child: [const SpotsPanel(), const PostsPanel(),
        const ProfilesPanel(), const ClaimsPanel()][_tab]),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 通用卡片/表格工具
// ─────────────────────────────────────────────────────────────────────────────
class _PanelScaffold extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onRefresh;
  final List<Widget> actions;
  final Widget body;

  const _PanelScaffold({
    required this.title, required this.count, required this.onRefresh,
    required this.actions, required this.body,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    _buildHeader(context),
    Expanded(child: body),
  ]);

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8E2DB))),
      ),
      child: Row(children: [
        Text(title, style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF0A7C74).withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count 条',
              style: const TextStyle(fontSize: 13, color: Color(0xFF0A7C74))),
        ),
        const Spacer(),
        ...actions,
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: '刷新',
          onPressed: onRefresh,
        ),
      ]),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Color(0xFF0A7C74)));
}

class _EmptyBox extends StatelessWidget {
  final String msg;
  const _EmptyBox([this.msg = '暂无数据']);
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(msg, style: TextStyle(color: Colors.grey[500])));
}

class _ErrorBox extends StatelessWidget {
  final String msg;
  const _ErrorBox(this.msg);
  @override
  Widget build(BuildContext context) =>
      Center(child: Text('加载失败: $msg',
          style: const TextStyle(color: Colors.red)));
}

// ─────────────────────────────────────────────────────────────────────────────
// 钉点面板
// ─────────────────────────────────────────────────────────────────────────────
class SpotsPanel extends StatefulWidget {
  const SpotsPanel({super.key});
  @override
  State<SpotsPanel> createState() => _SpotsPanelState();
}

class _SpotsPanelState extends State<SpotsPanel> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _err;
  String _q = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final d = await ApiService().spots();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _loading = false; });
    }
  }

  List<dynamic> get _filtered => _q.isEmpty ? _data :
      _data.where((s) =>
        (s['name'] ?? '').toString().contains(_q) ||
        (s['city'] ?? '').toString().contains(_q) ||
        (s['district'] ?? '').toString().contains(_q)).toList();

  @override
  Widget build(BuildContext context) => _PanelScaffold(
    title: '钓点',
    count: _filtered.length,
    onRefresh: _load,
    actions: [
      SizedBox(
        width: 200,
        child: TextField(
          decoration: InputDecoration(
            hintText: '搜索钓点名称/城市',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
    ],
    body: _loading ? const _LoadingBox()
        : _err != null ? _ErrorBox(_err!)
        : _filtered.isEmpty ? const _EmptyBox()
        : _buildTable(),
  );

  Widget _buildTable() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _buildHeader(),
      ...List.generate(_filtered.length, (i) => _buildRow(_filtered[i], i)),
    ]),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF0A7C74).withAlpha(15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Row(children: [
      Expanded(flex: 1, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 3, child: Text('名称', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('城市', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('类型', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 1, child: Text('价格', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('联系方式', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 1, child: Text('认领', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
    ]),
  );

  Widget _buildRow(dynamic s, int i) {
    final claimed = s['claimedBy'] != null;
    final phone = s['contactPhone'] ?? '—';
    final price = s['price'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: i.isEven ? Colors.white : const Color(0xFFFAF8F5),
        border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(30))),
      ),
      child: Row(children: [
        Expanded(flex: 1, child: Text('${i + 1}', style: TextStyle(
            fontSize: 12, color: Colors.grey[600]))),
        Expanded(flex: 3, child: Text(s['name'] ?? '?',
            style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text('${s['city'] ?? ''} ${s['district'] ?? ''}',
            style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(s['type'] ?? '—',
            style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 1, child: Text(price != null ? '¥$price' : '—',
            style: const TextStyle(fontSize: 13, color: Color(0xFFC49A5E)))),
        Expanded(flex: 2, child: Text(phone,
            style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 1, child: claimed
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F8A4C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('已认领', style: TextStyle(fontSize: 11, color: Colors.white)),
              )
            : Text('—', style: TextStyle(color: Colors.grey[400]))),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 帖子面板
// ─────────────────────────────────────────────────────────────────────────────
class PostsPanel extends StatefulWidget {
  const PostsPanel({super.key});
  @override
  State<PostsPanel> createState() => _PostsPanelState();
}

class _PostsPanelState extends State<PostsPanel> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _err;
  String _q = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final d = await ApiService().posts();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _loading = false; });
    }
  }

  List<dynamic> get _filtered => _q.isEmpty ? _data :
      _data.where((p) =>
        (p['title'] ?? '').toString().contains(_q) ||
        (p['authorName'] ?? '').toString().contains(_q) ||
        (p['type'] ?? '').toString().contains(_q)).toList();

  @override
  Widget build(BuildContext context) => _PanelScaffold(
    title: '帖子',
    count: _filtered.length,
    onRefresh: _load,
    actions: [
      SizedBox(
        width: 200,
        child: TextField(
          decoration: InputDecoration(
            hintText: '搜索标题/作者/类型',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (v) => setState(() => _q = v),
        ),
      ),
    ],
    body: _loading ? const _LoadingBox()
        : _err != null ? _ErrorBox(_err!)
        : _filtered.isEmpty ? const _EmptyBox()
        : _buildTable(),
  );

  Widget _buildTable() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _buildHeader(),
      ...List.generate(_filtered.length, (i) => _buildRow(_filtered[i], i)),
    ]),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF0A7C74).withAlpha(15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Row(children: [
      Expanded(flex: 1, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('作者', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 4, child: Text('标题', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('类型', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 1, child: Text('赞', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 1, child: Text('评', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('发布时间', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
    ]),
  );

  Widget _buildRow(dynamic p, int i) {
    final ts = p['createdAt'];
    String timeStr = '—';
    if (ts != null) {
      try {
        final d = DateTime.parse(ts.toString());
        timeStr = '${d.month}/${d.day} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
      } catch (_) {}
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: i.isEven ? Colors.white : const Color(0xFFFAF8F5),
        border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(30))),
      ),
      child: Row(children: [
        Expanded(flex: 1, child: Text('${i + 1}', style: TextStyle(
            fontSize: 12, color: Colors.grey[600]))),
        Expanded(flex: 2, child: Text(p['authorName'] ?? '?',
            style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 4, child: Text(p['title'] ?? '—',
            style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: _TypeChip(p['type'])),
        Expanded(flex: 1, child: Text('${p['likeCount'] ?? 0}',
            style: const TextStyle(fontSize: 13))),
        Expanded(flex: 1, child: Text('${p['commentCount'] ?? 0}',
            style: const TextStyle(fontSize: 13))),
        Expanded(flex: 2, child: Text(timeStr, style: const TextStyle(fontSize: 12))),
      ]),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String? type;
  const _TypeChip(this.type);
  @override
  Widget build(BuildContext context) {
    Color bg = const Color(0xFF0A7C74);
    String label = type ?? '?';
    switch (type) {
      case 'spot': bg = const Color(0xFF0A7C74); label = '钓点'; break;
      case 'catch': bg = const Color(0xFFC49A5E); label = '渔获'; break;
      case 'diary': bg = const Color(0xFF6C757D); label = '日记'; break;
      case 'guide': bg = const Color(0xFF1F8A4C); label = '指南'; break;
      default: label = type ?? '?';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg.withAlpha(25), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 12, color: bg)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 用户面板
// ─────────────────────────────────────────────────────────────────────────────
class ProfilesPanel extends StatefulWidget {
  const ProfilesPanel({super.key});
  @override
  State<ProfilesPanel> createState() => _ProfilesPanelState();
}

class _ProfilesPanelState extends State<ProfilesPanel> {
  List<dynamic> _data = [];
  bool _loading = true;
  String? _err;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final d = await ApiService().profiles();
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) => _PanelScaffold(
    title: '用户',
    count: _data.length,
    onRefresh: _load,
    actions: const [],
    body: _loading ? const _LoadingBox()
        : _err != null ? _ErrorBox(_err!)
        : _data.isEmpty ? const _EmptyBox('暂无用户数据（用户登录后才写入 profiles 表）')
        : _buildTable(),
  );

  Widget _buildTable() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _buildHeader(),
      ...List.generate(_data.length, (i) => _buildRow(_data[i], i)),
    ]),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF0A7C74).withAlpha(15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Row(children: [
      Expanded(flex: 3, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 3, child: Text('昵称', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('登录方式', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('手机号', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('创建时间', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
    ]),
  );

  Widget _buildRow(dynamic p, int i) {
    String ts = '—';
    if (p['createdAt'] != null) {
      try {
        final d = DateTime.parse(p['createdAt'].toString());
        ts = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      } catch (_) {}
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: i.isEven ? Colors.white : const Color(0xFFFAF8F5),
        border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(30))),
      ),
      child: Row(children: [
        Expanded(flex: 3, child: Text(p['id'] ?? '—', style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis)),
        Expanded(flex: 3, child: Text(p['nickname'] ?? '—', style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(p['loginMethod'] ?? '—', style: const TextStyle(fontSize: 13))),
        Expanded(flex: 2, child: Text(_maskPhone(p['phone']), style: const TextStyle(fontSize: 13))),
        Expanded(flex: 2, child: Text(ts, style: const TextStyle(fontSize: 12))),
      ]),
    );
  }

  String _maskPhone(String? phone) {
    if (phone == null || phone.length < 7) return phone ?? '—';
    return '${phone.substring(0,3)}****${phone.substring(phone.length - 4)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 认领审核面板
// ─────────────────────────────────────────────────────────────────────────────
class ClaimsPanel extends StatefulWidget {
  const ClaimsPanel({super.key});
  @override
  State<ClaimsPanel> createState() => _ClaimsPanelState();
}

class _ClaimsPanelState extends State<ClaimsPanel> {
  List<dynamic> _pending = [];
  List<dynamic> _processed = [];
  bool _loading = true;
  String? _err;
  String _filter = 'pending'; // pending | approved | rejected | all

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final api = ApiService();
      final pending = await api.claims(status: 'pending');
      final approved = await api.claims(status: 'approved');
      final rejected = await api.claims(status: 'rejected');
      if (!mounted) return;
      setState(() {
        _pending = pending;
        _processed = [...approved, ...rejected];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _loading = false; });
    }
  }

  List<dynamic> get _display {
    switch (_filter) {
      case 'pending': return _pending;
      case 'approved': return _processed.where((c) => c['status'] == 'approved').toList();
      case 'rejected': return _processed.where((c) => c['status'] == 'rejected').toList();
      default: return [..._pending, ..._processed];
    }
  }

  Future<void> _approve(String id) async {
    try {
      await ApiService().approveClaim(id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ 已通过，商家信息已更新到钓点'),
            backgroundColor: Color(0xFF1F8A4C)));
    } catch (e) {
      _snackErr('通过失败: $e');
    }
  }

  Future<void> _reject(String id) async {
    final note = await _showNoteDialog();
    if (note == null) return;
    try {
      await ApiService().rejectClaim(id, note: note);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已驳回'), backgroundColor: Color(0xFFFF4757)));
    } catch (e) {
      _snackErr('驳回失败: $e');
    }
  }

  Future<String?> _showNoteDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('驳回原因（选填）'),
        content: TextField(controller: ctrl, maxLines: 3,
          decoration: const InputDecoration(hintText: '例如：资质不明确，请补充营业执照'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF4757)),
            child: const Text('确认驳回'),
          ),
        ],
      ),
    );
  }

  void _snackErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) => _PanelScaffold(
    title: '认领审核',
    count: _pending.length,
    onRefresh: _load,
    actions: [
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'pending', label: Text('待审', style: TextStyle(fontSize: 12))),
          ButtonSegment(value: 'approved', label: Text('已通过', style: TextStyle(fontSize: 12))),
          ButtonSegment(value: 'rejected', label: Text('已驳回', style: TextStyle(fontSize: 12))),
          ButtonSegment(value: 'all', label: Text('全部', style: TextStyle(fontSize: 12))),
        ],
        selected: {_filter},
        onSelectionChanged: (s) => setState(() => _filter = s.first),
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ],
    body: _loading ? const _LoadingBox()
        : _err != null ? _ErrorBox('表可能未创建。请在云开发控制台执行 schema_claim_applications.sql\n\n$_err')
        : _display.isEmpty ? const _EmptyBox('暂无申请')
        : _buildTable(),
  );

  Widget _buildTable() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _buildHeader(),
      ...List.generate(_display.length, (i) => _buildRow(_display[i], i)),
    ]),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF0A7C74).withAlpha(15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Row(children: [
      Expanded(flex: 1, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 3, child: Text('钓点', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('申请人', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('电话/微信', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 3, child: Text('说明', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('提交时间', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
      Expanded(flex: 2, child: Text('状态/操作', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
    ]),
  );

  Widget _buildRow(dynamic c, int i) {
    final status = c['status'] ?? 'pending';
    String ts = '—';
    if (c['submittedAt'] != null) {
      try {
        final d = DateTime.parse(c['submittedAt'].toString());
        ts = '${d.month}/${d.day} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
      } catch (_) {}
    }
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'approved': statusColor = const Color(0xFF1F8A4C); statusLabel = '已通过'; break;
      case 'rejected': statusColor = const Color(0xFFFF4757); statusLabel = '已驳回'; break;
      default: statusColor = const Color(0xFFC49A5E); statusLabel = '待审';
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: i.isEven ? Colors.white : const Color(0xFFFAF8F5),
        border: Border(bottom: BorderSide(color: Colors.grey.withAlpha(30))),
      ),
      child: Row(children: [
        Expanded(flex: 1, child: Text('${i + 1}', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
        Expanded(flex: 3, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c['spotName'] ?? c['spotId'] ?? '?', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis),
            Text(c['spotId'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        )),
        Expanded(flex: 2, child: Text(c['applicantName'] ?? '—', style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c['contactPhone'] != null)
              Text(c['contactPhone'], style: const TextStyle(fontSize: 12)),
            if (c['wechat'] != null)
              Text('微信: ${c['wechat']}', style: const TextStyle(fontSize: 11, color: Color(0xFF0A7C74))),
          ],
        )),
        Expanded(flex: 3, child: Text(c['note'] ?? '—', style: const TextStyle(fontSize: 12),
            maxLines: 3, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Text(ts, style: const TextStyle(fontSize: 12))),
        Expanded(flex: 2, child: status == 'pending'
            ? Row(children: [
                _ActionBtn(
                  label: '通过', color: const Color(0xFF1F8A4C),
                  onPressed: () => _approve(c['id']),
                ),
                const SizedBox(width: 6),
                _ActionBtn(
                  label: '驳回', color: const Color(0xFFFF4757),
                  onPressed: () => _reject(c['id']),
                ),
              ])
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 12, color: statusColor)),
              )),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _ActionBtn({required this.label, required this.color, required this.onPressed});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
    ),
  );
}
