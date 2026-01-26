import 'dart:async';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  double dataAllocation = 0.00;
  bool DarkMode = true;

  BuildContext? paymentPageContext;
  BuildContext? dialogContext;

  //function area
  String secretKey = "xnd_development_CXoCfwuVDnt67nMnIDpxiyQ4NaaMUBPdFKxwTH4mAYeJRzvrxY3v2H5Q0k2hl";

  Future<void> payNow(BuildContext context,int price, double gb) async{
    dialogContext = context;
    showCupertinoDialog(context: context, builder: (context){
      return CupertinoAlertDialog(
        title: Text("Waiting for the Payment Page"),
        content: CupertinoActivityIndicator(),
      );
    });

    String auth = 'Basic ' + base64Encode(utf8.encode(secretKey));
    final url = "https://api.xendit.co/v2/invoices/";
    final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization" : auth,
          "Content-Type" : "application/json"
        },
        body: jsonEncode({
          "external_id" : "invoice_example",
          "amount" : price
        })
    );
    final data = jsonDecode(response.body);
    String id = data['id'];
    String invoice_url = data['invoice_url'];
    print(invoice_url);

    Navigator.push(context, CupertinoPageRoute(builder: (context) {
      paymentPageContext = context;
      return PaymentPage(url: invoice_url);
    }));
    PaymentStatus(auth, url, id, gb);
  }

  Future<void> PaymentStatus(String auth, String url, String id, double gb) async {
    Timer.periodic(Duration(seconds: 4), (timer) async{
      final response = await http.get(
          Uri.parse(url + id),
          headers: {
            "Authorization" : auth
          }
      );
      final data = jsonDecode(response.body);
      print(data['status']);
      if (data['status'] == "PAID") {
        timer.cancel();

        Future.delayed(Duration(seconds: 4), () {
          if (paymentPageContext != null) {
            Navigator.pop(paymentPageContext!);
            paymentPageContext = null;
          }

          if (dialogContext != null) {
            Navigator.pop(dialogContext!);
            dialogContext = null;
          }
        });

        setState(() {
          dataAllocation = dataAllocation + gb;
        });
      }
    });
  }

  // about member
  void showAboutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text("Our Group Members"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text("Caparas, Jerold"),
              Text("De Leon, Jessa Dianne"),
              Text("Gonzales, Marknel"),
              Text("Mallari, Mark Aj"),
              Text("Montoya, Irish"),
              Text("Mungcal, Arby"),
              Text("Taguchi, Tomoyuki"),
              Text("Tungol, Ariel")
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text("Close"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // Custom App Bar Widget
  Widget customAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Title on left
          Text(
            "TopUp",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemBlue,
            ),
          ),
          // Valorant Logo on right
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: CupertinoColors.systemGrey6,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/val.png', // Make sure you have this image in assets
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //widget area
  Widget promos(BuildContext context, price, String gb, ){
    return GestureDetector(
      onTap: (){
        print("$price, $gb");
        payNow(context,int.parse(price), double.parse(gb));
      },
      child: Container(
        margin: EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
            border: Border.all(
                color: CupertinoColors.systemBlue
            ),
            borderRadius: BorderRadius.circular(10)
        ),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("$gb VP", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Image.asset(
              'assets/images/vp.png',
              width: 50,
              height: 50,
            ),
            SizedBox(height: 8),
            Text("From", style: TextStyle(fontSize: 16)),
            Text("₱ $price", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget tiles(dynamic trailing,IconData icon, String title, Color color,){
    return CupertinoListTile(
      trailing: trailing,
      leading: Container(
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: color
        ),
        child: Icon(icon, color: CupertinoColors.white, size: 19,),
      ),
      title: Text(title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
          brightness: DarkMode? Brightness.dark : Brightness.light
      ),
      home: CupertinoTabScaffold(tabBar: CupertinoTabBar(items: [
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.profile_circled), label: "Profile"),
        BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings), label: "Settings")
      ]), tabBuilder: (context, index){
        switch (index){
          case 0: // Home tab
            return CupertinoPageScaffold(
              child: ListView(
                children: [
                  customAppBar(),
                  SizedBox(height: 30),

                  // VP Balance Card (New Design)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(15),

                      border: Border.all(
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Total VP Balance",
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "${dataAllocation.toStringAsFixed(2)} VP",
                          style: TextStyle(
                            color: CupertinoColors.systemBlue,
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Select Recharge Header (New Design)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select Recharge",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "See All",
                          style: TextStyle(
                            color: CupertinoColors.systemBlue,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 20),

                  // Promos in 2-column layout (using your existing promos function)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // First Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: 5),
                                child: promos(context, "199", "475"),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(left: 5),
                                child: promos(context, "399", "1000"),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        // Second Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: 5),
                                child: promos(context, "799", "2050"),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(left: 5),
                                child: promos(context, "1399", "3650"),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        // Third Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: 5),
                                child: promos(context, "1999", "5390"),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.only(left: 5),
                                child: promos(context, "3999", "11000"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),
                ],
              ),
            );

          case 1: // Profile tab
            return CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(
                middle: Text("Profile"),
              ),
              child: ListView(
                children: [
                  SizedBox(height: 40),
                  // Profile icon
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: CupertinoColors.systemBlue,
                      ),
                      child: Icon(
                        CupertinoIcons.profile_circled,
                        size: 50,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  // Moved profile text here
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 40),

                        Text(
                          "Profile Information",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),

                        SizedBox(height: 30),

                        // GAME NAME
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CupertinoColors.systemBlue),
                          ),
                          padding: EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text("GAME NAME",
                                  style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                              SizedBox(height: 6),
                              Text("Ariel",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),

                        // TAGLINE
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CupertinoColors.systemBlue),
                          ),
                          padding: EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text("TAGLINE",
                                  style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                              SizedBox(height: 6),
                              Text("#73621",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),

                        // PHONE
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CupertinoColors.systemBlue),
                          ),
                          padding: EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text("PHONE",
                                  style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                              SizedBox(height: 6),
                              Text(
                                "+63 923 5678 231",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,

                                ),
                              ),
                            ],
                          ),
                        ),

                        // MEMBER SINCE
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CupertinoColors.systemBlue),
                          ),
                          padding: EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text("MEMBER SINCE",
                                  style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey)),
                              SizedBox(height: 6),
                              Text("January 2024",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
                  )

                ],
              ),
            );

          default: // Settings tab (case 2)
            return CupertinoPageScaffold(
              child: ListView(
                children: [

                  SizedBox(height: 20),
                  CupertinoListSection.insetGrouped(
                    children: [
                      tiles(CupertinoSwitch(value: DarkMode, onChanged: (value){
                        setState(() {
                          DarkMode = !DarkMode;
                        });
                      }),
                          (CupertinoIcons.moon_fill),
                          "Dark Mode",
                          CupertinoColors.systemPurple
                      ),
                      CupertinoListTile(
                        trailing: Icon(CupertinoIcons.chevron_forward),
                        leading: Container(
                          padding: EdgeInsets.all(5),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: CupertinoColors.systemBlue
                          ),
                          child: Icon(CupertinoIcons.info, color: CupertinoColors.white, size: 19),
                        ),
                        title: Text("About"),
                        onTap: () {
                          showAboutDialog(context);
                        },
                      ),
                    ],
                  )
                ],
              ),
            );
        }
      }),
    );
  }
}

class PaymentPage extends StatefulWidget {
  final String url;
  const PaymentPage({super.key, required this.url});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController();
    controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text("Payment"),
        ),
        child: WebViewWidget(controller: controller));
  }
}