import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPropertyPage extends StatefulWidget {
  const AddPropertyPage({super.key});

  @override
  State<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends State<AddPropertyPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final locationController = TextEditingController();
  final priceController = TextEditingController();

  // حقول إضافية
  final areaSqftController = TextEditingController(); // مساحة
  final bedsController = TextEditingController();     // غرف
  final bathsController = TextEditingController();    // حمّامات

  // مصفوفات (أدخلها بفواصل)
  final amenitiesController   = TextEditingController();
  final interiorController    = TextEditingController();
  final constructionController= TextEditingController();

  String selectedType = "House";
  Uint8List? _imageBytes;
  bool _saving = false;

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    locationController.dispose();
    priceController.dispose();
    areaSqftController.dispose();
    bedsController.dispose();
    bathsController.dispose();
    amenitiesController.dispose();
    interiorController.dispose();
    constructionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<Uint8List?> _compressToUnder900KB(Uint8List input) async {
    const maxBytes = 900 * 1024;
    int quality = 75, minSide = 800, attempts = 0;

    Uint8List? out = await FlutterImageCompress.compressWithList(
      input,
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
    return (out != null && out.lengthInBytes <= maxBytes) ? out : null;
  }

  List<String> _splitToList(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick an image.')),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not signed in.')),
      );
      return;
    }

    final price = double.tryParse(priceController.text.trim());
    if (price == null || price.isNaN || price.isNegative) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be a valid non-negative number.')),
      );
      return;
    }

    final areaSqft = double.tryParse(areaSqftController.text.trim()) ?? 0;
    final beds = int.tryParse(bedsController.text.trim()) ?? 0;
    final baths = int.tryParse(bathsController.text.trim()) ?? 0;

    final amenities   = _splitToList(amenitiesController.text);
    final interior    = _splitToList(interiorController.text);
    final construction= _splitToList(constructionController.text);

    setState(() => _saving = true);
    try {
      final compressed = await _compressToUnder900KB(_imageBytes!);
      if (compressed == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected image is too large.')),
        );
        setState(() => _saving = false);
        return;
      }
      final blob = Blob(compressed);

      final col = _db
          .collection('companies')
          .doc(user.uid)
          .collection('properties');

      await col.add({
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'location': locationController.text.trim(),
        'price': price,
        'type': selectedType,
        'imageBlob': blob,
        'createdAt': FieldValue.serverTimestamp(),

        // مالك
        'ownerUid'   : user.uid,
        'ownerName'  : user.displayName ?? 'Company',
        'ownerEmail' : (user.email ?? '').toLowerCase(),
        'ownerImageUrl': user.photoURL ?? '',

        // أبعاد
        'areaSqft': areaSqft,
        'beds'    : beds,
        'baths'   : baths,

        // أقسام
        'amenities'   : amenities,
        'interior'    : interior,
        'construction': construction,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property added successfully')),
      );

      titleController.clear();
      descController.clear();
      locationController.clear();
      priceController.clear();
      areaSqftController.clear();
      bedsController.clear();
      bathsController.clear();
      amenitiesController.clear();
      interiorController.clear();
      constructionController.clear();

      setState(() {
        selectedType = "House";
        _imageBytes = null;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("Add Property")),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Form(
          key: formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _imageBytes == null
                    ? Container(
                  height: size.height * 0.25,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                  ),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    _imageBytes!,
                    height: size.height * 0.25,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),

              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              TextFormField(
                controller: locationController,
                decoration: const InputDecoration(labelText: "Location"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Price (e.g. 200000)"),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              SizedBox(height: size.height * 0.02),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: areaSqftController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Area (sqft)",
                        hintText: "e.g. 2000",
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    child: TextFormField(
                      controller: bedsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Beds",
                        hintText: "e.g. 4",
                      ),
                    ),
                  ),
                  SizedBox(width: size.width * 0.03),
                  Expanded(
                    child: TextFormField(
                      controller: bathsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Baths",
                        hintText: "e.g. 2",
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: size.height * 0.02),

              DropdownButtonFormField<String>(
                value: selectedType,
                items: const ["House", "Apartment", "Office", "Land"]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => selectedType = val!),
                decoration: const InputDecoration(labelText: "Type"),
              ),

              SizedBox(height: size.height * 0.02),

              // نصوص القوائم (تفصل بفواصل)
              TextFormField(
                controller: amenitiesController,
                decoration: const InputDecoration(
                  labelText: "Amenities (comma-separated)",
                  hintText: "Pool,Gym,Parking",
                ),
              ),
              TextFormField(
                controller: interiorController,
                decoration: const InputDecoration(
                  labelText: "Interior details (comma-separated)",
                  hintText: "3 Bedrooms,1 Kitchen,2 Bathrooms",
                ),
              ),
              TextFormField(
                controller: constructionController,
                decoration: const InputDecoration(
                  labelText: "Construction details (comma-separated)",
                  hintText: "Built in 2018,Concrete,5th Floor",
                ),
              ),

              SizedBox(height: size.height * 0.04),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _saving
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
