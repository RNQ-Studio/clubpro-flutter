// auth — domain
export 'src/auth/domain/entities/user.dart';
export 'src/auth/domain/repositories/auth_repository.dart';
export 'src/auth/domain/usecases/get_current_user_use_case.dart';
export 'src/auth/domain/usecases/login_use_case.dart';
export 'src/auth/domain/usecases/logout_use_case.dart';
export 'src/auth/domain/usecases/register_use_case.dart';

// auth — data
export 'src/auth/data/models/user_model.dart';
export 'src/auth/data/datasources/auth_local_data_source.dart';
export 'src/auth/data/datasources/auth_remote_data_source.dart';
export 'src/auth/data/repositories/auth_repository_impl.dart';
export 'src/auth/data/biometric_auth_service.dart';
export 'src/auth/data/google_sign_in_service.dart';

// auth — presentation
export 'src/auth/presentation/auth_guard.dart';
export 'src/auth/presentation/auth_provider.dart';
export 'src/auth/presentation/auth_routes.dart';
export 'src/auth/presentation/auth_state.dart';
export 'src/auth/presentation/login_screen.dart';
export 'src/auth/presentation/google_login_screen.dart';

// profile — domain
export 'src/profile/domain/entities/profile.dart';
export 'src/profile/domain/entities/member_profile.dart';
export 'src/profile/domain/repositories/profile_repository.dart';
export 'src/profile/domain/usecases/get_profile_use_case.dart';
export 'src/profile/domain/usecases/update_profile_use_case.dart';

// profile — data
export 'src/profile/data/repositories/profile_repository_impl.dart';

// profile — presentation
export 'src/profile/presentation/profile_provider.dart';
export 'src/profile/presentation/profile_screen.dart';
export 'src/profile/presentation/edit_profile_screen.dart';
export 'src/profile/presentation/member_profile_form.dart';
export 'src/profile/presentation/profile_setup_screen.dart';
export 'src/profile/presentation/widgets/profile_avatar_picker.dart';
export 'src/profile/presentation/widgets/profile_completion_card.dart';

// notifications — domain
export 'src/notifications/domain/entities/app_notification.dart';
export 'src/notifications/domain/repositories/notifications_repository.dart';
export 'src/notifications/domain/usecases/get_notifications_use_case.dart';

// notifications — data
export 'src/notifications/data/repositories/notifications_repository_impl.dart';

// notifications — presentation
export 'src/notifications/presentation/notifications_provider.dart';
export 'src/notifications/presentation/notifications_screen.dart';

// settings — domain
export 'src/settings/domain/repositories/settings_repository.dart';

// settings — data
export 'src/settings/data/repositories/settings_repository_impl.dart';

// settings — presentation
export 'src/settings/presentation/settings_providers.dart';
export 'src/settings/presentation/theme_notifier.dart';
export 'src/settings/presentation/locale_notifier.dart';

// onboarding — domain
export 'src/onboarding/domain/onboarding_repository.dart';

// onboarding — data
export 'src/onboarding/data/onboarding_repository_impl.dart';

// onboarding — presentation
export 'src/onboarding/presentation/onboarding_notifier.dart';
export 'src/onboarding/presentation/splash_screen.dart';
export 'src/onboarding/presentation/onboarding_screen.dart';
