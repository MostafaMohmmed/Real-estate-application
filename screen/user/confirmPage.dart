import 'dart:typed_data';
import 'package:flutter/material.dart';

class ConfirmPage extends StatelessWidget {
  const ConfirmPage({
    super.key,
    // الصور
    this.imageUrl,
    this.imageBytes,

    // معلومات أساسية
    required this.title,

    // السعر: ادعم الحالتين
    this.price,         // نص جاهز (مثلاً "$120,000") — الحقل اللي إنت عم تمرّره الآن
    this.priceLabel,    // بديل لنفس الغرض (لو كنت بتمرّره من صفحات أخرى)
    this.priceValue,    // رقم خام لو بدك تستخدمه لاحقًا لحسابات

    this.location,

    // مراجع اختيارية لتسجيل الطلب لاحقًا
    this.companyId,     // companies/{companyId}/properties/{propId}
    this.propId,
  });

  // الصور
  final String? imageUrl;
  final Uint8List? imageBytes;

  // معلومات أساسية
  final String title;

  // السعر
  final String? price;       // ما تمرّره حالياً من Propertdetalis
  final String? priceLabel;  // بديل اختياري
  final num?   priceValue;   // قيمة رقمية اختيارية

  final String? location;

  // مراجع اختيارية
  final String? companyId;
  final String? propId;

  Widget _mainImage() {
    if (imageBytes != null) {
      return Image.memory(imageBytes!, fit: BoxFit.cover);
    }
    if ((imageUrl ?? '').isNotEmpty) {
      return Image.network(imageUrl!, fit: BoxFit.cover);
    }
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.image, size: 40, color: Colors.white70),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // اختر النص المعروض للسعر
    final displayPrice = priceLabel ?? price ?? '-';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Purchase the property',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(aspectRatio: 16 / 9, child: _mainImage()),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if ((location ?? '').isNotEmpty)
                    Text(location!, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 10),
                  Text(
                    displayPrice,
                    style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(
                    width: 260,
                    child: Text(
                      'Please review the details, then confirm to send your purchase request to the company.',
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () async {
                // لاحقاً: سجل الطلب في Firestore باستخدام companyId/propId و priceValue (إن وجدت)
                // مثال لاحق: _submitRequest(...)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request submitted (placeholder).')),
                );
                Navigator.pop(context);
              },
              child: const Text('Confirm / Request', style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
