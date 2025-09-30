// فقط استبدل النسخة عندك بهذه (أو أضف السطرين المعلّمين)
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String pairId(String a, String b) =>
      (a.compareTo(b) <= 0) ? '${a}__${b}' : '${b}__${a}';

  static Future<String> getOrCreateChat({
    required String userUid,
    required String companyUid,
    String? userName,
    String? userPhone,
    String? companyName,
    String? companyPhone,
    String? initialMessage,
    Map<String, dynamic>? meta,
  }) async {
    final chatId  = pairId(userUid, companyUid);
    final chatRef = _db.collection('chats').doc(chatId);

    final Map<String, dynamic> metaToSave = {
      if (meta != null) ...meta,
      // 👇 مهم: خزّن هويّات الطرفين
      'userUid': userUid,
      'companyUid': companyUid,

      if (userName != null && userName.isNotEmpty) 'userName': userName,
      if (userPhone != null && userPhone.isNotEmpty) 'userPhone': userPhone,
      if (companyName != null && companyName.isNotEmpty) 'companyName': companyName,
      if (companyPhone != null && companyPhone.isNotEmpty) 'companyPhone': companyPhone,
    };

    await chatRef.set({
      'members': [userUid, companyUid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastAt': FieldValue.serverTimestamp(),
      if (initialMessage != null && initialMessage.isNotEmpty)
        'lastMessage': initialMessage,
      if (metaToSave.isNotEmpty) 'meta': metaToSave,
      'unread': { userUid: 0, companyUid: 0 },
    }, SetOptions(merge: true));

    if (initialMessage != null && initialMessage.isNotEmpty) {
      await chatRef.collection('messages').add({
        'text': initialMessage,
        'senderId': companyUid,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'text',
      });
      await chatRef.set({
        'lastMessage': initialMessage,
        'lastAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    return chatId;
  }
}
