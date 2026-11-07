// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_banner_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Kelola Banner. Setiap perubahan ikut menyegarkan slider Beranda.

@ProviderFor(AdminBannersNotifier)
final adminBannersProvider = AdminBannersNotifierProvider._();

/// Kelola Banner. Setiap perubahan ikut menyegarkan slider Beranda.
final class AdminBannersNotifierProvider
    extends $AsyncNotifierProvider<AdminBannersNotifier, AdminBannersState> {
  /// Kelola Banner. Setiap perubahan ikut menyegarkan slider Beranda.
  AdminBannersNotifierProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'adminBannersProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$adminBannersNotifierHash();

  @$internal
  @override
  AdminBannersNotifier create() => AdminBannersNotifier();
}

String _$adminBannersNotifierHash() =>
    r'0720eade3c749de309f1b0977517004c3fd346fb';

/// Kelola Banner. Setiap perubahan ikut menyegarkan slider Beranda.

abstract class _$AdminBannersNotifier
    extends $AsyncNotifier<AdminBannersState> {
  FutureOr<AdminBannersState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AdminBannersState>, AdminBannersState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<AdminBannersState>, AdminBannersState>,
        AsyncValue<AdminBannersState>,
        Object?,
        Object?>;
    element.handleCreate(ref, build);
  }
}
