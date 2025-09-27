// lib/screen/company/owner_profile.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:crypto/crypto.dart';

import '../company_home_page.dart';


class OwnerProfile extends StatefulWidget {
  const OwnerProfile({super.key});

  @override
  State<OwnerProfile> createState() => _OwnerProfileState();
}

class _OwnerProfileState extends State<OwnerProfile> {
  final User? _user = FirebaseAuth.instance.currentUser;

  Uint8List? _logoBytes;
  String? _logoHash;
  bool _updatingLogo = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyLogoOnce();
  }

  // ---------- Helpers ----------
  Uint8List? _bytes(dynamic raw) {
    if (raw == null) return null;
    if (raw is Blob) return raw.bytes;
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    return null;
  }

  String _sha256(Uint8List bytes) => sha256.convert(bytes).toString();

  // ---------- Load company logo once ----------
  Future<void> _loadCompanyLogoOnce() async {
    try {
      if (_user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(_user!.uid)
          .get();

      final data = doc.data();
      if (data == null) return;

      Uint8List? bytes;
      final dynamic raw = data['logoBlob']; // لو كنت مخزّن Blob مباشر
      if (raw != null) {
        bytes = _bytes(raw);
      } else {
        // جرّب الحقول المعروفة لروابط الصور أيضاً (كـ fallback عرض فقط)
        final url = (data['photoURL'] ?? data['logoUrl'] ?? data['avatar'] ?? '').toString();
        if (url.isNotEmpty) {
          // ما في تحميل شبكة هنا؛ بنتركه للـ Image.network في UI لو احتجنا
        }
      }

      setState(() {
        _logoBytes = bytes;
        _logoHash  = data['logoHash'] as String?;
      });
    } catch (e) {
      debugPrint('load company logo error: $e');
    }
  }

  // ---------- Pick → Compress → Save to companies/{uid} ----------
  Future<void> _pickAndSaveLogo() async {
    if (_updatingLogo) return;
    if (_user == null) return;

    setState(() => _updatingLogo = true);
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery);
      if (x == null) {
        setState(() => _updatingLogo = false);
        return;
      }

      final original = await x.readAsBytes();

      // Compress under ~900KB
      const maxBytes = 900 * 1024;
      int quality = 75, minSide = 600, attempts = 0;
      Uint8List? out = await FlutterImageCompress.compressWithList(
        original,
        quality: quality,
        minHeight: minSide,
        minWidth: minSide,
        format: CompressFormat.jpeg,
      );

      while (out != null &&
          out.lengthInBytes > maxBytes &&
          attempts < 6 &&
          (quality > 40 || minSide > 480)) {
        attempts++;
        if (quality > 40) quality -= 7;
        if (out.lengthInBytes > maxBytes && minSide > 480) minSide -= 60;
        out = await FlutterImageCompress.compressWithList(
          out,
          quality: quality,
          minHeight: minSide,
          minWidth: minSide,
          format: CompressFormat.jpeg,
        );
      }

      if (out == null || out.lengthInBytes > maxBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected image is too large.')),
        );
        setState(() => _updatingLogo = false);
        return;
      }

      final newHash = _sha256(out);
      if (newHash == _logoHash) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This logo is already saved.')),
        );
        setState(() => _updatingLogo = false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(_user!.uid)
          .set({
        'logoBlob': Blob(out),            // نخزن Blob حقيقي
        'logoHash': newHash,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _logoBytes = out;
        _logoHash  = newHash;
        _updatingLogo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company logo updated.')),
      );
    } catch (e) {
      debugPrint('pick/save logo error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong while updating.')),
      );
      setState(() => _updatingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xff22577A);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.grid_view, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const CompanyHomePage()),
                      (route) => false,
                );
              },
            ),
            SizedBox(width: size.width * 0.1),
            IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Owner Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // --------- Header (logo + name/email) ----------
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: ClipOval(
                              child: _logoBytes != null
                                  ? Image.memory(_logoBytes!, fit: BoxFit.cover)
                                  : SvgPicture.asset("images/logo_profile.svg", fit: BoxFit.cover),
                            ),
                          ),
                          if (_updatingLogo)
                            const Positioned.fill(
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _updatingLogo ? null : _pickAndSaveLogo,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: _updatingLogo ? Colors.grey : primaryColor,
                          child: const Icon(Icons.photo_library_outlined, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_user?.displayName ?? "No Name",
                    style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(_user?.email ?? "No Email", style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --------- Company Properties ---------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                'Properties',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: size.width * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: _user == null
                ? const Center(child: Text('Please sign in to see your properties.'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(_user!.uid)
                  .collection('properties')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Error loading properties'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No properties yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();

                    final title    = (d['title'] ?? '').toString();
                    final price    = (d['price'] ?? '').toString();
                    final location = (d['location'] ?? '').toString();
                    final beds     = (d['beds'] ?? '').toString();
                    final baths    = (d['baths'] ?? '').toString();
                    final area     = (d['areaSqft'] ?? '').toString();

                    final url   = (d['imageUrl'] ?? '').toString();
                    final bytes = _bytes(d['imageBlob']);

                    Widget image;
                    if (bytes != null) {
                      image = Image.memory(bytes, width: 80, height: 80, fit: BoxFit.cover);
                    } else if (url.isNotEmpty) {
                      image = Image.network(
                        url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ph(),
                      );
                    } else {
                      image = _ph();
                    }

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        price,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    children: [
                                      _smallIconText(Icons.square_foot, '$area sqft'),
                                      _smallIconText(Icons.bed, beds),
                                      _smallIconText(Icons.shower, baths),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ph() => Container(
    width: 80,
    height: 80,
    color: Colors.grey[300],
    child: const Icon(Icons.image, color: Colors.white70),
  );

  Widget _smallIconText(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Colors.deepOrange),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    ],
  );
}
