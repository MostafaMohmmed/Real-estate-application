import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'settings/map_picker_page.dart'; // عدّل المسار لو مختلف لديك
import 'package:final_iug_2025/services/plan_service.dart';
import 'package:final_iug_2025/screen/Company/paywall/paywall_page.dart';

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
  final addressController = TextEditingController();
  final priceController = TextEditingController();

  final areaSqftController = TextEditingController();
  final bedsController = TextEditingController();
  final bathsController = TextEditingController();

  final amenitiesController = TextEditingController();
  final interiorController = TextEditingController();
  final constructionController = TextEditingController();

  String selectedType = "House";
  Uint8List? _imageBytes;
  bool _saving = false;

  double? _lat;
  double? _lng;
  String? _pickedAddress;

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    addressController.dispose();
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

  Future<void> _openMapPicker() async {
    final res = await Navigator.push<MapPickResult?>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerPage()),
    );
    if (res == null) return;
    setState(() {
      _lat = res.lat;
      _lng = res.lng;
      _pickedAddress = res.address;
      if (res.address.trim().isNotEmpty) {
        addressController.text = res.address;
      }
    });
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

    setState(() => _saving = true);

    // ✅ فحص الخطة قبل الحفظ
    final planService = PlanService();
    final plan = await planService.getCompanyPlan(user.uid) ?? {};
    if (!planService.canPostNow(plan)) {
      final ok = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const PaywallPage()),
      );
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your plan request is pending.')),
        );
      }
      setState(() => _saving = false);
      return;
    }

    // التحقق من السعر
    final price = double.tryParse(priceController.text.trim());
    if (price == null || price.isNaN || price.isNegative) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be a valid non-negative number.')),
      );
      setState(() => _saving = false);
      return;
    }

    final areaSqft = double.tryParse(areaSqftController.text.trim()) ?? 0;
    final beds     = int.tryParse(bedsController.text.trim()) ?? 0;
    final baths    = int.tryParse(bathsController.text.trim()) ?? 0;

    final amenities   = _splitToList(amenitiesController.text);
    final interior    = _splitToList(interiorController.text);
    final construction= _splitToList(constructionController.text);

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

      final col = _db.collection('companies').doc(user.uid).collection('properties');

      final data = <String, dynamic>{
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'address': addressController.text.trim(),
        'location': addressController.text.trim(),
        'price': price,
        'type': selectedType,
        'imageBlob': blob,
        'createdAt': FieldValue.serverTimestamp(),
        'ownerUid': user.uid,
        'ownerName': user.displayName ?? 'Company',
        'ownerEmail': (user.email ?? '').toLowerCase(),
        'ownerImageUrl': user.photoURL ?? '',
        'areaSqft': areaSqft,
        'beds': beds,
        'baths': baths,
        'amenities': amenities,
        'interior': interior,
        'construction': construction,
      };

      if (_lat != null && _lng != null) {
        data['geo'] = GeoPoint(_lat!, _lng!);
      }

      await col.add(data);

      // ✅ خصم خانة من الرصيد
      await planService.consumeOneSlot(user.uid);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property added successfully')),
      );

      // إعادة الضبط
      titleController.clear();
      descController.clear();
      addressController.clear();
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
        _lat = null;
        _lng = null;
        _pickedAddress = null;
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

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: "Address"),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Pick on Map'),
                  ),
                ],
              ),
              if (_lat != null && _lng != null) ...[
                const SizedBox(height: 6),
                if ((_pickedAddress ?? '').isNotEmpty) Text(_pickedAddress!),
                Text(
                  'Lat: ${_lat!.toStringAsFixed(6)}, Lng: ${_lng!.toStringAsFixed(6)}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],

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
