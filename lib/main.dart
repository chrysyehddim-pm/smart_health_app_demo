import 'dart:math' show pi, cos, sin;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ==========================================
// 1. 全域狀態管理 (AppState)
// ==========================================
enum UserIdentity { guest, hgBoundUser }
enum AiScenario { mobilityDecline, vitalsWarning, perfectConsistency } 

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  UserIdentity currentIdentity = UserIdentity.guest; 
  AiScenario currentScenario = AiScenario.perfectConsistency; 
  double textScale = 1.0; 

  String userName = '訪客';
  int healthPoints = 0;
  int waterDrops = 0; // 花園水滴
  String title = '尚未註冊'; 
  Map<String, double> radar3D = {'腦動力': 0.0, '行動力': 0.0, '防護力': 0.0};
  int streakDays = 0; // 連續簽到天數

  void toggleTextScale() { textScale = textScale == 1.0 ? 1.25 : 1.0; notifyListeners(); }
  
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
        userName = '訪客'; healthPoints = 0; waterDrops = 0; streakDays = 0; title = '尚未註冊'; radar3D = {'腦動力': 0.1, '行動力': 0.1, '防護力': 0.1};
        break;
      case UserIdentity.hgBoundUser:
        userName = 'Chrys'; healthPoints = 12500; waterDrops = 6500; streakDays = 3; title = '健康探險家'; 
        switchScenario(AiScenario.perfectConsistency); 
        break;
    }
    notifyListeners();
  }

  void completeTask(int pts, int drops) {
    healthPoints += pts; waterDrops += drops; notifyListeners();
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

// 現代化色彩定義
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
      builder: (context, child) {
        return MaterialApp(
          title: 'Happy Health V3.0',
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
// 📍 登入流程 (極簡化版以加速測試)
// ==========================================
class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState() => _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  void _login(UserIdentity identity) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    appState.switchIdentity(identity);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigator()));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: primaryEmerald)));
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
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
              ElevatedButton(onPressed: () => _login(UserIdentity.hgBoundUser), style: ElevatedButton.styleFrom(backgroundColor: hgPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0), child: const Text('HAPPY GO 快速登入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))), const SizedBox(height: 12),
              TextButton(onPressed: () => _login(UserIdentity.guest), child: const Text('先逛逛，稍後再註冊', style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ),
    );
  }
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
            const Text('1. 動態 AI 推薦場景 (連動雷達)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)), const SizedBox(height: 8),
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
  Widget _buildAiBtn(BuildContext context, String label, AiScenario scenario, bool isSel, Color color) => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { appState.switchScenario(scenario); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? color : Colors.grey[50], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0, alignment: Alignment.centerLeft, side: BorderSide(color: isSel ? Colors.transparent : Colors.grey.shade300)), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));
}

// ==========================================
// 📍 主結構導覽 (5 Tabs Blueprint)
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
          NavigationDestination(icon: Icon(Icons.radar_outlined), selectedIcon: Icon(Icons.radar, color: darkTeal), label: '雷達'), 
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
      appBar: AppBar(title: const Text('林家專屬花園', style: TextStyle(color: darkTeal, fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        children: [
          // 上半部：科技擬物花園 (留存樞紐)
          const GardenVisual(),
          const SizedBox(height: 24),
          // 下半部：AI 商業管家 (變現樞紐)
          const Text('AI 專屬健康提案', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          _buildAiAgentCard(context),
        ],
      ),
    );
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
        Container(padding: const EdgeInsets.all(20), child: Column(children: [SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showToast(context, '已存入票匣！'), icon: Icon(btn1Icon, size: 18), label: Text(btn1Txt), style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _showToast(context, '申請已送出！'), icon: Icon(btn2Icon, size: 18), label: Text(btn2Txt), style: OutlinedButton.styleFrom(foregroundColor: themeColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: themeColor.withOpacity(0.5)))))]))
      ]),
    );
  }
  void _showToast(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}

// 🌸 科技擬物花園元件 (Glassmorphism + Animation)
class GardenVisual extends StatefulWidget { const GardenVisual({super.key}); @override State<GardenVisual> createState() => _GardenVisualState(); }
class _GardenVisualState extends State<GardenVisual> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _breathAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
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
          // 頂部目標
          Positioned(top: 20, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]), child: const Text('🏆 本週目標：黃金向日葵綻放', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal, fontSize: 13)))),
          
          // 2.5D 科技培育底座
          Positioned(
            bottom: 40,
            child: Container(width: 200, height: 60, decoration: BoxDecoration(shape: BoxShape.rectangle, borderRadius: BorderRadius.circular(100), gradient: LinearGradient(colors: [Colors.grey.shade200, Colors.white], begin: Alignment.topCenter, end: Alignment.bottomCenter), boxShadow: [BoxShadow(color: glowColor.withOpacity(0.3), blurRadius: 30, spreadRadius: 5)])),
          ),
          
          // 動態植物
          Positioned(bottom: 60, child: AnimatedBuilder(animation: _breathAnimation, builder: (context, child) => Transform.scale(scale: _breathAnimation.value, child: Text(emoji, style: TextStyle(fontSize: 120, shadows: [Shadow(color: glowColor.withOpacity(0.5), blurRadius: 20)]))))),

          // B2B 原生贊助 3D 標籤
          Positioned(bottom: 50, right: 30, child: InkWell(onTap: () => _showSponsorDialog(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade100, width: 2), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(children: [const Icon(Icons.chair_alt, size: 32, color: Colors.blue), const SizedBox(height: 4), Text('IKEA 贊助', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue.shade700))])))),

          // 底部水滴進度
          Positioned(bottom: -1, left: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.water_drop, color: Colors.blue, size: 20), const SizedBox(width: 8), Text('${appState.waterDrops} / 10,000 滴', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkTeal))]))),
        ],
      ),
    );
  }

  void _showSponsorDialog(BuildContext context) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (c) => Container(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.chair_alt, size: 60, color: Colors.blue), const SizedBox(height: 16), const Text('IKEA 贊助林家花園', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('恭喜獲得 IKEA 實體門市滿千折百券！', style: TextStyle(color: Colors.grey)), const SizedBox(height: 24), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 折價券已存入您的權益票匣！'))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('立即領取存入票匣')))])));
  }
}

// ==========================================
// 📍 Tab 2: 任務中心 (Tasks - 留存動能)
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
          // 階梯式簽到 (簡化視覺)
          const Text('連續簽到領寶箱', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (index) {
                bool isPast = index < appState.streakDays; bool isToday = index == appState.streakDays;
                return Column(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(color: isPast ? primaryEmerald : (isToday ? Colors.amber : Colors.grey.shade100), shape: BoxShape.circle, border: isToday ? Border.all(color: Colors.amber.shade700, width: 2) : null), child: Icon(index == 6 ? Icons.card_giftcard : Icons.check, color: (isPast || isToday) ? Colors.white : Colors.grey.shade300, size: 20)),
                  const SizedBox(height: 8), Text('D${index+1}', style: TextStyle(fontSize: 12, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? Colors.amber.shade700 : Colors.grey))
                ]);
              })),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { appState.completeTask(100, 100); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('簽到成功！獲得 100 點 + 100 滴水'))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white, elevation: 0), child: const Text('領取今日簽到獎勵', style: TextStyle(fontWeight: FontWeight.bold))))
            ]),
          ),
          const SizedBox(height: 24),

          // 被動步數轉換
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.blue.shade100]), borderRadius: BorderRadius.circular(16)), child: Row(children: [Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.directions_walk, color: Colors.blue)), const SizedBox(width: 16), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('今日步數自動同步：6,050 步', style: TextStyle(fontWeight: FontWeight.bold, color: darkTeal)), Text('點擊轉換為花園養分', style: TextStyle(fontSize: 12, color: Colors.blue))])), ElevatedButton(onPressed: () { appState.completeTask(50, 300); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('轉換成功！獲得 50 點 + 300 滴水'))); }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, elevation: 0), child: const Text('轉換'))])),
          const SizedBox(height: 24),

          // 主動任務 (雙軌獎勵標示)
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.shade50, border: Border.all(color: color.shade100), borderRadius: BorderRadius.circular(4)), child: Text('贊助 | $sponsor', style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.bold))), const SizedBox(height: 10),
            Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color.shade500)), const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))), const SizedBox(height: 2), Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Row(children: [Icon(Icons.monetization_on, size: 12, color: Colors.amber.shade700), const SizedBox(width: 2), Text('+$pts', style: TextStyle(color: Colors.amber.shade700, fontSize: 12, fontWeight: FontWeight.bold)), const SizedBox(width: 6), const Icon(Icons.water_drop, size: 12, color: Colors.blue), const SizedBox(width: 2), Text('+$drops', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: darkTeal, borderRadius: BorderRadius.circular(12)), child: const Text('去挑戰', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)))
              ])
            ])
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 📍 Tab 3: 健康雷達 (Dashboard - 數據深度與 ESG)
// ==========================================
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    if (appState.currentIdentity == UserIdentity.guest) return _buildGuestBlocker(context, '註冊會員查看專屬數據', Icons.radar);

    return Scaffold(
      appBar: AppBar(title: const Text('健康雷達與趨勢')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [const Text('3D 商業健康力分析', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 20), SizedBox(width: 200, height: 200, child: CustomPaint(painter: TriangleRadarPainter(stats: appState.radar3D)))])),
          const SizedBox(height: 24),
          const Text('家族健康動態與關懷', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          _buildFamilyMemberCard(context, '爸爸', '活躍', '今日步數達標', Colors.blue, false),
          _buildFamilyMemberCard(context, '媽媽', '警示', '連續三天未登入', Colors.red, true),
        ],
      ),
    );
  }
  Widget _buildFamilyMemberCard(BuildContext context, String name, String state, String sub, MaterialColor color, bool showWarning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: showWarning ? Colors.red.shade200 : Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: color.shade50, child: Icon(Icons.person, color: color.shade600)),
        title: Row(children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(4)), child: Text(state, style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.bold)))]), 
        subtitle: Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: showWarning ? ElevatedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已透過 Line 發送關懷訊息'))), icon: const Icon(Icons.favorite, size: 16), label: const Text('關心'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0)) : const SizedBox(),
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
          if (appState.currentIdentity != UserIdentity.guest) ...[Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: InkWell(onTap: () {}, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFB300)]), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: const Row(children: [Icon(Icons.military_tech, color: Colors.white, size: 36), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('我的成就勳章牆', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), Text('已收集 3 / 15 面勳章', style: TextStyle(color: Colors.white70, fontSize: 12))])), Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)])))), const SizedBox(height: 24)],
          if (!isBound && appState.currentIdentity != UserIdentity.guest) ...[Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.link, color: Colors.amber), SizedBox(width: 8), Text('尚未綁定 HAPPY GO 帳號', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)))]), const SizedBox(height: 8), const Text('綁定後即可同步您的健康積分！', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: hgPurple, foregroundColor: Colors.white, elevation: 0), child: const Text('立即綁定 (HG SSO)')))]))), const SizedBox(height: 24)],
          _buildSectionTitle('帳號與安全'),
          Container(margin: const EdgeInsets.symmetric(horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [_buildListTile(Icons.manage_accounts_outlined, '個人資料設定', '修改手機等資訊'), _buildListTile(Icons.security_outlined, '隱私與數據授權', '管理您的個人化推薦'), _buildListTile(Icons.link, '家族邀請連結', '管理分享網址')])),
          const SizedBox(height: 20),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: OutlinedButton(onPressed: () { appState.switchIdentity(UserIdentity.guest); Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false); }, style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('登出帳號', style: TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)));
  Widget _buildListTile(IconData icon, String title, String? sub) => Column(children: [ListTile(leading: Icon(icon, color: darkTeal), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)), subtitle: sub != null ? Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null, trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey)), const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF3F4F6))]);
}

// 🔺 通用元件
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