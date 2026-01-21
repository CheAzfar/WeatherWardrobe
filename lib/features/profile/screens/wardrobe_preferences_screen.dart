import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class WardrobePreferencesScreen extends StatefulWidget {
  const WardrobePreferencesScreen({super.key});

  @override
  State<WardrobePreferencesScreen> createState() => _WardrobePreferencesScreenState();
}

class _WardrobePreferencesScreenState extends State<WardrobePreferencesScreen> {
  String _topSize = 'M';
  String _bottomSize = 'M';
  String _shoeSize = 'EU 40';
  bool _loading = false;

  final List<String> _clothingSizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _shoeSizes = List.generate(12, (index) => "EU ${35 + index}");

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('preferences')) {
      final data = doc.data()!['preferences'] as Map<String, dynamic>;
      setState(() {
        if (_clothingSizes.contains(data['topSize'])) _topSize = data['topSize'];
        if (_clothingSizes.contains(data['bottomSize'])) _bottomSize = data['bottomSize'];
        if (_shoeSizes.contains(data['shoeSize'])) _shoeSize = data['shoeSize'];
      });
    }
  }

  Future<void> _savePreferences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'preferences': {
          'topSize': _topSize,
          'bottomSize': _bottomSize,
          'shoeSize': _shoeSize,
        }
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preferences Saved!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wardrobe Preferences")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Help us find your fit.", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 30),
            
            _buildDropdown("Top Size", _topSize, _clothingSizes, (v) => setState(() => _topSize = v!)),
            _buildDropdown("Bottom Size", _bottomSize, _clothingSizes, (v) => setState(() => _bottomSize = v!)),
            _buildDropdown("Shoe Size", _shoeSize, _shoeSizes, (v) => setState(() => _shoeSize = v!)),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_loading ? "Saving..." : "Save Preferences"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}