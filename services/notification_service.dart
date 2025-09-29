import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final _db = FirebaseFirestore.instance;

  /// (عربي) اكتب إشعار تحت:
  ///   {collection}/{uid}/notifications/{autoId}
  /// حيث collection = 'users' أو 'companies'
  static Future<DocumentReference<Map<String, dynamic>>> add({
    required String uid,
    String collection = 'users', // أو 'companies'
    required String title,
    required String body,
    required String type,        // Account / Security / Listings / Deals / Messages ..
    String? action,              // مثال: 'open_listing'
    String? relatedId,           // مثال: listingId أو bookingId
    String? deepLink,            // مثال: app://listing/123
    int priority = 0,            // 0=normal, 1=high (للترتيب أو الفلترة)
    Map<String, dynamic>? extra, // أي حقول إضافية مستقبلًا
  }) async {
    final ref = _db
        .collection(collection)
        .doc(uid)
        .collection('notifications')
        .doc();

    final data = <String, dynamic>{
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'priority': priority,
      'action': action,
      'relatedId': relatedId,
      'deepLink': deepLink,
      'createdAt': FieldValue.serverTimestamp(),
      if (extra != null) ...extra,
    };

    await ref.set(data);
    return ref; // (عربي) نرجّع المرجع لو بدك تستخدم الـ id لاحقًا
  }

  // ========= (عربي) مُساعِدات جاهزة لأحداث الـ Auth (users) =========
  static Future<DocumentReference<Map<String, dynamic>>> onSignUp(String uid) =>
      add(
        uid: uid,
        collection: 'users',
        title: 'Welcome to your account',
        body: 'Your sign up is complete. Explore listings now.',
        type: 'Account',
      );

  static Future<DocumentReference<Map<String, dynamic>>> onSignIn(String uid) =>
      add(
        uid: uid,
        collection: 'users',
        title: 'Signed in successfully',
        body: 'You are now signed in.',
        type: 'Account',
      );

  static Future<DocumentReference<Map<String, dynamic>>> onGoogleSignIn(String uid) =>
      add(
        uid: uid,
        collection: 'users',
        title: 'Signed in with Google',
        body: 'Google sign-in completed.',
        type: 'Account',
      );

  static Future<DocumentReference<Map<String, dynamic>>> onPasswordUpdated(String uid) =>
      add(
        uid: uid,
        collection: 'users',
        title: 'Password updated',
        body: 'Your password has been changed.',
        type: 'Security',
      );

  static Future<DocumentReference<Map<String, dynamic>>> onResetEmailSent(String uid) =>
      add(
        uid: uid,
        collection: 'users',
        title: 'Reset link sent',
        body: 'We sent a reset link to your email.',
        type: 'Security',
      );

  // ========= (عربي) نُسخ للشركات (اختياري إن احتجتها) =========
  static Future<DocumentReference<Map<String, dynamic>>> onCompanySignIn(String uid) =>
      add(
        uid: uid,
        collection: 'companies',
        title: 'Signed in',
        body: 'Welcome back to your company dashboard.',
        type: 'Account',
      );

  static Future<DocumentReference<Map<String, dynamic>>> newLeadForCompany({
    required String companyUid,
    required String listingId,
  }) =>
      add(
        uid: companyUid,
        collection: 'companies',
        title: 'New lead',
        body: 'You have a new message on your listing.',
        type: 'Messages',
        action: 'open_listing',
        relatedId: listingId,
        priority: 1,
      );
}
