import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// NEW
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Propertdetalis extends StatefulWidget {
  final String? imageUrl;
  final Uint8List? imageBytes;

  final String title;
  final String price;
  final String location; // نص العنوان (address/location)
  final String type;

  final double areaSqft;
  final int beds;
  final int baths;

  final String ownerName;
  final String? ownerImageUrl;

  final String? ownerUid;            // = companyId
  final String? propertyDocPath;     // companies/{cid}/properties/{pid}

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

  String? _ownerImgResolved;
  bool _loadingOwnerImg = false;

  bool _busy = false;
  bool _isSaved = false;
  String? _savedDocId;
  bool _useFrMirror = true;     // نجرب المرآة الفرنسية أولاً
  bool _switchedOnce = false;   // حتى ما يضل يلف


  // تبويبات
  final List<String> label = ['Location Map', 'Hospital', 'School'];
  int currentIndex = 0;

  // NEW: إحداثيات العقار (إن وُجدت)
  GeoPoint? _geo;        // من Firestore
  bool _loadingGeo = false;

  @override
  void initState() {
    super.initState();
    _prefetchOwnerImageIfNeeded();
    _checkIfAlreadySaved();
    _loadGeoIfPossible();
  }

  // ---------- load geo ----------
  Future<void> _loadGeoIfPossible() async {
    if ((widget.propertyDocPath ?? '').isEmpty) return;
    setState(() => _loadingGeo = true);
    try {
      final snap = await FirebaseFirestore.instance
          .doc(widget.propertyDocPath!)
          .get();
      final d = snap.data() as Map<String, dynamic>?;
      if (d != null && d['geo'] is GeoPoint) {
        setState(() => _geo = d['geo'] as GeoPoint);
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingGeo = false);
    }
  }

  // ======== helpers: owner image / saved ========
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
          final candidate = (d['photoURL'] ??
              d['logoUrl'] ??
              d['avatar'] ??
              d['ownerImageUrl'] ??
              '')
              .toString();
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
          .collection('users')
          .doc(user.uid)
          .collection('saved');

      if ((widget.propertyDocPath ?? '').isNotEmpty) {
        final propId = widget.propertyDocPath!.split('/').last;
        final fixedDoc = await col.doc(propId).get();
        if (fixedDoc.exists) {
          setState(() {
            _isSaved = true;
            _savedDocId = propId;
          });
          return;
        }
        final q = await col
            .where('propertyRef', isEqualTo: widget.propertyDocPath)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          setState(() {
            _isSaved = true;
            _savedDocId = q.docs.first.id;
          });
        }
      } else {
        final q = await col
            .where('title', isEqualTo: widget.title)
            .where('location', isEqualTo: widget.location)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          setState(() {
            _isSaved = true;
            _savedDocId = q.docs.first.id;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleSave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);

    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved');

    try {
      if (_isSaved && _savedDocId != null) {
        await col.doc(_savedDocId).delete();
        setState(() {
          _isSaved = false;
          _savedDocId = null;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Removed from saved')));
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
          'savedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        };

        if ((widget.propertyDocPath ?? '').isNotEmpty) {
          final propId = widget.propertyDocPath!.split('/').last;
          await col.doc(propId).set(payload, SetOptions(merge: true));
          _savedDocId = propId;
        } else {
          final ref = col.doc();
          await ref.set(payload);
          _savedDocId = ref.id;
        }

        setState(() => _isSaved = true);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved ✔')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error while saving: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ======== طلب الشراء (كما هو) ========
  Future<void> _confirmAndSubmitRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in first.')));
      return;
    }

    String? companyId, propId;
    if ((widget.propertyDocPath ?? '').isNotEmpty) {
      final parts = widget.propertyDocPath!.split('/');
      if (parts.length >= 4) {
        companyId = parts[1];
        propId = parts[3];
      }
    } else {
      companyId = widget.ownerUid ?? '';
    }
    if (companyId == null || companyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company not found for this property.')),
      );
      return;
    }

    String userName = FirebaseAuth.instance.currentUser?.displayName ?? '';
    String userPhone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
    try {
      final uSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final ud = uSnap.data() ?? {};
      if ((ud['fullName'] ?? '').toString().isNotEmpty) {
        userName = (ud['fullName'] ?? '').toString();
      }
      final ph =
      (ud['phone'] ?? ud['phoneNumber'] ?? ud['mobile'] ?? '').toString();
      if (ph.isNotEmpty) userPhone = ph;
    } catch (_) {}

    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send request?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userName.isEmpty ? 'Name: —' : 'Name: $userName'),
            Text(userPhone.isEmpty ? 'Phone: —' : 'Phone: $userPhone'),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (ok != true) return;

    if (_busy) return;
    setState(() => _busy = true);

    try {
      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();
      final priceValue =
      num.tryParse(widget.price.replaceAll(RegExp(r'[^0-9.]'), ''));

      final reqRef = db.collection('purchaseRequests').doc();
      final reqId = reqRef.id;

      final centralPayload = {
        'requestId': reqId,
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
        'userUid': user.uid,
        'companyId': companyId,
        'userName': userName,
        'userPhone': userPhone,
        'propId': propId ?? '',
        'title': widget.title,
        'location': widget.location,
        'priceLabel': widget.price,
        'priceValue': priceValue,
        'note': noteCtrl.text.trim(),
      };

      await reqRef.set(centralPayload, SetOptions(merge: true));

      await db
          .collection('companies')
          .doc(companyId)
          .collection('purchaseRequests')
          .doc(reqId)
          .set({
        ...centralPayload,
        'buyerUid': user.uid,
        'buyerName': userName,
        'buyerPhone': userPhone,
      }, SetOptions(merge: true));

      await db
          .collection('users')
          .doc(user.uid)
          .collection('purchaseRequests')
          .doc(reqId)
          .set(centralPayload, SetOptions(merge: true));

      await db
          .collection('companies')
          .doc(companyId)
          .collection('notifications')
          .add({
        'title': 'New purchase request',
        'body':
        '$userName (${userPhone.isEmpty ? 'no phone' : userPhone}) requested this property.',
        'type': 'Deals',
        'isRead': false,
        'createdAt': now,
        'reqId': reqId,
        'propId': propId ?? '',
        'buyerUid': user.uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted ✔')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request: $e')),
      );
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
      if (widget.imageBytes != null) {
        return Image.memory(widget.imageBytes!, fit: BoxFit.cover);
      }
      if ((widget.imageUrl ?? '').isNotEmpty) {
        return Image.network(
          widget.imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
        );
      }
      return Container(color: Colors.grey[300]);
    }

    final ownerImgFinal =
    (widget.ownerImageUrl != null && widget.ownerImageUrl!.isNotEmpty)
        ? widget.ownerImageUrl
        : _ownerImgResolved;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Property Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: (16 * scale).clamp(12, 20),
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isSaved ? 'Unsave' : 'Save',
            onPressed: _toggleSave,
            icon: _busy
                ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: const Color(0xFF4A43EC)),
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
                child: Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: (18 * scale).clamp(14, 22),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.price,
                style: TextStyle(
                  fontSize: (16 * scale).clamp(12, 20),
                  color: Colors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          SizedBox(height: 6 * scale),

          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.black54, fontSize: (13 * scale).clamp(11, 16)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.type,
                  style: const TextStyle(
                    color: Colors.deepOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
              backgroundImage:
              (ownerImgFinal != null && ownerImgFinal.isNotEmpty) ? NetworkImage(ownerImgFinal!) : null,
              child: (ownerImgFinal == null || ownerImgFinal.isEmpty)
                  ? (_loadingOwnerImg
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Icon(Icons.person, color: Colors.white))
                  : null,
            ),
            title: Text(
              widget.ownerName,
              style: TextStyle(fontSize: (15 * scale).clamp(12, 18), fontWeight: FontWeight.w600),
            ),
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

          // ===== خريطة بمرايا فرنسا =====
          _sectionHeader(
            title: 'Location Map',
            isExpanded: true,
            onTap: () {},
            bg: Colors.grey.shade100,
            style: sectionTitleStyle,
          ),
          const SizedBox(height: 8),
          _buildLocationMapCard(context),

          SizedBox(height: 20 * scale),

          // زر إرسال الطلب
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A43EC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              minimumSize: Size(double.infinity, (50 * scale).clamp(42, 60)),
            ),
            onPressed: _busy ? null : _confirmAndSubmitRequest,
            child: _busy
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: (18 * scale).clamp(14, 20),
                    fontWeight: FontWeight.w700)),
          ),
          SizedBox(height: 20 * scale),
        ],
      ),
    );
  }

  // ---------- Location map card ----------
  Widget _buildLocationMapCard(BuildContext context) {
    const h = 200.0;

    if (_loadingGeo) {
      return const SizedBox(
        height: h,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_geo == null) {
      return Container(
        height: h,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(
          widget.location.isEmpty ? 'No location available' : widget.location,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }

    final latLng = LatLng(_geo!.latitude, _geo!.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: h,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: latLng,   // v7
            initialZoom: 15,         // v7
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              tileProvider: NetworkTileProvider(
                headers:  {
                  // أي قيمة مميّزة لتطبيقك
                  'User-Agent': 'final_iug_2025/1.0 (+https://example.com)',
                },
              ),
              // خيار: لتشوف الأخطاء في اللوج بدل الكراش
              errorImage: const AssetImage('assets/images/tile_error.png'),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: latLng,
                  width: 60,
                  height: 60,
                  child: const Icon(Icons.location_on, size: 48, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI helpers ----------
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
