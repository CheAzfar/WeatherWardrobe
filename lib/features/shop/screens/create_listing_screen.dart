import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../services/marketplace_service.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
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
    _priceCtrl.dispose();
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

  Future<String?> _persistImage() async {
    if (_pickedImageFile == null) return null;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final wardrobeDir = Directory(p.join(dir.path, 'wardrobe_images'));
      if (!await wardrobeDir.exists()) {
        await wardrobeDir.create(recursive: true);
      }

      final ext = p.extension(_pickedImageFile!.path);
      final fileName = 'listing_${DateTime.now().millisecondsSinceEpoch}$ext';
      final newPath = p.join(wardrobeDir.path, fileName);

      final savedFile = await _pickedImageFile!.copy(newPath);
      return savedFile.path;
    } catch (_) {
      return _pickedImageFile!.path;
    }
  }

  Future<void> _createListing() async {
    if (!_formKey.currentState!.validate()) return;

    final imagePath = await _persistImage();

    final listingId = await MarketplaceService.createListing(
      name: _nameCtrl.text.trim(),
      category: _category,
      warmthLevel: _warmth,
      price: double.parse(_priceCtrl.text.trim()),
      imagePath: imagePath,
    );

    if (!mounted) return;

    if (listingId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create listing')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Listing')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _cardShell(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Photo',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            color: AppColors.softGreen.withOpacity(0.6),
                          ),
                          child: _pickedImageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _pickedImageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 44,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                        ),
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
                        'Details',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Item name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter item name'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Price (RM)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'Enter price';
                          if (double.tryParse(v) == null)
                            return 'Invalid price';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _category = v!),
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
                        'Warmth',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          _warmthChip('Light'),
                          _warmthChip('Medium'),
                          _warmthChip('Heavy'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Create Listing'),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _warmthChip(String label) {
    final selected = _warmth == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _warmth = label),
      selectedColor: AppColors.softGreen,
      side: const BorderSide(color: AppColors.border),
    );
  }
}
