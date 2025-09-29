import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../user/chat/chat_screen.dart';

class CompanyChatListPage extends StatelessWidget {
  const CompanyChatListPage({super.key});

  String get _companyUid => FirebaseAuth.instance.currentUser!.uid;

  Query _q() => FirebaseFirestore.instance
      .collection('chats')
      .where('members', arrayContains: _companyUid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _q().snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Error loading chats'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          final sorted = docs.toList()
            ..sort((a, b) {
              final am = _m(a.data());
              final bm = _m(b.data());
              return _ts(bm['lastAt']).compareTo(_ts(am['lastAt']));
            });

          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final doc = sorted[i];
              final d = _m(doc.data());

              // meta قد تكون مفقودة في مستندات قديمة — خليك آمن
              final meta = _m(d['meta']);
              final title = (meta['title'] ?? d['title'] ?? 'Chat').toString();

              final lastMsg = (d['lastMessage'] ?? '').toString();
              final lastAt  = _ts(d['lastAt']);

              // عداد الرسائل غير المقروءة على الشركة (اختياري)
              final unreadForCompany = meta['unread'] is Map
                  ? ((meta['unread'] as Map)[_companyUid] ?? 0)
                  : 0;

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.chat_bubble)),
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  lastMsg.isEmpty ? 'No messages yet' : lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_fmtTime(lastAt), style: const TextStyle(fontSize: 11)),
                    if (unreadForCompany is num && unreadForCompany > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadForCompany.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
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
      ),
    );
  }

  // ============== helpers ==============
  static Map<String, dynamic> _m(Object? v) {
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return <String, dynamic>{};
  }

  static DateTime _ts(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      final p = DateTime.tryParse(v);
      if (p != null) return p;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _fmtTime(DateTime dt) {
    if (dt.millisecondsSinceEpoch == 0) return '';
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) {
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return '${dt.month}/${dt.day}';
  }
}
