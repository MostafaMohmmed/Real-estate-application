import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId});
  final String chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _txt = TextEditingController();
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _msgs =>
      FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages');

  @override
  void dispose() {
    _txt.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _txt.text.trim();
    if (text.isEmpty) return;
    _txt.clear();

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    await _msgs.add({
      'senderId': _uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'lastMessage': text,
      'lastAt': FieldValue.serverTimestamp(),
      // عدّاد unread للطرف الآخر (اختياري تبسيطيًا ما حسبناه هنا)
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final stream = _msgs.orderBy('createdAt', descending: true).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Say hi 👋'));
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final isMe = d['senderId'] == _uid;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF4A43EC).withOpacity(.1) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(d['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                    child: TextField(
                      controller: _txt,
                      decoration: const InputDecoration(
                        hintText: 'Type a message…',
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        filled: true,
                      ),
                    ),
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
