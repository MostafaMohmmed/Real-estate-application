// lib/screen/Company/company_request_details.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// تأكد من المسارات لديك
import '../../../services/chat_service.dart';
import '../../user/chat/chat_screen.dart';

class CompanyRequestDetails extends StatefulWidget {
  const CompanyRequestDetails({super.key, required this.req});
  final DocumentSnapshot<Map<String, dynamic>> req;

  @override
  State<CompanyRequestDetails> createState() => _CompanyRequestDetailsState();
}

class _CompanyRequestDetailsState extends State<CompanyRequestDetails> {
  bool _busy = false;
  String get _companyId => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _acceptOrReject({
    required String desiredStatus,
    required Map<String, dynamic> d,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final reqId    = (d['requestId'] ?? widget.req.id).toString();
      final buyerUid = (d['buyerUid'] ?? d['userUid'] ?? '').toString();
      final propId   = (d['propId'] ?? '').toString();
      final title    = (d['title'] ?? '').toString();

      final db  = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();

      // 1) تحديث نسخة الشركة (مضمون الصلاحيات)
      await widget.req.reference.set({
        'status': desiredStatus,
        'updatedAt': now,
      }, SetOptions(merge: true));

      // 2) تحديث الجدول المركزي (اختياري؛ نتجاهل أي permission-denied)
      try {
        await db.collection('purchaseRequests').doc(reqId).set({
          'status': desiredStatus,
          'updatedAt': now,
          'companyId': _companyId, // يجعل القواعد أسهل لاحقًا
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('central set ignored: $e');
      }

      // 3) إن كانت Accepted: أنشئ/استرجع الشات وافتحه
      if (desiredStatus == 'accepted' && buyerUid.isNotEmpty) {
        final welcome =
            'Hello! Your request for "$title" was accepted. You can chat with us here for the next steps.';

        final chatId = await ChatService.getOrCreateChat(
          userUid: buyerUid,
          companyUid: _companyId,
          initialMessage: welcome,
          meta: {
            'reqId': reqId,
            'propId': propId,
            'title': title,
            'acceptedAt': now,
          },
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)),
        );
        return;
      }

      // 4) إن كانت Rejected
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openChat(Map<String, dynamic> d) async {
    // يُستخدم عندما تكون الحالة already accepted لفتح الشات مباشرة
    final buyerUid = (d['buyerUid'] ?? d['userUid'] ?? '').toString();
    if (buyerUid.isEmpty) return;

    setState(() => _busy = true);
    try {
      final chatId = await ChatService.getOrCreateChat(
        userUid: buyerUid,
        companyUid: _companyId,
        // بدون رسالة ترحيب؛ فقط تأكد من وجود الشات
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(chatId: chatId)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // نعرض نسخة الشركة كبث حي — الأزرار تتحدث تلقائيًا
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: widget.req.reference.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final d        = snap.data!.data() ?? {};
        final title    = (d['title'] ?? '').toString();
        final buyer    = (d['buyerName'] ?? d['userName'] ?? '').toString();
        final phone    = (d['buyerPhone'] ?? d['userPhone'] ?? '').toString();
        final note     = (d['note'] ?? '').toString();
        final priceLbl = (d['priceLabel'] ?? '').toString();
        final status   = (d['status'] ?? 'pending').toString();

        final isPending  = status == 'pending';
        final isAccepted = status == 'accepted';

        return Scaffold(
          appBar: AppBar(title: const Text('Request details')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: Text(
                  title.isEmpty ? 'Property' : title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(priceLbl),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.person),
                title: Text(buyer.isEmpty ? '-' : buyer),
                subtitle: Text(phone.isEmpty ? '—' : phone),
              ),
              if (note.isNotEmpty) ...[
                const Divider(),
                const Text('Note', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(note),
              ],
              const SizedBox(height: 20),

              // أزرار الحالة
              if (isPending) Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _acceptOrReject(
                        desiredStatus: 'accepted',
                        d: d,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _acceptOrReject(
                        desiredStatus: 'rejected',
                        d: d,
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ),
                ],
              ),

              // إن كانت مقبولة مسبقًا: زر فتح الشات مباشرة
              if (!isPending && isAccepted) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _busy ? null : () => _openChat(d),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Open chat'),
                ),
              ],

              const SizedBox(height: 10),
              Text(
                'Current status: $status',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }
}
