import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../network/api_client.dart';

class AuthNotifier extends StateNotifier<UserModel?> {
  AuthNotifier() : super(null) {
    _loadPersistedUser();
  }

  Future<void> _loadPersistedUser() async {
    final user = await AuthStorage.loadUser();
    if (mounted) state = user;
  }

  Future<void> login(String email, String password) async {
    final res = await ApiClient.login(email: email, password: password);
    final user = UserModel.fromJson(res['user'] ?? res);
    state = user;
    await AuthStorage.saveUser(user);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? location,
    String role = 'FARMER',
    String? licenseNumber,
    String? specialization,
    int? experienceYears,
    double? consultationFee,
    String? availableFrom,
    String? availableTo,
    List<String>? availableDays,
    String? bio,
    String? district,
  }) async {
    final res = await ApiClient.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      location: location,
      role: role,
    );

    final user = UserModel.fromJson(res['user'] ?? res);
    state = user;
    await AuthStorage.saveUser(user);

    // If vet, create vet profile
    if (role == 'VET' && licenseNumber != null && specialization != null) {
      await ApiClient.createVetProfile(
        userId: user.id,
        licenseNumber: licenseNumber,
        specialization: specialization,
        experienceYears: experienceYears,
        consultationFee: consultationFee,
        availableFrom: availableFrom,
        availableTo: availableTo,
        availableDays: availableDays,
        bio: bio,
        district: district,
      );
    }
  }

  Future<void> logout() async {
    state = null;
    await AuthStorage.clearUser();
  }

  void updateUser(UserModel updated) {
    state = updated;
    AuthStorage.saveUser(updated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  return AuthNotifier();
});

// Convenience providers
final currentUserProvider = Provider<UserModel?>((ref) => ref.watch(authProvider));
final isVetProvider = Provider<bool>((ref) => ref.watch(authProvider)?.isVet ?? false);
final isFarmerProvider = Provider<bool>((ref) => ref.watch(authProvider)?.isFarmer ?? false);
