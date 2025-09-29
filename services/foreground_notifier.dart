import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ForegroundNotifier {
  ForegroundNotifier._();
  static final instance = ForegroundNotifier._();

  final _db = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _activeUid;
  DateTime _lastNotifiedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// يجب استدعاؤها مرة واحدة في main بعد Firebase.initializeApp()
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const init = InitializationSettings(android: android, iOS: ios);
    await _local.initialize(init);

    // قناة افتراضية (Android)
    const channel = AndroidNotificationChannel(
      'default_channel',
      'General',
      importance: Importance.high,
      description: 'Default channel for foreground notifications',
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// ابدأ الاستماع لإشعارات المستخدم، idempotent (لن يكرر الاشتراك)
  Future<void> start(String uid) async {
    if (_activeUid == uid && _sub != null) return; // already started
    await stop(); // نظّف أي اشتراك قديم
    _activeUid = uid;
    _lastNotifiedAt = DateTime.fromMillisecondsSinceEpoch(0);

    _sub = _db
        .collection('users').doc(uid).collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;
        final ts = data['createdAt'];
        if (ts is! Timestamp) continue;
        final created = ts.toDate();

        // إشعار جديد فعليًا (أحدث من آخر واحد شغّلنا له صوت)
        if (created.isAfter(_lastNotifiedAt)) {
          _lastNotifiedAt = created;
          final title = (data['title'] ?? 'New notification').toString();
          final body  = (data['body'] ?? '').toString();

          _local.show(
            change.doc.id.hashCode,
            title,
            body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'default_channel',
                'General',
                priority: Priority.high,
                importance: Importance.high,
                playSound: true,
              ),
              iOS: DarwinNotificationDetails(presentSound: true),
            ),
          );
        }
      }
    });
  }

  /// أوقف الاستماع
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _activeUid = null;
    _lastNotifiedAt = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
