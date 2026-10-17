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
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async => _currentUser;

  @override
  Future<User> updateProfile(
      {required String name, required String email}) async {
    _currentUser = User(
      id: _currentUser?.id ?? 'dev-001',
      name: name,
      email: email,
      phone: _currentUser?.phone,
      avatarUrl: _currentUser?.avatarUrl,
      roles: _currentUser?.roles ?? const [],
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
