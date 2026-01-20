import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  // Keep your existing labels to avoid breaking your current data.
  // (If you want, later we can standardize Heavy -> Warm.)
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Item')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter item name';
                  if (v.trim().length < 2) return 'Name too short';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _saving ? null : (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _warmth,
                decoration: const InputDecoration(
                  labelText: 'Warmth',
                  border: OutlineInputBorder(),
                ),
                items: _warmths
                    .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                    .toList(),
                onChanged: _saving ? null : (v) => setState(() => _warmth = v ?? _warmth),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: _saving ? null : _pickNewImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _newImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_newImageBytes!, fit: BoxFit.cover),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (widget.initialImageUrl.isNotEmpty)
                              ? Image.network(
                                  widget.initialImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Center(child: Icon(Icons.broken_image)),
                                )
                              : const Center(child: Icon(Icons.image_outlined)),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
