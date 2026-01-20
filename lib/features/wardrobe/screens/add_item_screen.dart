import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/cloudinary_uploader.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _picker = ImagePicker();

  String _category = 'Tops';
  String _warmth = 'Light';
  Uint8List? _imageBytes;

  bool _saving = false;

  final List<String> _categories = const ['Tops', 'Bottoms', 'Outerwear', 'Shoes'];
  final List<String> _warmthLevels = const ['Light', 'Medium', 'Heavy'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _saveItem() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an image first')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // 1) Upload to Cloudinary
      final imageUrl = await CloudinaryUploader.uploadImageBytes(
        bytes: _imageBytes!,
        folder: 'weather_wardrobe/wardrobe',
      );

      // 2) Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('wardrobe_items')
          .add({
        'name': _nameCtrl.text.trim(),
        'category': _category,
        'warmthLevel': _warmth,
        'imageUrl': imageUrl,
        'source': 'manual',
        // IMPORTANT: WardrobeScreen orders by createdAt
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added to wardrobe')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _headerCard(),
                const SizedBox(height: 14),

                _cardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Photo', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _saving ? null : _pickImage,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            color: AppColors.softGreen.withValues(alpha: 0.55),
                          ),
                          child: _imageBytes == null
                              ? const Center(
                                  child: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 44,
                                    color: AppColors.primaryGreen,
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _imageBytes == null ? 'Tap to choose an image' : 'Image selected',
                        style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _cardShell(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Item name',
                          hintText: 'e.g., White T-shirt',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter item name';
                          if (v.trim().length < 2) return 'Name too short';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: _saving ? null : (v) => setState(() => _category = v ?? _category),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _warmth,
                        decoration: InputDecoration(
                          labelText: 'Warmth',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: _warmthLevels
                            .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                            .toList(),
                        onChanged: _saving ? null : (v) => setState(() => _warmth = v ?? _warmth),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.95),
            AppColors.primaryGreen.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.checkroom_outlined, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add Wardrobe Item\nSaved to Firestore (Cloudinary image URL)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
