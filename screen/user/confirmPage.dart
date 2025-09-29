import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ConfirmPage extends StatefulWidget {
  const ConfirmPage({
    super.key,
    this.imageUrl,
    this.imageBytes,
    required this.title,
    required this.location,
    this.priceLabel,
    this.priceValue,
    this.companyId,
    this.propId,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;

  final String title;
  final String location;

  final String? priceLabel; // مثل: "$120,000"
  final num? priceValue;    // القيمة الرقمية (اختياري)

  final String? companyId;  // companies/{companyId}
  final String? propId;     // companies/{companyId}/properties/{propId}

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Widget _mainImage() {
    if (widget.imageBytes != null) return Image.memory(widget.imageBytes!, fit: BoxFit.cover);
    if ((widget.imageUrl ?? '').isNotEmpty) return Image.network(widget.imageUrl!, fit: BoxFit.cover);
    return Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 36, color: Colors.white70));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    final companyId = widget.companyId;
    final propId = widget.propId;

    setState(() => _submitting = true);
    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final now = FieldValue.serverTimestamp();

      // (1) سجل عام
      final reqRef = db.collection('purchaseRequests').doc();
      final reqId = reqRef.id;

      batch.set(reqRef, {
        'requestId': reqId,
        'userUid': user.uid,
        'userName': _name.text.trim(),
        'userPhone': _phone.text.trim(),
        'note': _note.text.trim(),
        'title': widget.title,
        'location': widget.location,
        'priceLabel': widget.priceLabel ?? '',
        'priceValue': widget.priceValue,
        'companyId': companyId ?? '',
        'propId': propId ?? '',
        'propertyPath': (companyId != null && propId != null)
            ? 'companies/$companyId/properties/$propId'
            : '',
        'status': 'pending',
        'createdAt': now,
      });

      // (2) تحت المستخدم
      final userReqRef = db
          .collection('users').doc(user.uid)
          .collection('purchaseRequests').doc(reqId);

      batch.set(userReqRef, {
        'requestId': reqId,
        'title': widget.title,
        'location': widget.location,
        'priceLabel': widget.priceLabel ?? '',
        'priceValue': widget.priceValue,
        'companyId': companyId ?? '',
        'propId': propId ?? '',
        'status': 'pending',
        'createdAt': now,
      });

      // (3) داخل حساب الشركة + إشعار
      if (companyId != null && companyId.isNotEmpty) {
        final companyReqRef = db
            .collection('companies').doc(companyId)
            .collection('purchaseRequests').doc(reqId);

        batch.set(companyReqRef, {
          'requestId': reqId,
          'buyerUid': user.uid,
          'buyerName': _name.text.trim(),
          'buyerPhone': _phone.text.trim(),
          'note': _note.text.trim(),
          'title': widget.title,
          'location': widget.location,
          'priceLabel': widget.priceLabel ?? '',
          'priceValue': widget.priceValue,
          'propId': propId ?? '',
          'status': 'pending',
          'createdAt': now,
        });

        final companyNotifRef = db
            .collection('companies').doc(companyId)
            .collection('notifications').doc();

        batch.set(companyNotifRef, {
          'title': 'New purchase request',
          'body': '${_name.text.trim()} requested to purchase "${widget.title}".',
          'type': 'Deals',
          'isRead': false,
          'createdAt': now,
          'propId': propId ?? '',
          'reqId': reqId,
          'buyerUid': user.uid,
        });
      }

      // (4) إشعار للمستخدم
      final userNotifRef = db
          .collection('users').doc(user.uid)
          .collection('notifications').doc();

      batch.set(userNotifRef, {
        'title': 'Request sent',
        'body': 'Your request for "${widget.title}" was sent to the company.',
        'type': 'Deals',
        'isRead': false,
        'createdAt': now,
        'propId': propId ?? '',
        'reqId': reqId,
        'companyId': companyId ?? '',
      });

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted successfully.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Purchase the property',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // بطاقة العقار
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(aspectRatio: 16 / 9, child: _mainImage())),
                const SizedBox(height: 14),
                Text(widget.title, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (widget.location.isNotEmpty)
                  Text(widget.location, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 10),
                if ((widget.priceLabel ?? '').isNotEmpty)
                  Text(widget.priceLabel!, style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // نموذج
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Your full name', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Note (optional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A43EC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirm Purchase', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
