import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/cloudinary_uploader.dart';

class EditItemScreen extends StatefulWidget {
  const EditItemScreen({
    super.key,
    required this.docId,
    required this.initialName,
    required this.initialCategory,
    required this.initialWarmth,
    required this.initialImageUrl,
  });

  final String docId;
  final String initialName;
  final String initialCategory;
  final String initialWarmth;
  final String initialImageUrl;

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;

  final _categories = const ['Tops', 'Bottoms', 'Outerwear', 'Shoes'];
  final _warmths = const ['Light', 'Medium', 'Heavy'];

  late String _category;
  late String _warmth;

  Uint8List? _newImageBytes;
  String _fileExt = 'jpg';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _category = widget.initialCategory;
    _warmth = widget.initialWarmth;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickNewImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null) return;

    final file = result.files.single;
    if (file.bytes == null) return;

    setState(() {
      _newImageBytes = file.bytes!;
      _fileExt = (file.extension ?? 'jpg').toLowerCase();
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      String finalImageUrl = widget.initialImageUrl;

      // Upload only if user selected a new image
      if (_newImageBytes != null) {
        finalImageUrl = await CloudinaryUploader.uploadImageBytes(
          bytes: _newImageBytes!,
          folder: 'weather_wardrobe/wardrobe',
        );
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wardrobe_items')
          .doc(widget.docId)
          .update({
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'warmthLevel': _warmth,
        'imageUrl': finalImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light modern background
      appBar: AppBar(
        title: const Text('Edit Item', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- 1. IMAGE PICKER SECTION ---
              GestureDetector(
                onTap: _saving ? null : _pickNewImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Image display
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: _newImageBytes != null
                            ? Image.memory(_newImageBytes!, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                            : (widget.initialImageUrl.isNotEmpty
                                ? Image.network(
                                    widget.initialImageUrl,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                  )
                                : Container(
                                    color: AppColors.softGreen.withOpacity(0.2),
                                    child: const Center(child: Icon(Icons.image_outlined, size: 50, color: AppColors.primaryGreen)),
                                  )),
                      ),
                      // Edit Overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.black.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.edit, color: AppColors.primaryGreen, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Tap image to change",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // --- 2. FORM FIELDS SECTION ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Name Field
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        hintText: "e.g. Denim Jacket",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.checkroom_outlined, color: Colors.grey),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter item name';
                        if (v.trim().length < 2) return 'Name too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Dropdowns Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: _saving ? null : (v) => setState(() => _category = v ?? _category),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _warmth,
                            decoration: InputDecoration(
                              labelText: 'Warmth',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: _warmths.map((w) => DropdownMenuItem(value: w, child: Text(w))).toList(),
                            onChanged: _saving ? null : (v) => setState(() => _warmth = v ?? _warmth),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- 3. SAVE BUTTON ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: AppColors.primaryGreen.withOpacity(0.4),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Update Item',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}