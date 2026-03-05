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

  UserIdentity currentIdentity = UserIdentity.guest; // 預設從訪客/未登入開始
  AiScenario currentScenario = AiScenario.perfectConsistency; 
  double textScale = 1.0; 

  String userName = '訪客';
  int healthPoints = 0;
  String title = '尚未註冊'; 
  Map<String, double> radar3D = {'腦動力': 0.0, '行動力': 0.0, '防護力': 0.0};

  void toggleTextScale() { textScale = textScale == 1.0 ? 1.3 : 1.0; notifyListeners(); }
  
  void switchScenario(AiScenario scenario) { 
    currentScenario = scenario; 
    switch(scenario) {
      case AiScenario.mobilityDecline:
        radar3D = {'腦動力': 0.8, '行動力': 0.3, '防護力': 0.8}; 
        break;
      case AiScenario.vitalsWarning:
        radar3D = {'腦動力': 0.7, '行動力': 0.7, '防護力': 0.2}; 
        break;
      case AiScenario.perfectConsistency:
        radar3D = {'腦動力': 0.95, '行動力': 0.9, '防護力': 0.95}; 
        break;
    }
    notifyListeners(); 
  }

  void switchIdentity(UserIdentity identity) {
    currentIdentity = identity;
    switch (identity) {
      case UserIdentity.guest:
        userName = '訪客'; healthPoints = 0; title = '尚未註冊'; radar3D = {'腦動力': 0.1, '行動力': 0.1, '防護力': 0.1};
        break;
      case UserIdentity.newPhoneUser:
        userName = '0912***789'; healthPoints = 50; title = '健康新手'; radar3D = {'腦動力': 0.4, '行動力': 0.4, '防護力': 0.4};
        break;
      case UserIdentity.hgBoundUser:
        userName = 'Chrys'; healthPoints = 12500; title = '鋼鐵不老翁'; 
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

// 現代化色彩定義 (仿 Tailwind)
const Color primaryEmerald = Color(0xFF10B981);
const Color darkTeal = Color(0xFF0F766E);
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
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          builder: (context, widget) {
            Widget app = DevicePreview.appBuilder(context, widget);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(appState.textScale)), 
              child: app,
            );
          },
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: bgGray,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.white, elevation: 0, centerTitle: true, titleTextStyle: TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.bold), iconTheme: IconThemeData(color: Color(0xFF1F2937))),
            colorScheme: ColorScheme.fromSeed(seedColor: primaryEmerald, primary: primaryEmerald, secondary: darkTeal, background: bgGray),
            textTheme: GoogleFonts.notoSansTcTextTheme(),
          ),
          home: const LoginScreen(), // 1. 起始頁改為登入頁
        );
      },
    );
  }
}

// ==========================================
// 📍 全新：登入與身分融合頁面 (Login Screen)
// ==========================================
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _loginAndGo(BuildContext context, UserIdentity identity) {
    appState.switchIdentity(identity);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigator()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Logo 區塊
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(color: primaryEmerald.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.favorite_rounded, color: primaryEmerald, size: 40),
              ),
              const SizedBox(height: 24),
              const Text('Happy Health\n智慧健康服務', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2, color: Color(0xFF1F2937))),
              const SizedBox(height: 12),
              const Text('每天三分鐘，玩出健康新生活\n授權登入，累積您的專屬健康資產。', style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
              const Spacer(),
              
              // 登入按鈕群
              ElevatedButton.icon(
                onPressed: () => _loginAndGo(context, UserIdentity.hgBoundUser),
                icon: const Icon(Icons.flash_on, size: 20),
                label: const Text('HAPPY GO 快速登入 (推薦)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _loginAndGo(context, UserIdentity.newPhoneUser),
                icon: const Icon(Icons.phone_android, size: 20),
                label: const Text('手機號碼註冊 / 登入'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100], foregroundColor: const Color(0xFF1F2937), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _loginAndGo(context, UserIdentity.guest),
                child: const Text('先逛逛，稍後再註冊', style: TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 20),
              const Text('登入即代表您同意 服務條款 與 隱私權政策', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. 展示控制台 (God Mode)
// ==========================================
class GodModeFab extends StatelessWidget {
  const GodModeFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16, bottom: 16,
      child: FloatingActionButton.small(
        heroTag: 'god_mode', backgroundColor: const Color(0xFF1F2937), foregroundColor: Colors.amber,
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
              const Text('⚡️ 商業展示控制台', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              const Text('1. 身分切換 (檢視不同權限)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _buildOptBtn(context, '訪客模式', UserIdentity.guest, appState.currentIdentity == UserIdentity.guest),
                  _buildOptBtn(context, '純手機新戶', UserIdentity.newPhoneUser, appState.currentIdentity == UserIdentity.newPhoneUser),
                  _buildOptBtn(context, 'HG 老客', UserIdentity.hgBoundUser, appState.currentIdentity == UserIdentity.hgBoundUser),
                ],
              ),
              const SizedBox(height: 24),
              const Text('2. 動態 AI 推薦場景 (連動雷達)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              Column(
                children: [
                  _buildAiBtn(context, '情境 A：行動力衰退 (導購)', AiScenario.mobilityDecline, appState.currentScenario == AiScenario.mobilityDecline, Colors.orange),
                  const SizedBox(height: 8),
                  _buildAiBtn(context, '情境 B：防護力異常 (名單)', AiScenario.vitalsWarning, appState.currentScenario == AiScenario.vitalsWarning, Colors.redAccent),
                  const SizedBox(height: 8),
                  _buildAiBtn(context, '情境 C：連續滿分 (外溢保單)', AiScenario.perfectConsistency, appState.currentScenario == AiScenario.perfectConsistency, primaryEmerald),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F2937), foregroundColor: Colors.white), child: const Text('關閉')))
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptBtn(BuildContext context, String label, UserIdentity identity, bool isSel) => ElevatedButton(onPressed: () { appState.switchIdentity(identity); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? darkTeal : Colors.grey[100], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0), child: Text(label, style: const TextStyle(fontSize: 12)));
  Widget _buildAiBtn(BuildContext context, String label, AiScenario scenario, bool isSel, Color color) => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { appState.switchScenario(scenario); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? color : Colors.grey[50], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0, alignment: Alignment.centerLeft, side: BorderSide(color: isSel ? Colors.transparent : Colors.grey.shade300)), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));
}

// ==========================================
// 3. 主結構導覽 (5 Core Tabs)
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
        backgroundColor: Colors.white, indicatorColor: primaryEmerald.withOpacity(0.2), 
        elevation: 10, shadowColor: Colors.black12,
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
// 📍 Tab 1: 首頁大廳 (Home) - 現代化 UI
// ==========================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isGuest = appState.currentIdentity == UserIdentity.guest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Happy Health', style: TextStyle(color: darkTeal, fontWeight: FontWeight.w900, letterSpacing: 0.5)), 
        actions: [IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: (){})],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        children: [
          _buildHeroStatusCard(context), // 現代化漸層卡片
          const SizedBox(height: 24),
          
          if (!isGuest) ...[
            _buildRadarAndAiCard(context), // 個人健康雷達 + AI 推銷
            const SizedBox(height: 24),
            
            // 補上：生理數據與趨勢入口
            const Text('健康趨勢與紀錄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
            const SizedBox(height: 12),
            _buildTrendCard(context),
          ],
          
          if (isGuest) ...[
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade200)), child: Column(children: [const Icon(Icons.lock_person, size: 40, color: Colors.amber), const SizedBox(height: 12), const Text('您目前為訪客體驗模式', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309), fontSize: 16)), const SizedBox(height: 8), const Text('註冊即可解鎖專屬健康雷達、趨勢追蹤，\n並開始累積健康點數！', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF78350F), height: 1.5)), const SizedBox(height: 16), ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, elevation: 0), child: const Text('立即註冊 / 登入'))])),
          ],
        ],
      ),
    );
  }

  // 1. 現代化漸層狀態卡 (復刻 HTML 質感)
  Widget _buildHeroStatusCard(BuildContext context) {
    bool isBound = appState.currentIdentity == UserIdentity.hgBoundUser;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryEmerald, darkTeal], begin: Alignment.topLeft, end: Alignment.bottomRight), 
        borderRadius: BorderRadius.circular(24), 
        boxShadow: [BoxShadow(color: primaryEmerald.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('早安，${appState.userName} ☀️', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Text('🏅 稱號：${appState.title}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                      if (isBound) ...[
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(12)), child: const Text('HG 已綁定', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                      ]
                    ],
                  ),
                ],
              ),
              const CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('我的健康點 (Pts)', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${appState.healthPoints}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
              const SizedBox(width: 4), const Text('點', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  // 2. 個人健康雷達 + AI 管家 (去除生硬商業詞)
  Widget _buildRadarAndAiCard(BuildContext context) {
    String aiTitle, aiMsg, btn1Txt, btn2Txt;
    IconData btn1Icon, btn2Icon; Color themeColor;

    switch(appState.currentScenario) {
      case AiScenario.mobilityDecline:
        themeColor = Colors.orange; aiTitle = "健康守護提案";
        aiMsg = "系統觀察到您近期的『行動力』指標有下降趨勢。為保護關節健康，我為您爭取到【大樹藥局 - 葡萄糖胺】專屬優惠，以及自費復健評估專案，請問需要安排嗎？";
        btn1Txt = "用 500 點換購葡萄糖胺"; btn1Icon = Icons.shopping_cart; btn2Txt = "預約亞東自費復健"; btn2Icon = Icons.calendar_month;
        break;
      case AiScenario.vitalsWarning:
        themeColor = Colors.redAccent; aiTitle = "防護力異常警示";
        aiMsg = "您近期的防護力數值出現異常波動。為了您的健康，建議您進一步了解【亞東醫院高階腦部 MRI 健檢專案】，及早發現及早預防。";
        btn1Txt = "了解高階健檢專案"; btn1Icon = Icons.medical_services; btn2Txt = "重新進行檢測"; btn2Icon = Icons.refresh;
        break;
      case AiScenario.perfectConsistency:
        themeColor = primaryEmerald; aiTitle = "極致健康解鎖";
        aiMsg = "太棒了！您已【連續 30 天達標】，且三大健康力超越 95% 用戶！\n\nAI 已為您解鎖隱藏福利：購買【南山人壽外溢保單】首年保費減免 10%，同時桂格送您專屬禮物！";
        btn1Txt = "領取保單 10% 減免憑證"; btn1Icon = Icons.shield; btn2Txt = "領取桂格贊助兌換券"; btn2Icon = Icons.card_giftcard;
        break;
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          // 上半部：個人健康雷達
          Container(
            padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: bgGray, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(
              children: [
                SizedBox(width: 110, height: 110, child: CustomPaint(painter: TriangleRadarPainter(stats: appState.radar3D))),
                const SizedBox(width: 20),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('個人健康雷達', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))), const SizedBox(height: 10),
                  _buildRadarStatBar('🧠 腦動力', appState.radar3D['腦動力']!, Colors.amber.shade500),
                  _buildRadarStatBar('🏃‍♂️ 行動力', appState.radar3D['行動力']!, Colors.blue.shade400),
                  _buildRadarStatBar('🛡️ 防護力', appState.radar3D['防護力']!, primaryEmerald),
                ]))
              ],
            ),
          ),
          // 下半部：AI 語氣推薦
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.auto_awesome, color: themeColor, size: 16)), const SizedBox(width: 8), Text('AI 專屬管家：$aiTitle', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 12),
                Text(aiMsg, style: const TextStyle(height: 1.6, color: Color(0xFF4B5563), fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () {}, icon: Icon(btn1Icon, size: 18), label: Text(btn1Txt), style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: Icon(btn2Icon, size: 18), label: Text(btn2Txt), style: OutlinedButton.styleFrom(foregroundColor: themeColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: BorderSide(color: themeColor.withOpacity(0.5))))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRadarStatBar(String label, double val, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [SizedBox(width: 65, child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.w500))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: val, backgroundColor: Colors.grey.shade200, color: color, minHeight: 6)))]));
  }

  // 3. 補上：生理數據與趨勢卡片
  Widget _buildTrendCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.monitor_heart, color: Colors.blue.shade600)),
        title: const Text('生理數據與歷史趨勢', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: const Text('血壓、心跳、BMI及檢測紀錄', style: TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        onTap: () {}, // 導向詳細數據頁
      ),
    );
  }
}

// 🔺 三角形雷達繪製邏輯
class TriangleRadarPainter extends CustomPainter {
  final Map<String, double> stats;
  TriangleRadarPainter({required this.stats});
  @override
  void paint(Canvas canvas, Size size) {
    double cx = size.width / 2; double cy = size.height / 2 + 10; double r = size.width / 2 * 0.8;
    Paint bgPaint = Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 1;
    Paint fillPaint = Paint()..color = primaryEmerald.withOpacity(0.2)..style = PaintingStyle.fill;
    Paint linePaint = Paint()..color = primaryEmerald..style = PaintingStyle.stroke..strokeWidth = 2;
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
      tp.text = TextSpan(text: labels[i], style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10, fontWeight: FontWeight.bold));
      tp.layout(); tp.paint(canvas, Offset(lx - tp.width/2, ly - tp.height/2));
    }
    dataPath.close(); canvas.drawPath(dataPath, fillPaint); canvas.drawPath(dataPath, linePaint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 📍 Tab 3: 任務中心 (Play) - 復刻 HTML UI
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
          // 頂部公告
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade100)), child: Row(children: [const Icon(Icons.campaign, color: Colors.amber, size: 20), const SizedBox(width: 8), const Expanded(child: Text('完成今日打卡任務，賺取健康點數！', style: TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500)))] )),
          const SizedBox(height: 24),
          
          const Text('VIP 限定大禮包 (半年一次)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          _buildHtmlStyleTaskCard('幸福柑仔店-大腦測試', '測您是不是金牌店長！', '安達人壽 守護專案', Icons.storefront, Colors.amber, '+ 50 點', 'https://chrysyehddim-pm.github.io/ad8test/'),
          
          const SizedBox(height: 24),
          const Text('每日賺點任務', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))), const SizedBox(height: 12),
          _buildHtmlStyleTaskCard('眼力極限考驗', '專注力大挑戰', '白蘭氏 葉黃素 贊助', Icons.remove_red_eye, Colors.blue, '+ 10 點', 'https://chrysyehddim-pm.github.io/memory/'),
          _buildHtmlStyleTaskCard('金幣深蹲王', '跟著鏡頭動一動', 'World Gym 贊助', Icons.accessibility_new, Colors.purple, '+ 20 點', 'https://chrysyehddim-pm.github.io/Squat-Game-PoC/'),
          _buildHtmlStyleTaskCard('生活好時光', '短期記憶防護', null, Icons.psychology, Colors.teal, '+ 10 點', 'https://chrysyehddim-pm.github.io/memory/'),
        ],
      ),
    );
  }

  // 完美復刻 Phase 1 HTML Tailwind 質感的任務卡片
  Widget _buildHtmlStyleTaskCard(String title, String sub, String? sponsor, IconData icon, MaterialColor color, String pts, String url) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sponsor != null) ...[
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.shade50, border: Border.all(color: color.shade100), borderRadius: BorderRadius.circular(4)), child: Text('贊助 | $sponsor', style: TextStyle(fontSize: 10, color: color.shade700, fontWeight: FontWeight.bold))),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color.shade500)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))), const SizedBox(height: 2), Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)), child: Text(pts, style: TextStyle(color: Colors.green.shade700, fontSize: 12, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 4),
                  Row(children: [Text('去挑戰', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.shade600)), Icon(Icons.play_arrow, size: 14, color: color.shade600)])
                ])
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 📍 Tab 5: 我的 (Profile) - 完整功能擴充
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
          // 大頭貼與基本資料
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const CircleAvatar(radius: 36, backgroundColor: Colors.white, child: Icon(Icons.account_circle, size: 72, color: Colors.grey)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text('目前身分：${appState.title}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]))
            ]),
          ),
          const SizedBox(height: 32),
          
          // HG 綁定提示 (獨立區塊，不在名字旁邊干擾)
          if (!isBound && appState.currentIdentity != UserIdentity.guest) ...[
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.amber.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.link, color: Colors.amber), SizedBox(width: 8), Text('尚未綁定 HAPPY GO 帳號', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB45309)))]), const SizedBox(height: 8), const Text('綁定後即可同步您的健康積分，並兌換豐富實體商品！', style: TextStyle(fontSize: 12, color: Color(0xFF78350F))), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white, elevation: 0), child: const Text('立即綁定 (HG SSO)')))]))),
            const SizedBox(height: 24),
          ],

          _buildSectionTitle('我的健康與數據'),
          _buildSettingsList([
            _buildListTile(Icons.bar_chart, '健康趨勢與生理紀錄', '查看血壓、BMI與歷史測驗'),
            _buildListTile(Icons.fact_check_outlined, '歷史任務與測驗紀錄', '您完成的互動任務軌跡'),
            _buildListTile(Icons.monetization_on_outlined, '健康點數累兌明細', '點數獲得與兌換紀錄'),
          ]),

          _buildSectionTitle('帳號與安全'),
          _buildSettingsList([
            _buildListTile(Icons.manage_accounts_outlined, '個人資料設定', '修改手機、地址等資訊'),
            _buildListTile(Icons.security_outlined, '隱私與數據授權', '管理您的個人化推薦同意狀態'),
          ]),

          _buildSectionTitle('關於本服務'),
          _buildSettingsList([
            _buildListTile(Icons.description_outlined, '服務條款與政策須知', null),
            _buildListTile(Icons.help_outline, '常見問題與客服中心', null),
          ]),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: BorderSide(color: Colors.red.shade200), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('登出帳號', style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Padding(padding: const EdgeInsets.fromLTRB(24, 16, 24, 8), child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade600)));
  
  Widget _buildSettingsList(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: children),
    );
  }

  Widget _buildListTile(IconData icon, String title, String? sub) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: darkTeal),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF1F2937))),
          subtitle: sub != null ? Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          onTap: () {},
        ),
        const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF3F4F6)),
      ],
    );
  }
}

// ==========================================
// 📍 Tab 2: 親友圈 (Family) & Tab 4: 票匣 (Rewards) 保持精簡
// ==========================================
class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('家人群組')), body: const Center(child: Text('親友圈開發中...', style: TextStyle(color: Colors.grey))));
}

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('權益票匣')), body: const Center(child: Text('兌換商城開發中...', style: TextStyle(color: Colors.grey))));
}