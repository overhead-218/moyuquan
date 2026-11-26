import '../models/post.dart';
import 'backend_config.dart';
import 'tcb_rest_client.dart';
import 'user_profile.dart';

/// 帖子服务
///
/// 数据源优先级：腾讯云库 posts 表（权威） → 本地内置引导帖（兜底，永不白屏）。
/// ⚠️ 文件头原来写着「Firebase 被墙所以回退静态数据」，那段描述已经过期：
///    早期 Firebase 方案已废弃，现在走的是 CloudBase PG 模式 + PostgREST。
class PostService {
  // ---------------------------------------------------------------------------
  // Mock 数据 — 12 条帖子，覆盖三个 type（spot/catch/diary）
  // ---------------------------------------------------------------------------
  /// 全部城市覆盖的 Mock 数据
  static final List<Post> _mockPosts = [
    // ── 官方指南帖（置顶，讲解入驻与玩法）──────────────────────
    Post(id:'p_off_001', authorId:'official', authorName:'摸鱼圈官方', authorAvatar:'📢',
        type:'guide', title:'商家如何免费认领你的钓点',
        content:'钓场 / 农家乐 / 路亚基地老板看过来：认领你的钓点后，联系方式会展示给钓友，并标注「商家认证价」。下面按步骤讲清楚。',
        location:'全国',
        imageUrl:'https://moyuquan-d5g0pvpcw55f8a62e-1305016020.tcloudbaseapp.com/assets/assets/images/official/off_claim.png', height:280,
        likeCount:86, commentCount:21,
        sections: const [
          PostSection(title:'1. 谁能认领', body:'钓点实际运营方：钓场老板、农家乐 / 路亚基地负责人，或拿到授权的运营人员。个人钓友请勿认领非自有钓点。'),
          PostSection(title:'2. 在哪认领', body:'在摸鱼圈搜到你的钓点 → 进入详情页 → 页面下方的「认领此钓点」按钮，点开后提交认领申请。'),
          PostSection(title:'3. 要提交什么', body:'① 负责人 / 店名；② 真实联系电话与微信号；③ 一段资质说明（营业执照或场地授权情况）。信息越真实，审核越快。'),
          PostSection(title:'4. 认领后能做什么', body:'① 联系方式自助维护、立即生效；② 详情页展示「商家认证价」，替代平台采集参考价；③ 上传真实照片、自助维护价格 / 营业时间等功能正在陆续开放，敬请期待。'),
          PostSection(title:'5. 审核与费用', body:'完全免费。提交认领申请后进入审核，运营通过后立刻生效，详情页打上「已认领·商家」标签。审核期间不影响平台已采集的信息，也不展示商家认证价。'),
        ],
        createdAt: DateTime(2026, 9, 21)),
    Post(id:'p_off_002', authorId:'official', authorName:'摸鱼圈官方', authorAvatar:'📢',
        type:'guide', title:'怎么用摸鱼圈找到好钓点',
        content:'摸鱼圈把全国钓点按城市 + 热度聚合，配合钓友真实照片，找钓点不再靠群聊口口相传。下面 5 步带你上手。',
        location:'全国',
        imageUrl:'https://moyuquan-d5g0pvpcw55f8a62e-1305016020.tcloudbaseapp.com/assets/assets/images/official/off_find.png', height:240,
        likeCount:54, commentCount:12,
        sections: const [
          PostSection(title:'1. 按城市筛', body:'底部「钓点」进入列表，先选你所在的城市，钓点按热度排序，热门的排前面，先看你最关心的。'),
          PostSection(title:'2. 看热门推荐', body:'钓点页顶部「热门推荐」是近期最火的水域 TOP5，跟着老钓友的足迹走，不容易踩坑。'),
          PostSection(title:'3. 进详情看什么', body:'真实钓友照片、收费、鱼种旺季、设施配套（住宿 / WIFI / 停车）一条龙信息，出钓前先做功课。'),
          PostSection(title:'4. 发现错误怎么办', body:'详情页右上角「举报」一键反馈图错 / 信息错，运营核实后会修正并入库，帮所有人避坑。'),
          PostSection(title:'5. 收藏管理', body:'喜欢的钓点点收藏，都在「我的」里随时查看，周末出钓前翻一遍就能定目标。'),
        ],
        createdAt: DateTime(2026, 9, 21)),
    Post(id:'p_off_003', authorId:'official', authorName:'摸鱼圈官方', authorAvatar:'📢',
        type:'guide', title:'发布渔获，认识同城钓友',
        content:'在摸鱼圈发渔获、写日记，带定位就能被同城钓友看到，约钓认识朋友比微信群方便。下面说怎么玩。',
        location:'全国',
        imageUrl:'https://moyuquan-d5g0pvpcw55f8a62e-1305016020.tcloudbaseapp.com/assets/assets/images/official/off_community.png', height:300,
        likeCount:47, commentCount:15,
        sections: const [
          PostSection(title:'1. 怎么发帖', body:'首页中间「➕」可发布钓点 / 晒渔获 / 写渔获日记，带真实照片更容易被推荐。'),
          PostSection(title:'2. 同城流量', body:'帖子带定位会出现在同城信息流，方便附近钓友约钓、拼车、拼船，不用到处问群。'),
          PostSection(title:'3. 私信钓友', body:'在他人主页点头像即可私信，约钓、换钓位、聊饵料都不用来回加微信。'),
          PostSection(title:'4. 社区公约', body:'文明垂钓：不展示禁钓区、不晒违规钓法（如毒饵、电鱼）。违规内容会被下架。'),
          PostSection(title:'5. 上推荐技巧', body:'真实图 + 定位 + 高互动的帖子优先进热门，坚持发更容易被同城钓友认识，慢慢攒自己的粉丝。'),
        ],
        createdAt: DateTime(2026, 9, 21)),
    // ── 江苏 ──────────────────────────────────────────────────
    Post(id:'p_001', authorId:'u_one_bowl', authorName:'一碗木瓜水', authorAvatar:'🎣',
        type:'catch', title:'今早老位置又爆护了',
        content:'第三次在这出水，鲫鱼个头比上次还大',
        location:'南京·六合',
        likeCount:248, commentCount:32,
        createdAt:DateTime.now().subtract(const Duration(hours:2))),
    Post(id:'p_002', authorId:'u_old_fisher', authorName:'老钓翁', authorAvatar:'🐟',
        type:'spot', title:'六合郊外野塘·免费',
        content:'导航到龙池大道尽头，左手边土路下去200米',
        location:'南京·六合',
        likeCount:412, commentCount:58,
        createdAt:DateTime.now().subtract(const Duration(hours:5))),
    Post(id:'p_003', authorId:'u_morning_mist', authorName:'晨雾', authorAvatar:'🎣',
        type:'diary', title:'凌晨四点的滁河',
        content:'一个人一条河，风把雾吹散了，鱼没来',
        location:'南京·浦口',
        likeCount:89, commentCount:12,
        createdAt:DateTime.now().subtract(const Duration(hours:8))),
    Post(id:'p_004', authorId:'u_koi_master', authorName:'锦鲤王', authorAvatar:'🐠',
        type:'catch', title:'二十年没见过的野生甲鱼',
        content:'老李头帮我抄的网，手都在抖',
        location:'南京·江宁',
        likeCount:1024, commentCount:156,
        createdAt:DateTime.now().subtract(const Duration(hours:12))),
    Post(id:'p_005', authorId:'u_lake_walker', authorName:'湖边走', authorAvatar:'🦈',
        type:'spot', title:'石臼湖·冬季草洞',
        content:'冰封前最后一个窗口期，草洞密度极高',
        location:'南京·溧水',
        likeCount:567, commentCount:73,
        createdAt:DateTime.now().subtract(const Duration(hours:18))),
    Post(id:'p_006', authorId:'u_road_runner', authorName:'跑路党', authorAvatar:'🐡',
        type:'diary', title:'从滁州骑到南京，就为这一竿',
        content:'70公里，换三条竿，值',
        location:'南京·六合',
        likeCount:198, commentCount:24,
        createdAt:DateTime.now().subtract(const Duration(days:1))),
    Post(id:'p_007', authorId:'u_squid_kid', authorName:'鱿鱼仔', authorAvatar:'🦑',
        type:'catch', title:'路亚翘嘴·窗口期20分钟',
        content:'一口气八条，全是巴掌大',
        location:'南京·六合',
        likeCount:356, commentCount:41,
        createdAt:DateTime.now().subtract(const Duration(days:1, hours:4))),
    Post(id:'p_008', authorId:'u_old_zhou', authorName:'老周', authorAvatar:'🎣',
        type:'spot', title:'金牛湖·深水草区',
        content:'近岸全是小白条，深水区藏大物',
        location:'南京·六合',
        likeCount:723, commentCount:89,
        createdAt:DateTime.now().subtract(const Duration(days:2))),
    Post(id:'p_009', authorId:'u_midnight', authorName:'夜猫子', authorAvatar:'🦈',
        type:'diary', title:'夜钓被蚊子抬走了',
        content:'两条黄辣丁，但两条腿18个包',
        location:'南京·浦口',
        likeCount:145, commentCount:28,
        createdAt:DateTime.now().subtract(const Duration(days:2, hours:6))),
    Post(id:'p_010', authorId:'u_lure_king', authorName:'拟饵王', authorAvatar:'🐠',
        type:'catch', title:'今秋第一条鳜鱼',
        content:'拟饵克星·深水跳底',
        location:'南京·江宁',
        likeCount:891, commentCount:102,
        createdAt:DateTime.now().subtract(const Duration(days:3))),
    Post(id:'p_011', authorId:'u_grass_lake', authorName:'草湖人', authorAvatar:'🐟',
        type:'spot', title:'固城湖·枯水期钓位',
        content:'水位退到历史最低，结构全露出来',
        location:'南京·高淳',
        likeCount:432, commentCount:56,
        createdAt:DateTime.now().subtract(const Duration(days:4))),
    Post(id:'p_012', authorId:'u_traveler', authorName:'走南闯北', authorAvatar:'🎣',
        type:'diary', title:'出差路过新安江',
        content:'拦河堰下游闸口，半小时三条马口',
        location:'黄山·新安江',
        likeCount:267, commentCount:33,
        createdAt:DateTime.now().subtract(const Duration(days:5))),
    Post(id:'p_013', authorId:'u_lishui_fan', authorName:'漓水渔夫', authorAvatar:'🐟',
        type:'catch', title:'太平湖路亚·米级鳜鱼',
        content:'下午三点窗口期，一口就切线，第二天换了PE线才拿下',
        location:'黄山·太平湖',
        likeCount:634, commentCount:78,
        createdAt:DateTime.now().subtract(const Duration(days:3))),

    // ── 浙江 ──────────────────────────────────────────────────
    Post(id:'p_014', authorId:'u_westlake', authorName:'西湖渔翁', authorAvatar:'🎣',
        type:'catch', title:'西溪湿地·夜捞螺蛳青',
        content:'十斤出头，喊了朋友三个人才弄上岸',
        location:'杭州·西溪',
        likeCount:389, commentCount:45,
        createdAt:DateTime.now().subtract(const Duration(hours:6))),
    Post(id:'p_015', authorId:'u_qiandao_vip', authorName:'千岛湖王', authorAvatar:'🐠',
        type:'spot', title:'千岛湖·深处鳜鱼窝',
        content:'水深12米，铅头钩跳底，切了两次线才找到节奏',
        location:'千岛湖',
        likeCount:756, commentCount:91,
        createdAt:DateTime.now().subtract(const Duration(days:1))),
    Post(id:'p_016', authorId:'u_ningbo_fish', authorName:'宁波滩涂人', authorAvatar:'🦀',
        type:'catch', title:'象山港·潮汐钓青蟹',
        content:'小潮活汛，三小时六只，够一盘葱姜炒',
        location:'宁波·象山港',
        likeCount:521, commentCount:63,
        createdAt:DateTime.now().subtract(const Duration(hours:14))),
    Post(id:'p_017', authorId:'u_ningbo_lure', authorName:'宁波路亚人', authorAvatar:'🐟',
        type:'catch', title:'梅山岛·抽停米级海鲈',
        content:'重障碍区强抽，一斤半的海鲈，竿都拉弯了',
        location:'宁波·梅山岛',
        likeCount:483, commentCount:57,
        createdAt:DateTime.now().subtract(const Duration(days:2))),
    Post(id:'p_018', authorId:'u_wenzhou_old', authorName:'温州老郑', authorAvatar:'🎣',
        type:'spot', title:'楠溪江·浅滩鳜鱼',
        content:'早上五点下竿，七点前上了三条，晚了就没口了',
        location:'温州·楠溪江',
        likeCount:318, commentCount:39,
        createdAt:DateTime.now().subtract(const Duration(days:1, hours:8))),
    Post(id:'p_019', authorId:'u_wenzhou_fan', authorName:'温州钓友', authorAvatar:'🐠',
        type:'catch', title:'洞头岛·船路亚黄鳍鲷',
        content:'铅头钩+小T尾，抽停手法，二十多条上岸',
        location:'温州·洞头岛',
        likeCount:445, commentCount:52,
        createdAt:DateTime.now().subtract(const Duration(days:3))),

    // ── 四川 ──────────────────────────────────────────────────
    Post(id:'p_020', authorId:'u_chengdu_lure', authorName:'成都路亚人', authorAvatar:'🎣',
        type:'catch', title:'都江堰·马口季',
        content:'小雨天马口活性高，瓜子大亮片，三小时连竿',
        location:'成都·都江堰',
        likeCount:678, commentCount:84,
        createdAt:DateTime.now().subtract(const Duration(hours:10))),
    Post(id:'p_021', authorId:'u_chengdu_lake', authorName:'锦城湖主', authorAvatar:'🐟',
        type:'diary', title:'锦城湖晨练三小时',
        content:'三小时一口没见，收竿时旁边大爷说今天放水了',
        location:'成都·锦城湖',
        likeCount:234, commentCount:31,
        createdAt:DateTime.now().subtract(const Duration(days:1))),
    Post(id:'p_022', authorId:'u_shushan_fisher', authorName:'眉山老刘', authorAvatar:'🎣',
        type:'catch', title:'瓦屋山溪流·原生虹鳟',
        content:'高山水库出来的水，鳟鱼活性极好，飞蝇钩中鱼',
        location:'眉山·瓦屋山',
        likeCount:534, commentCount:67,
        createdAt:DateTime.now().subtract(const Duration(days:2))),
    Post(id:'p_023', authorId:'u_leshan_fisher', authorName:'乐山老吴', authorAvatar:'🐟',
        type:'spot', title:'大渡河·野钓鲤鲫',
        content:'大渡河边上一个大回湾，窝子打了半小时就开始连竿',
        location:'乐山·大渡河',
        likeCount:412, commentCount:49,
        createdAt:DateTime.now().subtract(const Duration(days:3))),
    Post(id:'p_024', authorId:'u_yibin_fisher', authorName:'宜宾老张', authorAvatar:'🎣',
        type:'catch', title:'金沙江·江团连竿',
        content:'鸡肝打窝，江团疯狂开口，三小时钓了十几条',
        location:'宜宾·金沙江',
        likeCount:367, commentCount:43,
        createdAt:DateTime.now().subtract(const Duration(days:4))),
    Post(id:'p_025', authorId:'u_luzhou_fan', authorName:'泸州小王', authorAvatar:'🐠',
        type:'diary', title:'长江边上的下午',
        content:'长江边上一个人坐了一下午，就上一条草鱼，但风景值了',
        location:'泸州·长江',
        likeCount:189, commentCount:22,
        createdAt:DateTime.now().subtract(const Duration(days:5))),

    // ── 贵州 ──────────────────────────────────────────────────
    Post(id:'p_026', authorId:'u_guiyang_lure', authorName:'贵阳路亚侠', authorAvatar:'🎣',
        type:'catch', title:'红枫湖·湖路亚大口黑鲈',
        content:'夏天窗口期在早上六点到九点，船长三十公分',
        location:'贵阳·红枫湖',
        likeCount:723, commentCount:88,
        createdAt:DateTime.now().subtract(const Duration(hours:16))),
    Post(id:'p_027', authorId:'u_qdn_fisher', authorName:'黔东南老杨', authorAvatar:'🐟',
        type:'catch', title:'都柳江·野钓军鱼',
        content:'标点在一块大石头后面，路亚瓜子饵中了一条斤级',
        location:'黔东南·都柳江',
        likeCount:456, commentCount:55,
        createdAt:DateTime.now().subtract(const Duration(days:2))),
    Post(id:'p_028', authorId:'u_zunyi_old', authorName:'遵义老赵', authorAvatar:'🎣',
        type:'spot', title:'乌江渡·野钓草鱼',
        content:'乌江水质好，草鱼个体大，打完窝子等半小时来了一口',
        location:'遵义·乌江',
        likeCount:334, commentCount:41,
        createdAt:DateTime.now().subtract(const Duration(days:3))),
    Post(id:'p_029', authorId:'u_anshun_fan', authorName:'安顺小李', authorAvatar:'🐠',
        type:'diary', title:'黄果树旁的小河',
        content:'游客都在看瀑布，我在旁边钓鱼，各钓各的',
        location:'安顺·黄果树',
        likeCount:278, commentCount:35,
        createdAt:DateTime.now().subtract(const Duration(days:4))),

    // ── 云南 ──────────────────────────────────────────────────
    Post(id:'p_030', authorId:'u_kunming_fan', authorName:'昆明老陈', authorAvatar:'🎣',
        type:'catch', title:'滇池·野钓鲤鱼',
        content:'早上五点半到，钓到九点上了六条鲤鱼，最大六斤',
        location:'昆明·滇池',
        likeCount:567, commentCount:72,
        createdAt:DateTime.now().subtract(const Duration(hours:20))),
    Post(id:'p_031', authorId:'u_kunming_lure', authorName:'云南路亚', authorAvatar:'🐟',
        type:'catch', title:'阳宗海·大口黑鲈',
        content:'阳宗海鲈鱼密度高，新手下沉系路亚，上鱼很快',
        location:'昆明·阳宗海',
        likeCount:489, commentCount:61,
        createdAt:DateTime.now().subtract(const Duration(days:1, hours:6))),
    Post(id:'p_032', authorId:'u_dali_fisher', authorName:'大理阿鹏', authorAvatar:'🎣',
        type:'catch', title:'洱海·手竿鲫鱼',
        content:'洱海西岸浅滩，秋季鲫鱼肥，用酒米打窝连竿',
        location:'大理·洱海',
        likeCount:634, commentCount:79,
        createdAt:DateTime.now().subtract(const Duration(days:2, hours:4))),
    Post(id:'p_033', authorId:'u_dali_lure', authorName:'丽江路亚', authorAvatar:'🐠',
        type:'spot', title:'拉市海·海菜花间找鱼',
        content:'高原湿地鱼种特殊，路亚瓜子饵效果不错',
        location:'大理·拉市海',
        likeCount:378, commentCount:46,
        createdAt:DateTime.now().subtract(const Duration(days:3))),
    Post(id:'p_034', authorId:'u_lijiang_old', authorName:'丽江老陈', authorAvatar:'🎣',
        type:'diary', title:'文笔山涧流',
        content:'文笔山脚的野溪，水清得能看到鱼，就在石缝里',
        location:'丽江·文笔山',
        likeCount:312, commentCount:38,
        createdAt:DateTime.now().subtract(const Duration(days:4))),
    Post(id:'p_035', authorId:'u_qujing_fan', authorName:'曲靖小周', authorAvatar:'🐟',
        type:'catch', title:'南盘江·野钓罗非',
        content:'夏天南盘江罗非密度高，手竿拉到手酸',
        location:'曲靖·南盘江',
        likeCount:423, commentCount:51,
        createdAt:DateTime.now().subtract(const Duration(days:5))),
  Post(id:'p_guide_submit', authorId:'u_moyuquan', authorName:'摸鱼圈官方', authorAvatar:'🐟',
        type:'diary', title:'3 步把钓点录进摸鱼圈，新手也能发',
        content:'第一步：首页点右下角 ➕ 选「发布钓点」\n第二步：填名称·位置·类型（野钓 / 路亚 / 黑坑 / 农家乐）·收费·鱼种，并上传现场照片\n第三步：提交后平台审核，通过即上架，其他钓友就能搜到\n\n不会填也别怕，信息越真实越容易被搜到。没电话可以标「商家可认领」，绝不编造。',
        location:'全国',
        likeCount:12, commentCount:3,
        createdAt:DateTime.now().subtract(const Duration(hours:2))),
  Post(id:'p_guide_photo', authorId:'u_moyuquan', authorName:'摸鱼圈官方', authorAvatar:'🐟',
        type:'diary', title:'钓点照片怎么拍才有人看？4 个要点',
        content:'①封面用航拍 / 全景，一眼看出水面和地形\n②水体近景必拍：岸线、水深、钓位\n③鱼货 + 设施（棚屋 / 码头 / 停车）各来一张\n④路线 / 入口照一张，别人好找\n\n最低 800×600，禁表情包、禁网图。照片越多星级越高，详情页越靠前。',
        location:'全国',
        likeCount:8, commentCount:1,
        createdAt:DateTime.now().subtract(const Duration(hours:5))),
  Post(id:'p_recruit_spot', authorId:'u_moyuquan', authorName:'摸鱼圈官方', authorAvatar:'🐟',
        type:'diary', title:'征集！你身边的宝藏钓点，发上来一起钓',
        content:'摸鱼圈正在建全国钓点库，缺的就是你本地的好位置。\n\n不管是野河、水库、路亚基地还是农家乐，只要真实，发上来就算共建。信息真实（名称 / 位置 / 收费 / 鱼种 / 电话）优先上精选。\n\n怎么发：首页 ➕ → 发布钓点，按提示填就行。暂时没电话标「商家可认领」即可，我们帮你联系核实。\n\n一起把钓点库做厚，下次出钓不踩坑 🎣',
        location:'全国',
        likeCount:21, commentCount:6,
        createdAt:DateTime.now().subtract(const Duration(hours:1))),
  ];

  // ── 云库接入层 ──────────────────────────────────────
  // _cache 为稳定引用：原地增删改，外部捕获的引用（如 catch_page）自动可见。
  static final List<Post> _cache = List<Post>.from(_mockPosts);

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

  /// 同步取所有帖子
  static List<Post> mockAll() => List.unmodifiable(_cache);

  /// Stream 版 — 给 feed_page 的 StreamBuilder 用，立即 emit 一次
  static Stream<List<Post>> streamAll({int limit = 50}) async* {
    final list = _cache.take(limit).toList(growable: false);
    yield list;
  }

  /// 按 type 过滤
  static Stream<List<Post>> streamByType(String type, {int limit = 50}) async* {
    final list = _cache
        .where((p) => p.type == type)
        .take(limit)
        .toList(growable: false);
    yield list;
  }

  /// 单帖
  static Future<Post?> getOne(String id) async {
    try {
      return _cache.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── 点赞（真实入库：post_likes 表 + posts.likeCount 计数）────────
  static final Set<String> _likedIds = {};
  static final Map<String, int> _likeDelta = {};
  static bool _likesLoaded = false;

  static bool isLiked(String postId) => _likedIds.contains(postId);

  /// 会话内点赞增量（详情页初始化用：base + delta）
  static int deltaOf(String postId) => _likeDelta[postId] ?? 0;

  /// 帖子当前展示点赞数 = 原始数 + 会话内增量
  static int likeCountOf(Post p) => p.likeCount + (_likeDelta[p.id] ?? 0);

  /// 启动时从云库拉取「我点过赞的帖子」。
  ///
  /// ⚠️ 原实现把点赞态完全放在内存里，重启 App / 换设备后所有点赞都不见了，
  ///   用户看到的「我赞过的帖子」永远为空。
  static Future<void> refreshLikesFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query('post_likes', params: {
        'select': 'postId',
        'userId': 'eq.${UserProfile.id}',
        'limit': '1000',
      });
      _likedIds
        ..clear()
        ..addAll(rows.map((r) => r['postId'] as String? ?? '').where((e) => e.isNotEmpty));
      _likesLoaded = true;
      _notify();
      print('[PostService] 已同步点赞态 ${_likedIds.length} 条');
    } catch (e) {
      // 表未建时静默降级：仍可用内存点赞，不阻断启动
      print('[PostService] 点赞态同步失败（降级为会话内状态）：$e');
      _likesLoaded = true;
    }
  }

  /// 切换点赞，返回是否已点赞。计数与明细表同时写入云库。
  static Future<bool> toggleLike(String postId) async {
    final nowLiked = !_likedIds.contains(postId);
    final likeId = 'pl_${UserProfile.id}_$postId';

    // 本地先响应，保证 UI 立即反馈
    if (nowLiked) {
      _likedIds.add(postId);
      _likeDelta[postId] = (_likeDelta[postId] ?? 0) + 1;
    } else {
      _likedIds.remove(postId);
      _likeDelta[postId] = (_likeDelta[postId] ?? 0) - 1;
    }
    _notify();

    if (!BackendConfig.cloudEnabled) return nowLiked;

    try {
      if (nowLiked) {
        await TcbRestClient.upsert('post_likes', {
          'id': likeId,
          'postId': postId,
          'userId': UserProfile.id,
          'createdAt': DateTime.now().toIso8601String(),
        });
      } else {
        await TcbRestClient.delete('post_likes', {'id': 'eq.$likeId'});
      }
      // 同步 posts 表上的聚合计数（服务端无 RPC，故由客户端做 read-modify-write；
      //  多端并发极端情况可能轻微漂移，正式环境应改为数据库端原子自增）
      final p = await getOne(postId);
      if (p != null) {
        await TcbRestClient.update(
          'posts',
          {'id': 'eq.$postId'},
          {'likeCount': p.likeCount + (nowLiked ? 1 : -1)},
        );
      }
    } catch (e) {
      print('[PostService] 点赞同步失败（本地已生效）：$e');
      // 写库失败则回滚本地态，避免出现「显示已赞但其实没存」
      if (nowLiked) {
        _likedIds.remove(postId);
        _likeDelta[postId] = (_likeDelta[postId] ?? 1) - 1;
      } else {
        _likedIds.add(postId);
        _likeDelta[postId] = (_likeDelta[postId] ?? -1) + 1;
      }
      _notify();
    }
    return nowLiked;
  }

  // ── 我的内容（authorId == 当前登录用户 uid）────────────────
  /// 我发布的全部帖子（新帖在前）
  static List<Post> myPosts() =>
      _cache.where((p) => p.authorId == UserProfile.id).toList();

  /// 我的鱼获帖（type == 'catch'）
  static List<Post> myCatchPosts() => _cache
      .where((p) => p.authorId == UserProfile.id && p.type == 'catch')
      .toList();

  /// 我点赞过的帖子（云库 post_likes 表同步进 _likedIds）。
  ///
  /// 「我的」页新增「我的点赞」入口用。列表顺序跟 _cache（最新在前）。
  static List<Post> myLikedPosts() =>
      _cache.where((p) => _likedIds.contains(p.id)).toList();

  /// 某位作者（按昵称匹配）发布的帖子，用于他人主页；找不到返回空。
  static List<Post> postsByAuthorName(String authorName) => _cache
      .where((p) => p.authorName == authorName && p.authorId != UserProfile.id)
      .toList();

  /// UGC 发帖：本地置顶 + 通知 + 异步写云库
  static void addPost(Post post) {
    _cache.insert(0, post);
    _notify();
    _pushAdd(post);
  }

  /// 登出时清空本机用户产生的内容与点赞态（回到启动游客态）。
  static void resetMyContent() {
    _cache.removeWhere((p) => p.authorId == UserProfile.id);
    _likedIds.clear();
    _likeDelta.clear();
    _notify();
  }

  /// 启动后调用：从云库拉取最新帖子覆盖本地缓存；失败保留 mock，永不白屏。
  static Future<void> refreshFromCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    try {
      final rows = await TcbRestClient.query('posts', params: {
        'select': '*',
        'limit': '1000',
        'order': 'createdAt.desc',
      });
      if (rows.isNotEmpty) {
        final cloud =
            rows.map((r) => Post.fromJson(r as Map<String, dynamic>)).toList();
        _cache
          ..clear()
          ..addAll(cloud);
        _notify();
        print('[PostService] 已从云库同步 ${cloud.length} 条帖子');
      }
    } catch (e) {
      print('[PostService] 云库同步失败，使用本地数据：$e');
    }
  }

  /// 一次性：把本地 mock 帖子写入云库（幂等，重复 id 忽略）。
  static Future<void> seedFromMockToCloud() async {
    if (!BackendConfig.cloudEnabled) return;
    for (final p in _mockPosts) {
      await TcbRestClient.upsert('posts', p.toJson()).catchError((e) {
        print('[PostService] seed 跳过 ${p.id}: $e');
      });
    }
    await refreshFromCloud();
  }

  static void _pushAdd(Post post) {
    if (!BackendConfig.cloudEnabled) return;
    TcbRestClient.insert('posts', post.toJson()).then((_) {
      print('[PostService] 已写入云库：${post.id}');
    }).catchError((e) {
      print('[PostService] 写入云库失败（本地已更新）：$e');
    });
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