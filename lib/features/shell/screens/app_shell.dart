import 'package:flutter/material.dart';

import '../../../core/widgets/ww_bottom_nav.dart';
import '../../home/screens/home_screen.dart';
import '../../wardrobe/screens/wardrobe_screen.dart';
import '../../shop/screens/shop_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../../core/constants/app_colors.dart';
import '../../wardrobe/screens/add_item_screen.dart';


class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  late final List<Widget> _tabs = const [
    HomeScreen(),
    WardrobeScreen(),
    ShopScreen(),
    ProfileScreen(),
  ];

  void _onTap(int newIndex) {
    setState(() => _index = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _tabs[_index]),
      bottomNavigationBar: WWBottomNav(
        currentIndex: _index,
        onTap: _onTap,
      ),  
    );
  }
}
