import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../../domain/models/animal.dart';

class HeroStats extends StatelessWidget {
  final AsyncValue<List<Animal>> animalsAsync;

  const HeroStats({super.key, required this.animalsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            StringsBn.registeredAnimals,
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              animalsAsync.when(
                data: (animals) => Text(
                  '${animals.length} টি প্রাণী',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                loading: () => const Text(' লোড হচ্ছে...', style: TextStyle(color: Colors.white, fontSize: 24)),
                error: (_, __) => const Text('০ টি প্রাণী', style: TextStyle(color: Colors.white, fontSize: 32)),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pets_rounded, color: Colors.white, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniIndicator(Icons.check_circle_rounded, 'সুস্থ: ১০০%', Colors.greenAccent),
              const SizedBox(width: 16),
              _buildMiniIndicator(Icons.warning_rounded, 'সতর্কতা: ০', Colors.orangeAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIndicator(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
