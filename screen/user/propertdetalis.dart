import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'confirmPage.dart';

class Propertdetalis extends StatefulWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  final String title;
  final String price;
  final String location;
  final String type;

  final double areaSqft;
  final int beds;
  final int baths;

  final String ownerName;
  final String? ownerImageUrl;

  final String? ownerUid;
  final String? propertyDocPath;

  final List<String> amenities;
  final List<String> interior;
  final List<String> construction;

  const Propertdetalis({
    super.key,
    required this.imageUrl,
    required this.imageBytes,
    required this.title,
    required this.price,
    required this.location,
    required this.type,
    required this.areaSqft,
    required this.beds,
    required this.baths,
    required this.ownerName,
    required this.ownerImageUrl,
    this.ownerUid,
    this.propertyDocPath,
    required this.amenities,
    required this.interior,
    required this.construction,
  });

  @override
  State<Propertdetalis> createState() => _PropertdetalisState();
}

class _PropertdetalisState extends State<Propertdetalis> {
  bool visibleAmenities = false;
  bool visibleInteriorDetails = false;
  bool visibleConstructionDetails = false;
  bool visibleLocationMapDerails = false;

  String? _ownerImgResolved;
  bool _loadingOwnerImg = false;

  bool _busy = false;
  bool _isSaved = false;
  String? _savedDocId;

  List<String> label = ['Location Map', 'Hospital', 'School'];
  int currentIndex = 0;
  String changeimg = 'images/location.png';
  String schoolimg = 'images/location.png';
  String locationimg = 'images/location.png';
  String hospital = 'images/location.png';

  @override
  void initState() {
    super.initState();
    _prefetchOwnerImageIfNeeded();
    _checkIfAlreadySaved();
  }

  void _prefetchOwnerImageIfNeeded() async {
    if ((widget.ownerImageUrl == null || widget.ownerImageUrl!.isEmpty) &&
        (widget.ownerUid != null && widget.ownerUid!.isNotEmpty)) {
      try {
        setState(() => _loadingOwnerImg = true);
        final doc = await FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.ownerUid!)
            .get();
        if (doc.exists) {
          final d = doc.data() ?? {};
          final candidate =
          (d['photoURL'] ?? d['logoUrl'] ?? d['avatar'] ?? d['ownerImageUrl'] ?? '').toString();
          if (candidate.isNotEmpty) setState(() => _ownerImgResolved = candidate);
        }
      } catch (_) {} finally {
        if (mounted) setState(() => _loadingOwnerImg = false);
      }
    }
  }

  Future<void> _checkIfAlreadySaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final col = FirebaseFirestore.instance
          .collection('users').doc(user.uid).collection('saved');

      if (widget.propertyDocPath != null && widget.propertyDocPath!.isNotEmpty) {
        final propId = widget.propertyDocPath!.split('/').last;

        final fixedDoc = await col.doc(propId).get();
        if (fixedDoc.exists) {
          setState(() { _isSaved = true; _savedDocId = propId; });
          return;
        }

        final q = await col.where('propertyRef', isEqualTo: widget.propertyDocPath).limit(1).get();
        if (q.docs.isNotEmpty) {
          setState(() { _isSaved = true; _savedDocId = q.docs.first.id; });
        }
      } else {
        final q = await col
            .where('title', isEqualTo: widget.title)
            .where('location', isEqualTo: widget.location)
            .limit(1).get();
        if (q.docs.isNotEmpty) {
          setState(() { _isSaved = true; _savedDocId = q.docs.first.id; });
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first.')),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);

    final col = FirebaseFirestore.instance
        .collection('users').doc(user.uid).collection('saved');

    try {
      if (_isSaved && _savedDocId != null) {
        await col.doc(_savedDocId).delete();
        setState(() { _isSaved = false; _savedDocId = null; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed from saved')));
      } else {
        final payload = <String, dynamic>{
          'propertyRef': widget.propertyDocPath ?? '',
          'title': widget.title,
          'price': widget.price,
          'location': widget.location,
          'type': widget.type,
          'areaSqft': widget.areaSqft,
          'beds': widget.beds,
          'baths': widget.baths,
          'imageUrl': widget.imageUrl ?? '',
          if (widget.imageBytes != null) 'imageBlob': Blob(widget.imageBytes!),
          'ownerName': widget.ownerName,
          'ownerImageUrl': (widget.ownerImageUrl?.isNotEmpty == true)
              ? widget.ownerImageUrl
              : (_ownerImgResolved ?? ''),
          'ownerUid': widget.ownerUid ?? '',
          'amenities': widget.amenities,
          'interior': widget.interior,
          'construction': widget.construction,
          // نحفظ الحقلين لتوافق كامل
          'savedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (widget.propertyDocPath != null && widget.propertyDocPath!.isNotEmpty) {
          final propId = widget.propertyDocPath!.split('/').last;
          await col.doc(propId).set(payload, SetOptions(merge: true));
          _savedDocId = propId;
        } else {
          final ref = col.doc();
          await ref.set(payload);
          _savedDocId = ref.id;
        }

        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved ✔')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error while saving: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = size.width / 411;

    final sectionTitleStyle = TextStyle(
      fontSize: (15 * scale).clamp(12, 18),
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    );
    final sectionTextStyle = TextStyle(
      fontSize: (13 * scale).clamp(10, 16),
      color: Colors.black87,
    );

    Widget mainImage() {
      if (widget.imageBytes != null) return Image.memory(widget.imageBytes!, fit: BoxFit.cover);
      if ((widget.imageUrl ?? '').isNotEmpty) {
        return Image.network(widget.imageUrl!, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]));
      }
      return Container(color: Colors.grey[300]);
    }

    final ownerImgFinal = (widget.ownerImageUrl != null && widget.ownerImageUrl!.isNotEmpty)
        ? widget.ownerImageUrl
        : _ownerImgResolved;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Property Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: (16 * scale).clamp(12, 20))),
        actions: [
          IconButton(
            tooltip: _isSaved ? 'Unsave' : 'Save',
            onPressed: _toggleSave,
            icon: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, color: const Color(0xFF4A43EC)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(12 * scale),
        children: [
          SizedBox(height: 8 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(aspectRatio: 16 / 9, child: mainImage()),
          ),
          SizedBox(height: 14 * scale),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(widget.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: (18 * scale).clamp(14, 22), fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Text(widget.price,
                  style: TextStyle(fontSize: (16 * scale).clamp(12, 20), color: Colors.blue, fontWeight: FontWeight.w800)),
            ],
          ),

          SizedBox(height: 6 * scale),

          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(widget.location,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black54, fontSize: (13 * scale).clamp(11, 16))),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(widget.type,
                    style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          SizedBox(height: 12 * scale),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _chip(icon: Icons.square_foot, text: '${widget.areaSqft} sqft'),
              _chip(icon: Icons.bed, text: '${widget.beds}'),
              _chip(icon: Icons.shower, text: '${widget.baths}'),
            ],
          ),

          SizedBox(height: 14 * scale),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 22 * scale,
              backgroundColor: Colors.grey[300],
              backgroundImage: (ownerImgFinal != null && ownerImgFinal.isNotEmpty)
                  ? NetworkImage(ownerImgFinal) : null,
              child: (ownerImgFinal == null || ownerImgFinal.isEmpty)
                  ? (_loadingOwnerImg ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.person, color: Colors.white))
                  : null,
            ),
            title: Text(widget.ownerName,
                style: TextStyle(fontSize: (15 * scale).clamp(12, 18), fontWeight: FontWeight.w600)),
            subtitle: Text('Home Owner/Broker', style: TextStyle(fontSize: (12 * scale).clamp(10, 16))),
          ),

          SizedBox(height: 6 * scale),

          RatingBar.builder(
            initialRating: 4,
            minRating: 1,
            allowHalfRating: true,
            itemSize: (20 * scale).clamp(14, 24),
            itemCount: 5,
            itemPadding: EdgeInsets.symmetric(horizontal: 4 * scale),
            itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (v) {},
          ),

          SizedBox(height: 18 * scale),

          _sectionHeader(
            title: 'Amenities',
            isExpanded: visibleAmenities,
            onTap: () => setState(() => visibleAmenities = !visibleAmenities),
            bg: Colors.grey.shade100,
            style: sectionTitleStyle,
          ),
          if (visibleAmenities)
            _sectionList(widget.amenities.isNotEmpty ? widget.amenities : const ['No data'], sectionTextStyle),

          _sectionHeader(
            title: 'Interior Details',
            isExpanded: visibleInteriorDetails,
            onTap: () => setState(() => visibleInteriorDetails = !visibleInteriorDetails),
            bg: Colors.grey.shade100,
            style: sectionTitleStyle,
          ),
          if (visibleInteriorDetails)
            _sectionList(widget.interior.isNotEmpty ? widget.interior : const ['No data'], sectionTextStyle),

          _sectionHeader(
            title: 'Construction Details',
            isExpanded: visibleConstructionDetails,
            onTap: () => setState(() => visibleConstructionDetails = !visibleConstructionDetails),
            bg: Colors.grey.shade100,
            style: sectionTitleStyle,
          ),
          if (visibleConstructionDetails)
            _sectionList(widget.construction.isNotEmpty ? widget.construction : const ['No data'], sectionTextStyle),

          SizedBox(height: 20 * scale),

          // تبويبات مكان الخريطة لاحقاً
          SizedBox(
            height: 40 * scale,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => SizedBox(width: 16 * scale),
              itemCount: label.length,
              itemBuilder: (context, index) {
                final isSelected = currentIndex == index;
                return InkWell(
                  onTap: () {
                    setState(() {
                      currentIndex = index;
                      changeimg = index == 0 ? locationimg : (index == 1 ? hospital : schoolimg);
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepOrange : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        label[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontSize: (14 * scale).clamp(10, 16),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 14 * scale),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(aspectRatio: 16 / 9, child: Image.asset(changeimg, fit: BoxFit.cover)),
          ),

          SizedBox(height: 20 * scale),

          // زر “Save” هنا يوديك لصفحة التأكيد فقط (ما إله علاقة بحفظ النجمة)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A43EC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: Size(double.infinity, (50 * scale).clamp(42, 60)),
            ),
            // ... باقي الكلاس كما عندك تماماً

            onPressed: () {
              String? companyId, propId;
              if ((widget.propertyDocPath ?? '').isNotEmpty) {
                final parts = widget.propertyDocPath!.split('/'); // companies/{cid}/properties/{pid}
                if (parts.length >= 4) {
                  companyId = parts[1];
                  propId = parts[3];
                }
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfirmPage(
                    imageUrl: widget.imageUrl,
                    imageBytes: widget.imageBytes,
                    title: widget.title,
                    price: widget.price,
                    location: widget.location,
                    companyId: companyId, // NEW
                    propId: propId,       // NEW
                  ),
                ),
              );
            },

            child: Text('Save',
                style: TextStyle(color: Colors.white, fontSize: (18 * scale).clamp(14, 20), fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: 20 * scale),
        ],
      ),
    );
  }

  Widget _chip({required IconData icon, required String text}) => Row(
    children: [
      Icon(icon, color: Colors.deepOrange),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    ],
  );

  Widget _sectionHeader({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Color bg,
    required TextStyle style,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: style),
            Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _sectionList(List<String> items, TextStyle textStyle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(e, style: textStyle),
        ))
            .toList(),
      ),
    );
  }
}
