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
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: isVet ? null : _buildBlurVignetteProDock(context),
    );
  }

  Widget _buildBlurVignetteProDock(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // 1. Sleek Bottom Vignette Gradient View Fade
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 100,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0x180F172A),
                    Color(0x3B047857),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        // 2. Translucent Glass Dock with Backdrop Blur & Ambient Glow
        SafeArea(
          bottom: true,
          child: Container(
            height: 64,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                // Professional Ambient Blue Glow below the dock
                const BoxShadow(
                  color: Color(0x400284C7),
                  blurRadius: 24,
                  spreadRadius: 1,
                  offset: Offset(0, 8),
                ),
                // Soft Emerald Shadow
                const BoxShadow(
                  color: Color(0x20047857),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xEFF4FBF7), // Translucent Theme Green Tint
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xD0A7F3D0), width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildDockItem(context, 0, Icons.grid_view_rounded, Icons.grid_view_outlined, StringsBn.navHome, selectedIndex == 0),
                      _buildDockItem(context, 1, Icons.pets_rounded, Icons.pets_outlined, StringsBn.navAnimals, selectedIndex == 1),
                      _buildDockItem(context, 2, Icons.forum_rounded, Icons.forum_outlined, StringsBn.navCommunity, selectedIndex == 2),
                      _buildDockItem(context, 3, Icons.person_rounded, Icons.person_outline_rounded, StringsBn.navProfile, selectedIndex == 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDockItem(BuildContext context, int index, IconData activeIcon, IconData inactiveIcon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF059669).withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? Colors.white : const Color(0xFF047857),
              size: isSelected ? 22 : 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
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
