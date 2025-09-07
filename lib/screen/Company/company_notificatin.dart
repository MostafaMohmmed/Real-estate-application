import 'package:flutter/material.dart';
// إذا كنت راح تستخدم Firebase Cloud Messaging
// import 'package:firebase_messaging/firebase_messaging.dart';
// وإذا بدك تجيب من Firestore
// import 'package:cloud_firestore/cloud_firestore.dart';

import '../../modle/modnotification.dart';

class Company_Notification extends StatefulWidget {
  const Company_Notification({super.key});

  @override
  State<Company_Notification> createState() => _notificationState();
}

class _notificationState extends State<Company_Notification> {
  List<modnotification> mod = [
    modnotification(img: '', title: 'New offer available', suptitle: 'Check out our latest discounts!'),
    modnotification(img: '', title: 'Booking confirmed', suptitle: 'Your booking has been successfully confirmed.'),
  ];

  int unreadCount = 0;

  @override
  void initState() {
    super.initState();

    /// 🔹 إذا كنت تستعمل Firebase Messaging (FCM)
    /// هون ممكن تعمل Subscribe لموضوع معين (topic) أو تستقبل إشعارات جديدة
    ///
    /// FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    ///   setState(() {
    ///     unreadCount++;  // كل ما يوصلك إشعار جديد يزيد العداد
    ///     mod.insert(0, modnotification(
    ///       img: '',
    ///       title: message.notification?.title ?? 'New Notification',
    ///       suptitle: message.notification?.body ?? '',
    ///     ));
    ///   });
    /// });
    ///
    /// 🔹 إذا كنت تستعمل Firestore
    /// ممكن تجيب عدد الإشعارات الغير مقروءة مباشرة من قاعدة البيانات:
    ///
    /// FirebaseFirestore.instance.collection('notifications')
    ///   .where('isRead', isEqualTo: false)
    ///   .snapshots()
    ///   .listen((snapshot) {
    ///     setState(() {
    ///       unreadCount = snapshot.docs.length;
    ///     });
    ///   });
  }

  @override
  Widget build(BuildContext context) {
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
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
        ),
      ),
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: const [
              Text(
                'Notifications',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.black),
                onPressed: () {
                  /// عند الضغط على الأيقونة → تصفير العداد (اعتبار الكل مقروء)
                  setState(() {
                    unreadCount = 0;
                  });
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
            ],
          )
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: mod.length,
        separatorBuilder: (context, index) => const SizedBox(height: 15),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.notifications, color: Colors.white),
            ),
            title: Text(
              mod[index].title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              mod[index].suptitle,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          );
        },
      ),
    );
  }
}
/*   📌 الشرح باختصار:
مع FCM (Firebase Cloud Messaging):

تستعمل FirebaseMessaging.onMessage.listen عشان تسمع أي إشعار جديد.

كل إشعار جديد → زيد unreadCount++ وأضفه للقائمة.

مع Firestore:

اعمل where('isRead', isEqualTo: false) عشان تجيب فقط الإشعارات الغير مقروءة.

snapshot.docs.length بيكون عدد الإشعارات الغير مقروءة → خليه يساوي unreadCount.

عند الضغط على أيقونة الإشعارات → صفّر العداد (unreadCount = 0) أو اعمل تحديث في Firestore (isRead = true).

 */