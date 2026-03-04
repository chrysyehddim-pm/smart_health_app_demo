import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ==========================================
// 1. 全域狀態管理 (AppState)
// ==========================================
enum UserType { guest, newMember, activeMember }
enum ProductPhase { mvp, vision } 
enum AiScenario { commerceLead, rewardSponsorship } // 👉 新增：AI 商業變現場景

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  UserType currentUserType = UserType.guest;
  ProductPhase currentPhase = ProductPhase.mvp; 
  AiScenario currentAiScenario = AiScenario.commerceLead; // 預設為導購場景
  
  String userName = '訪客';
  int points = 0;
  String level = '訪客';
  int currentExp = 0;
  int maxExp = 100;
  Map<String, double> radarStats = {};
  
  bool hasSetVitals = false;
  double textScale = 1.0; 

  void toggleTextScale() { textScale = textScale == 1.0 ? 1.3 : 1.0; notifyListeners(); }
  void switchAiScenario(AiScenario scenario) { currentAiScenario = scenario; notifyListeners(); }

  void switchUser(UserType type) {
    currentUserType = type;
    switch (type) {
      case UserType.guest:
        userName = '訪客'; points = 0; level = '訪客'; currentExp = 0; maxExp = 100; radarStats = {}; hasSetVitals = false;
        break;
      case UserType.newMember:
        userName = '新會員'; points = 100; level = 'Lv.1 新手'; currentExp = 20; maxExp = 100; hasSetVitals = false;
        radarStats = {'腦力': 0.0, '行動力': 0.0, '活力': 0.0, '防護力': 0.0, '恆毅力': 0.0}; 
        break;
      case UserType.activeMember:
        userName = 'Chrys'; points = 2800; level = 'Lv.4 探索家'; currentExp = 850; maxExp = 1000; hasSetVitals = true;
        radarStats = {'腦力': 0.8, '行動力': 0.4, '活力': 0.7, '防護力': 0.9, '恆毅力': 0.8};
        break;
    }
    notifyListeners();
  }

  void switchPhase(ProductPhase phase) { currentPhase = phase; notifyListeners(); }
}

final appState = AppState();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DevicePreview(enabled: true, builder: (context) => const SmartHealthApp()));
}

Future<void> _launchUrl(String url) async {
  if (url.isEmpty) return;
  if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) debugPrint('Could not launch $url');
}

class SmartHealthApp extends StatelessWidget {
  const SmartHealthApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, child) {
        return MaterialApp(
          title: 'Happy Health Demo',
          debugShowCheckedModeBanner: false,
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          builder: (context, widget) {
            Widget app = DevicePreview.appBuilder(context, widget);
            return MediaQuery(
              // ignore: deprecated_member_use
              data: MediaQuery.of(context).copyWith(textScaleFactor: appState.textScale), 
              child: app,
            );
          },
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0, centerTitle: true, titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold), iconTheme: IconThemeData(color: Colors.black87)),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32), background: const Color(0xFFF5F7FA)),
            textTheme: GoogleFonts.notoSansTcTextTheme(),
            cardTheme: CardThemeData(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}

// ==========================================
// 共用元件：推播小鈴鐺 (Notification)
// ==========================================
class BellIcon extends StatelessWidget {
  const BellIcon({super.key});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_none, color: Colors.black87),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage())),
    );
  }
}

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通知中心')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNotifItem(Icons.emoji_events, Colors.amber, '恭喜您解鎖「連續登入 7 天」成就！獲得 50 積分。', '系統通知・剛剛'),
          _buildNotifItem(Icons.family_restroom, Colors.deepOrange, '爸爸完成了今日的金幣深蹲王任務，快去給他按個讚！', '親友動態・1小時前'),
          _buildNotifItem(Icons.article, Colors.blue, '亞東醫院最新文章：預防中風的五個黃金守則，點擊查看。', '衛教推薦・昨天'),
        ],
      ),
    );
  }
  Widget _buildNotifItem(IconData icon, Color color, String title, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        onTap: () {},
      ),
    );
  }
}

// ==========================================
// 2. 展示控制台 (Demo Console FAB)
// ==========================================
class GodModeFab extends StatelessWidget {
  final int currentTabIndex;
  const GodModeFab({super.key, this.currentTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16, bottom: 16,
      child: FloatingActionButton.small(
        heroTag: 'god_mode', backgroundColor: Colors.black87, foregroundColor: Colors.yellowAccent,
        onPressed: () => _showConsole(context),
        child: const Icon(Icons.tune),
      ),
    );
  }

  void _showConsole(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('展示控制台 (Demo Console)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('1. 切換身分 (User Lifecycle)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptBtn(context, '訪客', UserType.guest, appState.currentUserType == UserType.guest),
                  _buildOptBtn(context, '新手', UserType.newMember, appState.currentUserType == UserType.newMember),
                  _buildOptBtn(context, '老手', UserType.activeMember, appState.currentUserType == UserType.activeMember),
                ],
              ),
              const SizedBox(height: 24),
              const Text('2. 產品階段展示 (Roadmap)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPhaseBtn(context, 'MVP 版', ProductPhase.mvp, appState.currentPhase == ProductPhase.mvp),
                  _buildPhaseBtn(context, 'Vision 版', ProductPhase.vision, appState.currentPhase == ProductPhase.vision),
                ],
              ),
              const SizedBox(height: 24),
              
              // 👉 新增：AI 商業變現場景切換 (PM Demo 殺手鐧)
              const Text('3. AI 商業主動出擊模擬 (Business Agent)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAiBtn(context, '場景 A: 導購與醫療', AiScenario.commerceLead, appState.currentAiScenario == AiScenario.commerceLead),
                  _buildAiBtn(context, '場景 B: 贊助與保險', AiScenario.rewardSponsorship, appState.currentAiScenario == AiScenario.rewardSponsorship),
                ],
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.text_increase, color: Colors.deepOrange),
                title: const Text('樂齡大字模式 (Demo 專用)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                trailing: Switch(value: appState.textScale > 1.0, onChanged: (v) { appState.toggleTextScale(); Navigator.pop(context); }, activeColor: Colors.deepOrange),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white), child: const Text('關閉')))
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptBtn(BuildContext context, String label, UserType type, bool isSel) => ElevatedButton(onPressed: () { appState.switchUser(type); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? const Color(0xFF2E7D32) : Colors.grey[200], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)), child: Text(label, style: const TextStyle(fontSize: 12)));
  Widget _buildPhaseBtn(BuildContext context, String label, ProductPhase phase, bool isSel) => ElevatedButton(onPressed: () { appState.switchPhase(phase); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? Colors.deepPurple : Colors.grey[200], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0), child: Text(label));
  Widget _buildAiBtn(BuildContext context, String label, AiScenario scenario, bool isSel) => ElevatedButton(onPressed: () { appState.switchAiScenario(scenario); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? Colors.blueAccent : Colors.grey[200], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 12)), child: Text(label, style: const TextStyle(fontSize: 12)));
}

// ==========================================
// 3. 登入 & 註冊
// ==========================================
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)), child: const Icon(Icons.health_and_safety, size: 50, color: Color(0xFF2E7D32))),
                  const SizedBox(height: 16),
                  Text('Happy Health', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2E7D32))),
                  const Text('您的全方位 AI 健康管家', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 48),
                  _buildLoginBtn(context, '會員登入', const Color(0xFF2E7D32), Colors.white, () { appState.switchUser(UserType.activeMember); Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigator())); }),
                  const SizedBox(height: 16),
                  _buildLoginBtn(context, '註冊新帳號', Colors.white, const Color(0xFF2E7D32), () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())), isOutline: true),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () { appState.switchUser(UserType.guest); Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigator())); }, child: const Text('訪客體驗模式 >', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          ),
          const GodModeFab(currentTabIndex: -1),
        ],
      ),
    );
  }
  Widget _buildLoginBtn(BuildContext context, String text, Color bg, Color fg, VoidCallback onTap, {bool isOutline = false}) => SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: onTap, style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: fg, elevation: 0, side: isOutline ? const BorderSide(color: Color(0xFF2E7D32)) : null, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))));
}

class RegisterPage extends StatefulWidget { const RegisterPage({super.key}); @override State<RegisterPage> createState() => _RegisterPageState(); }
class _RegisterPageState extends State<RegisterPage> {
  bool _agreed = false;
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('會員註冊')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('基本資料', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: '姓名', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? '必填' : null),
              const SizedBox(height: 12),
              TextFormField(decoration: const InputDecoration(labelText: '手機號碼 (唯一識別碼)', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 32),
              CheckboxListTile(value: _agreed, onChanged: (v) => setState(() => _agreed = v!), title: const Text('我同意服務條款及隱私授權'), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _agreed ? _submit : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white), child: const Text('確認註冊', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))
            ],
          ),
        ),
      ),
    );
  }
  void _submit() { if (_formKey.currentState!.validate()) { appState.switchUser(UserType.newMember); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainNavigator()), (route) => false); } }
}

// ==========================================
// 4. 主結構導覽
// ==========================================
class MainNavigator extends StatefulWidget { const MainNavigator({super.key}); @override State<MainNavigator> createState() => _MainNavigatorState(); }
class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  void _onTabTapped(int index) {
    if (appState.currentUserType == UserType.guest && (index == 3 || index == 4)) {
      showDialog(context: context, builder: (context) => AlertDialog(title: const Text('訪客權限受限'), content: const Text('健康趨勢與會員中心僅限會員使用。\n註冊即可獲得新手獎勵 100 點！'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('稍後')), ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterPage())); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white), child: const Text('立即註冊'))]));
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [HomePage(onTabChange: _onTabTapped), const TrainPage(), const CheckPage(), const DataPage(), const ProfilePage()];
    return Scaffold(
      body: Stack(
        children: [
          pages[_currentIndex],
          GodModeFab(currentTabIndex: _currentIndex),
        ],
      ),
      bottomNavigationBar: NavigationBar(selectedIndex: _currentIndex, onDestinationSelected: _onTabTapped, backgroundColor: Colors.white, indicatorColor: const Color(0xFFE8F5E9), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首頁'), NavigationDestination(icon: Icon(Icons.fitness_center_outlined), selectedIcon: Icon(Icons.fitness_center), label: '鍛鍊'), NavigationDestination(icon: Icon(Icons.medical_services_outlined), selectedIcon: Icon(Icons.medical_services), label: '檢測'), NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: '趨勢'), NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的')]),
    );
  }
}

// ==========================================
// 5. 首頁 (Home) - AI 核心商業化重構
// ==========================================
class HomePage extends StatelessWidget {
  final Function(int) onTabChange;
  const HomePage({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    bool isVision = appState.currentPhase == ProductPhase.vision;
    bool isActive = appState.currentUserType == UserType.activeMember;
    bool isNew = appState.currentUserType == UserType.newMember;
    bool isGuest = appState.currentUserType == UserType.guest;

    return Scaffold(
      appBar: AppBar(title: const Text('Happy Health'), actions: const [BellIcon(), SizedBox(width: 8)]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
        children: [
          if (!isGuest) _buildAssetCard(context),
          if (isGuest) _buildGuestCard(context),
          const SizedBox(height: 16),

          // 👉 核心亮點：AI 主動出擊商業卡片 (僅老會員顯示，展現意圖分析)
          if (isActive) _buildProactiveAiAgentCard(context),

          if (isVision && !isGuest) ...[
            const Row(children: [Icon(Icons.family_restroom, color: Colors.deepOrange), SizedBox(width: 8), Text('親友健康圈', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            SizedBox(height: 100, child: ListView(scrollDirection: Axis.horizontal, children: [_buildFamilyAvatar(context, '爸爸', true), _buildFamilyAvatar(context, '媽媽', false), _buildAddFamilyBtn(context)])),
            const SizedBox(height: 24),
          ],

          if (isNew) _buildOnboardingCard(),
          if (isActive) _buildRealRadarCard(context),
          const SizedBox(height: 24),
          
          if (isActive) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Row(children: [Icon(Icons.assignment_turned_in, color: Colors.teal), SizedBox(width: 8), Text('AI 今日動態處方', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TaskCenterPage())), child: const Text('全部任務 >'))
            ]),
            const SizedBox(height: 12),
            _buildPrescriptionCard(context, '行動力訓練', '金幣深蹲王 15 下', Icons.accessibility_new, Colors.purple, () => onTabChange(1)),
            const SizedBox(height: 8),
            _buildPrescriptionCard(context, '腦力維持', '眼力極限考驗 (A級)', Icons.psychology, Colors.orange, () => onTabChange(1)),
          ],
          const SizedBox(height: 32),

          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [const Text('衛教園地', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade200)), child: const Text('🏥 亞東醫院專業提供', style: TextStyle(fontSize: 10, color: Colors.blue)))]),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArticleListPage())), child: const Text('查看更多 >', style: TextStyle(color: Colors.grey))),
          ]),
          const SizedBox(height: 8),
          _buildArticleCard(context, 'AI助攻遠距安心守護心血管疾病', '醫學研究部 吳彥雯 主任', '#心血管', 'https://www.femh.org.tw/magazine/viewmag.aspx?ID=11838'),
          _buildArticleCard(context, '常常頭痛怎麼辦？我是不是得腦瘤了！', '神經醫學部 賴資賢 主任', '#神經醫學', 'https://www.femh.org.tw/research/news_detail.aspx?NewsNo=14687&Class=1'),
          _buildArticleCard(context, '解鎖大腦健康失智症新趨勢 健檢為您量身打造', '神經醫學部 黃彥翔 主任', '#失智症', 'https://www.femh.org.tw/magazine/viewmag.aspx?ID=11889'),
        ],
      ),
    );
  }

  // 🤖 AI 智能管家主動出擊卡片 (商業核心)
  Widget _buildProactiveAiAgentCard(BuildContext context) {
    bool isLead = appState.currentAiScenario == AiScenario.commerceLead;
    
    String aiTitle = isLead ? "健康警訊與提案" : "極致健康解鎖";
    String aiMessage = isLead 
      ? "早安，Chrys。系統偵測到您近期『行動力』標籤有衰退趨勢，且缺乏核心肌群鍛鍊。\n\n根據亞東醫院復健科專欄建議，我已為您爭取到【大樹藥局 - 白蘭氏雙效葡萄糖胺】的專屬優惠，以及自費復健評估專案，請問需要為您安排嗎？"
      : "太棒了，Chrys！您的『恆毅力與活力』標籤超越了 95% 的同齡用戶！\n\nAI 已為您解鎖隱藏版福利：憑此健康高分憑證，購買【南山人壽外溢保單】可直接減免首年保費 10%，同時桂格完膳也送您一份專屬禮物！";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.deepPurple.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.smart_toy, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Text('AI 專屬健康管家：$aiTitle', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aiMessage, style: const TextStyle(height: 1.6, color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 16),
                if (isLead) ...[
                  // 商業導購按鈕
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showToast(context, '已將專屬優惠券放入票匣！'), icon: const Icon(Icons.shopping_cart), label: const Text('用 500 點換購葡萄糖胺'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white))),
                  const SizedBox(height: 8),
                  // 名單收集 (Lead Gen) 按鈕
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _showToast(context, '已送出預約名單，專員將與您聯繫。'), icon: const Icon(Icons.calendar_month), label: const Text('預約亞東自費復健評估 (+1000 Pts)'), style: OutlinedButton.styleFrom(foregroundColor: Colors.blue.shade900, side: BorderSide(color: Colors.blue.shade900)))),
                ] else ...[
                  // 保險外溢與品牌贊助按鈕
                  SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showToast(context, '已領取保費減免憑證！'), icon: const Icon(Icons.shield), label: const Text('領取外溢保單 10% 減免憑證'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
                  const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _showToast(context, '已存入實體通路兌換券！'), icon: const Icon(Icons.card_giftcard), label: const Text('領取桂格完膳贊助兌換券'), style: OutlinedButton.styleFrom(foregroundColor: Colors.deepPurple, side: const BorderSide(color: Colors.deepPurple)))),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  Widget _buildAssetCard(BuildContext context) {
    double expProgress = appState.maxExp > 0 ? appState.currentExp / appState.maxExp : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: const Color(0xFF2E7D32).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(children: [
            const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.person, size: 36, color: Color(0xFF2E7D32))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('早安，${appState.userName}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Text(appState.level, style: const TextStyle(color: Colors.white, fontSize: 10))),
                const SizedBox(width: 8),
                Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: expProgress, backgroundColor: Colors.black26, color: Colors.amber, minHeight: 6))),
                const SizedBox(width: 8),
                Text('EXP: ${appState.currentExp}/${appState.maxExp}', style: const TextStyle(color: Colors.white70, fontSize: 10))
              ])
            ]))
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('健康積分', style: TextStyle(color: Colors.grey, fontSize: 12)), Row(children: [const Icon(Icons.monetization_on, color: Colors.amber, size: 20), const SizedBox(width: 4), Text('${appState.points}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87))])]),
              ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RewardsPage())), icon: const Icon(Icons.card_giftcard, size: 16), label: const Text('兌換'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8F5E9), foregroundColor: const Color(0xFF2E7D32), elevation: 0))
            ]),
          )
        ],
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade300)), child: Column(children: [const Icon(Icons.person_outline, size: 40, color: Colors.grey), const SizedBox(height: 8), const Text('您目前是訪客身分', style: TextStyle(fontWeight: FontWeight.bold)), ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterPage())), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white), child: const Text('立即註冊'))]));
  
  Widget _buildOnboardingCard() {
    return Container(
      padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('新手任務：健康啟航', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)), 
        const SizedBox(height: 8),
        const Row(children: [Icon(Icons.check_box, color: Colors.orange, size: 18), SizedBox(width: 8), Text('完成基本資料設定', style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey))]),
        const SizedBox(height: 4),
        const Row(children: [Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 18), SizedBox(width: 8), Text('遊玩三款鍛鍊遊戲 (大腦與體能)')]),
        const SizedBox(height: 4),
        const Row(children: [Icon(Icons.check_box_outline_blank, color: Colors.grey, size: 18), SizedBox(width: 8), Text('完成「幸福柑仔店」健康檢測')]),
        const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, elevation: 0), child: const Text('去完成 (領 100 Pts)')))
      ])
    );
  }

  Widget _buildRealRadarCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, 
            children: [
              const Text('5D 健康雷達', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                onPressed: () => showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('雷達指標說明', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('• 腦力：綜合專注、記憶、執行力遊戲表現。\n• 行動力：核心與下肢體能活動表現。\n• 活力：每日步數與日常活動達標率。\n• 防護力：早期健康檢測的防護指標狀態。\n• 恆毅力：平台任務達成率與持續毅力。', style: TextStyle(height: 1.8)),
                    actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('了解'))],
                  )
                ),
              )
            ]
          ),
          SizedBox(height: 200, width: double.infinity, child: CustomPaint(painter: RadarPainter(stats: appState.radarStats, labels: ['腦力', '行動力', '活力', '防護力', '恆毅力']))),
        ],
      ),
    );
  }

  void _showFamilyReportSheet(BuildContext context, String name, bool hasData) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [CircleAvatar(backgroundColor: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)), const SizedBox(width: 12), Text('$name 的昨日健康報告', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 16),
            
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: hasData ? Colors.blue[50] : Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.auto_awesome, color: hasData ? Colors.blue : Colors.grey, size: 20), const SizedBox(width: 8), Expanded(child: Text(hasData ? '昨日表現極佳！大腦活躍度超越多數同齡人 🌟，繼續保持喔！' : '昨日似乎在休息充飽電 🔋，記得提醒他起來動一動！', style: TextStyle(height: 1.5, color: hasData ? Colors.blue[800] : Colors.black87)))])),
            const SizedBox(height: 20),

            if (hasData) ...[
              _buildReportItem('大腦鍛鍊', '生活記憶力訓練', '85 分', '贏過同齡 82%', Colors.orange),
              _buildReportItem('體能鍛鍊', '金幣深蹲王', '15 下', '贏過同齡 75%', Colors.purple),
              _buildReportItem('檢測', '幸福柑仔店', '低風險', '維持良好', Colors.blue),
              _buildReportItem('步數', '已完成 6,500 步', '達成率 92%', '', Colors.green),
            ] else ...[
              Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox, color: Colors.grey, size: 40), SizedBox(height: 8), Text('昨日無測量紀錄', style: TextStyle(color: Colors.grey))])),
            ],
            
            const SizedBox(height: 24),
            const Text('給予關心與互動', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: hasData 
                ? [ _buildEmojiBtn(context, '👍', '你好棒', name), _buildEmojiBtn(context, '❤️', '愛你', name) ]
                : [ _buildEmojiBtn(context, '🥺', '想你囉', name), _buildEmojiBtn(context, '💪', '一起加油', name) ]
            )
          ],
        ),
      )
    );
  }

  Widget _buildReportItem(String cat, String title, String val, String sub, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 60, padding: const EdgeInsets.symmetric(vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(cat, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), if(sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildEmojiBtn(BuildContext context, String emoji, String label, String name) {
    return InkWell(
      onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已推播「$emoji $label」給 $name'))); },
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)), child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 24)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))])),
    );
  }

  Widget _buildFamilyAvatar(BuildContext context, String name, bool hasData) {
    return GestureDetector(
      onTap: () => _showFamilyReportSheet(context, name, hasData),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(radius: 30, backgroundColor: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey, size: 30)),
                Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: hasData ? Colors.green : Colors.grey, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: Icon(hasData ? Icons.thumb_up : Icons.snooze, size: 10, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 8), Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFamilyBtn(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(context: context, builder: (c) => AlertDialog(title: const Text('新增親友'), content: Column(mainAxisSize: MainAxisSize.min, children: const [TextField(decoration: InputDecoration(labelText: '稱呼 (如: 媽媽)', border: OutlineInputBorder())), SizedBox(height: 12), TextField(decoration: InputDecoration(labelText: '手機號碼', border: OutlineInputBorder()), keyboardType: TextInputType.phone)]), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')), ElevatedButton(onPressed: () { Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已發送邀請簡訊！'))); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white), child: const Text('送出邀請'))]));
      },
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 30, backgroundColor: Colors.orange[50], child: const Icon(Icons.add, color: Colors.orange)), const SizedBox(height: 8), const Text('新增', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange))]),
    );
  }

  Widget _buildPrescriptionCard(BuildContext context, String type, String title, IconData icon, Color color, VoidCallback onTap) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(type, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))])), const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey)])));
  Widget _buildArticleCard(BuildContext context, String title, String sub, String tag, String url) => InkWell(onTap: () => _launchUrl(url), child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.article_outlined, color: Colors.grey)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 4), Text(tag, style: const TextStyle(fontSize: 10, color: Colors.blueAccent))])), const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey)])));
}

class RadarPainter extends CustomPainter {
  final Map<String, double> stats;
  final List<String> labels;
  RadarPainter({required this.stats, required this.labels});
  @override
  void paint(Canvas canvas, Size size) {
    double centerX = size.width / 2; double centerY = size.height / 2; double radius = size.height / 2 * 0.8;
    Paint bgPaint = Paint()..color = Colors.grey.shade200..style = PaintingStyle.stroke..strokeWidth = 1;
    Paint fillPaint = Paint()..color = const Color(0xFF2E7D32).withOpacity(0.3)..style = PaintingStyle.fill;
    Paint linePaint = Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.stroke..strokeWidth = 2;
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int step = 1; step <= 3; step++) {
      Path path = Path(); double r = radius * (step / 3);
      for (int i = 0; i < 5; i++) {
        double angle = -pi / 2 + (2 * pi / 5) * i;
        double x = centerX + r * cos(angle); double y = centerY + r * sin(angle);
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      path.close(); canvas.drawPath(path, bgPaint);
    }
    Path dataPath = Path();
    for (int i = 0; i < 5; i++) {
      double angle = -pi / 2 + (2 * pi / 5) * i;
      double val = stats[labels[i]] ?? 0.0; if (val == 0.0) val = 0.5;
      double r = radius * val; double x = centerX + r * cos(angle); double y = centerY + r * sin(angle);
      if (i == 0) dataPath.moveTo(x, y); else dataPath.lineTo(x, y);
      double labelX = centerX + (radius + 20) * cos(angle); double labelY = centerY + (radius + 15) * sin(angle);
      textPainter.text = TextSpan(text: labels[i], style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold));
      textPainter.layout(); textPainter.paint(canvas, Offset(labelX - textPainter.width/2, labelY - textPainter.height/2));
    }
    dataPath.close();
    if (stats.values.any((v) => v > 0)) { canvas.drawPath(dataPath, fillPaint); canvas.drawPath(dataPath, linePaint); }
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ArticleListPage extends StatelessWidget {
  const ArticleListPage({super.key});
  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> articles = [
      {'title': 'AI助攻遠距安心守護心血管疾病', 'sub': '醫學研究部 吳彥雯 主任', 'url': 'https://www.femh.org.tw/magazine/viewmag.aspx?ID=11838'},
      {'title': '常常頭痛怎麼辦？我是不是得腦瘤了！', 'sub': '神經醫學部 賴資賢 主任', 'url': 'https://www.femh.org.tw/research/news_detail.aspx?NewsNo=14687&Class=1'},
      {'title': '解鎖大腦健康失智症新趨勢 健檢為您量身打造', 'sub': '神經醫學部 黃彥翔 主任', 'url': 'https://www.femh.org.tw/magazine/viewmag.aspx?ID=11889'},
      {'title': '憂鬱症不復發！醫師建議這樣做', 'sub': '精神部 潘怡如 主任', 'url': 'https://www.femh.org.tw/research/news_detail?NewsNo=11071&Class=1'},
      {'title': '嗓音照護團隊＋手機APP量身治療', 'sub': '嗓音中心 王棨德 主任', 'url': 'https://www.femh.org.tw/research/news_detail?NewsNo=6586&Class=1'},
      {'title': '重視中風後肢體痙攣 改善復健效率', 'sub': '復健科 莊博鈞 主任', 'url': 'https://www.femh.org.tw/research/news_detail?NewsNo=11398&Class=1'},
      {'title': '亞東醫院引進rTMS治療 助中風患者突破復健瓶頸', 'sub': '中風中心 唐志威 主任', 'url': 'https://www.storm.mg/article/11044790'},
      {'title': '舒緩疼痛跟我來（影音）', 'sub': '復健科 陳怡伶 組長（技術主任）', 'url': 'https://www.youtube.com/watch?v=bKFx2UNQ118'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('衛教園地')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16), itemCount: articles.length, separatorBuilder: (c, i) => const Divider(),
        itemBuilder: (c, i) => ListTile(
          leading: Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.article, color: Colors.grey)), 
          title: Text(articles[i]['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), 
          subtitle: Text(articles[i]['sub']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14), 
          onTap: () => _launchUrl(articles[i]['url']!)
        ),
      ),
    );
  }
}

// ==========================================
// 6. 權益與任務 (Rewards & Tasks)
// ==========================================
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('權益兌換中心'), bottom: const TabBar(labelColor: Color(0xFF2E7D32), indicatorColor: Color(0xFF2E7D32), tabs: [Tab(text: '點數兌換'), Tab(text: '我的票匣')])),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('目前積分', style: TextStyle(color: Colors.brown)), Text('${appState.points} Pts', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown))])),
                const SizedBox(height: 24), const Text('Happy Go 點數兌換', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
                _buildItem(context, 'Happy Go 10 點', 300), _buildItem(context, 'Happy Go 50 點', 1500), _buildItem(context, 'Happy Go 100 點', 3000),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(title: const Text('Happy Go 10 點序號', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('兌換期限：2026/12/31\n序號：HG26-ABCD-1234', style: TextStyle(height: 1.5)), trailing: ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('序號已複製！'))), child: const Text('複製')))),
              ],
            )
          ],
        ),
      ),
    );
  }
  Widget _buildItem(BuildContext context, String title, int cost) {
    bool canAfford = appState.points >= cost;
    return Card(
      margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.loyalty, color: Colors.red)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: canAfford ? Colors.black : Colors.grey)), subtitle: Text('$cost Pts', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        trailing: ElevatedButton(onPressed: canAfford ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('兌換成功！序號已存入票匣'))) : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white), child: const Text('兌換')),
      ),
    );
  }
}

class TaskCenterPage extends StatelessWidget { 
  const TaskCenterPage({super.key}); 
  @override Widget build(BuildContext context) { 
    return DefaultTabController(length: 2, child: Scaffold(appBar: AppBar(title: const Text('任務與成就'), bottom: const TabBar(labelColor: Color(0xFF2E7D32), indicatorColor: Color(0xFF2E7D32), tabs: [Tab(text: '每日任務'), Tab(text: '成就勳章')])), body: TabBarView(children: [ListView(padding: const EdgeInsets.all(16), children: [_buildTaskTile('每日簽到', true), _buildTaskTile('大腦鍛鍊：玩一場遊戲', true), _buildTaskTile('行動力：金幣深蹲王 15 下', false), _buildTaskTile('數據紀錄：輸入今日三高', false), _buildTaskTile('活力達標：步數 7000', false)]), ListView(padding: const EdgeInsets.all(16), children: [const Text('2026 年度賽季', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 16), GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, mainAxisSpacing: 16, crossAxisSpacing: 16, children: [_buildBadge('恆毅力', '連續7天', true, Colors.red), _buildBadge('深蹲王', '累計30天', false, Colors.purple), _buildBadge('知識家', '累計14天', true, Colors.blue)])])]))); 
  } 
  Widget _buildTaskTile(String title, bool isDone) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDone ? Colors.grey[100] : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null, color: isDone ? Colors.grey : Colors.black))), isDone ? const Icon(Icons.check_circle, color: Colors.green) : ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white), child: const Text('前往'))])); 
  Widget _buildBadge(String title, String sub, bool unlocked, Color color) => Column(children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(shape: BoxShape.circle, color: unlocked ? color.withOpacity(0.1) : Colors.grey[200], border: Border.all(color: unlocked ? color : Colors.grey[300]!, width: 2)), child: Icon(unlocked ? Icons.emoji_events : Icons.lock, color: unlocked ? color : Colors.grey)), const SizedBox(height: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: unlocked ? Colors.black : Colors.grey)), Text(sub, style: const TextStyle(fontSize: 10, color: Colors.grey))]); 
}

// ==========================================
// 7. 鍛鍊頁 (Train)
// ==========================================
class TrainPage extends StatelessWidget {
  const TrainPage({super.key});
  @override
  Widget build(BuildContext context) {
    bool isMVP = appState.currentPhase == ProductPhase.mvp;
    return Scaffold(
      appBar: AppBar(title: const Text('全方位鍛鍊館'), actions: const [BellIcon(), SizedBox(width: 8)]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('大腦訓練館', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8),
          _buildItem(context, '眼力極限考驗', '專注力訓練', Icons.center_focus_strong, Colors.orange, '', locked: isMVP),
          _buildItem(context, '生活記憶力訓練', '記憶力訓練', Icons.psychology, Colors.teal, 'https://chrysyehddim-pm.github.io/memory/', isExt: true, locked: isMVP),
          _buildItem(context, '超商店員特訓', '執行力(多工)訓練', Icons.extension, Colors.pink, 'https://chrysyehddim-pm.github.io/execution/', isExt: true, locked: isMVP),
          const SizedBox(height: 24), const Text('體能訓練館', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8),
          _buildItem(context, '金幣深蹲王', 'AI 鏡頭核心肌群訓練', Icons.accessibility_new, Colors.purple, 'https://chrysyehddim-pm.github.io/Squat-Game-PoC/', isExt: true, locked: isMVP),
          const SizedBox(height: 24), const Text('知識挑戰館', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8),
          _buildItem(context, '腦中風防衛戰', '俄羅斯方塊衛教遊戲', Icons.grid_view_rounded, Colors.indigo, 'https://jay331.github.io/games/', isExt: true, locked: false),
        ],
      ),
    );
  }
  Widget _buildItem(BuildContext context, String title, String sub, IconData icon, Color color, String url, {bool isExt = false, bool locked = false}) => Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: locked ? Colors.grey[200] : color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: locked ? Colors.grey : color)), title: Text(title, style: TextStyle(color: locked ? Colors.grey : Colors.black, fontWeight: FontWeight.bold)), subtitle: Text(sub, style: TextStyle(color: locked ? Colors.grey : Colors.grey[600], fontSize: 12)), trailing: locked ? const Chip(label: Text('Coming Soon', style: TextStyle(fontSize: 10))) : ElevatedButton(onPressed: () => _launchUrl(url), style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, elevation: 0), child: const Text('開始'))));
}

// ==========================================
// 8. 檢測頁 (Check)
// ==========================================
class CheckPage extends StatelessWidget { 
  const CheckPage({super.key}); 
  @override 
  Widget build(BuildContext context) { 
    return Scaffold(
      appBar: AppBar(title: const Text('自我探索檢測'), actions: const [BellIcon(), SizedBox(width: 8)]), 
      body: ListView(
        padding: const EdgeInsets.all(16), 
        children: [
          const Text('自我探索 (防護力)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8),
          _buildItem(context, '幸福柑仔店 - 一日店長冒險', 'AD8 極早期失智篩檢\n上次檢測：2025/08/15 (建議重新檢測)', 'https://chrysyehddim-pm.github.io/ad8test/', Colors.blue, Icons.storefront), 
          _buildItem(context, '黃金咖啡大師 - 穩定度特訓', '挑戰手部穩定，完美拉花不手抖', '', Colors.brown, Icons.coffee, isNew: true), 
          const SizedBox(height: 24), const Text('醫學研究計畫', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8),
          Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(leading: const Icon(Icons.assignment, color: Colors.teal, size: 30), title: const Text('醫師研究計畫：心律數據收集', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: const Text('填寫問卷貢獻醫療研究', style: TextStyle(color: Colors.teal)), trailing: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white), child: const Text('參加'))))
        ]
      )
    ); 
  } 
  Widget _buildItem(BuildContext context, String title, String sub, String url, Color color, IconData icon, {bool isNew = false}) => Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(contentPadding: const EdgeInsets.all(12), leading: Stack(alignment: Alignment.topRight, children: [Icon(icon, color: color, size: 40), if(isNew) Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.fiber_new, size: 10, color: Colors.white))]), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.5)), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () => _launchUrl(url))); 
}

// ==========================================
// 9. 趨勢數據頁 (Data)
// ==========================================
class DataPage extends StatefulWidget { const DataPage({super.key}); @override State<DataPage> createState() => _DataPageState(); }
class _DataPageState extends State<DataPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isSync = false;
  int _chartIndex = 0; 

  final _formKey = GlobalKey<FormState>();
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _hrCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _stepCtrl = TextEditingController();

  @override void initState() { 
    super.initState(); 
    _tabController = TabController(length: 2, vsync: this); 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!appState.hasSetVitals) _showInitVitalsDialog();
    });
  }

  void _showInitVitalsDialog() {
    final hCtrl = TextEditingController(); final wCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('初次設定：計算您的 BMI', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: hCtrl, decoration: const InputDecoration(labelText: '身高 (cm)'), keyboardType: TextInputType.number, validator: (v) { int? val = int.tryParse(v??''); if(val==null||val<100||val>250) return '限 100~250'; return null; }),
              const SizedBox(height: 12),
              TextFormField(controller: wCtrl, decoration: const InputDecoration(labelText: '體重 (kg)'), keyboardType: TextInputType.number, validator: (v) { int? val = int.tryParse(v??''); if(val==null||val<20||val>300) return '限 20~300'; return null; }),
            ],
          ),
        ),
        actions: [ElevatedButton(onPressed: () { if(formKey.currentState!.validate()) { appState.hasSetVitals = true; Navigator.pop(c); } }, child: const Text('完成設定'))],
      )
    );
  }

  void _toggleSync(bool val) {
    if (val) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('授權存取健康資料'),
          content: const Text('Happy Health 想要存取您的健康資料（步數、心跳、血壓）以進行 AI 趨勢分析。我們承諾嚴格保護您的隱私。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('拒絕')),
            ElevatedButton(
              onPressed: () { 
                Navigator.pop(c); 
                setState(() { isSync = true; _sysCtrl.text = '120'; _diaCtrl.text = '80'; _hrCtrl.text = '72'; _sugarCtrl.text = '95'; _stepCtrl.text = '6500'; });
              }, 
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white), child: const Text('同意授權')
            )
          ],
        )
      );
    } else {
      setState(() { isSync = false; _sysCtrl.clear(); _diaCtrl.clear(); _hrCtrl.clear(); _sugarCtrl.clear(); _stepCtrl.clear(); });
    }
  }

  @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: const Text('健康趨勢'), actions: const [BellIcon(), SizedBox(width: 8)], bottom: TabBar(controller: _tabController, labelColor: const Color(0xFF2E7D32), indicatorColor: const Color(0xFF2E7D32), tabs: const [Tab(text: '生理趨勢'), Tab(text: '腦健康趨勢')])), body: TabBarView(controller: _tabController, children: [_buildHealthTab(), _buildBrainTab()])); }
  
  Widget _buildHealthTab() { 
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16), 
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('今日量測', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Row(children: [const Text('手動', style: TextStyle(fontSize: 12)), Switch(value: isSync, onChanged: _toggleSync, activeColor: const Color(0xFF2E7D32)), const Text('裝置同步', style: TextStyle(fontSize: 12))])]),
          const SizedBox(height: 8),
          
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('血壓與心跳', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 12),
            Row(children: [Expanded(child: _buildInput('收縮壓', _sysCtrl, 70, 250)), const SizedBox(width: 8), Expanded(child: _buildInput('舒張壓', _diaCtrl, 40, 150)), const SizedBox(width: 8), Expanded(child: _buildInput('心跳', _hrCtrl, 40, 200))]),
            const SizedBox(height: 16), const Text('血糖', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 12),
            _buildInput('飯前血糖 (mg/dL)', _sugarCtrl, 50, 500),
          ])),
          
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('活力指標', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 12),
            _buildInput('今日步數', _stepCtrl, 0, 100000),
          ])),

          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: isSync ? null : () { if(_formKey.currentState!.validate()) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('紀錄成功'))); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white), child: const Text('儲存今日紀錄'))),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const HistoryDataPage())), icon: const Icon(Icons.history), label: const Text('查看完整歷史紀錄 (近3個月)')),
          const SizedBox(height: 24),
          
          const Text('近 10 次趨勢分析', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('血壓'), selected: _chartIndex==0, onSelected: (v)=>setState(()=>_chartIndex=0)),
              ChoiceChip(label: const Text('血糖'), selected: _chartIndex==1, onSelected: (v)=>setState(()=>_chartIndex=1)),
              ChoiceChip(label: const Text('心跳'), selected: _chartIndex==2, onSelected: (v)=>setState(()=>_chartIndex=2)),
              ChoiceChip(label: const Text('步數'), selected: _chartIndex==3, onSelected: (v)=>setState(()=>_chartIndex=3)),
            ],
          ),
          const SizedBox(height: 12),
          if (_chartIndex == 0) _buildTrendChart('血壓波動', [0.6, 0.7, 0.65, 0.8, 0.7, 0.6, 0.5, 0.6, 0.7, 0.6], Colors.red),
          if (_chartIndex == 1) _buildTrendChart('血糖趨勢', [0.5, 0.5, 0.55, 0.6, 0.5, 0.45, 0.5, 0.5, 0.5, 0.5], Colors.orange),
          if (_chartIndex == 2) _buildTrendChart('心跳趨勢', [0.7, 0.7, 0.75, 0.7, 0.6, 0.65, 0.7, 0.7, 0.75, 0.7], Colors.pink),
          if (_chartIndex == 3) _buildTrendChart('步數達成率', [0.8, 0.9, 0.4, 0.8, 1.0, 0.7, 0.8, 0.9, 0.8, 1.0], Colors.green),
        ]
      ),
    ); 
  }

  Widget _buildInput(String label, TextEditingController ctrl, int min, int max) {
    return TextFormField(
      controller: ctrl, enabled: !isSync, keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
      validator: (v) {
        if (v == null || v.isEmpty) return null; 
        int? val = int.tryParse(v);
        if (val == null || val < min || val > max) return '限 $min~$max';
        return null;
      },
    );
  }
  
  Widget _buildBrainTab() { 
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('各維度近 10 次分數', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildTrendChart('眼力極限 (專注力)', [0.4, 0.5, 0.6, 0.5, 0.7, 0.8, 0.8, 0.9, 0.85, 0.9], Colors.orange),
        const SizedBox(height: 16),
        _buildTrendChart('生活記憶 (記憶力)', [0.3, 0.3, 0.4, 0.4, 0.5, 0.4, 0.6, 0.5, 0.7, 0.6], Colors.teal),
        const SizedBox(height: 16),
        _buildTrendChart('超商店員 (執行力)', [0.6, 0.6, 0.5, 0.7, 0.6, 0.8, 0.7, 0.8, 0.9, 0.8], Colors.pink),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.auto_awesome, color: Colors.blue), SizedBox(width: 8), Expanded(child: Text('AI 評估：您的專注力與執行力穩定上升！記憶力區塊進步較緩慢，AI 已為您在首頁安排對應的加強任務。', style: TextStyle(color: Colors.blue, height: 1.5)))])),
      ],
    ); 
  }

  Widget _buildTrendChart(String title, List<double> values, Color color) {
    return Container(
      height: 120, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.end,
              children: values.map((v) => Container(width: 12, height: 80 * v, decoration: BoxDecoration(color: color.withOpacity(0.6), borderRadius: BorderRadius.circular(4)))).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryDataPage extends StatelessWidget {
  const HistoryDataPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('歷史紀錄 (近 100 筆)')),
      body: ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) {
          int day = index + 1;
          return ListTile(
            leading: const Icon(Icons.date_range, color: Colors.grey),
            title: Text('2026/02/${(28 - (index % 28)).toString().padLeft(2, '0')}'),
            subtitle: const Text('血壓: 120/80  |  心跳: 72  |  步數: 6500'),
          );
        },
      ),
    );
  }
}

// ==========================================
// 10. 會員中心 (Profile) 及下一層頁面
// ==========================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('會員中心'), actions: const [BellIcon(), SizedBox(width: 8)]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(leading: const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)), title: Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), subtitle: Text(appState.level)),
          const SizedBox(height: 24),
          
          const Text('帳號與設定', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          Card(margin: const EdgeInsets.only(top: 8, bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: Column(children: [
            _buildRouteItem(context, Icons.manage_accounts, '個人資料維護', const ProfileEditPage()), const Divider(height: 1), 
            _buildRouteItem(context, Icons.verified_user, '隱私權與授權設定', const PrivacySettingsPage()), const Divider(height: 1), 
            _buildRouteItem(context, Icons.policy, '服務政策與須知', const PolicyPage())
          ])),
          
          if (appState.currentPhase == ProductPhase.vision) ...[
            const Text('社交功能', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
            Card(margin: const EdgeInsets.only(top: 8, bottom: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: _buildRouteItem(context, Icons.family_restroom, '家人群組管理', const FamilyManagePage())),
          ],

          const Text('歷史紀錄中心', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          Card(margin: const EdgeInsets.only(top: 8, bottom: 24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: Column(children: [
            _buildRouteItem(context, Icons.history, '歷史紀錄總覽', const ProfileHistoryPage())
          ])),

          const Divider(),
          ListTile(leading: const Icon(Icons.headset_mic), title: const Text('客服中心'), trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CustomerServicePage()))),
          ListTile(leading: const Icon(Icons.logout, color: Colors.orange), title: const Text('登出帳號', style: TextStyle(color: Colors.orange)), onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()))),
          ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text('停用或刪除帳號', style: TextStyle(color: Colors.red)), onTap: () => _showDeleteDialog(context)),
          const SizedBox(height: 40), 
        ],
      ),
    );
  }
  
  Widget _buildRouteItem(BuildContext context, IconData icon, String title, Widget page) { 
    return ListTile(leading: Icon(icon, color: Colors.grey[700]), title: Text(title, style: const TextStyle(fontSize: 14)), trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => page))); 
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 8), Text('危險操作', style: TextStyle(color: Colors.red))]),
        content: const Text('您確定要刪除帳號嗎？此動作將清除所有健康數據與積分，且無法復原。請輸入密碼以確認。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')),
          ElevatedButton(onPressed: () { Navigator.pop(c); Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('確認刪除'))
        ],
      )
    );
  }
}

// 子頁面：個人資料維護
class ProfileEditPage extends StatefulWidget { const ProfileEditPage({super.key}); @override State<ProfileEditPage> createState() => _ProfileEditPageState(); }
class _ProfileEditPageState extends State<ProfileEditPage> {
  final _nickCtrl = TextEditingController(text: 'Chrys');
  final _nameCtrl = TextEditingController(text: '葉XX');
  final _phoneCtrl = TextEditingController(text: '0912345678');
  final _genderCtrl = TextEditingController(text: '男');
  final _birthCtrl = TextEditingController(text: '1989/01/01');

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('個人資料維護'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('儲存'))]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: Stack(children: [const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)), Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 14, backgroundColor: Colors.blue, child: const Icon(Icons.camera_alt, size: 14, color: Colors.white)))])),
          const SizedBox(height: 24),
          TextField(controller: _nickCtrl, decoration: const InputDecoration(labelText: '暱稱 (可修改)', border: OutlineInputBorder())), const SizedBox(height: 16),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '姓名', border: OutlineInputBorder(), filled: true, fillColor: Colors.black12), enabled: false), const SizedBox(height: 16),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: '手機號碼', border: OutlineInputBorder(), filled: true, fillColor: Colors.black12), enabled: false), const SizedBox(height: 16),
          TextField(controller: _genderCtrl, decoration: const InputDecoration(labelText: '性別', border: OutlineInputBorder(), filled: true, fillColor: Colors.black12), enabled: false), const SizedBox(height: 16),
          TextField(controller: _birthCtrl, decoration: const InputDecoration(labelText: '生日', border: OutlineInputBorder(), filled: true, fillColor: Colors.black12), enabled: false), const SizedBox(height: 24),
          Card(child: ListTile(leading: const Icon(Icons.loyalty, color: Colors.red), title: const Text('Happy Go 帳號已綁定'), trailing: OutlinedButton(onPressed: (){}, child: const Text('解除綁定'))))
        ],
      )
    );
  }
}

// 子頁面：隱私權與授權設定
class PrivacySettingsPage extends StatefulWidget { const PrivacySettingsPage({super.key}); @override State<PrivacySettingsPage> createState() => _PrivacySettingsPageState(); }
class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool push = true; bool health = true; bool camera = true; bool faceId = false;
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('隱私權與授權設定')),
      body: ListView(
        children: [
          SwitchListTile(title: const Text('接收推播通知'), value: push, onChanged: (v)=>setState(()=>push=v)),
          SwitchListTile(title: const Text('健康裝置數據連動'), subtitle: const Text('Apple Health / Google Fit'), value: health, onChanged: (v)=>setState(()=>health=v)),
          SwitchListTile(title: const Text('相機權限'), subtitle: const Text('用於金幣深蹲王等體感任務'), value: camera, onChanged: (v)=>setState(()=>camera=v)),
          SwitchListTile(title: const Text('生物辨識登入 (FaceID/指紋)'), value: faceId, onChanged: (v)=>setState(()=>faceId=v)),
        ],
      ),
    );
  }
}

// 子頁面：服務政策與須知
class PolicyPage extends StatelessWidget {
  const PolicyPage({super.key});
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('服務政策與須知')),
      body: ListView(
        children: [
          ListTile(title: const Text('隱私權保護政策'), trailing: const Icon(Icons.open_in_new, size: 16), onTap: (){}),
          ListTile(title: const Text('服務條款 (Terms of Service)'), trailing: const Icon(Icons.open_in_new, size: 16), onTap: (){}),
          ListTile(title: const Text('醫療數據授權同意書'), trailing: const Icon(Icons.open_in_new, size: 16), onTap: (){}),
        ],
      )
    );
  }
}

// 子頁面：家人群組管理
class FamilyManagePage extends StatelessWidget {
  const FamilyManagePage({super.key});
  @override Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('家人群組管理'), bottom: const TabBar(labelColor: Color(0xFF2E7D32), indicatorColor: Color(0xFF2E7D32), tabs: [Tab(text: '我邀請的親友'), Tab(text: '邀請我的親友')])),
        body: TabBarView(
          children: [
            ListView(children: [ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: const Text('爸爸'), subtitle: const Text('0987***321'), trailing: OutlinedButton(onPressed: (){}, child: const Text('解除綁定'))), ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: const Text('媽媽'), subtitle: const Text('0912***456'), trailing: OutlinedButton(onPressed: (){}, child: const Text('解除綁定')))]),
            ListView(children: [ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: const Text('大兒子'), subtitle: const Text('0955***789'), trailing: OutlinedButton(onPressed: (){}, child: const Text('封鎖/移除')))]),
          ],
        ),
      ),
    );
  }
}

// 子頁面：歷史紀錄中心
class ProfileHistoryPage extends StatelessWidget {
  const ProfileHistoryPage({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(title: const Text('歷史紀錄中心'), bottom: const TabBar(isScrollable: true, labelColor: Color(0xFF2E7D32), indicatorColor: Color(0xFF2E7D32), tabs: [Tab(text: '兌換紀錄'), Tab(text: '任務紀錄'), Tab(text: '檢測紀錄'), Tab(text: '健康與遊戲紀錄')])),
        body: Column(
          children: [
            Container(width: double.infinity, padding: const EdgeInsets.all(8), color: Colors.orange[50], child: const Text('💡 僅保留近 3 個月內，最多 100 筆資料', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.orange))),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(children: const [ListTile(title: Text('換取 Happy Go 10 點'), subtitle: Text('2026/02/20'), trailing: Text('-300 Pts', style: TextStyle(color: Colors.red)))]),
                  ListView(children: const [ListTile(title: Text('完成：金幣深蹲王'), subtitle: Text('2026/02/22'), trailing: Text('+20 Pts', style: TextStyle(color: Colors.green)))]),
                  ListView(children: const [ListTile(title: Text('幸福柑仔店 - 低風險'), subtitle: Text('2025/08/15'))]),
                  ListView(children: const [ListTile(title: Text('生活記憶力訓練'), subtitle: Text('2026/02/22'), trailing: Text('85 分')), ListTile(title: Text('步數達成'), subtitle: Text('2026/02/22'), trailing: Text('6500 步'))]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 子頁面：客服中心工單系統
class CustomerServicePage extends StatelessWidget {
  const CustomerServicePage({super.key});
  @override Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('客服中心'), bottom: const TabBar(labelColor: Color(0xFF2E7D32), indicatorColor: Color(0xFF2E7D32), tabs: [Tab(text: '提交問題'), Tab(text: '我的紀錄')])),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: '問題類型', border: OutlineInputBorder()), items: const [DropdownMenuItem(value: '1', child: Text('帳號問題')), DropdownMenuItem(value: '2', child: Text('檢測與數據異常')), DropdownMenuItem(value: '3', child: Text('點數兌換問題')), DropdownMenuItem(value: '4', child: Text('其他建議'))], onChanged: (v){}),
                const SizedBox(height: 16),
                const TextField(maxLines: 5, decoration: InputDecoration(hintText: '請描述您的問題...', border: OutlineInputBorder())),
                const SizedBox(height: 16),
                OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.add_photo_alternate), label: const Text('選擇圖片 (0/3，每張限 5MB)')),
                const SizedBox(height: 24),
                SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('問題已送出！客服將盡快回覆。'))), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white), child: const Text('送出問題')))
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(child: ListTile(title: const Text('點數兌換失敗未收到序號'), subtitle: const Text('2026/02/20'), trailing: const Chip(label: Text('處理中'), backgroundColor: Colors.amberAccent))),
                Card(child: ListTile(title: const Text('如何綁定家人帳號？'), subtitle: const Text('2026/01/15'), trailing: const Chip(label: Text('已回覆'), backgroundColor: Colors.lightGreenAccent))),
              ],
            )
          ],
        ),
      ),
    );
  }
}