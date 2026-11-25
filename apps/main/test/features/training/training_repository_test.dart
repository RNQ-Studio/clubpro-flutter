import 'package:app_main/features/finance/domain/finance.dart';
import 'package:app_main/features/training/data/training_models.dart';
import 'package:app_main/features/training/data/training_remote_data_source.dart';
import 'package:app_main/features/training/data/training_repository_impl.dart';
import 'package:app_main/features/training/domain/training.dart';
import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> packageJson({int sessions = 7, int price = 100003}) => {
      'sessions': sessions,
      'price': price,
      'session_floor': price ~/ sessions,
      'session_last': price - (price ~/ sessions) * (sessions - 1)
    };
Map<String, Object?> purchaseJson() => {
      'id': 'p',
      'sessions': 7,
      'remaining_sessions': 6,
      'price': 100003,
      'remaining_amount': 85717,
      'session_floor': 14286
    };
void main() {
  test('package money uses exact server floor and final remainder', () {
    final p = trainingPackageFromJson(packageJson());
    expect(p.sessionFloor, 14286);
    expect(p.sessionLast, 14287);
    expect(p.price, p.sessionFloor * 6 + p.sessionLast);
  });
  for (final raw in [0, -1, 1.5, '1.5', null, 9007199254740992]) {
    test('reject corrupt package nominal $raw', () {
      expect(() => trainingPackageFromJson({...packageJson(), 'price': raw}),
          throwsA(isA<FinanceDataException>()));
    });
  }
  test('reject invalid session count floor last or remaining reserve', () {
    for (final j in [
      {...packageJson(), 'sessions': 0},
      {...packageJson(), 'sessions': 8},
      {...packageJson(), 'session_floor': 1},
      {...packageJson(), 'session_last': 14286}
    ]) {
      expect(() => trainingPackageFromJson(j),
          throwsA(isA<FinanceDataException>()));
    }
    for (final j in [
      {...purchaseJson(), 'remaining_sessions': 8},
      {...purchaseJson(), 'remaining_amount': 100003},
      {...purchaseJson(), 'price': 1}
    ]) {
      expect(() => trainingPurchaseFromJson(j),
          throwsA(isA<FinanceDataException>()));
    }
  });
  test('missing financial data never silently reads as zero', () {
    expect(() => trainingAttendanceFromJson({'status': 'confirmed'}),
        throwsA(isA<FinanceDataException>()));
    expect(() => trainingReportFromJson({'totals': {}}),
        throwsA(isA<FinanceDataException>()));
  });
  test('scoped report legitimately omits global reconciliation fields', () {
    final r = trainingReportFromJson({
      'scope': 'recipient',
      'totals': {
        'allocated_amount': 8000,
        'filtered_allocated_amount': 8000,
        'filtered_attendance_count': 1
      }
    });
    expect(r.purchasedAmount, null);
    expect(r.reservedAmount, null);
    expect(r.allocatedAmount, 8000);
    expect(r.filteredAllocatedAmount, 8000);
  });
  test('repository sends actual route quote versions keys and report filters',
      () async {
    final requests = <RequestOptions>[];
    final dio =
        Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
          ..interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
            requests.add(o);
            h.resolve(Response(requestOptions: o, statusCode: 200, data: {
              'success': true,
              'data': o.path.endsWith('/report')
                  ? {
                      'scope': 'recipient',
                      'totals': {
                        'allocated_amount': 0,
                        'filtered_allocated_amount': 0,
                        'filtered_attendance_count': 0
                      }
                    }
                  : {}
            }));
          }));
    final repo = TrainingRepositoryImpl(TrainingRemoteDataSource(dio));
    await repo.purchase(
        '1',
        const TrainingPackage(
            sessions: 7,
            price: 100003,
            sessionFloor: 14286,
            sessionLast: 14287),
        2,
        'key-1');
    await repo.checkIn('1', '3', 'key-2');
    await repo.confirm('1', '3', '4', 'key-3');
    await repo.correct('1', 'a', 'Koreksi fixture', 'key-4');
    await repo.saveCatalog('1', {'expected_version': 2});
    await repo.saveLocation('1', '2', {'expected_version': 3});
    await repo.saveLocation('1', null, {'name': 'Fixture'});
    await repo.createSession('1', {'title': 'Latihan'});
    await repo.report('1',
        locationId: '2',
        recipientMemberId: '4',
        from: '2026-11-01',
        to: '2026-11-26');
    expect(requests.map((r) => r.path), [
      'v1/communities/1/training/purchases',
      'v1/communities/1/training/sessions/3/check-in',
      'v1/communities/1/training/sessions/3/confirm',
      'v1/communities/1/training/attendances/a/correct',
      'v1/communities/1/training/catalog',
      'v1/communities/1/training/locations/2',
      'v1/communities/1/training/locations',
      'v1/communities/1/training/sessions',
      'v1/communities/1/training/report'
    ]);
    expect(requests.first.data, {
      'sessions': 7,
      'expected_price': 100003,
      'catalog_version': 2,
      'idempotency_key': 'key-1'
    });
    expect(requests[2].data, {'member_id': 4, 'idempotency_key': 'key-3'});
    expect(requests[4].method, 'PUT');
    expect(requests[5].method, 'PUT');
    expect(requests[6].method, 'POST');
    expect(requests.last.queryParameters, {
      'location_id': '2',
      'recipient_member_id': '4',
      'from': '2026-11-01',
      'to': '2026-11-26'
    });
  });
  for (final status in [401, 402, 403, 409, 422, 500]) {
    test('HTTP $status maps to clear domain error', () async {
      final dio = Dio()
        ..interceptors.add(InterceptorsWrapper(
            onRequest: (o, h) => h.reject(DioException(
                requestOptions: o,
                response: Response(
                    requestOptions: o,
                    statusCode: status,
                    data: {'message': 'Pesan fixture'})))));
      final repo = TrainingRepositoryImpl(TrainingRemoteDataSource(dio));
      await expectLater(
          repo.overview('1'),
          throwsA(status == 401
              ? isA<FinanceAuthenticationException>()
              : status == 409
                  ? isA<FinanceConflictException>()
                  : isA<ServerException>()));
    });
  }
}
