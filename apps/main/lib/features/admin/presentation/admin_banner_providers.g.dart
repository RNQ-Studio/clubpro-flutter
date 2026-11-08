// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_banner_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Paid Promotion. Setiap perubahan ikut menyegarkan popup Beranda.

@ProviderFor(AdminBannersNotifier)
final adminBannersProvider = AdminBannersNotifierProvider._();

/// Paid Promotion. Setiap perubahan ikut menyegarkan popup Beranda.
final class AdminBannersNotifierProvider
    extends $AsyncNotifierProvider<AdminBannersNotifier, AdminBannersState> {
  /// Paid Promotion. Setiap perubahan ikut menyegarkan popup Beranda.
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
    r'b6d539be09bb73d1a418f4048048f8198f046020';

/// Paid Promotion. Setiap perubahan ikut menyegarkan popup Beranda.

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
