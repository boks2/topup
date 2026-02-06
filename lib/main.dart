import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Icons;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("database");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box("database");

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box box, widget) {
        bool isDark = box.get("isDark") ?? true;

        return CupertinoApp(
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primaryColor: CupertinoColors.systemBlue,
          ),
          home: (box.get("username") == null) ? const Signup() : const Homepage(),
        );
      },
    );
  }
}

// ==========================================
// LOGIN PAGE (With Reset Data)
// ==========================================
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final LocalAuthentication auth = LocalAuthentication();
  final box = Hive.box("database");
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  Future<void> authenticate() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to show account balance',
        biometricOnly: true,
      );
      if (didAuthenticate) {
        if (!mounted) return;
        Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => const MainStoreApp()));
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.person_crop_circle_fill, size: 80, color: CupertinoColors.systemBlue),
                  const SizedBox(height: 20),
                  const Text("Welcome Back", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
                  const SizedBox(height: 30),
                  CupertinoTextField(controller: _username, placeholder: "Username", padding: const EdgeInsets.all(15)),
                  const SizedBox(height: 15),
                  CupertinoTextField(controller: _password, placeholder: "Password", obscureText: true, padding: const EdgeInsets.all(15)),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      child: const Text('Login'),
                      onPressed: () {
                        if (_username.text.trim() == box.get("username") && _password.text.trim() == box.get("password")) {
                          Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => const MainStoreApp()));
                        } else {
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text("Error"),
                              content: const Text("Invalid account details"),
                              actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(context))],
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  if (box.get("biometrics") ?? false)
                    CupertinoButton(
                        child: const Icon(Icons.fingerprint, size: 60, color: CupertinoColors.systemBlue),
                        onPressed: authenticate
                    ),

                  const SizedBox(height: 20),

                  // RESET DATA BUTTON (Nasa Login Screen na)
                  CupertinoButton(
                    child: const Text("Reset App Data", style: TextStyle(color: CupertinoColors.destructiveRed, fontSize: 14)),
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text("Reset Everything?"),
                          content: const Text("This will delete your account and balance permanently."),
                          actions: [
                            CupertinoDialogAction(
                                child: const Text("Cancel"),
                                onPressed: () => Navigator.pop(context)
                            ),
                            CupertinoDialogAction(
                              isDestructiveAction: true,
                              child: const Text("Reset"),
                              onPressed: () {
                                box.clear();
                                Navigator.pushAndRemoveUntil(context, CupertinoPageRoute(builder: (context) => const Signup()), (r) => false);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SIGNUP PAGE
// ==========================================
class Signup extends StatefulWidget {
  const Signup({super.key});
  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final box = Hive.box("database");
  final TextEditingController _u = TextEditingController();
  final TextEditingController _p = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Create Account", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Join TopUp Valorant Store", style: TextStyle(color: CupertinoColors.systemGrey)),
            const SizedBox(height: 30),
            CupertinoTextField(controller: _u, placeholder: "Username", padding: const EdgeInsets.all(15)),
            const SizedBox(height: 15),
            CupertinoTextField(controller: _p, placeholder: "Password", obscureText: true, padding: const EdgeInsets.all(15)),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                child: const Text("Signup"),
                onPressed: () {
                  if (_u.text.isNotEmpty && _p.text.isNotEmpty) {
                    box.put("username", _u.text.trim());
                    box.put("password", _p.text.trim());
                    box.put("biometrics", false);
                    box.put("isDark", true);
                    box.put("balance", 0.0);
                    Navigator.pushReplacement(context, CupertinoPageRoute(builder: (context) => const Homepage()));
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// MAIN STORE APP (Dashboard)
// ==========================================
class MainStoreApp extends StatefulWidget {
  const MainStoreApp({super.key});

  @override
  State<MainStoreApp> createState() => _MainStoreAppState();
}

class _MainStoreAppState extends State<MainStoreApp> {
  final box = Hive.box("database");
  final String secretKey = "xnd_development_CXoCfwuVDnt67nMnIDpxiyQ4NaaMUBPdFKxwTH4mAYeJRzvrxY3v2H5Q0k2hl";

  Future<void> payNow(BuildContext context, int price, double vpAmount) async {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CupertinoAlertDialog(
        title: Text("Connecting..."),
        content: CupertinoActivityIndicator(),
      ),
    );

    try {
      String auth = 'Basic ${base64Encode(utf8.encode("$secretKey:"))}';
      final response = await http.post(
        Uri.parse("https://api.xendit.co/v2/invoices/"),
        headers: {"Authorization": auth, "Content-Type": "application/json"},
        body: jsonEncode({
          "external_id": "inv_${DateTime.now().millisecondsSinceEpoch}",
          "amount": price,
          "currency": "PHP"
        }),
      );

      final data = jsonDecode(response.body);
      String id = data['id'];
      String invoiceUrl = data['invoice_url'];

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(context, CupertinoPageRoute(builder: (context) => PaymentPage(url: invoiceUrl)));

      _startStatusCheck(auth, id, vpAmount);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint("Payment Error: $e");
    }
  }

  void _startStatusCheck(String auth, String id, double vpAmount) {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final response = await http.get(Uri.parse("https://api.xendit.co/v2/invoices/$id"), headers: {"Authorization": auth});
        final data = jsonDecode(response.body);

        if (data["status"] == "PAID") {
          timer.cancel();
          double currentBal = box.get("balance") ?? 0.0;
          box.put("balance", currentBal + vpAmount);

          if (mounted) {
            Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
          }
        }
      } catch (e) {
        debugPrint("Check Error: $e");
      }
    });
  }

  void showAboutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Our Group Members"),
        content: const Text("\nCaparas, Jerold\nDe Leon, Jessa Dianne\nGonzales, Marknel\nMallari, Mark Aj\nMontoya, Irish\nMungcal, Arby\nTaguchi, Tomoyuki\nTungol, Ariel"),
        actions: [CupertinoDialogAction(child: const Text("Close"), onPressed: () => Navigator.pop(context))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box box, _) {
        double balance = box.get("balance") ?? 0.0;
        bool isDark = box.get("isDark") ?? true;

        return CupertinoTabScaffold(
          tabBar: CupertinoTabBar(items: const [
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.profile_circled), label: "Profile"),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: "Settings")
          ]),
          tabBuilder: (context, index) {
            switch (index) {
              case 0: return _buildHome(balance);
              case 1: return _buildProfile();
              case 2: return _buildSettings(isDark);
              default: return const SizedBox();
            }
          },
        );
      },
    );
  }

  Widget _buildHome(double balance) {
    return CupertinoPageScaffold(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 40),
          const Text("Valorant Store", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CupertinoColors.systemBlue)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text("Total VP Balance", style: TextStyle(color: Colors.white70)),
                Text("${balance.toStringAsFixed(0)} VP", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text("Select Recharge", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
            children: [
              _promoCard("199", "475"),
              _promoCard("399", "1000"),
              _promoCard("799", "2050"),
              _promoCard("1399", "3650"),
              _promoCard("1999", "5390"),
              _promoCard("3999", "11000"),
            ],
          )
        ],
      ),
    );
  }

  Widget _promoCard(String price, String vp) {
    return GestureDetector(
      onTap: () => payNow(context, int.parse(price), double.parse(vp)),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
          color: box.get("isDark") ? CupertinoColors.darkBackgroundGray : CupertinoColors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("$vp VP", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Icon(CupertinoIcons.bolt_fill, color: CupertinoColors.systemYellow, size: 35),
            const SizedBox(height: 10),
            Text("₱$price", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.systemBlue)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Profile")),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.person_alt_circle, size: 100, color: CupertinoColors.systemBlue),
            const SizedBox(height: 20),
            Text(box.get("username") ?? "User", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Member Since 2024", style: TextStyle(color: CupertinoColors.systemGrey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(bool isDark) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Settings")),
      child: ListView(
        children: [
          CupertinoListSection.insetGrouped(
            children: [
              CupertinoListTile(
                title: const Text("Dark Mode"),
                leading: const Icon(CupertinoIcons.moon_fill, color: Colors.indigo),
                trailing: CupertinoSwitch(value: isDark, onChanged: (v) => box.put("isDark", v)),
              ),
              CupertinoListTile(
                title: const Text("Fingerprint Login"),
                leading: const Icon(Icons.fingerprint, color: Colors.purple),
                trailing: CupertinoSwitch(value: box.get("biometrics") ?? false, onChanged: (v) => box.put("biometrics", v)),
              ),
              CupertinoListTile(
                title: const Text("About Us"),
                leading: const Icon(CupertinoIcons.info, color: Colors.blue),
                onTap: () => showAboutDialog(context),
              ),
              // LOGOUT WITH CONFIRMATION
              CupertinoListTile(
                title: const Text("Log Out"),
                leading: const Icon(CupertinoIcons.square_arrow_right, color: Colors.red),
                onTap: () {
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text("Log Out"),
                      content: const Text("Are you sure?"),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          child: const Text("Log Out"),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                                context,
                                CupertinoPageRoute(builder: (context) => const Homepage()),
                                    (route) => false
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}

class PaymentPage extends StatelessWidget {
  final String url;
  const PaymentPage({super.key, required this.url});
  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text("Xendit Payment")),
      child: SafeArea(child: WebViewWidget(controller: controller)),
    );
  }
}