import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  Future<void> _approve({
    required BuildContext context,
    required String requestId,
    required String companyUid,
    required String planType, // '5'|'15'|'30'|'unlimited'
  }) async {
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();

      final companyRef = db.collection('companies').doc(companyUid);
      final reqRef = db.collection('plan_requests').doc(requestId);

      final isUnlimited = planType == 'unlimited';
      final int quota = isUnlimited ? 0 : int.tryParse(planType) ?? 0;

      batch.set(companyRef, {
        'planStatus': 'active',
        'planType'  : planType,
        'unlimited' : isUnlimited,
        'quotaRemaining': isUnlimited ? 0 : quota,
        'updatedAt' : FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.update(reqRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approved & activated')),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.code}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _reject({
    required BuildContext context,
    required String requestId,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('plan_requests')
          .doc(requestId)
          .update({'status': 'rejected', 'rejectedAt': FieldValue.serverTimestamp()});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rejected')),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.code}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('plan_requests').orderBy('createdAt', descending: true).snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No requests'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = docs[i].data()! as Map<String, dynamic>;
              final id = docs[i].id;
              final companyUid = (d['companyUid'] ?? '').toString();
              final companyName = (d['companyName'] ?? companyUid).toString();
              final companyEmail = (d['companyEmail'] ?? '').toString();
              final planType = (d['planType'] ?? '').toString();
              final status = (d['status'] ?? 'pending').toString();

              return ListTile(
                title: Text('$companyName ($planType)'),
                subtitle: Text('$companyEmail  •  status: $status'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: status == 'approved'
                          ? null
                          : () => _approve(
                        context: context,
                        requestId: id,
                        companyUid: companyUid,
                        planType: planType,
                      ),
                      child: const Text('Approve'),
                    ),
                    TextButton(
                      onPressed: status == 'rejected'
                          ? null
                          : () => _reject(context: context, requestId: id),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
