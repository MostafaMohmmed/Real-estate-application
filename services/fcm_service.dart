// lib/services/fcm_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../screen/user/chat/chat_page.dart';


/// استدعِ هذه بعد ما يسجّل المستخدم (العادي) دخول.
Future<void> initFcmForUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // iOS: طلب الإذن
  await FirebaseMessaging.instance.requestPermission();

  // احفظ التوكن الحالي
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection('users').doc(user.uid)
        .collection('tokens').doc(token).set({
      'createdAt': FieldValue.serverTimestamp(),
      'platform': 'flutter',
    });
  }

  // تحدّث التوكن تلقائيًا
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    await FirebaseFirestore.instance
        .collection('users').doc(u.uid)
        .collection('tokens').doc(newToken).set({
      'createdAt': FieldValue.serverTimestamp(),
      'platform': 'flutter',
    });
  });
}

/// نادِها مرّة مع بداية التطبيق (بعد بناء الـ MaterialApp) لالتقاط ضغط الإشعار وفتح الشات.
void setupMessageHandlers(GlobalKey<NavigatorState> navigatorKey) {
  // كان التطبيق مغلق وانفتح من الإشعار
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message == null) return;
    _handleMessage(message, navigatorKey);
  });

  // التطبيق مفتوح وتم الضغط على الإشعار
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    _handleMessage(message, navigatorKey);
  });
}

void _handleMessage(RemoteMessage message, GlobalKey<NavigatorState> navKey) async {
  final data = message.data;
  if (data['type'] == 'request_status' && data['status'] == 'accepted') {
    final chatId = data['chatId'];
    final reqId  = data['reqId'];
    if (chatId != null && chatId.toString().isNotEmpty) {
      // علّم آخر إشعار لهذا الطلب كمقروء
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && reqId != null) {
        final qs = await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .collection('notifications')
            .where('reqId', isEqualTo: reqId)
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
        if (qs.docs.isNotEmpty) {
          await qs.docs.first.reference.set({'isRead': true}, SetOptions(merge: true));
        }
      }

      navKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ChatPage(chatId: chatId)),
      );
    }
  }
}

