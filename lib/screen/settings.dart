import 'package:flutter/material.dart';

import '../modle/modsettings.dart';
import 'homePage.dart';

class settings extends StatefulWidget {
  const settings({super.key});

  @override
  State<settings> createState() => _settingsState();
}

class _settingsState extends State<settings> {
  List<modsettings> mod = [
    modsettings(Title: 'profile', img: 'images/profile.png'),
    modsettings(Title: 'Change Password', img: 'images/change_password.png'),
    modsettings(Title: 'Privacy Policy', img: 'images/privacy_policy.png'),
    modsettings(Title: 'Save', img: 'images/Save.png'),
    modsettings(Title: 'Log Out', img: 'images/Logout.png'),
    modsettings(Title: 'Notification', img: 'images/Notification.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xff22577A),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const homePage()),
                );
              },
            ),
            SizedBox(width: size.width * 0.1),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const settings()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Padding(
          padding: EdgeInsets.all(size.width * 0.02),
          child: Row(
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: size.width * 0.05,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    radius: size.width * 0.06,
                    child: Image.asset(
                      mod[index].img,
                      height: size.width * 0.1,
                      width: size.width * 0.1,
                    ),
                  ),
                  title: Text(
                    mod[index].Title,
                    style: TextStyle(fontSize: size.width * 0.04),
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return SizedBox(height: size.height * 0.03);
              },
              itemCount: mod.length,
            ),
          ],
        ),
      ),
    );
  }
}