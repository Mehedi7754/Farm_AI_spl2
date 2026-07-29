import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? user;

  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    initAuth();
  }

  Future<void> initAuth() async {
    await ApiClient.loadPersistedAuth();
    if (ApiClient.currentUser != null) {
      state = state.copyWith(user: ApiClient.currentUser);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await ApiClient.login(email: email, password: password);
      
      // If it reaches here without throwing, it's successful
      final token = res['token'];
      final user = res['user'];
      ApiClient.setAuthData(token, user);

      state = state.copyWith(isLoading: false, user: user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Network error occurred. Please check your connection.');
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (state.user == null || state.user!['id'] == null) return false;
    final userId = state.user!['id'];

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updatedUser = await ApiClient.updateUser(userId, updates);
      final newUserMap = {
        ...?state.user,
        ...updatedUser,
      };
      ApiClient.setAuthData(ApiClient.authToken ?? '', newUserMap);
      state = state.copyWith(isLoading: false, user: newUserMap);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'প্রোফাইল আপডেট ব্যর্থ হয়েছে।');
      return false;
    }
  }

  void logout() {
    ApiClient.logout();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
