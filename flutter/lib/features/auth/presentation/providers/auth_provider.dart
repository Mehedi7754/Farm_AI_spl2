import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/call_service.dart';

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
    _init();
  }

  Future<void> _init() async {
    await ApiClient.loadPersistedAuth();
    if (ApiClient.currentUser != null) {
      state = state.copyWith(user: ApiClient.currentUser);
      // Start listening for incoming calls
      final userId = ApiClient.currentUser!['id'] as String?;
      if (userId != null) CallService().connect(userId);
    }
  }

  Future<void> initAuth() async {
    await _init();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await ApiClient.login(email: email, password: password);

      final token = res['token'];
      final user = res['user'];
      ApiClient.setAuthData(token, user);

      state = state.copyWith(isLoading: false, user: user);
      // Start listening for incoming calls
      final userId = user['id'] as String?;
      if (userId != null) CallService().connect(userId);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Network error occurred. Please check your connection.');
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await ApiClient.register(
        email: data['email'] ?? '',
        password: data['password'] ?? '',
        name: data['name'] ?? '',
        phone: data['phone'] ?? data['phoneNumber'],
        role: data['role'] ?? 'FARMER',
      );
      final token = res['token'];
      final user = res['user'];
      ApiClient.setAuthData(token, user);

      state = state.copyWith(isLoading: false, user: user);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Registration failed.');
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates, [String? userId]) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final targetId = userId ?? state.user?['id'] ?? '';
      final updatedUser = await ApiClient.updateUser(targetId, updates);
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
    CallService().disconnect();
    ApiClient.logout();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
