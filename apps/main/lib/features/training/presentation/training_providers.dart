import 'package:features_shared/features_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/training_remote_data_source.dart';
import '../data/training_repository_impl.dart';
import '../domain/training.dart';
import '../domain/training_repository.dart';
part 'training_providers.g.dart';

Duration? _noRetry(int count, Object error) => null;
@Riverpod(keepAlive: true)
TrainingRepository trainingRepository(Ref ref) => TrainingRepositoryImpl(
    TrainingRemoteDataSource(ref.watch(apiClientProvider).dio));
@Riverpod(retry: _noRetry)
Future<TrainingOverview> trainingOverview(Ref ref, String communityId) =>
    ref.watch(trainingRepositoryProvider).overview(communityId);
@Riverpod(retry: _noRetry)
Future<TrainingReport> trainingReport(Ref ref, String communityId,
        {String? locationId,
        String? recipientMemberId,
        String? from,
        String? to}) =>
    ref.watch(trainingRepositoryProvider).report(communityId,
        locationId: locationId,
        recipientMemberId: recipientMemberId,
        from: from,
        to: to);
