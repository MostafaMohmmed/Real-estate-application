// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final _db = FirebaseFirestore.instance;

  // خليها public لو بتحتاج توليد الـ id خارجياً
  static String pairId(String a, String b) =>
      (a.compareTo(b) <= 0) ? '${a}__${b}' : '${b}__${a}';

  /// ينشئ/يحدّث الشات بدون أي قراءة مسبقة (لمنع permission-denied)
  static Future<String> getOrCreateChat({
    required String userUid,
    required String companyUid,
    String? initialMessage,
    Map<String, dynamic>? meta,
  }) async {
    final chatId  = pairId(userUid, companyUid);
    final chatRef = _db.collection('chats').doc(chatId);

    // اكتب مباشرة (create/merge) — لا get()
    await chatRef.set({
      'members': [userUid, companyUid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastAt': FieldValue.serverTimestamp(),
      if (initialMessage != null && initialMessage.isNotEmpty)
        'lastMessage': initialMessage,
      if (meta != null) 'meta': meta,
      'unread': {
        userUid: 0,
        companyUid: 0,
      },
    }, SetOptions(merge: true));

    // أضف رسالة البداية (اختياري)
    if (initialMessage != null && initialMessage.isNotEmpty) {
      final msgRef = chatRef.collection('messages').doc();
      await msgRef.set({
        'text': initialMessage,
        'senderId': companyUid, // الشركة ترسل الترحيب
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      // حدّث آخر رسالة/وقت
      await chatRef.set({
        'lastMessage': initialMessage,
        'lastAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return chatId;
  }
}
