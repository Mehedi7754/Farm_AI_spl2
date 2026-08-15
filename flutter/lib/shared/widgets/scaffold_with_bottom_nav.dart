import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/strings_bn.dart';
import '../../core/network/api_client.dart';

class ScaffoldWithBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final user = ApiClient.currentUser;
    final isVet = user?['role'] == 'VET';

    return Scaffold(
      extendBody: false, // Connected bottom bar, content sits nicely above nav bar
      body: navigationShell,
      bottomNavigationBar: isVet ? null : _buildConnectedBottomNavBar(context),
    );
  }

  Widget _buildConnectedBottomNavBar(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 0.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFFA7F3D0), width: 0.9) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF047857) : const Color(0xFF64748B),
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF047857),
                  letterSpacing: -0.2,
                ),
              ),
            ],
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
