import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// ==========================================
// 1. 全域狀態管理 (AppState - 支援 God Mode)
// ==========================================
enum UserIdentity { guest, newPhoneUser, hgBoundUser }
enum AiScenario { mobilityDecline, vitalsWarning, perfectConsistency } 

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  UserIdentity currentIdentity = UserIdentity.hgBoundUser; // 預設展示 HG 老客
  AiScenario currentScenario = AiScenario.perfectConsistency; // 預設展示最高含金量情境
  double textScale = 1.0; 

  String userName = 'Chrys';
  int healthPoints = 12500;
  String title = '鋼鐵不老翁'; // 稱號系統
  Map<String, double> radar3D = {'腦動力': 0.9, '行動力': 0.9, '防護力': 0.9};

  void toggleTextScale() { textScale = textScale == 1.0 ? 1.3 : 1.0; notifyListeners(); }
  
  void switchScenario(AiScenario scenario) { 
    currentScenario = scenario; 
    switch(scenario) {
      case AiScenario.mobilityDecline:
        radar3D = {'腦動力': 0.8, '行動力': 0.3, '防護力': 0.8}; // 行動力凹陷
        break;
      case AiScenario.vitalsWarning:
        radar3D = {'腦動力': 0.7, '行動力': 0.7, '防護力': 0.2}; // 防護力凹陷
        break;
      case AiScenario.perfectConsistency:
        radar3D = {'腦動力': 0.95, '行動力': 0.9, '防護力': 0.95}; // 接近滿分
        break;
    }
    notifyListeners(); 
  }

  void switchIdentity(UserIdentity identity) {
    currentIdentity = identity;
    switch (identity) {
      case UserIdentity.guest:
        userName = '訪客'; healthPoints = 0; title = '尚未註冊'; radar3D = {'腦動力': 0.0, '行動力': 0.0, '防護力': 0.0};
        break;
      case UserIdentity.newPhoneUser:
        userName = '0912***789'; healthPoints = 50; title = '健康新手'; radar3D = {'腦動力': 0.4, '行動力': 0.4, '防護力': 0.4};
        break;
      case UserIdentity.hgBoundUser:
        userName = 'Chrys (HG 已綁定)'; healthPoints = 12500; title = '鋼鐵不老翁'; 
        switchScenario(AiScenario.perfectConsistency); // 重置為高分
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

class HappyHealthApp extends StatelessWidget {
  const HappyHealthApp({super.key});
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, child) {
        return MaterialApp(
          title: 'Happy Health Phase 2',
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
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100), primary: const Color(0xFFE65100), secondary: const Color(0xFF004D40), background: const Color(0xFFF5F7FA)),
            textTheme: GoogleFonts.notoSansTcTextTheme(),
          ),
          home: const MainNavigator(), // Phase 2 直接進入主結構
        );
      },
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
              const Text('⚡️ Phase 2 商業展示控制台', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              const Text('1. 身分與 SSO 融合切換', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  _buildOptBtn(context, '訪客模式', UserIdentity.guest, appState.currentIdentity == UserIdentity.guest),
                  _buildOptBtn(context, '純手機新戶', UserIdentity.newPhoneUser, appState.currentIdentity == UserIdentity.newPhoneUser),
                  _buildOptBtn(context, 'HG SSO 老客', UserIdentity.hgBoundUser, appState.currentIdentity == UserIdentity.hgBoundUser),
                ],
              ),
              const SizedBox(height: 24),
              
              const Text('2. AI 商業變現場景 (連動 3D 雷達)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: [
                  _buildAiBtn(context, '情境 A：行動力衰退 (導購 CPS)', AiScenario.mobilityDecline, appState.currentScenario == AiScenario.mobilityDecline, Colors.orange),
                  const SizedBox(height: 8),
                  _buildAiBtn(context, '情境 B：防護力異常 (名單 CPL)', AiScenario.vitalsWarning, appState.currentScenario == AiScenario.vitalsWarning, Colors.redAccent),
                  const SizedBox(height: 8),
                  _buildAiBtn(context, '情境 C：連續達標滿分 (贊助/保險)', AiScenario.perfectConsistency, appState.currentScenario == AiScenario.perfectConsistency, Colors.green),
                ],
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.text_increase, color: Colors.deepPurple),
                title: const Text('樂齡大字模式 (Demo 專用)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                trailing: Switch(value: appState.textScale > 1.0, onChanged: (v) { appState.toggleTextScale(); Navigator.pop(context); }, activeColor: Colors.deepPurple),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, foregroundColor: Colors.white), child: const Text('關閉')))
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptBtn(BuildContext context, String label, UserIdentity identity, bool isSel) => ElevatedButton(onPressed: () { appState.switchIdentity(identity); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? const Color(0xFF004D40) : Colors.grey[200], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0), child: Text(label, style: const TextStyle(fontSize: 12)));
  Widget _buildAiBtn(BuildContext context, String label, AiScenario scenario, bool isSel, Color color) => SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { appState.switchScenario(scenario); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: isSel ? color : Colors.grey[100], foregroundColor: isSel ? Colors.white : Colors.black87, elevation: 0, alignment: Alignment.centerLeft), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));
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
      body: Stack(
        children: [
          pages[_currentIndex],
          const GodModeFab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex, onDestinationSelected: (i) => setState(() => _currentIndex = i), 
        backgroundColor: Colors.white, indicatorColor: const Color(0xFFFFCC80), 
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '大廳'), 
          NavigationDestination(icon: Icon(Icons.family_restroom_outlined), selectedIcon: Icon(Icons.family_restroom), label: '親友'), 
          NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: '探索'), 
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: '票匣'), 
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的')
        ]
      ),
    );
  }
}

// ==========================================
// 📍 Tab 1: 首頁大廳 (Home) - 意圖觸發與導購印鈔機
// ==========================================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isGuest = appState.currentIdentity == UserIdentity.guest;

    return Scaffold(
      appBar: AppBar(title: const Text('Happy Health', style: TextStyle(color: Color(0xFFE65100))), actions: [IconButton(icon: const Icon(Icons.notifications_none), onPressed: (){})]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
        children: [
          _buildStatusCard(context),
          const SizedBox(height: 16),
          
          if (!isGuest) ...[
            // 3D 商業雷達與 AI 助理 (核心變現區塊)
            _buildAiAgentCard(context),
            const SizedBox(height: 24),
            
            const Row(children: [Icon(Icons.task_alt, color: Colors.teal), SizedBox(width: 8), Text('今日 3 分鐘打卡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
            const SizedBox(height: 12),
            _buildTaskCard('腦力激盪', '玩一場眼力極限遊戲', Icons.psychology, Colors.orange),
            _buildTaskCard('行動力維持', '完成金幣深蹲王 15 下', Icons.accessibility_new, Colors.purple),
          ],
          
          if (isGuest) ...[
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(16)), child: const Column(children: [Text('您目前為訪客體驗模式', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)), SizedBox(height: 8), Text('註冊即可解鎖 AI 健康管家、領取健康點數，並與家人連線！', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))])),
            const SizedBox(height: 24),
          ],

          const SizedBox(height: 24),
          const Row(children: [Icon(Icons.local_hospital, color: Colors.blue), SizedBox(width: 8), Text('亞東醫院 衛教專區', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 12),
          _buildArticleCard('解鎖大腦健康失智症新趨勢', '神經醫學部 黃彥翔 主任', 'https://www.femh.org.tw/magazine/viewmag.aspx?ID=11889'),
          _buildArticleCard('常常頭痛怎麼辦？', '神經醫學部 賴資賢 主任', 'https://www.femh.org.tw/research/news_detail.aspx?NewsNo=14687&Class=1'),
        ],
      ),
    );
  }

  // 狀態與稱號卡
  Widget _buildStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE65100), Color(0xFFFFB74D)]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        children: [
          Row(children: [
            const CircleAvatar(radius: 28, backgroundColor: Colors.white, child: Icon(Icons.person, size: 36, color: Color(0xFFE65100))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(appState.userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), child: Text('稱號：${appState.title}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
            ]))
          ]),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('健康點 (HP)', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)), Row(children: [const Icon(Icons.stars, color: Colors.amber, size: 20), const SizedBox(width: 6), Text('${appState.healthPoints}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87))])]),
              if (appState.currentIdentity == UserIdentity.guest) ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white), child: const Text('立即註冊'))
              else const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey)
            ]),
          )
        ],
      ),
    );
  }

  // AI 規則引擎管家 (結合 3D 雷達)
  Widget _buildAiAgentCard(BuildContext context) {
    String aiTitle, aiMsg, btn1Txt, btn2Txt;
    IconData btn1Icon, btn2Icon;
    Color themeColor;

    switch(appState.currentScenario) {
      case AiScenario.mobilityDecline:
        themeColor = Colors.orange; aiTitle = "健康警訊與提案";
        aiMsg = "早安，${appState.userName}。系統偵測到您近期『行動力』標籤有衰退趨勢。\n\n根據亞東醫院復健科專欄建議，我已為您爭取到【大樹藥局 - 葡萄糖胺】的專屬優惠，以及自費復健評估專案，請問需要為您安排嗎？";
        btn1Txt = "用 500 點換購葡萄糖胺"; btn1Icon = Icons.shopping_cart;
        btn2Txt = "預約亞東自費復健 (+1000 Pts)"; btn2Icon = Icons.calendar_month;
        break;
      case AiScenario.vitalsWarning:
        themeColor = Colors.redAccent; aiTitle = "防護力異常警示";
        aiMsg = "${appState.userName} 您好，您近期的 AD8 檢測與防護力數值出現異常波動。為了您的健康，AI 建議您進一步了解【亞東醫院高階腦部 MRI 健檢專案】，及早發現及早預防。";
        btn1Txt = "了解高階健檢專案"; btn1Icon = Icons.medical_services;
        btn2Txt = "重新進行 AD8 檢測"; btn2Icon = Icons.refresh;
        break;
      case AiScenario.perfectConsistency:
        themeColor = Colors.green; aiTitle = "極致健康解鎖";
        aiMsg = "太棒了，${appState.userName}！您已【連續 30 天完成打卡】，且『三大健康力』超越 95% 用戶！\n\nAI 已為您解鎖隱藏版福利：購買【南山人壽外溢保單】可直接減免首年保費 10%，同時桂格也送您一份專屬禮物！";
        btn1Txt = "領取保單 10% 減免憑證"; btn1Icon = Icons.shield;
        btn2Txt = "領取桂格完膳贊助兌換券"; btn2Icon = Icons.card_giftcard;
        break;
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: themeColor.withOpacity(0.3), width: 2), boxShadow: [BoxShadow(color: themeColor.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        children: [
          // 上半部：3D 雷達圖
          Container(
            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(top: Radius.circular(18))),
            child: Row(
              children: [
                SizedBox(width: 120, height: 120, child: CustomPaint(painter: TriangleRadarPainter(stats: appState.radar3D))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('3D 商業健康力', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 8),
                  _buildRadarStatBar('🧠 腦動力', appState.radar3D['腦動力']!, Colors.orange),
                  _buildRadarStatBar('🏃‍♂️ 行動力', appState.radar3D['行動力']!, Colors.purple),
                  _buildRadarStatBar('🛡️ 防護力', appState.radar3D['防護力']!, Colors.blue),
                ]))
              ],
            ),
          ),
          // 下半部：AI 話術與按鈕
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Icon(Icons.smart_toy, color: themeColor), const SizedBox(width: 8), Text('AI 管家：$aiTitle', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 12),
                Text(aiMsg, style: const TextStyle(height: 1.6, color: Colors.black87, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => _showToast(context, '已存入票匣！'), icon: Icon(btn1Icon, size: 18), label: Text(btn1Txt), style: ElevatedButton.styleFrom(backgroundColor: themeColor, foregroundColor: Colors.white))),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _showToast(context, '已送出申請！'), icon: Icon(btn2Icon, size: 18), label: Text(btn2Txt), style: OutlinedButton.styleFrom(foregroundColor: themeColor, side: BorderSide(color: themeColor)))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRadarStatBar(String label, double val, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [SizedBox(width: 65, child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: val, backgroundColor: Colors.grey[300], color: color, minHeight: 6)))]));
  }

  void _showToast(BuildContext context, String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  
  Widget _buildTaskCard(String title, String sub, IconData icon, Color color) => Card(margin: const EdgeInsets.only(bottom: 8), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(sub, style: const TextStyle(fontSize: 12)), trailing: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white), child: const Text('前往'))));
  Widget _buildArticleCard(String title, String sub, String url) => InkWell(onTap: () => _launchUrl(url), child: Card(margin: const EdgeInsets.only(bottom: 8), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(leading: Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.article, color: Colors.blue)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), subtitle: Text(sub, style: const TextStyle(fontSize: 12)), trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey))));
}

// 🔺 三角形 3D 雷達繪製邏輯
class TriangleRadarPainter extends CustomPainter {
  final Map<String, double> stats;
  TriangleRadarPainter({required this.stats});
  @override
  void paint(Canvas canvas, Size size) {
    double cx = size.width / 2; double cy = size.height / 2 + 10; double r = size.width / 2 * 0.8;
    Paint bgPaint = Paint()..color = Colors.grey.shade300..style = PaintingStyle.stroke..strokeWidth = 1;
    Paint fillPaint = Paint()..color = const Color(0xFFE65100).withOpacity(0.3)..style = PaintingStyle.fill;
    Paint linePaint = Paint()..color = const Color(0xFFE65100)..style = PaintingStyle.stroke..strokeWidth = 2;
    TextPainter tp = TextPainter(textDirection: TextDirection.ltr);

    List<String> labels = ['腦動力', '行動力', '防護力'];
    List<double> angles = [-pi/2, pi/6, 5*pi/6]; // 頂、右下、左下

    // 畫背景網格 (3層)
    for (int step = 1; step <= 3; step++) {
      Path path = Path(); double currentR = r * (step / 3);
      for (int i = 0; i < 3; i++) {
        double x = cx + currentR * cos(angles[i]); double y = cy + currentR * sin(angles[i]);
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      path.close(); canvas.drawPath(path, bgPaint);
    }
    // 畫數據
    Path dataPath = Path();
    for (int i = 0; i < 3; i++) {
      double val = stats[labels[i]] ?? 0.1;
      double x = cx + (r * val) * cos(angles[i]); double y = cy + (r * val) * sin(angles[i]);
      if (i == 0) dataPath.moveTo(x, y); else dataPath.lineTo(x, y);
      
      // 畫標籤
      double lx = cx + (r + 15) * cos(angles[i]); double ly = cy + (r + 15) * sin(angles[i]);
      tp.text = TextSpan(text: labels[i], style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold));
      tp.layout(); tp.paint(canvas, Offset(lx - tp.width/2, ly - tp.height/2));
    }
    dataPath.close();
    canvas.drawPath(dataPath, fillPaint); canvas.drawPath(dataPath, linePaint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ==========================================
// 📍 Tab 2: 親友圈 (Family) - 逆向獎勵與關懷
// ==========================================
class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (appState.currentIdentity == UserIdentity.guest) return _buildGuestBlocker(context);

    return Scaffold(
      appBar: AppBar(title: const Text('家人群組與獎勵')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.info_outline, color: Colors.orange), SizedBox(width: 8), Expanded(child: Text('將您的健康點「轉贈」給子孫，或透過邀請連結關懷父母的健康狀況。', style: TextStyle(color: Colors.orange, fontSize: 12)))])),
          const SizedBox(height: 24),
          const Text('我邀請的家人', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _buildFamilyMemberCard(context, '大兒子', '已連線', true),
          _buildFamilyMemberCard(context, '小女兒', '已連線', true),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.person_add), label: const Text('產生邀請連結 (Line/簡訊)')),
          
          const SizedBox(height: 32),
          const Text('邀請我的家人 (長輩)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: ListTile(leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)), title: const Text('爸爸', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('今日已完成 2 項任務'), trailing: TextButton(onPressed: (){}, child: const Text('查看狀態')))),
        ],
      ),
    );
  }

  Widget _buildFamilyMemberCard(BuildContext context, String name, String status, bool canGift) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: canGift ? ElevatedButton.icon(onPressed: () => _showGiftDialog(context, name), icon: const Icon(Icons.card_giftcard, size: 16), label: const Text('轉贈點數'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white)) : null,
      ),
    );
  }

  void _showGiftDialog(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('轉贈健康點給 $name'),
        content: const TextField(decoration: InputDecoration(labelText: '輸入轉贈點數', suffixText: 'Pts', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('取消')), ElevatedButton(onPressed: () { Navigator.pop(c); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('成功轉贈給 $name！'))); }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE65100), foregroundColor: Colors.white), child: const Text('確認轉贈'))],
      )
    );
  }

  Widget _buildGuestBlocker(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock_outline, size: 64, color: Colors.grey), const SizedBox(height: 16), const Text('註冊會員解鎖家人群組'), ElevatedButton(onPressed: (){}, child: const Text('立即註冊'))]));
}

// ==========================================
// 📍 Tab 3: 探索任務庫 (Play) - Webview 遊戲入口
// ==========================================
class PlayPage extends StatelessWidget {
  const PlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('探索任務庫')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)), child: const Text('💡 每次完成遊戲，皆可獲得健康點數，並有機會解鎖品牌專屬贊助折價券！', style: TextStyle(color: Colors.blue, fontSize: 12))),
          const SizedBox(height: 24),
          const Text('腦動力特訓館', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8),
          _buildGameCard('眼力極限考驗', '訓練專注力與反應', Icons.center_focus_strong, Colors.orange, 'https://chrysyehddim-pm.github.io/memory/'),
          _buildGameCard('生活記憶力訓練', '短期記憶防護', Icons.psychology, Colors.teal, 'https://chrysyehddim-pm.github.io/memory/'),
          
          const SizedBox(height: 24),
          const Text('行動力挑戰館', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8),
          _buildGameCard('金幣深蹲王', 'AI 鏡頭體感判定', Icons.accessibility_new, Colors.purple, 'https://chrysyehddim-pm.github.io/Squat-Game-PoC/'),
          
          const SizedBox(height: 24),
          const Text('防護力檢測站', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8),
          _buildGameCard('幸福柑仔店 - AD8', '極早期失智症趣味篩檢', Icons.storefront, Colors.blue, 'https://chrysyehddim-pm.github.io/ad8test/'),
        ],
      ),
    );
  }

  Widget _buildGameCard(String title, String sub, IconData icon, Color color, String url) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 28)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), subtitle: Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: ElevatedButton(onPressed: () => _launchUrl(url), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white, elevation: 0), child: const Text('開始')),
      ),
    );
  }
}

// ==========================================
// 📍 Tab 4: 權益票匣 (Rewards) - 經濟閉環
// ==========================================
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (appState.currentIdentity == UserIdentity.guest) return _buildGuestBlocker();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('權益票匣'), bottom: const TabBar(labelColor: Color(0xFFE65100), indicatorColor: Color(0xFFE65100), tabs: [Tab(text: '兌換中心'), Tab(text: '我的票匣')])),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('可用健康點', style: TextStyle(fontWeight: FontWeight.bold)), Text('${appState.healthPoints} Pts', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFE65100)))])),
                const SizedBox(height: 24), const Text('點數兌換', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 12),
                _buildExchangeItem(context, 'HAPPY GO 10 點', 300), _buildExchangeItem(context, '全家 Let\'s Café 中杯拿鐵', 1500),
              ],
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('AI 專屬推薦與贊助', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)), const SizedBox(height: 12),
                Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.orange)), child: ListTile(leading: const Icon(Icons.medication, color: Colors.orange), title: const Text('大樹藥局 葡萄糖胺 \$50 折價券', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('期限：本月底'), trailing: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), child: const Text('使用')))),
                Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.green)), child: ListTile(leading: const Icon(Icons.shield, color: Colors.green), title: const Text('南山人壽 外溢保單 10% 減免', style: TextStyle(fontWeight: FontWeight.bold)), subtitle: const Text('達標專屬'), trailing: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), child: const Text('使用')))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildExchangeItem(BuildContext context, String title, int cost) {
    bool canAfford = appState.healthPoints >= cost;
    return Card(
      margin: const EdgeInsets.only(bottom: 8), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('$cost Pts', style: const TextStyle(color: Color(0xFFE65100))), trailing: ElevatedButton(onPressed: canAfford ? () {} : null, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white), child: const Text('兌換'))),
    );
  }
  Widget _buildGuestBlocker() => Scaffold(appBar: AppBar(title: const Text('權益票匣')), body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.lock_outline, size: 64, color: Colors.grey), const SizedBox(height: 16), const Text('註冊會員開始兌換獎品'), ElevatedButton(onPressed: (){}, child: const Text('立即註冊'))])));
}

// ==========================================
// 📍 Tab 5: 我的 (Profile) - 帳號與設定
// ==========================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isBound = appState.currentIdentity == UserIdentity.hgBoundUser;
    
    return Scaffold(
      appBar: AppBar(title: const Text('會員中心')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(leading: const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)), title: Text(appState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)), subtitle: Text(appState.title)),
          const SizedBox(height: 24),
          
          if (!isBound && appState.currentIdentity != UserIdentity.guest) ...[
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.warning_amber, color: Colors.red), SizedBox(width: 8), Text('尚未綁定 HAPPY GO 帳號', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]), const SizedBox(height: 8), const Text('綁定後即可同步您的健康積分，並兌換豐富實體商品！', style: TextStyle(fontSize: 12)), const SizedBox(height: 12), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: (){}, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('立即綁定 (HG SSO)')))])),
            const SizedBox(height: 24),
          ],

          const Text('帳號與設定', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          Card(margin: const EdgeInsets.only(top: 8, bottom: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)), child: Column(children: [
            ListTile(leading: const Icon(Icons.history), title: const Text('歷史紀錄總覽'), trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: (){}), const Divider(height: 1), 
            ListTile(leading: const Icon(Icons.verified_user), title: const Text('隱私權與授權設定'), subtitle: const Text('個人化推薦授權'), trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: (){}),
          ])),
          
          const Divider(),
          ListTile(leading: const Icon(Icons.headset_mic), title: const Text('客服中心'), trailing: const Icon(Icons.arrow_forward_ios, size: 14), onTap: (){}),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('登出帳號', style: TextStyle(color: Colors.red)), onTap: (){}),
        ],
      ),
    );
  }
}