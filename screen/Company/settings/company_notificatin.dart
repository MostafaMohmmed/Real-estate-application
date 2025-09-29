import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'company_request_details.dart';

class CompanyNotificationsPage extends StatefulWidget {
  const CompanyNotificationsPage({super.key});

  @override
  State<CompanyNotificationsPage> createState() => _CompanyNotificationsPageState();
}

class _CompanyNotificationsPageState extends State<CompanyNotificationsPage> {
  String get _companyId => FirebaseAuth.instance.currentUser!.uid;

  Query<Map<String, dynamic>> get _q => FirebaseFirestore.instance
      .collection('companies').doc(_companyId)
      .collection('notifications')
      .orderBy('createdAt', descending: true);

  Future<void> _markAllRead(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (docs.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    for (final d in docs) {
      if ((d.data()['isRead'] ?? false) != true) {
        batch.update(d.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  Future<void> _clearAll(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (docs.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This will delete all notifications for this company.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear all')),
        ],
      ),
    );
    if (ok != true) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final d in docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All cleared')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'),backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _q.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Error loading notifications'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          final unread = docs.where((d) => (d.data()['isRead'] ?? false) != true).length;

          if (docs.isEmpty) {
            return Column(
              children: [
                _Toolbar(
                  unreadCount: 0,
                  onMarkAll: null,
                  onClearAll: null,
                ),
                const Expanded(child: Center(child: Text('No notifications'))),
              ],
            );
          }

          return Column(
            children: [
              // شريط علوي داخل الصفحة: العداد + الأزرار
              _Toolbar(
                unreadCount: unread,
                onMarkAll: () => _markAllRead(docs),
                onClearAll: () => _clearAll(docs),
              ),

              const Divider(height: 0),

              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final d = doc.data();
                    final title = (d['title'] ?? '').toString();
                    final body  = (d['body'] ?? '').toString();
                    final isRead= d['isRead'] == true;
                    final reqId = (d['reqId'] ?? '').toString();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isRead ? Colors.grey.shade200 : const Color(0xFFEDE7F6),
                        child: Icon(Icons.local_offer_outlined,
                            color: isRead ? Colors.grey : Colors.deepPurple),
                      ),
                      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                      trailing: isRead
                          ? null
                          : const Icon(Icons.fiber_new, color: Colors.red, size: 18),
                      onTap: () async {
                        // علّمها مقروءة وافتح الطلب المرتبط (نفس السلوك السابق)
                        final batch = FirebaseFirestore.instance.batch();
                        batch.update(doc.reference, {'isRead': true});
                        await batch.commit();

                        if (reqId.isNotEmpty) {
                          final reqSnap = await FirebaseFirestore.instance
                              .collection('companies').doc(_companyId)
                              .collection('purchaseRequests').doc(reqId).get();
                          if (reqSnap.exists && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CompanyRequestDetails(req: reqSnap),
                              ),
                            );
                          }
                        }
                      },
                      onLongPress: () async {
                        // ضغط مطوّل: تبديل read/unread بسرعة
                        await doc.reference.update({'isRead': !isRead});
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.unreadCount,
    required this.onMarkAll,
    required this.onClearAll,
  });

  final int unreadCount;
  final VoidCallback? onMarkAll;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    final hasItems = onMarkAll != null && onClearAll != null;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            // عدّاد غير المقروء
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, size: 16, color: Colors.deepPurple),
                  const SizedBox(width: 6),
                  Text(
                    '$unreadCount unread',
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Mark all as read
            TextButton.icon(
              onPressed: hasItems ? onMarkAll : null,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all'),
            ),
            const SizedBox(width: 6),
            // Clear all
            TextButton.icon(
              onPressed: hasItems ? onClearAll : null,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear all'),
            ),
          ],
        ),
      ),
    );
  }
}
