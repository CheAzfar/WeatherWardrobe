import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../shop/screens/purchase_history_screen.dart';
import 'edit_profile_screen.dart';
import '../../shop/screens/sales_history_screen.dart';
import 'wardrobe_preferences_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Wrap in StreamBuilder to update Profile info immediately after editing
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final String userName = user?.displayName ?? "Weather Wardrobe User";
        final String userEmail = user?.email ?? "No Email";
        final String? photoUrl = user?.photoURL;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                // --- PROFILE HEADER ---
                const SizedBox(height: 10),
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                              child: photoUrl == null ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                              child: Container(
                                height: 36, width: 36,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                ),
                                child: const Icon(Icons.edit, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(userEmail, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- ACCOUNT SECTIONS ---
                _buildSectionHeader("Account"),
                _buildMenuOption(
                  context,
                  icon: Icons.person_outline,
                  title: "Edit Profile",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                ),
                _buildMenuOption(
                  context,
                  icon: Icons.checkroom_outlined,
                  title: "Wardrobe Preferences",
                  subtitle: "Sizes, style preferences",
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WardrobePreferencesScreen())),
                ),

                const SizedBox(height: 20),
                _buildSectionHeader("Activity"),

                // Purchase History (Badge Logic)
                StreamBuilder<QuerySnapshot>(
                  stream: currentUser != null 
                      ? FirebaseFirestore.instance.collection('orders').where('buyerId', isEqualTo: currentUser!.uid).snapshots()
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    final int orderCount = snapshot.data?.docs.length ?? 0;
                    return _buildMenuOption(
                      context,
                      icon: Icons.shopping_bag_outlined,
                      title: "Purchase History",
                      trailing: orderCount > 0 
                        ? _badge(context, "$orderCount Orders") 
                        : null,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen())),
                    );
                  },
                ),

                // NEW: Sales Dashboard (Total Sales Logic)
                StreamBuilder<QuerySnapshot>(
                  stream: currentUser != null 
                      ? FirebaseFirestore.instance.collection('marketplace_listings')
                          .where('sellerId', isEqualTo: currentUser!.uid)
                          .where('status', isEqualTo: 'sold')
                          .snapshots()
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    double totalEarned = 0;
                    for (var d in docs) totalEarned += (d['price'] ?? 0);

                    return _buildMenuOption(
                      context,
                      icon: Icons.monetization_on_outlined,
                      title: "Sales Dashboard",
                      subtitle: "Items you've sold",
                      trailing: totalEarned > 0 
                        ? _badge(context, "RM ${totalEarned.toStringAsFixed(0)}", color: Colors.green)
                        : null,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
                    );
                  },
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _signOut(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badge(BuildContext context, String text, {Color? color}) {
    final c = color ?? Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, {required IconData icon, required String title, String? subtitle, Widget? trailing, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])) : null,
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[300]),
      ),
    );
  }
}