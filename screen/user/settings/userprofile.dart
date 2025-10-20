// lib/screen/user/user_profile.dart
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../homePage.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final User? _user = FirebaseAuth.instance.currentUser;
  Uint8List? _profileImageBytes;
  String? _profileHash;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadProfileImageOnce();
  }

  // ================= Helper Methods =================

  Uint8List? _bytes(dynamic raw) {
    if (raw == null) return null;
    if (raw is Blob) return raw.bytes;
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    return null;
  }

  String _sha256(Uint8List bytes) => sha256.convert(bytes).toString();

  // ================= Load once =================
  Future<void> _loadProfileImageOnce() async {
    try {
      if (_user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      final data = doc.data();
      if (data == null) return;

      Uint8List? bytes;
      final dynamic raw = data['profileImage'];
      if (raw != null) bytes = _bytes(raw);

      setState(() {
        _profileImageBytes = bytes;
        _profileHash = data['profileHash'] as String?;
      });
    } catch (e) {
      debugPrint('load profile image error: $e');
    }
  }

  // ================= Pick + Compress + Save =================
  Future<void> _pickAndSaveProfile() async {
    if (_isUpdating) return;
    if (_user == null) return;

    setState(() => _isUpdating = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) {
        setState(() => _isUpdating = false);
        return;
      }

      final original = await picked.readAsBytes();

      // ضغط الصورة لتكون تحت ~900KB
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
        setState(() => _isUpdating = false);
        return;
      }

      final newHash = _sha256(out);
      if (newHash == _profileHash) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This profile picture is already saved.')),
        );
        setState(() => _isUpdating = false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .set({
        'profileImage': Blob(out),
        'profileHash': newHash,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _profileImageBytes = out;
        _profileHash = newHash;
        _isUpdating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully.')),
      );
    } catch (e) {
      debugPrint('pick/save profile error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong while updating.')),
      );
      setState(() => _isUpdating = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xff22577A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
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
                              child: _profileImageBytes != null
                                  ? Image.memory(_profileImageBytes!,
                                  fit: BoxFit.cover)
                                  : SvgPicture.asset(
                                  "images/logo_profile.svg",
                                  fit: BoxFit.cover),
                            ),
                          ),
                          if (_isUpdating)
                            const Positioned.fill(
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                  CircularProgressIndicator(strokeWidth: 2),
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
                        onTap: _isUpdating ? null : _pickAndSaveProfile,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor:
                          _isUpdating ? Colors.grey : primaryColor,
                          child: const Icon(Icons.photo_library_outlined,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(_user?.displayName ?? "No Name",
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(_user?.email ?? "No Email",
                    style:
                    const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ======= SAVED =======
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text('Saved',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: size.width * 0.05,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: _user == null
                ? const Center(child: Text('Please sign in to see saved items.'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user!.uid)
                  .collection('saved')
                  .orderBy('savedAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                      child: Text('Error loading saved items'));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No saved items yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 16),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final title = (d['title'] ?? '').toString();
                    final price = (d['price'] ?? '').toString();
                    final location = (d['location'] ?? '').toString();
                    final url = (d['imageUrl'] ?? '').toString();
                    final bytes = _bytes(d['imageBlob']);

                    Widget image;
                    if (bytes != null) {
                      image = Image.memory(bytes,
                          width: 80, height: 80, fit: BoxFit.cover);
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: image),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
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
                                      const Icon(
                                          Icons.location_on_outlined,
                                          size: 14,
                                          color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location,
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
}
