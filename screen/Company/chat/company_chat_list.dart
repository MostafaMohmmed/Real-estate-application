// lib/screen/Company/chat/company_chat_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../user/chat/chat_screen.dart';

class CompanyChatListPage extends StatelessWidget {
  const CompanyChatListPage({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Query _q() => FirebaseFirestore.instance
      .collection('chats')
      .where('members', arrayContains: _uid);

  // كاش بسيط لنتائج البروفايل حسب uid
  static final Map<String, Map<String, String>> _profileCache = {};

  Future<Map<String, String>> _fallbackLoadProfile(String otherId) async {
    if (otherId.isEmpty) return const {'name': '—', 'phone': '—'};
    if (_profileCache[otherId] != null) return _profileCache[otherId]!;

    final db = FirebaseFirestore.instance;

    // الشركات ترى المستخدم، فنجرب users أولاً ثم companies احتياطًا
    var snap = await db.collection('users').doc(otherId).get();
    if (!snap.exists) snap = await db.collection('companies').doc(otherId).get();

    String name = '—', phone = '—';
    if (snap.exists) {
      final d = snap.data() ?? {};
      name  = (d['fullName'] ?? d['name'] ?? d['companyName'] ?? '—').toString();
      phone = (d['phone'] ?? d['phoneNumber'] ?? '—').toString();
    }
    return _profileCache[otherId] = {'name': name, 'phone': phone};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _q().snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Error loading chats'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No chats yet'));

          final sorted = docs.toList()
            ..sort((a, b) {
              final am = _map(a.data());
              final bm = _map(b.data());
              return _ts(bm['lastAt']).compareTo(_ts(am['lastAt']));
            });

          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final doc = sorted[i];
              final d = _map(doc.data());
              final members = _listOfString(d['members']);
              final otherId = members.firstWhere((m) => m != _uid, orElse: () => '');
              final meta = _map(d['meta']);
              final lastAt = _ts(d['lastAt']);
              final lastMsg = (d['lastMessage'] ?? '').toString();

              // المعنى هنا: الشركة تشاهد المستخدم.
              // إن كانت الميتاداتا موجودة نعتمد عليها أولاً:
              String title = '—', sub = '—';
              final metaUserUid    = (meta['userUid'] ?? '').toString();
              final metaCompanyUid = (meta['companyUid'] ?? '').toString();

              if (metaUserUid.isNotEmpty && metaCompanyUid.isNotEmpty) {
                final iAmCompany = (_uid == metaCompanyUid);
                if (iAmCompany) {
                  // الشركة ترى بيانات المستخدم
                  title = (meta['userName'] ?? '—').toString();
                  sub   = (meta['userPhone'] ?? '—').toString();
                } else {
                  // لو فتحها المستخدم بالخطأ، تبقى آمنة
                  title = (meta['companyName'] ?? '—').toString();
                  sub   = (meta['companyPhone'] ?? '—').toString();
                }
              }

              return FutureBuilder<Map<String, String>>(
                future: (title != '—' || sub != '—')
                    ? Future.value({'name': title, 'phone': sub})
                    : _fallbackLoadProfile(otherId),
                builder: (context, prof) {
                  final name  = (prof.data?['name']  ?? '—');
                  final phone = (prof.data?['phone'] ?? '—');

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.chat_bubble)),
                    title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      phone.isEmpty ? '—' : phone,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_fmtTime(lastAt), style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChatScreen(chatId: doc.id)),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // helpers
  static Map<String, dynamic> _map(Object? v) =>
      v is Map ? v.map((k, val) => MapEntry(k.toString(), val)) : <String, dynamic>{};

  static List<String> _listOfString(Object? v) =>
      v is Iterable ? v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList() : const <String>[];

  static DateTime _ts(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    final p = (v is String) ? DateTime.tryParse(v) : null;
    return p ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _fmtTime(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '';
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return '${dt.month}/${dt.day}';
  }
}
