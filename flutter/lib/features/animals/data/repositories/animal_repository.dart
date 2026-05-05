import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/animal.dart';

abstract class AnimalRepository {
  Future<List<Animal>> getAnimals();
  Future<Animal?> getAnimalById(String id);
}

class MockAnimalRepository implements AnimalRepository {
  final List<Animal> _mockAnimals = [
    Animal(
      id: '1',
      name: 'লক্ষ্মী',
      type: 'গরু',
      breed: 'হলস্টাইন ফ্রিজিয়ান',
      age: '৩ বছর ২ মাস',
      imageUrl: 'https://placeholder.com/cow1.png',
      healthScore: 92,
      lastChecked: 'আজ সকাল ৮:০০',
    ),
    Animal(
      id: '2',
      name: 'লাল্টু',
      type: 'ষাঁড়',
      breed: 'ব্রাহ্মা',
      age: '৪ বছর ১ মাস',
      imageUrl: 'https://placeholder.com/bull1.png',
      healthScore: 88,
      lastChecked: 'গতকাল সন্ধ্যা ৬:৩০',
    ),
  ];

  @override
  Future<List<Animal>> getAnimals() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockAnimals;
  }

  @override
  Future<Animal?> getAnimalById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockAnimals.firstWhere((a) => a.id == id, orElse: () => _mockAnimals[0]);
  }
}

final animalRepositoryProvider = Provider<AnimalRepository>((ref) {
  return MockAnimalRepository();
});

final animalsProvider = FutureProvider<List<Animal>>((ref) {
  final repository = ref.watch(animalRepositoryProvider);
  return repository.getAnimals();
});
