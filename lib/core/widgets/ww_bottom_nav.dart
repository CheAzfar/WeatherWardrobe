import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WWBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const WWBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: Colors.black45,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.checkroom_rounded), label: 'Wardrobe'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_rounded), label: 'Shop'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}
