import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/datasources/auth_local_data_source.dart';
import '../data/repositories/pin_repository_impl.dart';
import '../domain/repositories/pin_repository.dart';
import 'auth_repository_provider.dart';
part 'pin_provider.g.dart';

@riverpod
PinRepository pinRepository(Ref ref) => PinRepositoryImpl(
    ref.watch(apiClientProvider).dio,
    AuthLocalDataSource(ref.watch(storageServiceProvider)));
