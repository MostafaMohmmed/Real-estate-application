// lib/screen/chat/chat_list_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Query _q() => FirebaseFirestore.instance
      .collection('chats')
      .where('members', arrayContains: _uid);

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

          // ترتيب محلي بالأحدث
          final sorted = docs.toList()
            ..sort((a, b) {
              final am = _map(a.data());
              final bm = _map(b.data());
              final at = _ts(am['lastAt']);
              final bt = _ts(bm['lastAt']);
              return bt.compareTo(at);
            });

          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (context, i) {
              final doc = sorted[i];
              final d = _map(doc.data());

              // members: ممكن تكون List<dynamic>
              final members = _listOfString(d['members']);
              final otherId =
              members.firstWhere((m) => m != _uid, orElse: () => '');

              // meta: لازم Map لكن نتأكد
              final meta = _map(d['meta']);
              final title = (meta['title'] ?? d['title'] ?? 'Chat').toString();

              final lastMsg = (d['lastMessage'] ?? '').toString();
              final lastAt = _ts(d['lastAt']);
              final unread = meta['unread'] is Map
                  ? ((meta['unread'] as Map)[_uid] ?? 0)
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
                    Text(_fmtTime(lastAt),
                        style: const TextStyle(fontSize: 11)),
                    if (unread is num && unread > 0) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(chatId: doc.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ================= helpers =================

  /// يحوّل أي كائن إلى Map<String,dynamic> إن أمكن، وإلا يرجّع {}
  static Map<String, dynamic> _map(Object? v) {
    if (v is Map) {
      // نحاول تحويل المفاتيح لسلاسل (غالبًا هي أصلًا سلاسل)
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return <String, dynamic>{};
  }

  /// يحوّل أي Iterable إلى List<String>
  static List<String> _listOfString(Object? v) {
    if (v is Iterable) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    return const <String>[];
  }

  static DateTime _ts(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      // لو محفوظ كنص ISO
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
