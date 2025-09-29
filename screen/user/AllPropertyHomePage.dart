import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'propertdetalis.dart'; // تأكد من المسار الصحيح

class AllPropertyHomePage extends StatelessWidget {
  const AllPropertyHomePage({super.key});

  // ------- Helpers -------
  Uint8List? _bytes(dynamic raw) {
    if (raw == null) return null;
    if (raw is Blob) return raw.bytes;
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    return null;
  }

  List<String> _list(dynamic v) {
    if (v == null) return const [];
    if (v is Iterable) return v.map((e) => e.toString()).toList();
    if (v is String && v.trim().isNotEmpty) {
      return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  String _fmtPrice(dynamic value) {
    if (value is num) {
      final s = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
      return '\$$s';
    }
    final s = (value ?? '').toString();
    if (s.isEmpty) return '-';
    return s.startsWith('\$') ? s : '\$$s';
  }

  num _numOrZero(dynamic v) => (v is num) ? v : 0;
  // -----------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final double imgH = size.width * 0.38; // ارتفاع الصورة
    const double infoH = 112;              // نصوص + مزايا
    final double listH = imgH + infoH + 20;

    final stream = FirebaseFirestore.instance
        .collectionGroup('properties')
        .limit(12)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(
            height: 140,
            child: Center(child: Text('حدث خطأ أثناء التحميل')),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox(
            height: 140,
            child: Center(child: Text('لا توجد بيانات')),
          );
        }

        final count = min(8, docs.length);

        return SizedBox(
          height: listH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
            itemCount: count,
            separatorBuilder: (_, __) => SizedBox(width: size.width * 0.03),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data();

              // استخرج companyId / propId / path من الـ collectionGroup
              final companyId = doc.reference.parent.parent!.id;
              final propId = doc.id;
              final propertyPath = 'companies/$companyId/properties/$propId';

              // حقول أساسية
              final title       = (data['title'] ?? '').toString();
              final priceRaw    = data['price'];
              final type        = (data['type'] ?? '').toString();
              final location    = (data['location'] ?? '').toString();

              // أرقام المزايا
              final areaSqftNum = _numOrZero(data['areaSqft']);
              final bedsNum     = _numOrZero(data['beds']);
              final bathsNum    = _numOrZero(data['baths']);

              // قوائم للتفاصيل
              final amenities    = _list(data['amenities']);
              final interior     = _list(data['interior']);
              final construction = _list(data['construction']);

              // صور
              final imageUrl  = (data['imageUrl'] ?? '').toString();
              final imageBlob = _bytes(data['imageBlob']);

              // المالك (اختياري)
              final ownerName = (data['ownerName'] ?? 'Company').toString();
              final ownerImg  = (data['ownerImageUrl'] ?? '').toString();
              // ownerUid بناخذه من المسار نفسه (companyId)

              Widget image;
              if (imageBlob != null) {
                image = Image.memory(
                  imageBlob,
                  width: double.infinity,
                  height: imgH,
                  fit: BoxFit.cover,
                );
              } else if (imageUrl.isNotEmpty) {
                image = Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: imgH,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(imgH),
                );
              } else {
                image = _placeholder(imgH);
              }

              return InkWell(
                onTap: () {
                  // نمرّر المسار والـ companyId عشان صفحة التفاصيل وحفظ الطلبات
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Propertdetalis(
                        imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                        imageBytes: imageBlob,
                        title: title.isEmpty ? 'Apartment' : title,
                        price: _fmtPrice(priceRaw),
                        location: location,
                        type: type,
                        areaSqft: areaSqftNum.toDouble(),
                        beds: bedsNum.toInt(),
                        baths: bathsNum.toInt(),
                        ownerName: ownerName,
                        ownerImageUrl: ownerImg.isNotEmpty ? ownerImg : null,
                        ownerUid: companyId,            // ✅ مهم
                        propertyDocPath: propertyPath,  // ✅ مهم
                        amenities: amenities,
                        interior: interior,
                        construction: construction,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: size.width * 0.55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(10), // ✅ تأكد من وجود "padding:"
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: imgH,
                            width: double.infinity,
                            child: image,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title.isEmpty ? 'Apartment' : title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: (size.width * 0.040).clamp(13.0, 18.0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _fmtPrice(priceRaw),
                              style: TextStyle(
                                color: const Color(0xFF4A43EC),
                                fontWeight: FontWeight.w800,
                                fontSize: (size.width * 0.035).clamp(12.0, 16.0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: (size.width * 0.030).clamp(11.0, 14.0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                type,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              _IconText(icon: Icons.square_foot, text: '${areaSqftNum > 0 ? areaSqftNum : 0} sqft'),
                              const SizedBox(width: 12),
                              _IconText(icon: Icons.bed,         text: '${bedsNum > 0 ? bedsNum : 0}'),
                              const SizedBox(width: 12),
                              _IconText(icon: Icons.shower,      text: '${bathsNum > 0 ? bathsNum : 0}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _placeholder(double h) => Container(
    width: double.infinity,
    height: h,
    color: Colors.grey[300],
    child: const Center(child: Icon(Icons.image_not_supported)),
  );
}

class _IconText extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFEA8734)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}
