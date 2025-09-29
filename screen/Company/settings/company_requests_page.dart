import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'company_request_details.dart';

class CompanyRequestsPage extends StatefulWidget {
  const CompanyRequestsPage({super.key});
  @override
  State<CompanyRequestsPage> createState() => _CompanyRequestsPageState();
}

class _CompanyRequestsPageState extends State<CompanyRequestsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tc = TabController(length: 3, vsync: this);

  String get _companyId => FirebaseAuth.instance.currentUser!.uid;

  // ⬇️ بدون orderBy — سنرتّب محلياً في UI
  Query<Map<String, dynamic>> _q(String status) {
    return FirebaseFirestore.instance
        .collection('companies').doc(_companyId)
        .collection('purchaseRequests')
        .where('status', isEqualTo: status); // pending / accepted / rejected
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Requests'),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        bottom: TabBar(
          controller: _tc,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Accepted'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: [
          _RequestsList(q: _q('pending')),
          _RequestsList(q: _q('accepted')),
          _RequestsList(q: _q('rejected')),
        ],
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  const _RequestsList({required this.q});
  final Query<Map<String, dynamic>> q;

  DateTime _dt(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return const Center(child: Text('Failed to load'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        // ⬇️ نرتب محلياً بالأحدث أولاً
        final docs = snap.data!.docs.toList()
          ..sort((a, b) => _dt(b.data()['createdAt']).compareTo(_dt(a.data()['createdAt'])));

        if (docs.isEmpty) return const Center(child: Text('No requests here'));

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final title  = (d['title'] ?? '').toString();
            final buyer  = (d['buyerName'] ?? d['userName'] ?? '').toString();
            final price  = (d['priceLabel'] ?? '').toString();
            final note   = (d['note'] ?? '').toString();
            final status = (d['status'] ?? 'pending').toString();

            return ListTile(
              title: Text(
                title.isEmpty ? 'Property' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$buyer • $price\n$note',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: _StatusChip(status: status),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyRequestDetails(req: docs[i]),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color c;
    switch (status) {
      case 'accepted':
        c = Colors.green;
        break;
      case 'rejected':
        c = Colors.red;
        break;
      default:
        c = Colors.orange;
    }
    return Chip(
      label: Text(status),
      backgroundColor: c.withOpacity(.15),
      labelStyle: TextStyle(color: c, fontWeight: FontWeight.w700),
    );
  }
}
