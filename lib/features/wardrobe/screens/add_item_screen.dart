import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/clothing_item.dart';

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
  File? _pickedImageFile;

  final List<String> _categories = const [
    'Tops',
    'Bottoms',
    'Outerwear',
    'Shoes',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (xfile == null) return;

      setState(() {
        _pickedImageFile = File(xfile.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _removeImage() {
    setState(() => _pickedImageFile = null);
  }

  Future<String?> _persistImageIfAny() async {
    if (_pickedImageFile == null) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final wardrobeDir = Directory(p.join(dir.path, 'wardrobe_images'));
      if (!await wardrobeDir.exists()) {
        await wardrobeDir.create(recursive: true);
      }

      final ext = p.extension(_pickedImageFile!.path);
      final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}$ext';
      final newPath = p.join(wardrobeDir.path, fileName);

      final savedFile = await _pickedImageFile!.copy(newPath);
      return savedFile.path;
    } catch (_) {
      // Fallback to original path (still works, but less durable across devices)
      return _pickedImageFile!.path;
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final imagePath = await _persistImageIfAny();

    final item = ClothingItem(
      name: _nameCtrl.text.trim(),
      category: _category,
      warmthLevel: _warmth,
      imagePath: imagePath,
    );

    final box = Hive.box<ClothingItem>('wardrobeBox');
    await box.add(item);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added to wardrobe')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Clothing Item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _heroHeader(),
                const SizedBox(height: 14),

                _cardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      _imagePickerCard(),
                      if (_pickedImageFile != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _removeImage,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Remove photo'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _cardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Item name',
                          hintText: 'e.g., White T-shirt',
                          prefixIcon: const Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter an item name';
                          }
                          if (v.trim().length < 2) {
                            return 'Name is too short';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _category = v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _cardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Warmth Level',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose how warm this clothing is.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _pillLabel(_category),
                          const SizedBox(width: 8),
                          _pillLabel(_warmth),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _warmthChoice('Light'),
                          _warmthChoice('Medium'),
                          _warmthChoice('Heavy'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                const Text(
                  'Tip: Add images for better wardrobe browsing.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- UI helpers ----------------

  Widget _heroHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withOpacity(0.95),
            AppColors.primaryGreen.withOpacity(0.55),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Item',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Save items with category and warmth level',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _imagePickerCard() {
    final hasImage = _pickedImageFile != null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          color: AppColors.softGreen.withOpacity(0.6),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _pickedImageFile!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            : SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.image_outlined, size: 44, color: AppColors.primaryGreen),
                    SizedBox(height: 10),
                    Text(
                      'Tap to choose an image',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Recommended for better browsing',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _warmthChoice(String label) {
    final selected = _warmth == label;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: selected ? AppColors.primaryGreen : Colors.black87,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.softGreen,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      onSelected: (_) => setState(() => _warmth = label),
    );
  }

  Widget _pillLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        color: Colors.white,
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
