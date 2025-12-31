import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../models/clothing_item.dart';

class EditItemScreen extends StatefulWidget {
  final dynamic itemKey; // Hive key can be int or String
  final ClothingItem item;

  const EditItemScreen({
    super.key,
    required this.itemKey,
    required this.item,
  });

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;

  final _picker = ImagePicker();

  late String _category;
  late String _warmth;

  File? _pickedImageFile; // newly selected image
  String? _existingImagePath; // existing saved path

  final List<String> _categories = const [
    'Tops',
    'Bottoms',
    'Outerwear',
    'Shoes',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _category = widget.item.category;
    _warmth = widget.item.warmthLevel;
    _existingImagePath = widget.item.imagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xfile == null) return;

    setState(() {
      _pickedImageFile = File(xfile.path);
    });
  }

  void _removeImage() {
    setState(() {
      _pickedImageFile = null;
      _existingImagePath = null; // remove existing too
    });
  }

  Future<String?> _persistImageIfAny() async {
    // if user picked a new image, copy into app storage
    if (_pickedImageFile != null) {
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
        return _pickedImageFile!.path;
      }
    }

    // otherwise keep existing image path (can be null)
    return _existingImagePath;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final imagePath = await _persistImageIfAny();

    final updated = ClothingItem(
      name: _nameCtrl.text.trim(),
      category: _category,
      warmthLevel: _warmth,
      imagePath: imagePath,
    );

    final box = Hive.box<ClothingItem>('wardrobeBox');
    await box.put(widget.itemKey, updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item updated')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final previewFile = _pickedImageFile;
    final previewPath = _existingImagePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _cardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Photo', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),

                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            color: AppColors.softGreen.withOpacity(0.6),
                          ),
                          child: (previewFile != null)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    previewFile,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                )
                              : (previewPath == null || previewPath.isEmpty)
                                  ? const SizedBox.expand(
                                      child: Center(
                                        child: Icon(Icons.image_outlined,
                                            size: 44, color: AppColors.primaryGreen),
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.file(
                                        File(previewPath),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Change'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: _removeImage,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                _cardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Details', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Item name',
                          prefixIcon: const Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter an item name';
                          if (v.trim().length < 2) return 'Name is too short';
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
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
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
                      const Text('Warmth', style: TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 6),
                      const Text(
                        'Choose how warm this clothing is.',
                        style: TextStyle(color: AppColors.textMuted),
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
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      onSelected: (_) => setState(() => _warmth = label),
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
}
