import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'propertdetalis.dart'; // 👈 تأكد من المسار الصحيح

class SeeAllPage extends StatefulWidget {
  const SeeAllPage({super.key});

  @override
  State<SeeAllPage> createState() => _SeeAllPageState();
}

class _SeeAllPageState extends State<SeeAllPage> {
  bool _grid = true;   // تبديل Grid/List
  int _pageSize = 10;  // حجم الدفعة
  int _visible = 10;   // المعروض حاليًا

  Uint8List? _bytes(dynamic raw) {
    if (raw == null) return null;
    if (raw is Blob) return raw.bytes;
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    return null;
  }

  DateTime _createdAtOf(Map<String, dynamic> d) {
    final ts = d['createdAt'];
    if (ts is Timestamp) return ts.toDate();
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collectionGroup('properties') // من كل الشركات
        .snapshots();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6FB),
        elevation: 0,
        title: const Text('See All'),
        actions: [
          IconButton(
            tooltip: _grid ? 'قائمة' : 'شبكة',
            onPressed: () => setState(() => _grid = !_grid),
            icon: Icon(_grid ? Icons.view_list_rounded : Icons.grid_view_rounded),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'خطأ:\n${snap.error}',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = (snap.data?.docs ?? []).toList();
          // ترتيب محلي (الأجدد أولاً)
          all.sort((a, b) => _createdAtOf(b.data()).compareTo(_createdAtOf(a.data())));

          if (all.isEmpty) return const Center(child: Text('لا توجد عقارات.'));

          final total = all.length;
          if (_visible > total) _visible = total;
          final items = all.take(_visible).toList();

          if (_grid) {
            return Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, cons) {
                      final w = cons.maxWidth;
                      const spacing = 12.0;
                      final columns = w >= 900 ? 4 : (w >= 650 ? 3 : 2);
                      final childAspectRatio = (w >= 900)
                          ? 0.78
                          : (w >= 650 ? 0.74 : 0.70);

                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _CardTile(
                          doc: items[i],            // 👈 نمرّر الـ snapshot
                          isGrid: true,
                          bytesOf: _bytes,
                          onOpenDetails: _openDetailsWithDoc, // 👈 فتح التفاصيل بالـ doc
                        ),
                      );
                    },
                  ),
                ),
                _LoadMoreBar(
                  hasMore: _visible < total,
                  onTap: () => setState(() {
                    _visible = (_visible + _pageSize).clamp(0, total);
                  }),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CardTile(
                        doc: items[i],            // 👈 نمرّر الـ snapshot
                        isGrid: false,
                        bytesOf: _bytes,
                        onOpenDetails: _openDetailsWithDoc,
                      ),
                    ),
                  ),
                ),
                _LoadMoreBar(
                  hasMore: _visible < total,
                  onTap: () => setState(() {
                    _visible = (_visible + _pageSize).clamp(0, total);
                  }),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  // === يفتح Propertdetalis ويمرّر المسار companies/{cid}/properties/{pid} ===
  void _openDetailsWithDoc(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      Uint8List? Function(dynamic) toBytes,
      ) {
    final d = doc.data();
    final imageUrl  = (d['imageUrl'] ?? '').toString();
    final imageBlob = toBytes(d['imageBlob']);

    String _fmtPrice(dynamic value) {
      if (value is num) {
        final s = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
        return '\$$s';
      }
      final s = (value ?? '').toString();
      if (s.isEmpty) return '-';
      return s.startsWith('\$') ? s : '\$$s';
    }

    List<String> _list(dynamic v) {
      if (v == null) return const [];
      if (v is Iterable) return v.map((e) => e.toString()).toList();
      if (v is String && v.trim().isNotEmpty) {
        return v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    // 👇 استخراج companyId/propId من الـ collectionGroup doc
    final companyId = doc.reference.parent.parent!.id; // companies/{companyId}
    final propId = doc.id;                             // properties/{propId}
    final path = 'companies/$companyId/properties/$propId';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Propertdetalis(
          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
          imageBytes: imageBlob,
          title: (d['title'] ?? 'Apartment').toString(),
          price: _fmtPrice(d['price']),
          location: (d['location'] ?? '').toString(),
          type: (d['type'] ?? '').toString(),
          areaSqft: (d['areaSqft'] is num) ? (d['areaSqft'] as num).toDouble() : 0.0,
          beds: (d['beds'] is num) ? (d['beds'] as num).toInt() : 0,
          baths: (d['baths'] is num) ? (d['baths'] as num).toInt() : 0,
          ownerName: (d['ownerName'] ?? 'Company').toString(),
          ownerImageUrl: (d['ownerImageUrl'] ?? '').toString().isNotEmpty
              ? (d['ownerImageUrl'] as String)
              : null,
          ownerUid: companyId,            // مفيد لو احتجته
          propertyDocPath: path,          // ✅ مهم للحفظ والإشعارات
          amenities: _list(d['amenities']),
          interior: _list(d['interior']),
          construction: _list(d['construction']),
        ),
      ),
    );
  }
}

class _LoadMoreBar extends StatelessWidget {
  final bool hasMore;
  final VoidCallback onTap;
  const _LoadMoreBar({required this.hasMore, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.expand_more),
            label: const Text('Load more'),
          ),
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc; // 👈 بدل Map إلى snapshot
  final bool isGrid;
  final Uint8List? Function(dynamic) bytesOf;
  final void Function(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      Uint8List? Function(dynamic) toBytes,
      ) onOpenDetails;

  const _CardTile({
    required this.doc,
    required this.isGrid,
    required this.bytesOf,
    required this.onOpenDetails,
  });

  String _fmtPrice(dynamic value) {
    if (value is num) {
      final s = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
      return '\$$s';
    }
    final s = (value ?? '').toString();
    if (s.isEmpty) return '-';
    return '\$$s';
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final w = MediaQuery.of(context).size.width;

    // أحجام مرِنة
    final titleSize = (w * 0.040).clamp(13.0, 18.0);
    final priceSize = (w * 0.036).clamp(12.0, 16.0);
    final smallSize = (w * 0.032).clamp(11.0, 14.0);

    // قراءات من Firestore
    final title     = (data['title'] ?? '').toString();
    final price     = data['price'];          // قد يكون num
    final location  = (data['location'] ?? '').toString();
    final type      = (data['type'] ?? '').toString();
    final ownerName = (data['ownerName'] ?? 'Company').toString();

    final areaSqft  = (data['areaSqft'] is num) ? (data['areaSqft'] as num) : 0;
    final beds      = (data['beds'] is num) ? (data['beds'] as num) : 0;
    final baths     = (data['baths'] is num) ? (data['baths'] as num) : 0;

    final imageUrl  = (data['imageUrl'] ?? '').toString();
    final imageBlob = bytesOf(data['imageBlob']);

    Widget imageChild;
    if (imageBlob != null) {
      imageChild = Image.memory(imageBlob, fit: BoxFit.cover);
    } else if (imageUrl.isNotEmpty) {
      imageChild = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: Colors.grey[300], child: const Icon(Icons.image)),
      );
    } else {
      imageChild = Container(color: Colors.grey[300], child: const Icon(Icons.image));
    }

    // شارة (بادج) اسم الشركة — للـ Grid فقط
    Widget ownerBadge = Align(
      alignment: Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            ownerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ),
    );

    // سطر المالك للـ List (داخل الكارد)
    Widget ownerLine = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
          radius: 12,
          backgroundColor: Color(0xFF4A43EC),
          child: Icon(Icons.business, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            ownerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: smallSize,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );

    final cardRadius = 22.0;
    final imgRadius = 26.0;

    Widget featuresRow() {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 14,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _IconText(icon: Icons.square_foot, text: '${areaSqft > 0 ? areaSqft : 0} sqft'),
            _IconText(icon: Icons.bed,         text: '${beds > 0 ? beds : 0}'),
            _IconText(icon: Icons.shower,      text: '${baths > 0 ? baths : 0}'),
          ],
        ),
      );
    }

    Widget infoBlock({required bool includeOwnerLine}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (includeOwnerLine) ...[
            ownerLine,
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.isEmpty ? 'Apartment' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _fmtPrice(price),
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: priceSize,
                    color: const Color(0xFF4A43EC),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.black45),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black54, fontSize: smallSize),
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
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          featuresRow(),
        ],
      );
    }

    // صورة مع شارة اسم الشركة (للـ Grid فقط)
    Widget imageWithOwnerBadge() {
      final img = ClipRRect(
        borderRadius: BorderRadius.circular(imgRadius),
        child: imageChild,
      );
      return Stack(
        children: [
          Positioned.fill(child: img),
          ownerBadge,
        ],
      );
    }

    final gridChild = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.15,
          child: imageWithOwnerBadge(),
        ),
        const SizedBox(height: 10),
        infoBlock(includeOwnerLine: false), // المالك كبادج فوق الصورة
      ],
    );

    final listChild = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(imgRadius),
          child: SizedBox(width: 120, height: 120, child: imageChild),
        ),
        const SizedBox(width: 12),
        Expanded(child: infoBlock(includeOwnerLine: true)),
      ],
    );

    return InkWell(
      onTap: () => onOpenDetails(context, doc, bytesOf), // 👈 نمرّر الـ doc نفسه
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: isGrid ? gridChild : listChild,
      ),
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
        Icon(icon, size: 18, color: const Color(0xFFEA8734)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
      ],
    );
  }
}
