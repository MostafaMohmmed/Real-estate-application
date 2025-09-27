import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const typeAll = 'All';
  static const typeAccount = 'Account';
  static const typeSecurity = 'Security';
  static const typeListings = 'Listings';
  static const typeDeals = 'Deals';
  static const typeMessages = 'Messages';

  String _activeFilter = typeAll;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<int> _unreadCountStream(String uid) {
    return _db
        .collection('users').doc(uid).collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  Query<Map<String, dynamic>> _baseQuery(String uid) {
    final ref = _db.collection('users').doc(uid).collection('notifications');
    final q = (_activeFilter == typeAll)
        ? ref
        : ref.where('type', isEqualTo: _activeFilter);
    return q.orderBy('createdAt', descending: true);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _notificationsStream(String uid) {
    return _baseQuery(uid).snapshots();
  }

  Future<void> _markAllRead(String uid) async {
    final q = await _db
        .collection('users').doc(uid).collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _clearAll(String uid) async {
    final q = await _db
        .collection('users').doc(uid).collection('notifications')
        .get();
    final batch = _db.batch();
    for (final d in q.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }

  IconData _iconFor(String type) {
    switch (type) {
      case typeAccount:
        return Icons.account_circle_outlined;
      case typeSecurity:
        return Icons.verified_user_outlined;
      case typeListings:
        return Icons.home_work_outlined;
      case typeDeals:
        return Icons.local_offer_outlined;
      case typeMessages:
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none;
    }
  }

  String _timeLabel(Timestamp? ts) {
    if (ts == null) return '';
    final t = ts.toDate();
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view notifications')),
      );
    }
    final uid = user.uid;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xff22577A),
        child: const Icon(Icons.grid_view, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            const SizedBox(width: 40),
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          StreamBuilder<int>(
            stream: _unreadCountStream(uid),
            builder: (context, snap) {
              final unread = snap.data ?? 0;
              return Stack(
                children: [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.notifications, color: Colors.black),
                    onSelected: (v) {
                      if (v == 'mark_all') _markAllRead(uid);
                      if (v == 'clear_all') _clearAll(uid);
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'mark_all', child: Text('Mark all as read')),
                      PopupMenuItem(value: 'clear_all', child: Text('Clear all')),
                    ],
                  ),
                  if (unread > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _FilterChip(
                  label: typeAll,
                  active: _activeFilter == typeAll,
                  onTap: () => setState(() => _activeFilter = typeAll),
                ),
                _FilterChip(
                  label: typeAccount,
                  active: _activeFilter == typeAccount,
                  onTap: () => setState(() => _activeFilter = typeAccount),
                ),
                _FilterChip(
                  label: typeSecurity,
                  active: _activeFilter == typeSecurity,
                  onTap: () => setState(() => _activeFilter = typeSecurity),
                ),
                _FilterChip(
                  label: typeListings,
                  active: _activeFilter == typeListings,
                  onTap: () => setState(() => _activeFilter = typeListings),
                ),
                _FilterChip(
                  label: typeDeals,
                  active: _activeFilter == typeDeals,
                  onTap: () => setState(() => _activeFilter = typeDeals),
                ),
                _FilterChip(
                  label: typeMessages,
                  active: _activeFilter == typeMessages,
                  onTap: () => setState(() => _activeFilter = typeMessages),
                ),
              ],
            ),
          ),
          const Divider(height: 16, thickness: 0.6),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _notificationsStream(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No notifications yet'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final d = docs[index];
                    final data = d.data();
                    final title = (data['title'] ?? '') as String;
                    final body  = (data['body'] ?? '') as String;
                    final type  = (data['type'] ?? '') as String;
                    final isRead = (data['isRead'] ?? false) as bool;
                    final createdAt = data['createdAt'] as Timestamp?;

                    return Dismissible(
                      key: ValueKey(d.id),
                      background: _SwipeBackground(
                        icon: Icons.done_all,
                        color: Colors.green.shade600,
                        text: 'Mark as read',
                        alignLeft: true,
                      ),
                      secondaryBackground: _SwipeBackground(
                        icon: Icons.delete,
                        color: Colors.red.shade600,
                        text: 'Delete',
                        alignLeft: false,
                      ),
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          await d.reference.update({'isRead': true});
                          return false;
                        } else {
                          await d.reference.delete();
                          return true;
                        }
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isRead
                              ? Colors.grey.shade300
                              : const Color(0xff22577A),
                          child: Icon(_iconFor(type), color: Colors.white),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _timeLabel(createdAt),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          body,
                          style: const TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        onTap: () async {
                          if (!isRead) {
                            await d.reference.update({'isRead': true});
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xff22577A);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(
          color: active ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: color,
        backgroundColor: Colors.grey.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool alignLeft;
  const _SwipeBackground({
    required this.icon,
    required this.color,
    required this.text,
    required this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (!alignLeft) const Spacer(),
        const SizedBox(width: 16),
        Icon(icon, color: Colors.white),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white)),
        const SizedBox(width: 16),
        if (alignLeft) const Spacer(),
      ],
    );
    return Container(color: color, child: child);
  }
}
