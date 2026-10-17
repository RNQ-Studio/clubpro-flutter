import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

/// Membaca data profil dari sesi auth yang sudah ada —
/// tidak perlu API call terpisah untuk Sprint 006.
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._authRepository);

  final AuthRepository _authRepository;

  @override
  Future<Profile?> getProfile() async {
    final user = await _authRepository.getCurrentUser();
    if (user == null) return null;
    return Profile(
      id: user.id,
      name: user.name,
      email: user.email,
      avatarUrl: user.avatarUrl,
    );
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    await _authRepository.updateProfile({
      'name': profile.name,
      'email': profile.email,
    });
  }
}
