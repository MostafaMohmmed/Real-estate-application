import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _text = TextEditingController();
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _msgs =>
      FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages');

  Future<void> _send() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final t = _text.text.trim();
    if (t.isEmpty) return;

    final now = FieldValue.serverTimestamp();
    await _msgs.add({
      'senderId': user.uid,
      'text': t,
      'type': 'text',
      'createdAt': now,
    });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage': t,
      'lastSender': user.uid,
      'updatedAt'  : now,
    });

    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _msgs.orderBy('createdAt', descending: true).limit(50).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                final myId = _auth.currentUser?.uid;
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final m = docs[i].data();
                    final mine = m['senderId'] == myId;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: mine ? const Color(0xFF4A43EC).withOpacity(.1) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text((m['text'] ?? '').toString()),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
