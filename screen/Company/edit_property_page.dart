import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img; // ← مهم

class EditPropertyPage extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> docRef;
  final Map<String, dynamic> initialData;
  const EditPropertyPage({super.key, required this.docRef, required this.initialData});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _titleCtrl =
  TextEditingController(text: (widget.initialData['title'] ?? '').toString());
  late final TextEditingController _priceCtrl =
  TextEditingController(text: (widget.initialData['price'] ?? '').toString());
  late final TextEditingController _locationCtrl =
  TextEditingController(text: (widget.initialData['location'] ?? '').toString());
  late final TextEditingController _descCtrl =
  TextEditingController(text: (widget.initialData['description'] ?? '').toString());
  late String _type = (widget.initialData['type'] ?? 'House').toString();

  Uint8List? _existingBlobBytes;
  String _existingUrl = '';
  Uint8List? _pickedBytes;

  final _types = const ['House', 'Apartment', 'Office', 'Land'];

  @override
  void initState() {
    super.initState();
    final raw = widget.initialData['imageBlob'];
    if (raw is Blob) {
      _existingBlobBytes = raw.bytes;
    } else if (raw is Uint8List) {
      _existingBlobBytes = raw;
    } else if (raw is List) {
      _existingBlobBytes = Uint8List.fromList(raw.cast<int>());
    }
    _existingUrl = (widget.initialData['imageUrl'] ?? '').toString();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /// اضغط الصورة لتناسب حد Firestore (~1MB للمستند)
  Future<Uint8List> _compressForFirestore(Uint8List input) async {
    // 1) حمّل الصورة
    final decoded = img.decodeImage(input);
    if (decoded == null) return input;

    // 2) صغّر الأبعاد لو كبيرة (مثلاً الحد الأقصى 1600 بكسل لأكبر ضلع)
    const maxSide = 1600;
    img.Image resized = decoded;
    if (decoded.width > maxSide || decoded.height > maxSide) {
      resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxSide : null,
        height: decoded.height > decoded.width ? maxSide : null,
        interpolation: img.Interpolation.average,
      );
    }

    // 3) جرّب بجودة JPEG تنزل تدريجيًا لحد ما ننزل تحت 900KB
    int quality = 85;
    Uint8List out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    const target = 900 * 1024; // 900KB احتياطًا

    while (out.lengthInBytes > target && quality > 30) {
      quality -= 10;
      out = Uint8List.fromList(img.encodeJpg(resized, quality: quality));
    }

    return out;
  }

  Future<void> _pickImage() async {
    try {
      final res = await FilePicker.platform.pickFiles(type: FileType.image);
      if (res == null) return;

      Uint8List? bytes = res.files.single.bytes;
      if (bytes == null && res.files.single.path != null) {
        bytes = await File(res.files.single.path!).readAsBytes();
      }
      if (bytes == null) {
        _toast('Could not read image bytes.');
        return;
      }

      // اضغط قبل التخزين
      final compressed = await _compressForFirestore(bytes);
      if (compressed.lengthInBytes > 950 * 1024) {
        _toast('Image is still too large. Please choose a smaller one.');
        return;
      }

      setState(() => _pickedBytes = compressed);
    } catch (e) {
      _toast('Image pick failed: $e');
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final patch = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'type': _type,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_pickedBytes != null && _pickedBytes!.isNotEmpty) {
        // خزّن Blob واحذف الـ URL القديم
        patch['imageBlob'] = Blob(_pickedBytes!);
        patch['imageUrl'] = FieldValue.delete();
        patch['imageHash'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      await widget.docRef.update(patch);

      if (!mounted) return;
      Navigator.pop(context, true);
    } on FirebaseException catch (e) {
      _toast('Update failed: ${e.code}');
    } catch (e) {
      _toast('Update failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    Widget imgWidget;
    if (_pickedBytes != null) {
      imgWidget = Image.memory(_pickedBytes!, fit: BoxFit.cover);
    } else if (_existingBlobBytes != null) {
      imgWidget = Image.memory(_existingBlobBytes!, fit: BoxFit.cover);
    } else if (_existingUrl.isNotEmpty) {
      imgWidget = Image.network(_existingUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _ph());
    } else {
      imgWidget = _ph();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Property'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SAVE'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: size.height * 0.25,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imgWidget,
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text('Change', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter title' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter price' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter location' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ph() => Container(
    color: Colors.grey[300],
    child: const Center(child: Icon(Icons.image, size: 42, color: Colors.white70)),
  );
}
