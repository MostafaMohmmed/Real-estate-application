// searchPage.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'confirmPage.dart';
import 'propertdetalis.dart';

enum _ViewTab { building, outsideWall, others }

class SearchEstimatedCostPage extends StatefulWidget {
  const SearchEstimatedCostPage({super.key, this.initialQuery = ''});
  final String initialQuery;

  @override
  State<SearchEstimatedCostPage> createState() => _SearchEstimatedCostPageState();
}

class _SearchEstimatedCostPageState extends State<SearchEstimatedCostPage> {
  final _q = TextEditingController();
  _ViewTab _tab = _ViewTab.building;

  @override
  void initState() {
    super.initState();
    _q.text = widget.initialQuery;
  }

  Uint8List? _bytes(dynamic raw) {
    if (raw == null) return null;
    if (raw is Blob) return raw.bytes;
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    return null;
  }

  String _fmtPrice(dynamic value) {
    if (value is num) {
      final s = value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
      return '\$$s';
    }
    final s = (value ?? '').toString();
    return s.isEmpty ? '-' : '\$$s';
  }

  bool _matchQuery(Map<String, dynamic> d, String q) {
    if (q.trim().isEmpty) return true;
    final v = q.toLowerCase().trim();
    final title = (d['title'] ?? '').toString().toLowerCase();
    final loc   = (d['location'] ?? '').toString().toLowerCase();
    final type  = (d['type'] ?? '').toString().toLowerCase();
    return title.contains(v) || loc.contains(v) || type.contains(v);
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance.collectionGroup('properties').snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Search Estimated Cost', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          // Header: search + filter
          final header = Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    onSubmitted: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search…',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.tune),
                  label: const Text('Filter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B5AF0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          );

          final tabs = Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _ChipTab(
                  text: 'Building',
                  selected: _tab == _ViewTab.building,
                  onTap: () => setState(() => _tab = _ViewTab.building),
                ),
                const SizedBox(width: 10),
                _ChipTab(
                  text: 'Outside Wall',
                  selected: _tab == _ViewTab.outsideWall,
                  onTap: () => setState(() => _tab = _ViewTab.outsideWall),
                ),
                const SizedBox(width: 10),
                _ChipTab(
                  text: 'Others',
                  selected: _tab == _ViewTab.others,
                  onTap: () => setState(() => _tab = _ViewTab.others),
                ),
              ],
            ),
          );

          if (snap.hasError) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header, tabs,
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Error loading data', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header, tabs,
                const Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            );
          }

          final all = (snap.data?.docs ?? []);
          // فلترة نصية محلية
          final docs = all.where((d) => _matchQuery(d.data(), _q.text)).toList();

          DateTime dt(dynamic v) {
            if (v is Timestamp) return v.toDate();
            if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
            return DateTime.fromMillisecondsSinceEpoch(0);
          }
          docs.sort((a, b) => dt(b.data()['createdAt']).compareTo(dt(a.data()['createdAt'])));

          if (docs.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header, tabs,
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                  child: Text('Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                const Expanded(
                  child: Center(child: Text('No results for your query', style: TextStyle(color: Colors.grey))),
                ),
              ],
            );
          }

          Widget thumbFor(DocumentSnapshot<Map<String, dynamic>> doc) {
            final data = doc.data()!;
            final tUrl = (data['imageUrl'] ?? '').toString();
            final tBytes = _bytes(data['imageBlob']);
            Widget img;
            if (tBytes != null) {
              img = Image.memory(tBytes, fit: BoxFit.cover);
            } else if (tUrl.isNotEmpty) {
              img = Image.network(tUrl, fit: BoxFit.cover);
            } else {
              img = Container(color: Colors.grey[300], child: const Icon(Icons.image));
            }
            return InkWell(
              onTap: () => _openDetailsWithDoc(context, doc),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(44),
                child: SizedBox(width: 56, height: 56, child: img),
              ),
            );
          }

          final thumbs = SizedBox(
            height: 64,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) => thumbFor(docs[i]),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: docs.length.clamp(0, 10),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                child: Text('Results', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              thumbs,
              const SizedBox(height: 6),
              tabs,
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final d = doc.data();
                    return _ResultCard(
                      data: d,
                      bytesOf: _bytes,
                      fmtPrice: _fmtPrice,
                      onEstimated: () => _openConfirmWithDoc(context, doc),
                      onDetails: () => _openDetailsWithDoc(context, doc),
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

  // === فتح صفحة التأكيد مع companyId/propId من الـ collectionGroup ===
  void _openConfirmWithDoc(
      BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final d = doc.data() ?? {};
    final url = (d['imageUrl'] ?? '').toString();
    final bts = _bytes(d['imageBlob']);

    // parent.parent = companies/{companyId}
    final companyId = doc.reference.parent.parent!.id;
    final propId = doc.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmPage(
          imageUrl: url.isNotEmpty ? url : null,
          imageBytes: bts,
          title: (d['title'] ?? '—').toString(),
          priceLabel: (d['price'] is num) ? _fmtPrice(d['price']) : (d['price'] ?? '-').toString(),
          location: (d['location'] ?? '').toString(),
          companyId: companyId,
          propId: propId,
          priceValue: (d['price'] is num) ? (d['price'] as num) : null,
        ),
      ),
    );
  }

  // === فتح التفاصيل وتمرير المسار (مهم للحفظ والإشعارات) ===
  void _openDetailsWithDoc(
      BuildContext context,
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final d = doc.data() ?? {};
    final url = (d['imageUrl'] ?? '').toString();
    final bts = _bytes(d['imageBlob']);

    final companyId = doc.reference.parent.parent!.id;
    final propId = doc.id;
    final path = 'companies/$companyId/properties/$propId';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Propertdetalis(
          imageUrl: url.isNotEmpty ? url : null,
          imageBytes: bts,
          title: (d['title'] ?? '—').toString(),
          price: (d['price'] is num) ? _fmtPrice(d['price']) : (d['price'] ?? '-').toString(),
          location: (d['location'] ?? '').toString(),
          type: (d['type'] ?? '').toString(),
          areaSqft: (d['areaSqft'] is num) ? (d['areaSqft'] as num).toDouble() : 0.0,
          beds: (d['beds'] is num) ? (d['beds'] as num).toInt() : 0,
          baths: (d['baths'] is num) ? (d['baths'] as num).toInt() : 0,
          ownerName: (d['ownerName'] ?? 'Company').toString(),
          ownerImageUrl: (d['ownerImageUrl'] ?? '').toString(),
          ownerUid: companyId,           // مفيد لو احتجته
          propertyDocPath: path,         // ✅ مهم جدًا
          amenities: (d['amenities'] is Iterable)
              ? (d['amenities'] as Iterable).map((e) => e.toString()).toList()
              : const [],
          interior: (d['interior'] is Iterable)
              ? (d['interior'] as Iterable).map((e) => e.toString()).toList()
              : const [],
          construction: (d['construction'] is Iterable)
              ? (d['construction'] as Iterable).map((e) => e.toString()).toList()
              : const [],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.data,
    required this.bytesOf,
    required this.fmtPrice,
    required this.onEstimated,
    required this.onDetails,
  });

  final Map<String, dynamic> data;
  final Uint8List? Function(dynamic) bytesOf;
  final String Function(dynamic) fmtPrice;
  final VoidCallback onEstimated;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final url = (data['imageUrl'] ?? '').toString();
    final bts = bytesOf(data['imageBlob']);
    final title = (data['title'] ?? '—').toString();

    Widget img;
    if (bts != null) {
      img = Image.memory(bts, fit: BoxFit.cover);
    } else if (url.isNotEmpty) {
      img = Image.network(url, fit: BoxFit.cover);
    } else {
      img = Container(color: Colors.grey[300], child: const Icon(Icons.image));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(aspectRatio: 16 / 9, child: img),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onDetails,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View details'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChipTab extends StatelessWidget {
  const _ChipTab({required this.text, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFEFE6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? const Color(0xFFFFA96B) : const Color(0xFFE6E6EA)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? const Color(0xFFFF7F2C) : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
