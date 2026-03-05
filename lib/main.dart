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
  bool hasSetupHealthData = false; // 控制是否顯示初次健康設定

  String userName = '訪客';
  int healthPoints = 0;
  String title = '尚未註冊'; 
  Map<String, double> radar3D = {'腦動力': 0.0, '行動力': 0.0, '防護力': 0.0};

  void toggleTextScale() { textScale = textScale == 1.0 ? 1.25 : 1.0; notifyListeners(); }
  void completeHealthSetup() { hasSetupHealthData = true; notifyListeners(); }
  
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
        userName = '訪客'; healthPoints = 0; title = '尚未註冊'; radar3D = {'腦動力': 0.1, '行動力': 0.1, '防護力': 0.1}; hasSetupHealthData = false;
        break;
      case UserIdentity.newPhoneUser:
        userName = '王小明'; healthPoints = 50; title = '健康探險家'; radar3D = {'腦動力': 0.4, '行動力': 0.4, '防護力': 0.4}; hasSetupHealthData = false;
        break;
      case UserIdentity.hgBoundUser:
        userName = 'Chrys'; healthPoints = 12500; title = '健康探險家'; hasSetupHealthData = true;
        switchScenario(AiScenario.perfectConsistency); 
        break;
    }
    notifyListeners();
  }
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
const Color hgPurple = Color(0xFF673AB7); // HAPPY GO 紫色
const Color bgGray = Color(0xFFF9FAFB);

class HappyHealthApp extends StatelessWidget {
  const HappyHealthApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, child) {
        return MaterialApp(
          title: 'Happy Health',
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
        );
      },
    );
  }
}

// ==========================================
// 📍 登入與註冊流程 (Login & Registration Flow)
// ==========================================
class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState() => _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> {
  int _viewState = 0; // 0: Main Menu, 1: Loading, 2: Phone Login, 3: Phone Register

  void _simulateHgLogin() async {
    setState(() => _viewState = 1);
    await Future.delayed(const Duration(seconds: 2)); // 模擬跳轉授權
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
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentView(),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_viewState == 1) return _buildLoadingView();
    if (_viewState == 2) return _buildPhoneLoginView();
    if (_viewState == 3) return _buildPhoneRegisterView();
    return _buildMainMenuView();
  }

  Widget _buildLoadingView() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(color: hgPurple), const SizedBox(height: 24), const Text('跳轉 HAPPY GO 授權中...', style: TextStyle(color: hgPurple, fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8), Text('安全登入，同步您的健康紀錄', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))]));

  Widget _buildMainMenuView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Container(width: 80, height: 80, decoration: BoxDecoration(color: primaryEmerald.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.favorite_rounded, color: primaryEmerald, size: 40)),
          const SizedBox(height: 24),
          const Text('Happy Health\n智慧健康服務', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2, color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          const Text('每天三分鐘，玩出健康新生活\n授權登入，累積您的專屬健康資產。', style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
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
  }

  Widget _buildPhoneLoginView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('手機號碼登入', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('請輸入您的手機與密碼', style: TextStyle(color: Colors.grey)), const SizedBox(height: 32),
        const TextField(decoration: InputDecoration(labelText: '手機號碼', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())), const SizedBox(height: 16),
        const TextField(obscureText: true, decoration: InputDecoration(labelText: '密碼', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())), const SizedBox(height: 24),
        ElevatedButton(onPressed: () => _finishPhoneFlow(false), style: ElevatedButton.styleFrom(backgroundColor: primaryEmerald, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('登入')),
      ]),
    );
  }

  Widget _buildPhoneRegisterView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text('建立專屬健康帳號', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('我們需要一些基本資料來提供精準的健康建議', style: TextStyle(color: Colors.grey)), const SizedBox(height: 32),
        const TextField(decoration: InputDecoration(labelText: '真實姓名', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())), const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: '生日 (YYYY/MM/DD)', prefixIcon: Icon(Icons.cake), border: OutlineInputBorder())), const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: '手機號碼', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder())), const SizedBox(height: 16),
        Row(children: [Expanded(child: const TextField(decoration: InputDecoration(labelText: '輸入 OTP 驗證碼', border: OutlineInputBorder()))), const SizedBox(width: 12), OutlinedButton(onPressed: (){}, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('發送簡訊'))]), const SizedBox(height: 32),
        ElevatedButton(onPressed: () => _finishPhoneFlow(true), style: ElevatedButton.styleFrom(backgroundColor: primaryEmerald, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('同意條款並註冊')),
      ],
    );
  }
}

// ==========================================
// 📍 展示控制台 (God Mode)
// ==========================================
class GodModeFab extends StatelessWidget {
  const GodModeFab({super.key});
  @override
  Widget build(BuildContext context) {
    return Positioned(left: 16, bottom: 16, child: FloatingActionButton.small(heroTag: 'god_mode', backgroundColor: const Color(0xFF1F2937), foregroundColor: Colors.amber, onPressed: () => _showConsole(context), child: const Icon(Icons.tune)));
  }

  void _showConsole(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚡️ 商業展示控制台', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 24),
            const Text('1. 身分切換', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _buildOptBtn(context, '訪客', UserIdentity.guest, appState.currentIdentity == UserIdentity.guest),
              _buildOptBtn(context, '純手機新戶', UserIdentity.newPhoneUser, appState.currentIdentity == UserIdentity.newPhoneUser),
              _buildOptBtn(context, 'HG 老客', UserIdentity.hgBoundUser, appState.currentIdentity == UserIdentity.hgBoundUser),
            ]),
            const SizedBox(height: 24),
            const Text('2. 動態 AI 推薦場景', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8),
            Column(children: [
              _buildAiBtn(context, '情境 A：行動力衰退 (導購)', AiScenario.mobilityDecline, appState.currentScenario == AiScenario.mobilityDecline, Colors.orange), const SizedBox(height: 8),
              _buildAiBtn(context, '情境 B：防護力異常 (名單)', AiScenario.vitalsWarning, appState.currentScenario == AiScenario.vitalsWarning, Colors.redAccent), const SizedBox(height: 8),
              _buildAiBtn(context, '情境 C：連續滿分 (外溢保單)', AiScenario.perfectConsistency, appState.currentScenario == AiScenario.perfectConsistency, primaryEmerald),
            ]),
            const SizedBox(height: 16), const Divider(),
            ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.format_size, color: darkTeal), title: const Text('樂齡大字模式', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)), trailing: Switch(value: appState.textScale > 1.0, activeColor: primaryEmerald, onChanged: (v) { appState.toggleTextScale(); Navigator.pop(context); })),
            const SizedBox(height: 16), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2937), foregroundColor: Colors.white), child: const Text('關閉')))
          ],
        ),
      ),
    );
  }

  Widget _buildOptBtn(BuildContext context, String label, UserIdentity identity, bool isSel) => ElevatedButton(onPressed: () { appState.switchIdentity(identity); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? darkTeal : Colors.grey[100], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0), child: Text(label, style: const TextStyle(fontSize: 12)));
  Widget _buildAiBtn(BuildContext context, String label, AiScenario scenario, bool isSel, Color color) => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { appState.switchScenario(scenario); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? color : Colors.grey[50], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0, alignment: Alignment.centerLeft, side: BorderSide(color: isSel ? Colors.transparent : Colors.grey.shade300)), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));
}

// ==========================================
// 📍 主結構導覽
// ==========================================
class MainNavigator extends StatefulWidget { const MainNavigator({super.key}); @override State<MainNavigator> createState() => _MainNavigatorState(); }
class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [const HomePage(), const FamilyPage(), const PlayPage(), const RewardsPage(), const ProfilePage()];
    return Scaffold(
      body: Stack(children: [pages[_currentIndex], const GodModeFab()]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex, onDestinationSelected: (i) => setState(() => _currentIndex = i), 
        backgroundColor: Colors.white, indicatorColor: primaryEmerald.withOpacity(0.2), elevation: 10, shadowColor: Colors.black12,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: darkTeal), label: '大廳'), 
          NavigationDestination(icon: Icon(Icons.family_restroom_outlined), selectedIcon: Icon(Icons.family_restroom, color: darkTeal), label: '親友'), 
          NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports, color: darkTeal), label: '任務'), 
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: darkTeal), label: '票匣'), 
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: darkTeal), label: '我的')
        ]
      ),
    );
  }
}

// ==========================================
// 📍 Tab 1: 首頁大廳 (Home)
// ==========================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    bool isGuest = appState.currentIdentity == UserIdentity.guest;
    return Scaffold(
      appBar: AppBar(title: const Text('Happy Health', style: TextStyle(color: darkTeal, fontWeight: FontWeight.w900, letterSpacing: 0.5)), actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DummyPage(title: '通知中心', icon: Icons.notifications))))]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        children: [
          _buildHeroStatusCard(context), const SizedBox(height: 24),
          if (!isGuest) ...[
            _buildRadarAndAiCard(context), const SizedBox(height: 24),
            const Text('健康趨勢與紀錄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))), const SizedBox(height: 12),
            _buildTrendCard(context),
          ],
          if (isGuest) _buildGuestPrompt(context),
          const SizedBox(height: 32),
          const Row(children: [Icon(Icons.local_hospital, color: Colors.blue), SizedBox(width: 8), Text('亞東醫院 衛教專區', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)))]), const SizedBox(height: 12),
          _buildArticleCard('解鎖大腦健康失智症新趨勢', '神經醫學部 黃彥翔 主任', 'https://www.femh.org.tw/magazine/viewmag.aspx?ID=11889'),
          _buildArticleCard('常常頭痛怎麼辦？', '神經醫學部 賴資賢 主任', 'https://www.femh.org.tw/research/news_detail.aspx?NewsNo=14687&Class=1'),
        ],
      ),
    );
  }

  Widget _buildHeroStatusCard(BuildContext context) {
    bool isBound = appState.currentIdentity == UserIdentity.hgBoundUser;
    return Container(
      padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [primaryEmerald, darkTeal], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: primaryEmerald.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('早安，${appState.userName} ☀️', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 6),
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text('🏅 稱號：${appState.title}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              if (isBound) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: hgPurple, borderRadius: BorderRadius.circular(12)), child: const Text('HG 已綁定', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))]
            ]),
          ]),
          const CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
        ]),
        const SizedBox(height: 24), const Text('我的健康點 (Pts)', style: TextStyle(color: Colors.white70, fontSize: 12)),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text('${appState.healthPoints}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)), const SizedBox(width: 4), const Text('點', style: TextStyle(color: Colors.white70, fontSize: 14))]),
      ]),
    );
  }

  Widget _buildRadarAndAiCard(BuildContext context) {
    String aiTitle, aiMsg, btn1Txt, btn2Txt; IconData btn1Icon, btn2Icon; Color themeColor;
    switch(appState.currentScenario) {
      case AiScenario.mobilityDecline: themeColor = Colors.orange; aiTitle = "健康守護提案"; aiMsg = "觀察到您近期『行動力』指標有下降趨勢。為保護關節，為您爭取到【大樹藥局葡萄糖胺】優惠，及自費復健評估專案。"; btn1Txt = "用 500 點換購葡萄糖胺"; btn1Icon = Icons.shopping_cart; btn2Txt = "預約亞東自費復健"; btn2Icon = Icons.calendar_month; break;
      case AiScenario.vitalsWarning: themeColor = Colors.redAccent; aiTitle = "防護力異常警示"; aiMsg = "您近期的防護力數值出現異常波動。建議進一步了解【亞東醫院高階腦部 MRI 健檢專案】，及早發現及早預防。"; btn1Txt = "了解高階健檢專案"; btn1Icon = Icons.medical_services; btn2Txt = "重新進行檢測"; btn2Icon = Icons.refresh; break;
      case AiScenario.perfectConsistency: themeColor = primaryEmerald; aiTitle = "極致健康解鎖"; aiMsg = "太棒了！您已【連續 30 天達標】，三大健康力超越 95% 用戶！\nAI 已解鎖：【南山人壽外溢保單】首年保費減免 10%，及專屬禮物！"; btn1Txt = "領取保單 10% 減免憑證"; btn1Icon = Icons.shield; btn2Txt = "領取桂格贊助兌換券"; btn2Icon = Icons.card_giftcard; break;
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: bgGray, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), child: Row(children: [SizedBox(width: 110, height: 110, child: CustomPaint(painter: TriangleRadarPainter(stats: appState.radar3D))), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('個人健康雷達', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))), const SizedBox(height: 10), _buildRadarStatBar('🧠 腦動力', appState.radar3D['腦動力']!, Colors.amber.shade500), _buildRadarStatBar('🏃‍♂️ 行動力', appState.radar3D['行動力']!, Colors.blue.shade400), _buildRadarStatBar('🛡️ 防護力', appState.radar3D['防護力']!, primaryEmerald)]))])),
        Container(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.auto_awesome, color: themeColor, size: 16)), const SizedBox(width: 8), Text('AI 專屬管家：$aiTitle', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold))]), const SizedBox(height: 12), Text(aiMsg, style: const TextStyle(height: 1.6, color: Color(0xFF4B5563), fontSize: 13)), const SizedBox(height: 16), SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () {}, icon: Icon(btn1Icon, size: 18), label: Text(btn1Txt), style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))), const SizedBox(height: 8), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: Icon(btn2Icon, size: 18), label: Text(btn2Txt), style: OutlinedButton.styleFrom(foregroundColor: themeColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: themeColor.withOpacity(0.5)))))])),
      ]),
    );
  }

  Widget _buildRadarStatBar(String label, double val, Color color) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [SizedBox(width: 65, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.w500))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: val, backgroundColor: Colors.grey.shade200, color: color, minHeight: 6)))]));

  Widget _buildTrendCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.monitor_heart, color: Colors.blue.shade600)),
        title: const Text('生理數據與歷史趨勢', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), subtitle: const Text('血壓、心跳、BMI及檢測紀錄', style: TextStyle(fontSize: 12, color: Colors.grey)), trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {
          if (!appState.hasSetupHealthData) { _showHealthSetupDialog(context); } 
          else { Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthDataPage())); }
        },
      ),
    );
  }

  void _showHealthSetupDialog(BuildContext context) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white, title: const Text('初次健康設定', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('為了提供更精準的數據追蹤，請輸入基本資料並授權步數同步。', style: TextStyle(fontSize: 13, color: Colors.grey)), const SizedBox(height: 16),
          const Row(children: [Expanded(child: TextField(decoration: InputDecoration(labelText: '身高 (cm)', border: OutlineInputBorder()), keyboardType: TextInputType.number)), SizedBox(width: 12), Expanded(child: TextField(decoration: InputDecoration(labelText: '體重 (kg)', border: OutlineInputBorder()), keyboardType: TextInputType.number))]),
          const SizedBox(height: 16), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: const Row(children: [Icon(Icons.directions_walk, color: Colors.blue), SizedBox(width: 8), Expanded(child: Text('允許同步 Apple Health / Google Fit 步數資料', style: TextStyle(fontSize: 12)))])),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('稍後再說', style: TextStyle(color: Colors.grey))), ElevatedButton(onPressed: () { appState.completeHealthSetup(); Navigator.pop(c); Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthDataPage())); }, style: ElevatedButton.styleFrom(backgroundColor: primaryEmerald, foregroundColor: Colors.white), child: const Text('儲存並授權'))],
      )
    );
  }

  Widget _buildGuestPrompt(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade200)), child: Column(children: [const Icon(Icons.lock_person, size: 40, color: Colors.amber), const SizedBox(height: 12), const Text('您目前為訪客體驗模式', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontSize: 16)), const SizedBox(height: 8), const Text('註冊即可解鎖專屬健康雷達、趨勢追蹤，\n並開始累積健康點數！', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF78350F), height: 1.5)), const SizedBox(height: 16), ElevatedButton(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, elevation: 0), child: const Text('立即註冊 / 登入'))]));
  Widget _buildArticleCard(String title, String sub, String url) => InkWell(onTap: () => _launchUrl(url), child: Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(contentPadding: const EdgeInsets.all(12), leading: Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.article, color: Colors.blue)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)), trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey))));
}

// ==========================================
// 📍 Tab 2: 親友圈 (Family)
// ==========================================
class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (appState.currentIdentity == UserIdentity.guest) return _buildGuestBlocker(context, '註冊會員解鎖家人群組', Icons.family_restroom);

    return Scaffold(
      appBar: AppBar(title: const Text('健康守護圈 - 家人互聯')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade100)), child: const Row(children: [Icon(Icons.volunteer_activism, color: Colors.orange), SizedBox(width: 12), Expanded(child: Text('邀請家人加入，互相查看每日健康進度，還能互贈點數、分享專屬健康獎勵！', style: TextStyle(color: Color(0xFF92400E), fontSize: 13, height: 1.5)))])),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 邀請連結已複製到剪貼簿！請貼上至 Line 傳送給家人。'))), 
            icon: const Icon(Icons.share), label: const Text('產生家庭邀請連結 (Line/簡訊)'), style: OutlinedButton.styleFrom(foregroundColor: darkTeal, side: const BorderSide(color: darkTeal), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
          ),
          const SizedBox(height: 32),
          const Text('我的家人列表', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          _buildFamilyMemberCard(context, '爸爸', '昨日步數: 6,500', '長輩', Colors.blue),
          _buildFamilyMemberCard(context, '媽媽', '昨日完成: 專注力挑戰', '長輩', Colors.pink),
          _buildFamilyMemberCard(context, '大兒子', '昨日步數: 12,000', '晚輩', Colors.teal),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberCard(BuildContext context, String name, String status, String tag, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: color.shade50, child: Icon(Icons.person, color: color.shade600)),
        title: Row(children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)), child: Text(tag, style: const TextStyle(fontSize: 10, color: Colors.black54)))]), 
        subtitle: Text(status, style: const TextStyle(color: primaryEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FamilyMemberDetailScreen(name: name, tag: tag))),
      ),
    );
  }
}

// 家人詳細資料頁
class FamilyMemberDetailScreen extends StatelessWidget {
  final String name; final String tag;
  const FamilyMemberDetailScreen({super.key, required this.name, required this.tag});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$name 的健康日報')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: Column(children: [const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.account_circle, size: 80, color: Colors.grey)), const SizedBox(height: 12), Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text('身分：$tag', style: const TextStyle(color: Colors.grey))])),
          const SizedBox(height: 32),
          const Text('昨日健康報告', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [_buildReportRow('步數達成', '6,500 步', Icons.directions_walk, Colors.blue), const Divider(height: 24), _buildReportRow('完成遊戲', '專注力大挑戰 (95分)', Icons.sports_esports, Colors.orange), const Divider(height: 24), _buildReportRow('獲得點數', '+30 Pts', Icons.monetization_on, Colors.amber)])),
          const SizedBox(height: 32),
          ElevatedButton.icon(onPressed: () => _showGiftDialog(context), icon: const Icon(Icons.card_giftcard), label: const Text('轉贈健康點數給他'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 16),
          TextButton(onPressed: () => _showUnbindWarning(context), child: const Text('解除綁定', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
  Widget _buildReportRow(String label, String val, IconData icon, Color color) => Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 12), Text(label, style: const TextStyle(color: Colors.grey)), const Spacer(), Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]);
  
  void _showGiftDialog(BuildContext context) {
    showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: Colors.white, title: Text('轉贈給 $name'), content: const TextField(decoration: InputDecoration(labelText: '輸入轉贈點數', suffixText: 'Pts', border: OutlineInputBorder()), keyboardType: TextInputType.number), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消', style: TextStyle(color: Colors.grey))), ElevatedButton(onPressed: () { Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功轉贈給 $name！'))); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white), child: const Text('確認轉贈'))]));
  }
  void _showUnbindWarning(BuildContext context) {
    showDialog(context: context, builder: (c) => AlertDialog(backgroundColor: Colors.white, title: const Text('確定要解除綁定嗎？', style: TextStyle(color: Colors.red)), content: const Text('解除綁定後，雙方將無法再查看彼此的健康數據與互相轉贈點數。\n\n⚠️ 注意：系統將會發送解除通知給對方。'), actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消', style: TextStyle(color: Colors.grey))), ElevatedButton(onPressed: () { Navigator.pop(c); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已解除綁定'))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('確定解除'))]));
  }
}

// ==========================================
// 📍 Tab 3: 任務中心 (Play)
// ==========================================
class PlayPage extends StatelessWidget {
  const PlayPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('探索任務')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade100)), child: const Row(children: [Icon(Icons.campaign, color: Colors.amber, size: 20), SizedBox(width: 8), Expanded(child: Text('完成今日打卡任務，賺取健康點數！', style: TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500)))] )),
          const SizedBox(height: 24),
          const Text('VIP 限定大禮包 (半年一次)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          _buildHtmlStyleTaskCard('幸福柑仔店-大腦測試', '測您是不是金牌店長！', '安達人壽 守護專案', Icons.storefront, Colors.amber, '+ 50 點', 'https://ad8test.vercel.app/'),
          const SizedBox(height: 24),
          const Text('每日賺點任務', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          _buildHtmlStyleTaskCard('生活好時光', '短期記憶防護', '桂格完膳 贊助', Icons.psychology, Colors.teal, '+ 10 點', 'https://memory-game-ad.vercel.app/'),
          _buildHtmlStyleTaskCard('一日超商店長', '多工處理大挑戰', '全家便利商店 贊助', Icons.store, Colors.orange, '+ 10 點', 'https://execution-ad.vercel.app/'),
          _buildHtmlStyleTaskCard('眼力極限考驗', '專注力大挑戰', '白蘭氏 葉黃素 贊助', Icons.remove_red_eye, Colors.blue, '+ 10 點', 'https://concentration-ad.vercel.app/'),
          _buildHtmlStyleTaskCard('金幣深蹲王', '跟著鏡頭動一動', '挺立 UC-II / World Gym', Icons.accessibility_new, Colors.purple, '+ 20 點', 'https://squat-game-ad.vercel.app/'),
        ],
      ),
    );
  }

  Widget _buildHtmlStyleTaskCard(String title, String sub, String? sponsor, IconData icon, MaterialColor color, String pts, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sponsor != null) ...[Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.shade50, border: Border.all(color: color.shade100), borderRadius: BorderRadius.circular(4)), child: Text('贊助 | $sponsor', style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.bold))), const SizedBox(height: 10)],
            Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color.shade500)), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))), const SizedBox(height: 2), Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: Text(pts, style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold))), const SizedBox(height: 4), Row(children: [Text('去挑戰', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.shade600)), Icon(Icons.play_arrow, size: 14, color: color.shade600)])])
            ])
          ],
        ),
      ),
    );
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('權益票匣'), bottom: const TabBar(labelColor: darkTeal, indicatorColor: darkTeal, tabs: [Tab(text: '兌換中心'), Tab(text: '我的票匣')])),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: bgGray, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('可用健康點', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))), Text('${appState.healthPoints} Pts', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryEmerald))])),
                const SizedBox(height: 24), const Text('點數兌換', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
                _buildExchangeItem(context, 'HAPPY GO 10 點', 300), _buildExchangeItem(context, '全家 Let\'s Café 中杯拿鐵', 1500),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('AI 專屬推薦與贊助', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)), const SizedBox(height: 12),
                Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)), child: ListTile(contentPadding: const EdgeInsets.all(16), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medication, color: Colors.orange)), title: const Text('大樹藥局 葡萄糖胺 \$50 折價券', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('期限：本月底'), trailing: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, elevation: 0), child: const Text('使用')))),
                const SizedBox(height: 12),
                Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.shade200)), child: ListTile(contentPadding: const EdgeInsets.all(16), leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.shield, color: Colors.green)), title: const Text('南山人壽 外溢保單 10% 減免', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('達標專屬'), trailing: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: primaryEmerald, foregroundColor: Colors.white, elevation: 0), child: const Text('使用')))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeItem(BuildContext context, String title, int cost) {
    bool canAfford = appState.healthPoints >= cost;
    return Container(
      margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))), subtitle: Text('$cost Pts', style: const TextStyle(color: primaryEmerald, fontWeight: FontWeight.bold)), trailing: ElevatedButton(onPressed: canAfford ? () {} : null, style: ElevatedButton.styleFrom(backgroundColor: darkTeal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('兌換'))),
    );
  }
}

// ==========================================
// 📍 Tab 5: 我的 (Profile) 
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const CircleAvatar(radius: 36, backgroundColor: Colors.white, child: Icon(Icons.account_circle, size: 72, color: Colors.grey)), const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1F2937))), const SizedBox(height: 4), Text('目前身分：${appState.title}', style: const TextStyle(color: Colors.grey, fontSize: 13))]))
            ]),
          ),
          const SizedBox(height: 24),

          // 成就勳章入口 (整合在 Profile)
          if (appState.currentIdentity != UserIdentity.guest) ...[
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: InkWell(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DummyPage(title: '成就勳章牆', icon: Icons.military_tech))), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFB300)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(children: [const Icon(Icons.military_tech, color: Colors.white, size: 36), const SizedBox(width: 12), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('我的成就勳章牆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text('已收集 3 / 15 面勳章', style: TextStyle(color: Colors.white70, fontSize: 12))])), const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)])))), const SizedBox(height: 24),
          ],
          
          if (!isBound && appState.currentIdentity != UserIdentity.guest) ...[
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.link, color: Colors.amber), SizedBox(width: 8), Text('尚未綁定 HAPPY GO 帳號', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)))]), const SizedBox(height: 8), const Text('綁定後即可同步您的健康積分，並兌換豐富實體商品！', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: hgPurple, foregroundColor: Colors.white, elevation: 0), child: const Text('立即綁定 (HG SSO)')))]))), const SizedBox(height: 24),
          ],

          _buildSectionTitle('我的健康與數據'),
          _buildSettingsList([
            _buildListTile(context, Icons.bar_chart, '健康趨勢與生理紀錄', '查看血壓、BMI與歷史測驗', const HealthDataPage()),
            _buildListTile(context, Icons.fact_check_outlined, '歷史任務與測驗紀錄', '您完成的互動任務軌跡', const HistoryPage()),
            _buildListTile(context, Icons.monetization_on_outlined, '健康點數累兌明細', '點數獲得與兌換紀錄', const PointsHistoryPage()),
          ]),
          _buildSectionTitle('帳號與安全'),
          _buildSettingsList([
            _buildListTile(context, Icons.manage_accounts_outlined, '個人資料設定', '修改手機、地址等資訊', const ProfileSettingsPage()),
            _buildListTile(context, Icons.security_outlined, '隱私與數據授權', '管理您的個人化推薦同意狀態', const PrivacySettingsPage()),
          ]),
          _buildSectionTitle('關於本服務'),
          _buildSettingsList([
            _buildListTile(context, Icons.description_outlined, '服務條款與政策須知', null, const DummyPage(title: '服務條款', icon: Icons.gavel)),
            _buildListTile(context, Icons.help_outline, '常見問題與客服中心', null, const DummyPage(title: '客服中心', icon: Icons.headset_mic)),
          ]),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton(
              onPressed: () { 
                appState.switchIdentity(UserIdentity.guest); // 清除狀態
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); 
              }, 
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('登出帳號', style: TextStyle(fontWeight: FontWeight.bold))
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)));
  Widget _buildSettingsList(List<Widget> children) => Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(children: children));
  Widget _buildListTile(BuildContext context, IconData icon, String title, String? sub, Widget targetPage) {
    return Column(children: [
      ListTile(leading: Icon(icon, color: darkTeal), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF1F2937))), subtitle: sub != null ? Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null, trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage))),
      const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF3F4F6)),
    ]);
  }
}

// ==========================================
// 📍 附屬頁面實作 (Drill-down Pages)
// ==========================================

// 健康數據歷史
class HealthDataPage extends StatelessWidget {
  const HealthDataPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('健康趨勢與生理紀錄')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('本週活動量', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildDataStat('👣 平均步數', '8,432', '步'), _buildDataStat('🔥 消耗熱量', '320', 'kcal')])),
          const SizedBox(height: 24),
          const Text('生理數據紀錄', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          _buildDataCard('血壓', '118 / 75', 'mmHg', '正常', Colors.blue), _buildDataCard('靜止心率', '72', 'bpm', '正常', Colors.redAccent), _buildDataCard('BMI', '23.4', '', '標準', primaryEmerald),
          const SizedBox(height: 24),
          const Text('過去三個月紀錄 (最多顯示 100 筆)', style: TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 8),
          Container(height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: const Center(child: Text('📊 折線圖表區塊 (開發中)', style: TextStyle(color: Colors.grey)))),
        ],
      ),
    );
  }
  Widget _buildDataStat(String title, String val, String unit) => Column(children: [Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)), const SizedBox(height: 8), Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkTeal)), const SizedBox(width: 4), Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey))])]);
  Widget _buildDataCard(String title, String val, String unit, String status, Color color) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))), Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))), const SizedBox(width: 4), Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(width: 16), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)))]));
}

// 歷史任務紀錄
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('歷史任務與測驗紀錄')), body: ListView(children: [ListTile(leading: const Icon(Icons.sports_esports, color: Colors.blue), title: const Text('眼力極限考驗'), subtitle: const Text('2026-03-04 14:30'), trailing: const Text('PR 85', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))), const Divider(height: 1), ListTile(leading: const Icon(Icons.accessibility_new, color: Colors.purple), title: const Text('金幣深蹲王'), subtitle: const Text('2026-03-03 09:15'), trailing: const Text('20 下', style: TextStyle(fontWeight: FontWeight.bold)))]));
}

// 點數明細
class PointsHistoryPage extends StatelessWidget {
  const PointsHistoryPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('點數累兌明細')), body: ListView(children: [ListTile(leading: const Icon(Icons.add_circle, color: Colors.green), title: const Text('完成眼力極限任務'), subtitle: const Text('2026-03-04 14:30'), trailing: const Text('+10 Pts', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))), const Divider(height: 1), ListTile(leading: const Icon(Icons.remove_circle, color: Colors.orange), title: const Text('兌換大樹藥局折價券'), subtitle: const Text('2026-03-02 10:00'), trailing: const Text('-500 Pts', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)))]));
}

// 個人資料設定
class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('個人資料設定')), body: ListView(padding: const EdgeInsets.all(20), children: [const TextField(decoration: InputDecoration(labelText: '真實姓名', border: OutlineInputBorder())), const SizedBox(height: 16), const TextField(decoration: InputDecoration(labelText: '手機號碼', border: OutlineInputBorder())), const SizedBox(height: 16), const TextField(decoration: InputDecoration(labelText: '通訊地址', border: OutlineInputBorder())), const SizedBox(height: 24), ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: primaryEmerald, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('儲存修改'))]));
}

// 隱私與授權設定
class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('隱私與數據授權')), body: ListView(padding: const EdgeInsets.all(20), children: [SwitchListTile(title: const Text('允許行銷推薦'), subtitle: const Text('同意系統根據您的健康標籤推薦專屬優惠'), value: true, onChanged: (v){}, activeColor: primaryEmerald), const Divider(), SwitchListTile(title: const Text('步數與活動資料同步'), subtitle: const Text('允許存取 Apple Health / Google Fit'), value: appState.hasSetupHealthData, onChanged: (v){}, activeColor: primaryEmerald)]));
}

// 通用佔位頁
class DummyPage extends StatelessWidget {
  final String title; final IconData icon;
  const DummyPage({super.key, required this.title, required this.icon});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('$title 內容建置中...', style: const TextStyle(color: Colors.grey))])));
}

// 🔺 訪客阻擋 UI
Widget _buildGuestBlocker(BuildContext context, String msg, IconData icon) => Scaffold(appBar: AppBar(title: const Text('尚未解鎖')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 16)), const SizedBox(height: 16), ElevatedButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, elevation: 0), child: const Text('立即註冊 / 登入'))])));

// 🔺 三角形雷達繪製邏輯
class TriangleRadarPainter extends CustomPainter {
  final Map<String, double> stats;
  TriangleRadarPainter({required this.stats});
  @override void paint(Canvas canvas, Size size) {
    double cx = size.width / 2; double cy = size.height / 2 + 10; double r = size.width / 2 * 0.8;
    Paint bgPaint = Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 1; Paint fillPaint = Paint()..color = primaryEmerald.withOpacity(0.2)..style = PaintingStyle.fill; Paint linePaint = Paint()..color = primaryEmerald..style = PaintingStyle.stroke..strokeWidth = 2;
    TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    List<String> labels = ['腦動力', '行動力', '防護力']; List<double> angles = [-pi/2, pi/6, 5*pi/6]; 
    for (int step = 1; step <= 3; step++) {
      Path path = Path(); double currentR = r * (step / 3);
      for (int i = 0; i < 3; i++) { double x = cx + currentR * cos(angles[i]); double y = cy + currentR * sin(angles[i]); if (i == 0) path.moveTo(x, y); else path.lineTo(x, y); }
      path.close(); canvas.drawPath(path, bgPaint);
    }
    Path dataPath = Path();
    for (int i = 0; i < 3; i++) {
      double val = stats[labels[i]] ?? 0.1; double x = cx + (r * val) * cos(angles[i]); double y = cy + (r * val) * sin(angles[i]);
      if (i == 0) dataPath.moveTo(x, y); else dataPath.lineTo(x, y);
      double lx = cx + (r + 15) * cos(angles[i]); double ly = cy + (r + 15) * sin(angles[i]);
      tp.text = TextSpan(text: labels[i], style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold)); tp.layout(); tp.paint(canvas, Offset(lx - tp.width/2, ly - tp.height/2));
    }
    dataPath.close(); canvas.drawPath(dataPath, fillPaint); canvas.drawPath(dataPath, linePaint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}