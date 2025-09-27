import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'propertdetalis.dart'; // تأكد من المسار الصحيح

class FeaturedPropertyhomepage extends StatelessWidget {
  final String propertyType; // النوع المطلوب
  const FeaturedPropertyhomepage({super.key, required this.propertyType});

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
      // يدعم "a,b,c"
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

  DateTime _createdAtOf(Map<String, dynamic> d) {
    final ts = d['createdAt'];
    if (ts is Timestamp) return ts.toDate();
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  // -----------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final stream = FirebaseFirestore.instance
        .collectionGroup('properties')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // ignore: avoid_print
          print('Featured error => ${snapshot.error}');
          return const Center(child: Text('An error occurred while downloading'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data?.docs ?? [];
        // فلترة حسب النوع
        docs = docs.where((d) => (d.data()['type'] ?? '') == propertyType).toList();
        // ترتيب محلي بالأجدد أولًا
        docs.sort((a, b) => _createdAtOf(b.data()).compareTo(_createdAtOf(a.data())));
        if (docs.isEmpty) return const Center(child: Text('No data for this species.'));

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
          separatorBuilder: (_, __) => SizedBox(height: size.height * 0.012),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();

            final title    = (data['title'] ?? '').toString();
            final price    = data['price'];
            final type     = (data['type'] ?? '').toString();
            final location = (data['location'] ?? '').toString();

            final areaSqft = (data['areaSqft'] is num) ? (data['areaSqft'] as num) : 0;
            final beds     = (data['beds'] is num) ? (data['beds'] as num) : 0;
            final baths    = (data['baths'] is num) ? (data['baths'] as num) : 0;

            final amenities    = _list(data['amenities']);
            final interior     = _list(data['interior']);
            final construction = _list(data['construction']);

            final ownerName     = (data['ownerName'] ?? 'Company').toString();
            final ownerImageUrl = (data['ownerImageUrl'] ?? '').toString();

            final imageUrl  = (data['imageUrl'] ?? '').toString();
            final imageBlob = _bytes(data['imageBlob']);

            Widget image;
            if (imageBlob != null) {
              image = Image.memory(imageBlob, fit: BoxFit.cover);
            } else if (imageUrl.isNotEmpty) {
              image = Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[300], child: const Icon(Icons.image)),
              );
            } else {
              image = Container(color: Colors.grey[300], child: const Icon(Icons.image));
            }

            return InkWell(
              onTap: () {
                // 👈 فتح صفحة التفاصيل وتمرير كل القيم المطلوبة
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Propertdetalis(
                      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                      imageBytes: imageBlob,
                      title: title.isEmpty ? 'Apartment' : title,
                      price: _fmtPrice(price),
                      location: location,
                      type: type,
                      areaSqft: areaSqft.toDouble(),
                      beds: beds.toInt(),
                      baths: baths.toInt(),
                      ownerName: ownerName,
                      ownerImageUrl: ownerImageUrl.isNotEmpty ? ownerImageUrl : null,
                      amenities: amenities,
                      interior: interior,
                      construction: construction,
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 110,
                          height: 110,
                          child: image,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // عنوان + سعر
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title.isEmpty ? 'Apartment' : title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize:
                                      (size.width * 0.040).clamp(13.0, 16.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _fmtPrice(price),
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: const Color(0xFF4A43EC),
                                    fontWeight: FontWeight.w800,
                                    fontSize:
                                    (size.width * 0.035).clamp(11.0, 14.0),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // موقع + شارة النوع
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 14, color: Colors.black54),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize:
                                      (size.width * 0.030).clamp(10.5, 13.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    type,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.deepOrange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // مزايا مضغوطة
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  _IconText(
                                    icon: Icons.square_foot,
                                    text: '${areaSqft > 0 ? areaSqft : 0} sqft',
                                  ),
                                  const SizedBox(width: 12),
                                  _IconText(
                                      icon: Icons.bed,
                                      text: '${beds > 0 ? beds : 0}'),
                                  const SizedBox(width: 12),
                                  _IconText(
                                      icon: Icons.shower,
                                      text: '${baths > 0 ? baths : 0}'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
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
        Icon(icon, size: 16, color: const Color(0xFFEA8734)),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
        ),
      ],
    );
  }
}
