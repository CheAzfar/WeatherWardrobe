import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shop/screens/purchase_history_screen.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // 1. Helper to get the current user
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // AuthGate will automatically handle the redirection to LoginScreen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. Extract real data (with fallbacks)
    final String userName = currentUser?.displayName ?? "Weather Wardrobe User";
    final String userEmail = currentUser?.email ?? "No Email";
    final String? photoUrl = currentUser?.photoURL;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // --- 1. PROFILE HEADER (REAL DATA) ---
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 10,
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        // 3. Show Real Photo or Default Icon
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: photoUrl != null 
                              ? NetworkImage(photoUrl) 
                              : null,
                          child: photoUrl == null
                              ? const Icon(Icons.person, size: 50, color: Colors.grey)
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          height: 36,
                          width: 36,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- 2. MENU SECTIONS ---
            
            _buildSectionHeader("Account"),
            _buildMenuOption(
              context,
              icon: Icons.person_outline,
              title: "Edit Profile",
              onTap: () {
                // Navigate to Edit Profile
              },
            ),
            _buildMenuOption(
              context,
              icon: Icons.checkroom_outlined,
              title: "Wardrobe Preferences",
              subtitle: "Sizes, style preferences",
              onTap: () {
                // Navigate to Preferences
              },
            ),
            
            const SizedBox(height: 20),

            // ... inside ProfileScreen ...

            _buildSectionHeader("Activity"),
            
            // CORRECTED STREAM:
            StreamBuilder<QuerySnapshot>(
              stream: currentUser != null 
                  ? FirebaseFirestore.instance
                      .collection('orders') // Look in 'orders'
                      .where('buyerId', isEqualTo: currentUser!.uid) // Filter by this user
                      .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                final int orderCount = snapshot.data?.docs.length ?? 0;
                
                return _buildMenuOption(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  title: "Purchase History",
                  trailing: orderCount > 0 
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "$orderCount Orders", 
                          style: TextStyle(
                            color: Theme.of(context).primaryColor, 
                            fontSize: 12,
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      )
                    : null,
                  onTap: () {
                     // Ensure you have imported the PurchaseHistoryScreen at the top
                     Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PurchaseHistoryScreen()),
                    );
                  },
                );
              },
            ),
            // ... rest of the code
            const SizedBox(height: 20),

            _buildSectionHeader("General"),
            _buildMenuOption(
              context,
              icon: Icons.settings_outlined,
              title: "Settings",
              onTap: () {
                // Navigate to Settings
              },
            ),

            const SizedBox(height: 30),

            // --- 3. LOGOUT BUTTON (FUNCTIONAL) ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _signOut(context), // Calls the real logout
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.red,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "Log Out",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12, 
                            color: Colors.grey[500]
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey[300],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
