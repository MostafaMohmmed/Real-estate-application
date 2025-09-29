import 'package:flutter/material.dart';
import 'package:final_iug_2025/screen/user/settings/changepassword.dart';
import 'package:final_iug_2025/screen/user/settings/privacy_policy.dart';
import 'package:final_iug_2025/screen/user/settings/userprofile.dart';
import 'package:final_iug_2025/screen/user/homePage.dart';
import 'package:final_iug_2025/screen/login_signup_app/login_in_and_sign_up.dart';

// 👇 أضِف استيراد صفحة قائمة المحادثات (عدّل المسار لو مختلف)

import '../chat/chat_list_page.dart';
import 'notification.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _CompanySettingsState();
}

class _CompanySettingsState extends State<SettingsPage> {
  // أضفت "Chats" قبل Notification، وخليت Log Out آخر عنصر
  final List<Map<String, dynamic>> settings = const [
    {"title": "Profile", "icon": Icons.person},
    {"title": "Change Password", "icon": Icons.lock_reset},
    {"title": "Privacy Policy", "icon": Icons.privacy_tip},
    {"title": "Chats", "icon": Icons.chat_bubble_outline},       // 👈 جديد
    {"title": "Notification", "icon": Icons.notifications},
    {"title": "Log Out", "icon": Icons.logout},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xff22577A);

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
                  MaterialPageRoute(builder: (context) => const homePage()),
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
              // موبايل -> قائمة
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
              // تابلت/شاشة كبيرة -> Grid
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserProfile()),
        );
        break;

      case "Change Password":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChangePassword()),
        );
        break;

      case "Privacy Policy":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Privacy_Policy()),
        );
        break;

      case "Chats": // 👈 فتح قائمة المحادثات
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatListPage()),
        );
        break;

      case "Notification":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsPage()),
        );
        break;

      case "Log Out":
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginAndSignUp()),
              (Route<dynamic> route) => false,
        );
        break;
    }
  }
}
