import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/cloudinary_uploader.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _picker = ImagePicker();
  
  Uint8List? _newImageBytes;
  bool _loading = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = _user?.displayName ?? '';
  }

  Future<void> _pickImage() async {
    final xFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      setState(() => _newImageBytes = bytes);
    }
  }

  Future<void> _saveProfile() async {
    if (_user == null) return;
    setState(() => _loading = true);

    try {
      // 1. Upload Image if changed
      if (_newImageBytes != null) {
        final url = await CloudinaryUploader.uploadImageBytes(
          bytes: _newImageBytes!,
          folder: 'weather_wardrobe/profiles',
        );
        await _user!.updatePhotoURL(url);
      }

      // 2. Update Name
      if (_nameCtrl.text.trim() != _user!.displayName) {
        await _user!.updateDisplayName(_nameCtrl.text.trim());
      }

      // 3. Force reload to update UI immediately
      await _user!.reload();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar Picker
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _newImageBytes != null
                        ? MemoryImage(_newImageBytes!)
                        : (_user?.photoURL != null ? NetworkImage(_user!.photoURL!) : null) as ImageProvider?,
                    child: (_newImageBytes == null && _user?.photoURL == null)
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        backgroundColor: AppColors.primaryGreen,
                        radius: 18,
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: "Display Name",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}