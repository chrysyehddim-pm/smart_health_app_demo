import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ==========================================
// 1. 全域狀態管理 (AppState)
// ==========================================
enum UserIdentity { guest, newPhoneUser, hgBoundUser }
enum AiScenario { mobilityDecline, vitalsWarning, perfectConsistency } 

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  UserIdentity currentIdentity = UserIdentity.guest; 
  AiScenario currentScenario = AiScenario.perfectConsistency; 
  double textScale = 1.0; 
  bool hasSetupHealthData = false; 
  bool hasFamilyGroup = false; 

  String userName = '訪客';
  int healthPoints = 0;
  int waterDrops = 0; 
  String title = '尚未註冊'; 
  Map<String, double> radar3D = {'腦動力': 0.0, '行動力': 0.0, '防護力': 0.0};
  int streakDays = 0; 

  void toggleTextScale() { textScale = textScale == 1.0 ? 1.25 : 1.0; notifyListeners(); }
  void completeHealthSetup() { hasSetupHealthData = true; notifyListeners(); }
  void toggleFamilyGroup(bool hasGroup) { hasFamilyGroup = hasGroup; notifyListeners(); }
  
  void switchScenario(AiScenario scenario) { 
    currentScenario = scenario; 
    switch(scenario) {
      case AiScenario.mobilityDecline: radar3D = {'腦動力': 0.8, '行動力': 0.3, '防護力': 0.8}; break;
      case AiScenario.vitalsWarning: radar3D = {'腦動力': 0.7, '行動力': 0.7, '防護力': 0.2}; break;
      case AiScenario.perfectConsistency: radar3D = {'腦動力': 0.95, '行動力': 0.9, '防護力': 0.95}; break;
    }
    notifyListeners(); 
  }

  void switchIdentity(UserIdentity identity) {
    currentIdentity = identity;
    switch (identity) {
      case UserIdentity.guest:
        userName = '訪客'; healthPoints = 0; waterDrops = 0; streakDays = 0; title = '尚未註冊'; radar3D = {'腦動力': 0.1, '行動力': 0.1, '防護力': 0.1}; hasFamilyGroup = false;
        break;
      case UserIdentity.newPhoneUser:
        userName = '王小明'; healthPoints = 50; waterDrops = 100; streakDays = 1; title = '健康探險家'; radar3D = {'腦動力': 0.4, '行動力': 0.4, '防護力': 0.4}; hasFamilyGroup = false;
        break;
      case UserIdentity.hgBoundUser:
        userName = 'Chrys'; healthPoints = 12500; waterDrops = 6500; streakDays = 3; title = '健康探險家'; hasFamilyGroup = true;
        switchScenario(AiScenario.perfectConsistency); 
        break;
    }
    notifyListeners();
  }

  void completeTask(int pts, int drops) { healthPoints += pts; waterDrops += drops; notifyListeners(); }
}

final appState = AppState();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DevicePreview(enabled: true, builder: (context) => const HappyHealthApp()));
}

Future<void> _launchUrl(String url) async {
  if (url.isEmpty) return;
  if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) debugPrint('Could not launch $url');
}

// 色彩定義
const Color primaryEmerald = Color(0xFF10B981);
const Color darkTeal = Color(0xFF0F766E);
const Color hgPurple = Color(0xFF673AB7); 
const Color bgGray = Color(0xFFF9FAFB);

class HappyHealthApp extends StatelessWidget {
  const HappyHealthApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, child) => MaterialApp(
        title: 'Happy Health V3.1',
        debugShowCheckedModeBanner: false,
        useInheritedMediaQuery: true, locale: DevicePreview.locale(context),
        builder: (context, widget) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(appState.textScale)), child: DevicePreview.appBuilder(context, widget!)),
        theme: ThemeData(
          useMaterial3: true, scaffoldBackgroundColor: bgGray,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0, centerTitle: true, titleTextStyle: TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.bold), iconTheme: IconThemeData(color: Color(0xFF1F2937))),
          colorScheme: ColorScheme.fromSeed(seedColor: primaryEmerald, primary: primaryEmerald, secondary: darkTeal, background: bgGray),
          textTheme: GoogleFonts.notoSansTcTextTheme(),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}

// ==========================================
// 📍 登入與註冊流程 (完整版)
// ==========================================
class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState() => _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> {
  int _viewState = 0; 
  void _simulateHgLogin() async {
    setState(() => _viewState = 1);
    await Future.delayed(const Duration(seconds: 2)); 
    if (!mounted) return;
    appState.switchIdentity(UserIdentity.hgBoundUser);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigator()));
  }
  void _finishPhoneFlow(bool isRegister) {
    appState.switchIdentity(UserIdentity.newPhoneUser);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigator()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _viewState > 0 && _viewState != 1 ? AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _viewState = 0))) : null,
      body: SafeArea(child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: _buildCurrentView())),
    );
  }

  Widget _buildCurrentView() {
    if (_viewState == 1) return _buildLoadingView();
    if (_viewState == 2) return _buildPhoneLoginView();
    if (_viewState == 3) return _buildPhoneRegisterView();
    return _buildMainMenuView();
  }

  Widget _buildLoadingView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: hgPurple), const SizedBox(height: 24), const Text('跳轉 HAPPY GO 授權中...', style: TextStyle(color: hgPurple, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8), Text('安全登入，同步您的健康紀錄', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))]));

  Widget _buildMainMenuView() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Container(width: 80, height: 80, decoration: BoxDecoration(color: primaryEmerald.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.favorite_rounded, color: primaryEmerald, size: 40)),
        const SizedBox(height: 24),
        const Text('Happy Health\n智慧健康服務', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2, color: Color(0xFF1F2937))), const SizedBox(height: 12),
        const Text('每天三分鐘，玩出健康新生活\n雙軌積分機制，全家一起種出快樂花園。', style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
        const Spacer(),
        ElevatedButton(onPressed: _simulateHgLogin, style: ElevatedButton.styleFrom(backgroundColor: hgPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.flash_on, size: 20), SizedBox(width: 8), Text('HAPPY GO 授權登入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))])),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: () => setState(() => _viewState = 2), icon: const Icon(Icons.phone_android, size: 20), label: const Text('手機號碼登入'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100], foregroundColor: const Color(0xFF1F2937), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('還沒有帳號？', style: TextStyle(color: Colors.grey)), TextButton(onPressed: () => setState(() => _viewState = 3), child: const Text('全新註冊', style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold)))]),
        TextButton(onPressed: () { appState.switchIdentity(UserIdentity.guest); Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigator())); }, child: const Text('先逛逛，稍後再註冊', style: TextStyle(color: Colors.grey, fontSize: 12))),
      ],
    ),
  );

  Widget _buildPhoneLoginView() => Padding(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [const Text('手機號碼登入', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('請輸入您的手機與密碼', style: TextStyle(color: Colors.grey)), const SizedBox(height: 32), const TextField(decoration: InputDecoration(labelText: '手機號碼', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())), const SizedBox(height: 16), const TextField(obscureText: true, decoration: InputDecoration(labelText: '密碼', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())), const SizedBox(height: 24), ElevatedButton(onPressed: () => _finishPhoneFlow(false), style: ElevatedButton.styleFrom(backgroundColor: primaryEmerald, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('登入'))]));
  Widget _buildPhoneRegisterView() => ListView(padding: const EdgeInsets.all(24.0), children: [const Text('建立專屬健康帳號', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('我們需要一些基本資料來提供精準的健康建議', style: TextStyle(color: Colors.grey)), const SizedBox(height: 32), const TextField(decoration: InputDecoration(labelText: '真實姓名', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())), const SizedBox(height: 16), const TextField(decoration: InputDecoration(labelText: '生日 (YYYY/MM/DD)', prefixIcon: Icon(Icons.cake), border: OutlineInputBorder())), const SizedBox(height: 16), const TextField(decoration: InputDecoration(labelText: '手機號碼', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())), const SizedBox(height: 16), Row(children: [const Expanded(child: TextField(decoration: InputDecoration(labelText: '輸入 OTP 驗證碼', border: OutlineInputBorder()))), const SizedBox(width: 12), OutlinedButton(onPressed: (){}, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('發送簡訊'))]), const SizedBox(height: 32), ElevatedButton(onPressed: () => _finishPhoneFlow(true), style: ElevatedButton.styleFrom(backgroundColor: primaryEmerald, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('同意條款並註冊'))]);
}

// ==========================================
// 📍 展示控制台 (God Mode)
// ==========================================
class GodModeFab extends StatelessWidget {
  const GodModeFab({super.key});
  @override
  Widget build(BuildContext context) => Positioned(left: 16, bottom: 16, child: FloatingActionButton.small(heroTag: 'god_mode', backgroundColor: const Color(0xFF1F2937), foregroundColor: Colors.amber, onPressed: () => _showConsole(context), child: const Icon(Icons.tune)));

  void _showConsole(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚡️ 商業展示控制台', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 24),
            const Text('1. 家族花園狀態', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8),
            Row(children: [Expanded(child: _buildOptBtn(context, '無家族 (單人)', () => appState.toggleFamilyGroup(false), !appState.hasFamilyGroup)), const SizedBox(width: 8), Expanded(child: _buildOptBtn(context, '家族共建中', () => appState.toggleFamilyGroup(true), appState.hasFamilyGroup))]), const SizedBox(height: 24),
            const Text('2. 動態 AI 推薦場景 (連動雷達)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8),
            Column(children: [_buildAiBtn(context, '情境 A：行動力衰退 (導購)', AiScenario.mobilityDecline, appState.currentScenario == AiScenario.mobilityDecline, Colors.orange), const SizedBox(height: 8), _buildAiBtn(context, '情境 B：防護力異常 (名單)', AiScenario.vitalsWarning, appState.currentScenario == AiScenario.vitalsWarning, Colors.redAccent), const SizedBox(height: 8), _buildAiBtn(context, '情境 C：連續滿分 (外溢保單)', AiScenario.perfectConsistency, appState.currentScenario == AiScenario.perfectConsistency, primaryEmerald)]),
            const SizedBox(height: 16), const Divider(),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.format_size, color: darkTeal), title: const Text('樂齡大字模式', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)), trailing: Switch(value: appState.textScale > 1.0, activeColor: primaryEmerald, onChanged: (v) { appState.toggleTextScale(); Navigator.pop(context); })),
            const SizedBox(height: 16), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2937), foregroundColor: Colors.white), child: const Text('關閉')))
          ],
        ),
      ),
    );
  }
  Widget _buildOptBtn(BuildContext context, String label, VoidCallback onTap, bool isSel) => ElevatedButton(onPressed: () { onTap(); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? darkTeal : Colors.grey[100], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0), child: Text(label, style: const TextStyle(fontSize: 12)));
  Widget _buildAiBtn(BuildContext context, String label, AiScenario scenario, bool isSel, Color color) => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { appState.switchScenario(scenario); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? color : Colors.grey[50], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0, alignment: Alignment.centerLeft, side: BorderSide(color: isSel ? Colors.transparent : Colors.grey.shade300)), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));
}

// ==========================================
// 📍 主結構導覽 (5 Tabs)
// ==========================================
class MainNavigator extends StatefulWidget { const MainNavigator({super.key}); @override State<MainNavigator> createState() => _MainNavigatorState(); }
class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [const HomeGardenPage(), const TaskCenterPage(), const DashboardPage(), const RewardsPage(), const ProfilePage()];
    return Scaffold(
      body: Stack(children: [pages[_currentIndex], const GodModeFab()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex, onDestinationSelected: (i) => setState(() => _currentIndex = i), 
        backgroundColor: Colors.white, indicatorColor: primaryEmerald.withOpacity(0.2), elevation: 10, shadowColor: Colors.black12,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.park_outlined), selectedIcon: Icon(Icons.park, color: darkTeal), label: '庭院'), 
          NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports, color: darkTeal), label: '任務'), 
          NavigationDestination(icon: Icon(Icons.radar_outlined), selectedIcon: Icon(Icons.radar, color: darkTeal), label: '數據'), 
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: darkTeal), label: '票匣'), 
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: darkTeal), label: '我的')
        ]
      ),
    );
  }
}

// ==========================================
// 📍 Tab 1: 共育大廳 (Home - 流量與變現樞紐)
// ==========================================
class HomeGardenPage extends StatelessWidget {
  const HomeGardenPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (appState.currentIdentity == UserIdentity.guest) return _buildGuestBlocker(context, '註冊解鎖您的專屬庭院', Icons.park);

    return Scaffold(
      appBar: AppBar(title: Text(appState.hasFamilyGroup ? '林家專屬花園' : '我的個人花園', style: const TextStyle(color: darkTeal, fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        children: [
          // 家族共建視覺
          const GardenVisual(),
          const SizedBox(height: 16),
          // 家族動態跑馬燈
          if (appState.hasFamilyGroup)
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)), child: const Row(children: [Icon(Icons.notifications_active, color: Colors.orange, size: 16), SizedBox(width: 8), Expanded(child: Text('爸爸剛完成了專注力挑戰，為花園注入 20 滴水💧', style: TextStyle(fontSize: 12, color: Color(0xFF4B5563))))]))
          else
            InkWell(onTap: () => _showInviteFlowDialog(context), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)), child: const Row(children: [Icon(Icons.person_add, color: Colors.amber, size: 20), SizedBox(width: 8), Expanded(child: Text('邀請家人加入，解鎖 1.2 倍生長加速與週末寶箱！', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E))))]))),
          
          const SizedBox(height: 24),
          const Text('AI 專屬健康提案', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          _buildAiAgentCard(context),
        ],
      ),
    );
  }

  void _showInviteFlowDialog(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))), builder: (c) => Padding(padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: primaryEmerald, size: 64), const SizedBox(height: 16), const Text('家族專屬花園已建立！', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('趕快把邀請連結傳給家人，讓他們加入你的花園！', style: TextStyle(color: Colors.grey)), const SizedBox(height: 32), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.link, color: Colors.grey), const SizedBox(width: 12), const Expanded(child: Text('https://happyhealth.app/join/林家888', style: TextStyle(color: darkTeal, fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.copy, color: primaryEmerald), onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 網址已複製到剪貼簿'))); })])), const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(c); appState.toggleFamilyGroup(true); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2937), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('完成，進入共育花園！')))])));
  }

  Widget _buildAiAgentCard(BuildContext context) {
    String aiTitle, aiMsg, btn1Txt, btn2Txt; IconData btn1Icon, btn2Icon; Color themeColor;
    switch(appState.currentScenario) {
      case AiScenario.mobilityDecline: themeColor = Colors.orange; aiTitle = "行動力守護計畫"; aiMsg = "AI 園丁偵測到您近期『行動力』下降。為保護您的關節，大樹藥局特別贊助您一份【葡萄糖胺 50 元折價券】！"; btn1Txt = "領取大樹折價券"; btn1Icon = Icons.shopping_cart; btn2Txt = "預約自費復健評估"; btn2Icon = Icons.calendar_month; break;
      case AiScenario.vitalsWarning: themeColor = Colors.redAccent; aiTitle = "防護力預警通知"; aiMsg = "您近期的防護力數值出現異常波動。建議進一步了解【亞東醫院高階腦部 MRI 健檢專案】，及早發現及早預防。"; btn1Txt = "了解高階健檢專案"; btn1Icon = Icons.medical_services; btn2Txt = "聯繫客服專員"; btn2Icon = Icons.headset_mic; break;
      case AiScenario.perfectConsistency: themeColor = primaryEmerald; aiTitle = "極致健康解鎖"; aiMsg = "太棒了！您已【連續 30 天達標】！\nAI 已為您解鎖：【南山人壽外溢保單】首年保費減免 10%，及桂格專屬禮物！"; btn1Txt = "領取保單減免憑證"; btn1Icon = Icons.shield; btn2Txt = "領取桂格贊助兌換券"; btn2Icon = Icons.card_giftcard; break;
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: themeColor.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: themeColor.withOpacity(0.05), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.auto_awesome, color: themeColor, size: 24)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(aiTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: themeColor)), const SizedBox(height: 4), Text(aiMsg, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.5))]))])),
        Container(padding: const EdgeInsets.all(20), child: Column(children: [SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已存入票匣！'))), icon: Icon(btn1Icon, size: 18), label: Text(btn1Txt), style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('申請已送出！'))), icon: Icon(btn2Icon, size: 18), label: Text(btn2Txt), style: OutlinedButton.styleFrom(foregroundColor: themeColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: themeColor.withOpacity(0.5)))))]))
      ]),
    );
  }
}

// 🌸 科技擬物花園元件
class GardenVisual extends StatefulWidget { const GardenVisual({super.key}); @override State<GardenVisual> createState() => _GardenVisualState(); }
class _GardenVisualState extends State<GardenVisual> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _breathAnimation;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true); _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)); }
  @override void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    int drops = appState.waterDrops;
    String emoji = drops < 3000 ? '🌱' : (drops < 8000 ? '🌿' : '🌻');
    Color glowColor = drops < 3000 ? Colors.grey : (drops < 8000 ? primaryEmerald : Colors.amber);

    return Container(
      height: 320, decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFFE0F2FE), Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 20, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Text('🏆 本週目標：黃金向日葵綻放', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 13)))),
          Positioned(bottom: 40, child: Container(width: 200, height: 60, decoration: BoxDecoration(shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(100), gradient: LinearGradient(colors: [Colors.grey.shade200, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter), boxShadow: [BoxShadow(color: glowColor.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)]))),
          Positioned(bottom: 60, child: AnimatedBuilder(animation: _breathAnimation, builder: (context, child) => Transform.scale(scale: _breathAnimation.value, child: Text(emoji, style: TextStyle(fontSize: 120, shadows: [Shadow(color: glowColor.withOpacity(0.5), blurRadius: 20)]))))),
          
          // 家族貢獻者懸浮頭像
          if (appState.hasFamilyGroup) ...[
            Positioned(bottom: 150, left: 40, child: _buildContributorAvatar('爸爸', '45%', Colors.blue)),
            Positioned(bottom: 100, right: 30, child: _buildContributorAvatar('大兒子', '30%', Colors.teal)),
          ],

          Positioned(bottom: 50, right: 30, child: InkWell(onTap: () => _showSponsorDialog(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100, width: 2), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(children: [const Icon(Icons.chair_alt, size: 32, color: Colors.blue), const SizedBox(height: 4), Text('IKEA 贊助', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade700))])))),
          Positioned(bottom: -1, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.water_drop, color: Colors.blue, size: 20), const SizedBox(width: 8), Text('${appState.waterDrops} / 10,000 滴', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkTeal))]))),
        ],
      ),
    );
  }

  Widget _buildContributorAvatar(String name, String percent, Color color) {
    return Column(children: [
      CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.2), child: Icon(Icons.person, color: color, size: 20)),
      const SizedBox(height: 4),
      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(8)), child: Text('$name $percent', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)))
    ]);
  }

  void _showSponsorDialog(BuildContext context) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (c) => Container(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.chair_alt, size: 60, color: Colors.blue), const SizedBox(height: 16), const Text('IKEA 贊助林家花園', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('恭喜獲得 IKEA 實體門市滿千折百券！', style: TextStyle(color: Colors.grey)), const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 折價券已存入您的權益票匣！'))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('立即領取存入票匣')))])));
  }
}

// ==========================================
// 📍 Tab 2: 任務中心 (Tasks)
// ==========================================
class TaskCenterPage extends StatelessWidget {
  const TaskCenterPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (appState.currentIdentity == UserIdentity.guest) return _buildGuestBlocker(context, '註冊會員開始賺點數', Icons.sports_esports);

    return Scaffold(
      appBar: AppBar(title: const Text('動能任務大廳')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('連續簽到領寶箱', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (index) { bool isPast = index < appState.streakDays; bool isToday = index == appState.streakDays; return Column(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: isPast ? primaryEmerald : (isToday ? Colors.amber : Colors.grey.shade100), shape: BoxShape.circle, border: isToday ? Border.all(color: Colors.amber.shade700, width: 2) : null), child: Icon(index == 6 ? Icons.card_giftcard : Icons.check, color: (isPast || isToday) ? Colors.white : Colors.grey.shade300, size: 20)), const SizedBox(height: 8), Text('D${index+1}', style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? Colors.amber.shade700 : Colors.grey))]); })), const SizedBox(height: 16), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { appState.completeTask(100, 100); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('簽到成功！獲得 100 點 + 100 滴水'))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white, elevation: 0), child: const Text('領取今日簽到獎勵', style: TextStyle(fontWeight: FontWeight.bold))))])),
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100]), borderRadius: BorderRadius.circular(16)), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.directions_walk, color: Colors.blue)), const SizedBox(width: 16), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('今日步數自動同步：6,050 步', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)), Text('點擊轉換為花園養分', style: TextStyle(fontSize: 12, color: Colors.blue))])), ElevatedButton(onPressed: () { appState.completeTask(50, 300); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('轉換成功！獲得 50 點 + 300 滴水'))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, elevation: 0), child: const Text('轉換'))])),
          const SizedBox(height: 24),
          const Text('主動遊戲大挑戰', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          _buildHtmlStyleTaskCard(context, '生活好時光', '短期記憶防護', '桂格完膳 贊助', Icons.psychology, Colors.teal, 10, 10, 'https://memory-game-ad.vercel.app/'),
          _buildHtmlStyleTaskCard(context, '一日超商店長', '多工處理大挑戰', '全家便利商店 贊助', Icons.store, Colors.orange, 15, 15, 'https://execution-ad.vercel.app/'),
          _buildHtmlStyleTaskCard(context, '眼力極限考驗', '專注力大挑戰', '白蘭氏 葉黃素 贊助', Icons.remove_red_eye, Colors.blue, 10, 10, 'https://concentration-ad.vercel.app/'),
          _buildHtmlStyleTaskCard(context, '金幣深蹲王', '跟著鏡頭動一動', '挺立 / World Gym', Icons.accessibility_new, Colors.purple, 20, 50, 'https://squat-game-ad.vercel.app/'),
        ],
      ),
    );
  }

  Widget _buildHtmlStyleTaskCard(BuildContext context, String title, String sub, String sponsor, IconData icon, MaterialColor color, int pts, int drops, String url) {
    return GestureDetector(
      onTap: () { appState.completeTask(pts, drops); _launchUrl(url); },
      child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.shade50, border: Border.all(color: color.shade100), borderRadius: BorderRadius.circular(4)), child: Text('贊助 | $sponsor', style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.bold))), const SizedBox(height: 10), Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color.shade500)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))), const SizedBox(height: 2), Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey))])), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Row(children: [Icon(Icons.monetization_on, size: 12, color: Colors.amber.shade700), const SizedBox(width: 2), Text('+$pts', style: TextStyle(color: Colors.amber.shade700, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(width: 6), const Icon(Icons.water_drop, size: 12, color: Colors.blue), const SizedBox(width: 2), Text('+$drops', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))]), const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: darkTeal, borderRadius: BorderRadius.circular(12)), child: const Text('去挑戰', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))])])])),
    );
  }
}

// ==========================================
// 📍 Tab 3: 數據中心 (Dashboard - 雷達與親友關懷)
// ==========================================
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (appState.currentIdentity == UserIdentity.guest) return _buildGuestBlocker(context, '註冊會員查看專屬數據', Icons.radar);

    return Scaffold(
      appBar: AppBar(title: const Text('全家健康與數據中心')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [const Text('個人綜合健康防護網', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 20), SizedBox(width: 200, height: 200, child: CustomPaint(painter: TriangleRadarPainter(stats: appState.radar3D)))])),
          const SizedBox(height: 16),
          // 生理數據入口
          Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.monitor_heart, color: Colors.blue.shade600)), title: const Text('生理數據歷史趨勢', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), subtitle: const Text('血壓、心跳、BMI及紀錄', style: TextStyle(fontSize: 12, color: Colors.grey)), trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthDataPage())))),
          const SizedBox(height: 32),
          
          const Text('家人健康日報與關懷', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          if (appState.hasFamilyGroup) ...[
            _buildFamilyReportCard(context, '爸爸', '警示', '連續三天未登入任務', Colors.red, true),
            _buildFamilyReportCard(context, '大兒子', '活躍', '昨日步數: 12,000 步', Colors.teal, false),
          ] else 
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text('尚未加入家族，無親友數據', style: TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }

  Widget _buildFamilyReportCard(BuildContext context, String name, String state, String sub, MaterialColor color, bool showWarning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: showWarning ? Colors.red.shade200 : Colors.grey.shade200)),
      child: Column(children: [
        Row(children: [
          CircleAvatar(backgroundColor: color.shade50, child: Icon(Icons.person, color: color.shade600)), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(4)), child: Text(state, style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.bold)))]), const SizedBox(height: 4), Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))])),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: () => _showGiftDialog(context, name), icon: const Icon(Icons.card_giftcard, size: 16), label: const Text('贈送點數'), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFF59E0B), side: const BorderSide(color: Color(0xFFF59E0B))))),
          if (showWarning) ...[const SizedBox(width: 8), Expanded(child: ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已透過 Line 發送關懷訊息'))), icon: const Icon(Icons.favorite, size: 16), label: const Text('一鍵關心'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0)))],
        ])
      ]),
    );
  }

  void _showGiftDialog(BuildContext context, String name) {
    showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: Colors.white, title: Text('轉贈給 $name'), content: const TextField(decoration: InputDecoration(labelText: '輸入轉贈點數', suffixText: 'Pts', border: OutlineInputBorder()), keyboardType: TextInputType.number), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消', style: TextStyle(color: Colors.grey))), ElevatedButton(onPressed: () { Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功轉贈給 $name！'))); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white), child: const Text('確認轉贈'))]));
  }
}

// ==========================================
// 📍 Tab 4: 權益票匣 (Rewards)
// ==========================================
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (appState.currentIdentity == UserIdentity.guest) return _buildGuestBlocker(context, '註冊會員開始兌換獎品', Icons.account_balance_wallet);
    return DefaultTabController(length: 2, child: Scaffold(appBar: AppBar(title: const Text('權益票匣'), bottom: const TabBar(labelColor: darkTeal, indicatorColor: darkTeal, tabs: [Tab(text: '兌換中心'), Tab(text: '我的票匣')])), body: TabBarView(children: [ListView(padding: const EdgeInsets.all(20), children: [Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('可用健康點 (私有)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))), Text('${appState.healthPoints} Pts', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber))])), const SizedBox(height: 24), const Text('點數兌換', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12), _buildExchangeItem(context, 'HAPPY GO 10 點', 300), _buildExchangeItem(context, '全家 Let\'s Café 中杯拿鐵', 1500)]), ListView(padding: const EdgeInsets.all(20), children: [const Text('AI 專屬推薦與贊助', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)), const SizedBox(height: 12), Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)), child: ListTile(contentPadding: const EdgeInsets.all(16), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medication, color: Colors.orange)), title: const Text('大樹藥局 葡萄糖胺 \$50 折價券', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('期限：本月底'), trailing: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, elevation: 0), child: const Text('使用'))))])])));
  }
  Widget _buildExchangeItem(BuildContext context, String title, int cost) {
    bool canAfford = appState.healthPoints >= cost;
    return Container(margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))), subtitle: Text('$cost Pts', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)), trailing: ElevatedButton(onPressed: canAfford ? () {} : null, style: ElevatedButton.styleFrom(backgroundColor: darkTeal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('兌換'))));
  }
}

// ==========================================
// 📍 Tab 5: 會員中心 (Profile) 
// ==========================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    bool isBound = appState.currentIdentity == UserIdentity.hgBoundUser;
    return Scaffold(
      appBar: AppBar(title: const Text('會員中心')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [const CircleAvatar(radius: 36, backgroundColor: Colors.white, child: Icon(Icons.account_circle, size: 72, color: Colors.grey)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1F2937))), const SizedBox(height: 4), Text('目前身分：${appState.title}', style: const TextStyle(color: Colors.grey, fontSize: 13))]))])),
          const SizedBox(height: 24),
          if (appState.currentIdentity != UserIdentity.guest) ...[Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DummyPage(title: '成就勳章牆', icon: Icons.military_tech))), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFB300)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: const Row(children: [Icon(Icons.military_tech, color: Colors.white, size: 36), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('我的成就勳章牆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text('已收集 3 / 15 面勳章', style: TextStyle(color: Colors.white70, fontSize: 12))])), Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)])))), const SizedBox(height: 24)],
          if (!isBound && appState.currentIdentity != UserIdentity.guest) ...[Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.link, color: Colors.amber), SizedBox(width: 8), Text('尚未綁定 HAPPY GO 帳號', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)))]), const SizedBox(height: 8), const Text('綁定後即可同步您的健康積分！', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: hgPurple, foregroundColor: Colors.white, elevation: 0), child: const Text('立即綁定 (HG SSO)')))]))), const SizedBox(height: 24)],
          
          _buildSectionTitle('我的數據與軌跡'),
          Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [_buildListTile(context, Icons.fact_check_outlined, '歷史任務與測驗紀錄', '您完成的互動任務軌跡', const HistoryPage()), _buildListTile(context, Icons.monetization_on_outlined, '健康點數累兌明細', '點數獲得與兌換紀錄', const PointsHistoryPage())])),
          
          _buildSectionTitle('帳號與安全'),
          Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [_buildListTile(context, Icons.manage_accounts_outlined, '個人資料設定', '修改手機等資訊', const ProfileSettingsPage()), _buildListTile(context, Icons.security_outlined, '隱私與數據授權', '管理您的個人化推薦', const PrivacySettingsPage()), _buildListTile(context, Icons.link, '家族邀請連結', '管理分享網址', const DummyPage(title: '家族連結管理', icon: Icons.link))])),
          
          _buildSectionTitle('關於本服務'),
          Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [_buildListTile(context, Icons.description_outlined, '服務條款與政策須知', null, const DummyPage(title: '服務條款', icon: Icons.gavel)), _buildListTile(context, Icons.help_outline, '常見問題與客服中心', null, const DummyPage(title: '客服中心', icon: Icons.headset_mic))])),

          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: OutlinedButton(onPressed: () { appState.switchIdentity(UserIdentity.guest); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); }, style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('登出帳號', style: TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)));
  Widget _buildListTile(BuildContext context, IconData icon, String title, String? sub, Widget targetPage) => Column(children: [ListTile(leading: Icon(icon, color: darkTeal), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)), subtitle: sub != null ? Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null, trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage))), const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF3F4F6))]);
}

// 附屬資料頁 (Health Data, History, Settings, etc.)
class HealthDataPage extends StatelessWidget {
  const HealthDataPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('健康趨勢與生理紀錄')), body: ListView(padding: const EdgeInsets.all(20), children: [const Text('本週活動量', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildDataStat('👣 平均步數', '8,432', '步'), _buildDataStat('🔥 消耗熱量', '320', 'kcal')])), const SizedBox(height: 24), const Text('生理數據紀錄', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12), _buildDataCard('血壓', '118 / 75', 'mmHg', '正常', Colors.blue), _buildDataCard('靜止心率', '72', 'bpm', '正常', Colors.redAccent), _buildDataCard('BMI', '23.4', '', '標準', primaryEmerald), const SizedBox(height: 24), const Text('過去三個月紀錄 (最多顯示 100 筆)', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 8), Container(height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: const Center(child: Text('📊 折線圖表區塊 (開發中)', style: TextStyle(color: Colors.grey))))]));
  Widget _buildDataStat(String title, String val, String unit) => Column(children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 8), Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkTeal)), const SizedBox(width: 4), Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey))])]);
  Widget _buildDataCard(String title, String val, String unit, String status, Color color) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))), Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))), const SizedBox(width: 4), Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(width: 16), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)))]));
}
class HistoryPage extends StatelessWidget { const HistoryPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('歷史任務與測驗紀錄')), body: ListView(children: const [ListTile(leading: Icon(Icons.sports_esports, color: Colors.blue), title: Text('眼力極限考驗'), subtitle: Text('2026-03-04 14:30'), trailing: Text('PR 85', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))), Divider(height: 1), ListTile(leading: Icon(Icons.accessibility_new, color: Colors.purple), title: Text('金幣深蹲王'), subtitle: Text('2026-03-03 09:15'), trailing: Text('20 下', style: TextStyle(fontWeight: FontWeight.bold)))])); }
class PointsHistoryPage extends StatelessWidget { const PointsHistoryPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('點數累兌明細')), body: ListView(children: const [ListTile(leading: Icon(Icons.add_circle, color: Colors.green), title: Text('完成眼力極限任務'), subtitle: Text('2026-03-04 14:30'), trailing: Text('+10 Pts', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))), Divider(height: 1), ListTile(leading: Icon(Icons.remove_circle, color: Colors.orange), title: Text('兌換大樹藥局折價券'), subtitle: Text('2026-03-02 10:00'), trailing: Text('-500 Pts', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)))])); }
class ProfileSettingsPage extends StatelessWidget { const ProfileSettingsPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('個人資料設定')), body: ListView(padding: const EdgeInsets.all(20), children: [const TextField(decoration: InputDecoration(labelText: '真實姓名', border: OutlineInputBorder())), const SizedBox(height: 16), const TextField(decoration: InputDecoration(labelText: '手機號碼', border: OutlineInputBorder())), const SizedBox(height: 16), const TextField(decoration: InputDecoration(labelText: '通訊地址', border: OutlineInputBorder())), const SizedBox(height: 24), ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: primaryEmerald, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('儲存修改'))])); }
class PrivacySettingsPage extends StatelessWidget { const PrivacySettingsPage({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('隱私與數據授權')), body: ListView(padding: const EdgeInsets.all(20), children: [SwitchListTile(title: const Text('允許行銷推薦'), subtitle: const Text('同意系統根據您的健康標籤推薦專屬優惠'), value: true, onChanged: (v){}, activeColor: primaryEmerald), const Divider(), SwitchListTile(title: const Text('步數與活動資料同步'), subtitle: const Text('允許存取 Apple Health / Google Fit'), value: appState.hasSetupHealthData, onChanged: (v){}, activeColor: primaryEmerald)])); }
class DummyPage extends StatelessWidget { final String title; final IconData icon; const DummyPage({super.key, required this.title, required this.icon}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('$title 內容建置中...', style: const TextStyle(color: Colors.grey))]))); }
Widget _buildGuestBlocker(BuildContext context, String msg, IconData icon) => Scaffold(appBar: AppBar(title: const Text('尚未解鎖')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 16)), const SizedBox(height: 16), ElevatedButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, elevation: 0), child: const Text('立即註冊 / 登入'))])));

// 🔺 雷達圖
class TriangleRadarPainter extends CustomPainter {
  final Map<String, double> stats; TriangleRadarPainter({required this.stats});
  @override void paint(Canvas canvas, Size size) {
    double cx = size.width / 2; double cy = size.height / 2 + 10; double r = size.width / 2 * 0.8;
    Paint bgPaint = Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 1; Paint fillPaint = Paint()..color = primaryEmerald.withOpacity(0.2)..style = PaintingStyle.fill; Paint linePaint = Paint()..color = primaryEmerald..style = PaintingStyle.stroke..strokeWidth = 2;
    TextPainter tp = TextPainter(textDirection: TextDirection.ltr); List<String> labels = ['腦動力', '行動力', '防護力']; List<double> angles = [-pi/2, pi/6, 5*pi/6]; 
    for (int step = 1; step <= 3; step++) { Path path = Path(); double currentR = r * (step / 3); for (int i = 0; i < 3; i++) { double x = cx + currentR * cos(angles[i]); double y = cy + currentR * sin(angles[i]); if (i == 0) path.moveTo(x, y); else path.lineTo(x, y); } path.close(); canvas.drawPath(path, bgPaint); }
    Path dataPath = Path();
    for (int i = 0; i < 3; i++) { double val = stats[labels[i]] ?? 0.1; double x = cx + (r * val) * cos(angles[i]); double y = cy + (r * val) * sin(angles[i]); if (i == 0) dataPath.moveTo(x, y); else dataPath.lineTo(x, y); double lx = cx + (r + 15) * cos(angles[i]); double ly = cy + (r + 15) * sin(angles[i]); tp.text = TextSpan(text: labels[i], style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)); tp.layout(); tp.paint(canvas, Offset(lx - tp.width/2, ly - tp.height/2)); }
    dataPath.close(); canvas.drawPath(dataPath, fillPaint); canvas.drawPath(dataPath, linePaint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}