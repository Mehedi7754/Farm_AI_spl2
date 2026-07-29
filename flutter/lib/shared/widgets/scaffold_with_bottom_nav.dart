import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/strings_bn.dart';

class ScaffoldWithBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _buildConnectedBottomNav(context),
    );
  }

  Widget _buildConnectedBottomNav(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(context, 0, Icons.grid_view_rounded, Icons.grid_view_outlined, StringsBn.navHome, selectedIndex == 0),
              _buildNavItem(context, 1, Icons.pets_rounded, Icons.pets_outlined, StringsBn.navAnimals, selectedIndex == 1),
              _buildNavItem(context, 2, Icons.forum_rounded, Icons.forum_outlined, StringsBn.navCommunity, selectedIndex == 2),
              _buildNavItem(context, 3, Icons.person_rounded, Icons.person_outline_rounded, StringsBn.navProfile, selectedIndex == 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData activeIcon, IconData inactiveIcon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B),
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
