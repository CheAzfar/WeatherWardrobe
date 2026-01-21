import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/cloudinary_uploader.dart';
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
  final _descCtrl = TextEditingController();

  final _picker = ImagePicker();
  Uint8List? _imageBytes;

  String _category = 'Tops';
  String _warmth = 'Light';
  String _size = 'M'; // Default start value
  bool _saving = false;

  final List<String> _categories = const ['Tops', 'Bottoms', 'Outerwear', 'Shoes'];
  final List<String> _warmthLevels = const ['Light', 'Medium', 'Heavy'];

  // --- LOGIC: Separate Size Lists ---
  final List<String> _clothingSizes = const ['XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL'];
  final List<String> _shoeSizes = const [
    'EU 35', 'EU 36', 'EU 37', 'EU 38', 'EU 39', 'EU 40', 
    'EU 41', 'EU 42', 'EU 43', 'EU 44', 'EU 45', 'EU 46'
  ];

  // Helper to get correct list based on current category
  List<String> get _currentSizes {
    if (_category == 'Shoes') {
      return _shoeSizes;
    }
    return _clothingSizes;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  double? _parsePrice(String raw) {
    final cleaned = raw.trim().replaceAll('RM', '').replaceAll(',', '');
    final v = double.tryParse(cleaned);
    if (v == null) return null;
    if (v <= 0) return null;
    return v;
  }

  Future<void> _createListing() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an image')),
      );
      return;
    }

    final price = _parsePrice(_priceCtrl.text);
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final imageUrl = await CloudinaryUploader.uploadImageBytes(
        bytes: _imageBytes!,
        folder: 'weather_wardrobe/listings',
      );

      final listingId = await MarketplaceService.createListing(
        name: _nameCtrl.text.trim(),
        category: _category,
        warmthLevel: _warmth,
        price: price,
        imageUrl: imageUrl,
        size: _size,
        description: _descCtrl.text,
      );

      if (!mounted) return;

      if (listingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create listing failed')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create listing error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Sell Item')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _header(),
                const SizedBox(height: 14),

                // --- PHOTO ---
                _card(
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

                // --- DETAILS ---
                _card(
                  child: Column(
                    children: [
                      // Name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Item name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter item name';
                          if (v.trim().length < 2) return 'Name too short';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Price & Size Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _priceCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Price (RM)',
                                hintText: 'e.g., 25.00',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              validator: (v) {
                                final p = _parsePrice(v ?? '');
                                if (p == null) return 'Enter a valid price';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          
                          // --- UPDATED SIZE DROPDOWN ---
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _size,
                              isExpanded: true, // Prevents overflow for longer text
                              decoration: InputDecoration(
                                labelText: 'Size',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              items: _currentSizes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: _saving ? null : (v) => setState(() => _size = v!),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),

                      // Category & Warmth Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _category,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              items: _categories
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                              // --- LOGIC CHANGE HERE ---
                              onChanged: _saving ? null : (v) {
                                if (v == null) return;
                                setState(() {
                                  _category = v;
                                  
                                  // If we switched to shoes, pick default shoe size
                                  // If we switched to clothes, pick default clothes size
                                  if (_category == 'Shoes') {
                                    if (!_shoeSizes.contains(_size)) {
                                      _size = _shoeSizes[3]; // Default to ~38/39
                                    }
                                  } else {
                                    if (!_clothingSizes.contains(_size)) {
                                      _size = 'M'; // Default to M
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Condition, Brand, Material, etc.',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- BUTTON ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _createListing,
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
                            'Post Listing',
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

  Widget _header() {
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
          Icon(Icons.storefront_outlined, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Create Listing\nPhoto uploads to Cloudinary, listing saved to Firestore',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
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