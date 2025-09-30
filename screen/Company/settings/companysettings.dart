import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../login_signup_app/login_in_and_sign_up.dart';
import '../../user/chat/chat_list_page.dart';
import '../chat/company_chat_list.dart';
import '../company_home_page.dart';
import 'company_change_password.dart';
import 'company_notificatin.dart';
import 'company_privacy_policy.dart';
import 'company_requests_page.dart';
import 'ownerprofile.dart';

class CompanySettings extends StatefulWidget {
  const CompanySettings({super.key});

  @override
  State<CompanySettings> createState() => _CompanySettingsState();
}

class _CompanySettingsState extends State<CompanySettings> {
  static const primaryColor = Color(0xff22577A);

  bool _isCompany = false;

  final List<Map<String, dynamic>> _baseSettings = const [
    {"title": "Profile", "icon": Icons.person},
    {"title": "Change Password", "icon": Icons.lock_reset},
    {"title": "Privacy Policy", "icon": Icons.privacy_tip},
  ];

  @override
  void initState() {
    super.initState();
    _checkIfCompany();
  }

  Future<void> _checkIfCompany() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('companies')
        .doc(user.uid)
        .get();
    if (mounted) setState(() => _isCompany = snap.exists);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // لو الحساب شركة، أضف عناصر الشركة قبل Log Out
    final settings = [
      ..._baseSettings,
      if (_isCompany) {
        "title": "Requests",
        "icon": Icons.shopping_bag_outlined
      },
      if (_isCompany) {
        "title": "Notifications",
        "icon": Icons.notifications_active_outlined
      },
      // داخل settings list عند الشركة
      if (_isCompany) {"title": "Chats", "icon": Icons.forum_outlined},

      {"title": "Log Out", "icon": Icons.logout}, // ⬅️ آخر عنصر دائمًا
    ];

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.grid_view, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CompanyHomePage()),
                );
              },
            ),
            SizedBox(width: size.width * 0.1),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: size.width * 0.05,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Mobile view
              return ListView.separated(
                padding: EdgeInsets.all(constraints.maxWidth * 0.04),
                itemCount: settings.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: constraints.maxHeight * 0.02),
                itemBuilder: (context, index) {
                  final item = settings[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _handleTap(item["title"] as String),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: constraints.maxHeight * 0.02,
                          horizontal: constraints.maxWidth * 0.04,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: constraints.maxWidth * 0.07,
                              backgroundColor: primaryColor.withOpacity(0.1),
                              child: Icon(
                                item["icon"] as IconData,
                                color: primaryColor,
                                size: constraints.maxWidth * 0.07,
                              ),
                            ),
                            SizedBox(width: constraints.maxWidth * 0.05),
                            Expanded(
                              child: Text(
                                item["title"] as String,
                                style: TextStyle(
                                  fontSize: constraints.maxWidth * 0.045,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 18),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              // Tablet / large screen -> Grid
              return GridView.builder(
                padding: EdgeInsets.all(constraints.maxWidth * 0.05),
                itemCount: settings.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth ~/ 250,
                  crossAxisSpacing: constraints.maxWidth * 0.04,
                  mainAxisSpacing: constraints.maxHeight * 0.03,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final item = settings[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _handleTap(item["title"] as String),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: constraints.maxWidth * 0.05,
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: Icon(
                              item["icon"] as IconData,
                              color: primaryColor,
                              size: constraints.maxWidth * 0.06,
                            ),
                          ),
                          SizedBox(height: constraints.maxHeight * 0.01),
                          Text(
                            item["title"] as String,
                            style: TextStyle(
                              fontSize: constraints.maxWidth * 0.025,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  void _handleTap(String title) {
    switch (title) {
      case "Profile":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OwnerProfile()));
        break;

      case "Change Password":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CompanyChangePassword()));
        break;

      case "Privacy Policy":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const Company_Privacy_Policy()));
        break;

      case "Requests":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CompanyRequestsPage()));
        break;

      case "Notifications":
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CompanyNotificationsPage()));
        break;
      case "Chats":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CompanyChatListPage()),
        );
        break;


      case "Log Out":
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginAndSignUp()),
              (route) => false,
        );
        break;
    }
  }
}
