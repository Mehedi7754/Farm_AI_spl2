import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/strings_bn.dart';
import '../../data/repositories/animal_repository.dart';
import '../widgets/hero_stats.dart';
import '../widgets/animal_card.dart';

class AnimalListScreen extends ConsumerWidget {
  const AnimalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animalsAsync = ref.watch(animalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          HeroStats(animalsAsync: animalsAsync),
          Expanded(
            child: animalsAsync.when(
              data: (animals) => ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: animals.length,
                itemBuilder: (context, index) => AnimalCard(animal: animals[index]),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              ),
              error: (err, _) => Center(
                child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50), size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text(
        StringsBn.myAnimals,
        style: const TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Color(0xFF2C3E50)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {},
      backgroundColor: const Color(0xFF2E7D32),
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'নতুন প্রাণী',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
