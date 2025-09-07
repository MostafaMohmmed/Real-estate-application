import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../modle/modproperty.dart';

class EditPropertyPage extends StatefulWidget {
  final PropertyModel property;
  const EditPropertyPage({super.key, required this.property});

  @override
  State<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends State<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late String _selectedType;
  File? _imageFile;

  final List<String> propertyTypes = ["House", "Apartment", "Office", "Land"];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property.title);
    _priceController = TextEditingController(text: widget.property.price);
    _locationController = TextEditingController(text: widget.property.location);
    _descriptionController =
        TextEditingController(text: widget.property.description);
    _selectedType = widget.property.type;

    if (widget.property.imagePath.isNotEmpty) {
      _imageFile = File(widget.property.imagePath);
    }
  }

  // ✅ اختيار صورة جديدة
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _imageFile = File(result.files.single.path!);
      });
    }
  }

  void _saveEdits() {
    if (_formKey.currentState!.validate()) {
      final editedProperty = PropertyModel(
        title: _titleController.text,
        price: _priceController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        type: _selectedType, // ✅ إذا تغير النوع، ينعكس على التبويب
        imagePath: _imageFile?.path ?? widget.property.imagePath,
      );

      Navigator.pop(context, editedProperty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Property")),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.04),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _imageFile == null
                    ? Container(
                  height: size.height * 0.25,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, size: 50),
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: size.height * 0.25,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.02),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Title"),
                validator: (v) =>
                v!.isEmpty ? "Please enter property title" : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Price"),
                keyboardType: TextInputType.number,
                validator: (v) =>
                v!.isEmpty ? "Please enter property price" : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Location"),
                validator: (v) =>
                v!.isEmpty ? "Please enter property location" : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Description"),
                maxLines: 3,
              ),

              SizedBox(height: size.height * 0.02),

              // ✅ اختيار نوع العقار (يتغير التبويب لما نحفظ)
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: propertyTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: const InputDecoration(labelText: "Type"),
              ),

              SizedBox(height: size.height * 0.04),

              ElevatedButton(
                onPressed: _saveEdits,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
