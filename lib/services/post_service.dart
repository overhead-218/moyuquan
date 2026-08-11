import '../models/post.dart';

/// 帖子服务（mock 版）
///
/// 暂时回退到静态数据，原因：PC 端 `identitytoolkit.googleapis.com` 被网络层阻断，
/// Firebase Web SDK 拿不到 OAuth token，feed 永远进不了 onData。
/// iPhone 蜂窝网可通，但当前没有在 iPhone 上跑摸鱼圈 App 的条件。
///
/// 恢复路径：等网络层修复后，把 _mockAll() 调用换成 streamAll()，
/// 并启用 lib/main.dart 中已注释的 Firebase.initializeApp()。
class PostService {
  // ---------------------------------------------------------------------------
  // Mock 数据 — 12 条帖子，覆盖三个 type（spot/catch/diary）
  // ---------------------------------------------------------------------------
  /// 全部城市覆盖的 Mock 数据
  static final List<Post> _mockPosts = [
    // ── 江苏 ──────────────────────────────────────────────────
    Post(id:'p_001', authorId:'u_one_bowl', authorName:'一碗木瓜水', authorAvatar:'🎣',
        type:'catch', title:'今早老位置又爆护了',
        content:'第三次在这出水，鲫鱼个头比上次还大',
        location:'南京·六合',
        imageUrl:'https://picsum.photos/seed/fq_a/600/800', height:280,
        likeCount:248, commentCount:32,
        createdAt:DateTime.now().subtract(const Duration(hours:2))),
    Post(id:'p_002', authorId:'u_old_fisher', authorName:'老钓翁', authorAvatar:'🐟',
        type:'spot', title:'六合郊外野塘·免费',
        content:'导航到龙池大道尽头，左手边土路下去200米',
        location:'南京·六合',
        imageUrl:'https://picsum.photos/seed/fq_b/600/900', height:320,
        likeCount:412, commentCount:58,
        createdAt:DateTime.now().subtract(const Duration(hours:5))),
    Post(id:'p_003', authorId:'u_morning_mist', authorName:'晨雾', authorAvatar:'🎣',
        type:'diary', title:'凌晨四点的滁河',
        content:'一个人一条河，风把雾吹散了，鱼没来',
        location:'南京·浦口',
        imageUrl:'https://picsum.photos/seed/pk_c/600/700', height:240,
        likeCount:89, commentCount:12,
        createdAt:DateTime.now().subtract(const Duration(hours:8))),
    Post(id:'p_004', authorId:'u_koi_master', authorName:'锦鲤王', authorAvatar:'🐠',
        type:'catch', title:'二十年没见过的野生甲鱼',
        content:'老李头帮我抄的网，手都在抖',
        location:'南京·江宁',
        imageUrl:'https://picsum.photos/seed/jn_d/600/850', height:300,
        likeCount:1024, commentCount:156,
        createdAt:DateTime.now().subtract(const Duration(hours:12))),
    Post(id:'p_005', authorId:'u_lake_walker', authorName:'湖边走', authorAvatar:'🦈',
        type:'spot', title:'石臼湖·冬季草洞',
        content:'冰封前最后一个窗口期，草洞密度极高',
        location:'南京·溧水',
        imageUrl:'https://picsum.photos/seed/ls_e/600/750', height:260,
        likeCount:567, commentCount:73,
        createdAt:DateTime.now().subtract(const Duration(hours:18))),
    Post(id:'p_006', authorId:'u_road_runner', authorName:'跑路党', authorAvatar:'🐡',
        type:'diary', title:'从滁州骑到南京，就为这一竿',
        content:'70公里，换三条竿，值',
        location:'南京·六合',
        imageUrl:'https://picsum.photos/seed/fq_f/600/880', height:310,
        likeCount:198, commentCount:24,
        createdAt:DateTime.now().subtract(const Duration(days:1))),
    Post(id:'p_007', authorId:'u_squid_kid', authorName:'鱿鱼仔', authorAvatar:'🦑',
        type:'catch', title:'路亚翘嘴·窗口期20分钟',
        content:'一口气八条，全是巴掌大',
        location:'南京·六合',
        imageUrl:'https://picsum.photos/seed/fq_g/600/720', height:250,
        likeCount:356, commentCount:41,
        createdAt:DateTime.now().subtract(const Duration(days:1, hours:4))),
    Post(id:'p_008', authorId:'u_old_zhou', authorName:'老周', authorAvatar:'🎣',
        type:'spot', title:'金牛湖·深水草区',
        content:'近岸全是小白条，深水区藏大物',
        location:'南京·六合',
        imageUrl:'https://picsum.photos/seed/fq_h/600/820', height:290,
        likeCount:723, commentCount:89,
        createdAt:DateTime.now().subtract(const Duration(days:2))),
    Post(id:'p_009', authorId:'u_midnight', authorName:'夜猫子', authorAvatar:'🦈',
        type:'diary', title:'夜钓被蚊子抬走了',
        content:'两条黄辣丁，但两条腿18个包',
        location:'南京·浦口',
        imageUrl:'https://picsum.photos/seed/pk_i/600/680', height:230,
        likeCount:145, commentCount:28,
        createdAt:DateTime.now().subtract(const Duration(days:2, hours:6))),
    Post(id:'p_010', authorId:'u_lure_king', authorName:'拟饵王', authorAvatar:'🐠',
        type:'catch', title:'今秋第一条鳜鱼',
        content:'拟饵克星·深水跳底',
        location:'南京·江宁',
        imageUrl:'https://picsum.photos/seed/jn_j/600/780', height:270,
        likeCount:891, commentCount:102,
        createdAt:DateTime.now().subtract(const Duration(days:3))),
    Post(id:'p_011', authorId:'u_grass_lake', authorName:'草湖人', authorAvatar:'🐟',
        type:'spot', title:'固城湖·枯水期钓位',
        content:'水位退到历史最低，结构全露出来',
        location:'南京·高淳',
        imageUrl:'https://picsum.photos/seed/gc_k/600/860', height:295,
        likeCount:432, commentCount:56,
        createdAt:DateTime.now().subtract(const Duration(days:4))),
    Post(id:'p_012', authorId:'u_traveler', authorName:'走南闯北', authorAvatar:'🎣',
        type:'diary', title:'出差路过新安江',
        content:'拦河堰下游闸口，半小时三条马口',
        location:'黄山·新安江',
        imageUrl:'https://picsum.photos/seed/xaj/600/740', height:255,
        likeCount:267, commentCount:33,
        createdAt:DateTime.now().subtract(const Duration(days:5))),
    Post(id:'p_013', authorId:'u_lishui_fan', authorName:'漓水渔夫', authorAvatar:'🐟',
        type:'catch', title:'太平湖路亚·米级鳜鱼',
        content:'下午三点窗口期，一口就切线，第二天换了PE线才拿下',
        location:'黄山·太平湖',
        imageUrl:'https://picsum.photos/seed/tph/600/830', height:285,
        likeCount:634, commentCount:78,
        createdAt:DateTime.now().subtract(const Duration(days:3))),

    // ── 浙江 ──────────────────────────────────────────────────
    Post(id:'p_014', authorId:'u_westlake', authorName:'西湖渔翁', authorAvatar:'🎣',
        type:'catch', title:'西溪湿地·夜捞螺蛳青',
        content:'十斤出头，喊了朋友三个人才弄上岸',
        location:'杭州·西溪',
        imageUrl:'https://picsum.photos/seed/xxj/600/810', height:280,
        likeCount:389, commentCount:45,
        createdAt:DateTime.now().subtract(const Duration(hours:6))),
    Post(id:'p_015', authorId:'u_qiandao_vip', authorName:'千岛湖王', authorAvatar:'🐠',
        type:'spot', title:'千岛湖·深处鳜鱼窝',
        content:'水深12米，铅头钩跳底，切了两次线才找到节奏',
        location:'千岛湖',
        imageUrl:'https://picsum.photos/seed/qdh/600/850', height:295,
        likeCount:756, commentCount:91,
        createdAt:DateTime.now().subtract(const Duration(days:1))),
    Post(id:'p_016', authorId:'u_ningbo_fish', authorName:'宁波滩涂人', authorAvatar:'🦀',
        type:'catch', title:'象山港·潮汐钓青蟹',
        content:'小潮活汛，三小时六只，够一盘葱姜炒',
        location:'宁波·象山港',
        imageUrl:'https://picsum.photos/seed/xsg/600/720', height:250,
        likeCount:521, commentCount:63,
        createdAt:DateTime.now().subtract(const Duration(hours:14))),
    Post(id:'p_017', authorId:'u_ningbo_lure', authorName:'宁波路亚人', authorAvatar:'🐟',
        type:'catch', title:'梅山岛·抽停米级海鲈',
        content:'重障碍区强抽，一斤半的海鲈，竿都拉弯了',
        location:'宁波·梅山岛',
        imageUrl:'https://picsum.photos/seed/msd/600/790', height:275,
        likeCount:483, commentCount:57,
        createdAt:DateTime.now().subtract(const Duration(days:2))),
    Post(id:'p_018', authorId:'u_wenzhou_old', authorName:'温州老郑', authorAvatar:'🎣',
        type:'spot', title:'楠溪江·浅滩鳜鱼',
        content:'早上五点下竿，七点前上了三条，晚了就没口了',
        location:'温州·楠溪江',
        imageUrl:'https://picsum.photos/seed/nxj/600/760', height:265,
        likeCount:318, commentCount:39,
        createdAt:DateTime.now().subtract(const Duration(days:1, hours:8))),
    Post(id:'p_019', authorId:'u_wenzhou_fan', authorName:'温州钓友', authorAvatar:'🐠',
        type:'catch', title:'洞头岛·船路亚黄鳍鲷',
        content:'铅头钩+小T尾，抽停手法，二十多条上岸',
        location:'温州·洞头岛',
        imageUrl:'https://picsum.photos/seed/dtd/600/810', height:280,
        likeCount:445, commentCount:52,
        createdAt:DateTime.now().subtract(const Duration(days:3))),

    // ── 四川 ──────────────────────────────────────────────────
    Post(id:'p_020', authorId:'u_chengdu_lure', authorName:'成都路亚人', authorAvatar:'🎣',
        type:'catch', title:'都江堰·马口季',
        content:'小雨天马口活性高，瓜子大亮片，三小时连竿',
        location:'成都·都江堰',
        imageUrl:'https://picsum.photos/seed/djy/600/780', height:270,
        likeCount:678, commentCount:84,
        createdAt:DateTime.now().subtract(const Duration(hours:10))),
    Post(id:'p_021', authorId:'u_chengdu_lake', authorName:'锦城湖主', authorAvatar:'🐟',
        type:'diary', title:'锦城湖晨练三小时',
        content:'三小时一口没见，收竿时旁边大爷说今天放水了',
        location:'成都·锦城湖',
        imageUrl:'https://picsum.photos/seed/jch/600/750', height:260,
        likeCount:234, commentCount:31,
        createdAt:DateTime.now().subtract(const Duration(days:1))),
    Post(id:'p_022', authorId:'u_shushan_fisher', authorName:'眉山老刘', authorAvatar:'🎣',
        type:'catch', title:'瓦屋山溪流·原生虹鳟',
        content:'高山水库出来的水，鳟鱼活性极好，飞蝇钩中鱼',
        location:'眉山·瓦屋山',
        imageUrl:'https://picsum.photos/seed/wsh/600/820', height:285,
        likeCount:534, commentCount:67,
        createdAt:DateTime.now().subtract(const Duration(days:2))),
    Post(id:'p_023', authorId:'u_leshan_fisher', authorName:'乐山老吴', authorAvatar:'🐟',
        type:'spot', title:'大渡河·野钓鲤鲫',
        content:'大渡河边上一个大回湾，窝子打了半小时就开始连竿',
        location:'乐山·大渡河',
        imageUrl:'https://picsum.photos/seed/ddh/600/840', height:290,
        likeCount:412, commentCount:49,
        createdAt:DateTime.now().subtract(const Duration(days:3))),
    Post(id:'p_024', authorId:'u_yibin_fisher', authorName:'宜宾老张', authorAvatar:'🎣',
        type:'catch', title:'金沙江·江团连竿',
        content:'鸡肝打窝，江团疯狂开口，三小时钓了十几条',
        location:'宜宾·金沙江',
        imageUrl:'https://picsum.photos/seed/jsj/600/770', height:268,
        likeCount:367, commentCount:43,
        createdAt:DateTime.now().subtract(const Duration(days:4))),
    Post(id:'p_025', authorId:'u_luzhou_fan', authorName:'泸州小王', authorAvatar:'🐠',
        type:'diary', title:'长江边上的下午',
        content:'长江边上一个人坐了一下午，就上一条草鱼，但风景值了',
        location:'泸州·长江',
        imageUrl:'https://picsum.photos/seed/cjlz/600/800', height:278,
        likeCount:189, commentCount:22,
        createdAt:DateTime.now().subtract(const Duration(days:5))),

    // ── 贵州 ──────────────────────────────────────────────────
    Post(id:'p_026', authorId:'u_guiyang_lure', authorName:'贵阳路亚侠', authorAvatar:'🎣',
        type:'catch', title:'红枫湖·湖路亚大口黑鲈',
        content:'夏天窗口期在早上六点到九点，船长三十公分',
        location:'贵阳·红枫湖',
        imageUrl:'https://picsum.photos/seed/hfh/600/860', height:298,
        likeCount:723, commentCount:88,
        createdAt:DateTime.now().subtract(const Duration(hours:16))),
    Post(id:'p_027', authorId:'u_qdn_fisher', authorName:'黔东南老杨', authorAvatar:'🐟',
        type:'catch', title:'都柳江·野钓军鱼',
        content:'标点在一块大石头后面，路亚瓜子饵中了一条斤级',
        location:'黔东南·都柳江',
        imageUrl:'https://picsum.photos/seed/dlj/600/830', height:288,
        likeCount:456, commentCount:55,
        createdAt:DateTime.now().subtract(const Duration(days:2))),
    Post(id:'p_028', authorId:'u_zunyi_old', authorName:'遵义老赵', authorAvatar:'🎣',
        type:'spot', title:'乌江渡·野钓草鱼',
        content:'乌江水质好，草鱼个体大，打完窝子等半小时来了一口',
        location:'遵义·乌江',
        imageUrl:'https://picsum.photos/seed/wjd/600/810', height:282,
        likeCount:334, commentCount:41,
        createdAt:DateTime.now().subtract(const Duration(days:3))),
    Post(id:'p_029', authorId:'u_anshun_fan', authorName:'安顺小李', authorAvatar:'🐠',
        type:'diary', title:'黄果树旁的小河',
        content:'游客都在看瀑布，我在旁边钓鱼，各钓各的',
        location:'安顺·黄果树',
        imageUrl:'https://picsum.photos/seed/hgs/600/760', height:264,
        likeCount:278, commentCount:35,
        createdAt:DateTime.now().subtract(const Duration(days:4))),

    // ── 云南 ──────────────────────────────────────────────────
    Post(id:'p_030', authorId:'u_kunming_fan', authorName:'昆明老陈', authorAvatar:'🎣',
        type:'catch', title:'滇池·野钓鲤鱼',
        content:'早上五点半到，钓到九点上了六条鲤鱼，最大六斤',
        location:'昆明·滇池',
        imageUrl:'https://picsum.photos/seed/dc/600/880', height:305,
        likeCount:567, commentCount:72,
        createdAt:DateTime.now().subtract(const Duration(hours:20))),
    Post(id:'p_031', authorId:'u_kunming_lure', authorName:'云南路亚', authorAvatar:'🐟',
        type:'catch', title:'阳宗海·大口黑鲈',
        content:'阳宗海鲈鱼密度高，新手下沉系路亚，上鱼很快',
        location:'昆明·阳宗海',
        imageUrl:'https://picsum.photos/seed/yzh/600/840', height:292,
        likeCount:489, commentCount:61,
        createdAt:DateTime.now().subtract(const Duration(days:1, hours:6))),
    Post(id:'p_032', authorId:'u_dali_fisher', authorName:'大理阿鹏', authorAvatar:'🎣',
        type:'catch', title:'洱海·手竿鲫鱼',
        content:'洱海西岸浅滩，秋季鲫鱼肥，用酒米打窝连竿',
        location:'大理·洱海',
        imageUrl:'https://picsum.photos/seed/eh/600/820', height:285,
        likeCount:634, commentCount:79,
        createdAt:DateTime.now().subtract(const Duration(days:2, hours:4))),
    Post(id:'p_033', authorId:'u_dali_lure', authorName:'丽江路亚', authorAvatar:'🐠',
        type:'spot', title:'拉市海·海菜花间找鱼',
        content:'高原湿地鱼种特殊，路亚瓜子饵效果不错',
        location:'大理·拉市海',
        imageUrl:'https://picsum.photos/seed/lsh/600/800', height:278,
        likeCount:378, commentCount:46,
        createdAt:DateTime.now().subtract(const Duration(days:3))),
    Post(id:'p_034', authorId:'u_lijiang_old', authorName:'丽江老陈', authorAvatar:'🎣',
        type:'diary', title:'文笔山涧流',
        content:'文笔山脚的野溪，水清得能看到鱼，就在石缝里',
        location:'丽江·文笔山',
        imageUrl:'https://picsum.photos/seed/wbs/600/750', height:262,
        likeCount:312, commentCount:38,
        createdAt:DateTime.now().subtract(const Duration(days:4))),
    Post(id:'p_035', authorId:'u_qujing_fan', authorName:'曲靖小周', authorAvatar:'🐟',
        type:'catch', title:'南盘江·野钓罗非',
        content:'夏天南盘江罗非密度高，手竿拉到手酸',
        location:'曲靖·南盘江',
        imageUrl:'https://picsum.photos/seed/npj/600/810', height:282,
        likeCount:423, commentCount:51,
        createdAt:DateTime.now().subtract(const Duration(days:5))),
  ];

  // ---------------------------------------------------------------------------
  // 对外 API（mock 同步版 + Stream 兼容版）
  // ---------------------------------------------------------------------------

  /// 同步取所有帖子（mock）
  static List<Post> mockAll() => List.unmodifiable(_mockPosts);

  /// Stream 版 — 给 feed_page 的 StreamBuilder 用，立即 emit 一次
  static Stream<List<Post>> streamAll({int limit = 50}) async* {
    final list = _mockPosts.take(limit).toList(growable: false);
    yield list;
  }

  /// 按 type 过滤（mock）
  static Stream<List<Post>> streamByType(String type, {int limit = 50}) async* {
    final list = _mockPosts
        .where((p) => p.type == type)
        .take(limit)
        .toList(growable: false);
    yield list;
  }

  /// 单帖（mock）
  static Future<Post?> getOne(String id) async {
    try {
      return _mockPosts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ===========================================================================
  // 旧 Firestore 实现（保留，恢复时把上面的方法换回去即可）
  // ===========================================================================
  /*
  import 'package:cloud_firestore/cloud_firestore.dart';
  static final _db = FirebaseFirestore.instance;

  static Stream<List<Post>> streamAll({int limit = 50}) {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(Post.fromDoc).toList(growable: false));
  }
  */
}