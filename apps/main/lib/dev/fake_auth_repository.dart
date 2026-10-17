import 'package:features_shared/features_shared.dart';

class FakeAuthRepository implements AuthRepository {
  User? _currentUser;

  @override
  Future<User> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = User(id: 'dev-001', name: 'Dev User', email: email);
    return _currentUser!;
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = User(id: 'dev-001', name: name, email: email);
    return _currentUser!;
  }

  @override
  Future<User> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 400));
    _currentUser = const User(
      id: 'dev-001',
      name: 'Dev User',
      email: 'dev@example.com',
    );
    return _currentUser!;
  }

  @override
  Future<void> clearSession() async {
    _currentUser = null;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async => _currentUser;

  @override
  Future<User> updateProfile(Map<String, Object?> fields) async {
    final current = _currentUser!;
    _currentUser = User(
      id: current.id,
      name: (fields['name'] as String?) ?? current.name,
      email: current.email,
    );
    return _currentUser!;
  }

  @override
  Future<User> uploadAvatar(String filePath) async {
    _currentUser = User(
      id: _currentUser?.id ?? 'dev-001',
      name: _currentUser?.name ?? 'Dev User',
      email: _currentUser?.email ?? 'dev@example.com',
      phone: _currentUser?.phone,
      avatarUrl: filePath,
      roles: _currentUser?.roles ?? const [],
    );
    return _currentUser!;
  }
}
