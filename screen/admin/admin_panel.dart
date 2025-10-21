// lib/screen/admin/admin_panel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final db = FirebaseFirestore.instance;
  String _search = '';
  String _filterStatus = 'all';
  bool _globalLoading = false;
  final Map<String, bool> _itemLoading = {};

  Future<void> _approve({
    required BuildContext context,
    required String requestId,
    required String companyUid,
    required String planType,
  }) async {
    setState(() => _itemLoading[requestId] = true);
    try {
      final batch = db.batch();
      final companyRef = db.collection('companies').doc(companyUid);
      final reqRef = db.collection('plan_requests').doc(requestId);

      final isUnlimited = planType == 'unlimited';
      final int quota = isUnlimited ? 0 : int.tryParse(planType) ?? 0;

      batch.set(companyRef, {
        'planStatus': 'active',
        'planType': planType,
        'unlimited': isUnlimited,
        'quotaRemaining': isUnlimited ? 0 : quota,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.update(reqRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('approved_ok'.tr())));
      }
    } finally {
      setState(() => _itemLoading.remove(requestId));
    }
  }

  Future<void> _reject({
    required BuildContext context,
    required String requestId,
  }) async {
    setState(() => _itemLoading[requestId] = true);
    try {
      await db.collection('plan_requests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('rejected_ok'.tr())));
      }
    } finally {
      setState(() => _itemLoading.remove(requestId));
    }
  }

  Future<bool?> _confirmDialog(
      BuildContext ctx, {
        required String title,
        required String body,
        String okLabel = 'Confirm',
      }) {
    return showDialog<bool>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: Text(okLabel.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    IconData icon;
    switch (status) {
      case 'approved':
        bg = Colors.green.shade600;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        bg = Colors.red.shade600;
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        bg = Colors.amber.shade700;
        icon = Icons.hourglass_top;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg.withOpacity(0.6), bg.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            'status_$status'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTypeBadge(String planType, int quota) {
    // تحديد الألوان والأيقونات لكل خطة
    Color startColor;
    Color endColor;
    IconData icon;
    String label = planType.isEmpty
        ? 'Free'.tr()
        : 'plan_type_label'.tr();

    switch (planType.toLowerCase()) {
      case 'unlimited':
        startColor = Colors.purple.shade500;
        endColor = Colors.purple.shade800;
        icon = Icons.all_inclusive;
        break;
      case 'premium':
        startColor = Colors.orange.shade400;
        endColor = Colors.orange.shade700;
        icon = Icons.star;
        break;
      default:
        startColor = Colors.grey.shade400;
        endColor = Colors.grey.shade700;
        icon = Icons.card_membership;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: endColor.withOpacity(0.3),
            offset: const Offset(2, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (planType.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                '$quota',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _prettyDate(Timestamp? t) {
    if (t == null) return '-';
    final dt = t.toDate().toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final queries = db
        .collection('plan_requests')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('panel_title'.tr()),
        actions: [
          IconButton(
            tooltip: 'refresh'.tr(),
            icon: _globalLoading
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: () async {
              setState(() => _globalLoading = true);
              await Future.delayed(const Duration(milliseconds: 400));
              setState(() => _globalLoading = false);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'search_hint'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filterStatus,
                  items: [
                    DropdownMenuItem(value: 'all', child: Text('filter_all'.tr())),
                    DropdownMenuItem(value: 'pending', child: Text('status_pending'.tr())),
                    DropdownMenuItem(value: 'approved', child: Text('status_approved'.tr())),
                    DropdownMenuItem(value: 'rejected', child: Text('status_rejected'.tr())),
                  ],
                  onChanged: (v) => setState(() => _filterStatus = v ?? 'all'),
                  underline: const SizedBox.shrink(),
                )
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: queries,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${'error'.tr()}: ${snap.error}'));
          }

          final docs = snap.data?.docs ?? [];
          final filtered = docs.where((doc) {
            final d = (doc.data()! as Map<String, dynamic>);
            final status = (d['status'] ?? 'pending').toString();
            final planType = (d['planType'] ?? '').toString();
            final name = (d['companyName'] ?? '').toString().toLowerCase();
            final email = (d['companyEmail'] ?? '').toString().toLowerCase();
            if (_filterStatus != 'all' && status != _filterStatus) return false;
            if (_search.isEmpty) return true;
            return name.contains(_search) ||
                email.contains(_search) ||
                planType.contains(_search) ||
                doc.id.contains(_search);
          }).toList();

          if (filtered.isEmpty) {
            return Center(child: Text('no_requests'.tr()));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final doc = filtered[index];
              final d = (doc.data()! as Map<String, dynamic>);
              final id = doc.id;
              final companyUid = (d['companyUid'] ?? '').toString();
              final companyName = (d['companyName'] ?? companyUid).toString();
              final companyEmail = (d['companyEmail'] ?? '').toString();
              final planType = (d['planType'] ?? '').toString();
              final status = (d['status'] ?? 'pending').toString();
              final createdAt = d['createdAt'] as Timestamp?;
              final note = (d['note'] ?? '').toString();
              final int quota = planType == 'unlimited' ? 0 : int.tryParse(planType) ?? 0;

              final loading =
                  _itemLoading.containsKey(id) && _itemLoading[id] == true;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.blue.shade50,
                        child: Text(
                          (companyName.isNotEmpty ? companyName[0].toUpperCase() : '?'),
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Main info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row: name + status
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    companyName,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                _buildStatusChip(status),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Email
                            Text(
                              companyEmail,
                              style: TextStyle(color: Colors.grey.shade800),
                            ),
                            const SizedBox(height: 6),
                            // PlanType & Quota
                            _buildPlanTypeBadge(planType, quota),
                            const SizedBox(height: 8),
                            if (note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  note,
                                  style: TextStyle(color: Colors.grey.shade800),
                                ),
                              ),
                            Text(
                              '${'requested_on'.tr()}: ${_prettyDate(createdAt)}',
                              style:
                              TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Actions
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 100,
                            child: ElevatedButton(
                              onPressed: (status == 'approved' || loading)
                                  ? null
                                  : () async {
                                final ok = await _confirmDialog(
                                  context,
                                  title: 'confirm_approve_title'.tr(),
                                  body: 'confirm_approve_body'
                                      .tr(args: [companyName, planType]),
                                  okLabel: 'approve'.tr(),
                                );
                                if (ok == true) {
                                  await _approve(
                                      context: context,
                                      requestId: id,
                                      companyUid: companyUid,
                                      planType: planType);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                backgroundColor: Colors.green.shade600,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: loading
                                  ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                                  : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'approve'.tr(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 100,
                            child: OutlinedButton(
                              onPressed: (status == 'rejected' || loading)
                                  ? null
                                  : () async {
                                final ok = await _confirmDialog(
                                  context,
                                  title: 'confirm_reject_title'.tr(),
                                  body: 'confirm_reject_body'.tr(args: [companyName]),
                                  okLabel: 'reject'.tr(),
                                );
                                if (ok == true) {
                                  await _reject(context: context, requestId: id);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('reject'.tr()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
