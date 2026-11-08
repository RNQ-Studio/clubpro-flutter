import 'dart:io';
import 'dart:typed_data';

import 'package:app_main/features/home/data/banner_remote_data_source.dart';
import 'package:app_main/features/home/domain/entities/promotion_action.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// JSON di `fixtures/` direkam dari respons clubpro-laravel sungguhan.
String _fixture(String name) =>
    File('test/features/home/fixtures/$name.json').readAsStringSync();

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final String body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(body, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

({BannerRemoteDataSource source, _FakeAdapter adapter}) _source(String body) {
  final adapter = _FakeAdapter(body);
  final dio =
      Dio(BaseOptions(baseUrl: 'https://anaklangit.manahpro.web.id/api/'))
        ..httpClientAdapter = adapter;
  return (source: BannerRemoteDataSource(dio), adapter: adapter);
}

void main() {
  test('promosi tayang, tombol, dan jeda dari respons asli', () async {
    final fake = _source(_fixture('promotions'));

    final promotions = await fake.source.fetchPromotions();

    expect(fake.adapter.request!.path, 'v1/banners');
    expect(promotions.intervalHours, 12);
    expect(promotions.banners.map((b) => b.id), ['1', '4', '5']);

    final community = promotions.banners[0];
    expect(community.action, PromotionActionKind.appPage);
    expect(community.button, 'Lihat Komunitas');
    expect(community.imageUrl, startsWith('https://'));

    final whatsapp = promotions.banners[1];
    expect(whatsapp.title, '');
    expect(whatsapp.action, PromotionActionKind.whatsapp);
    expect(whatsapp.button, 'Chat Sekarang');
    expect(PromotionAction.whatsappNumber(whatsapp.linkUrl), '6281234567890');
    expect(PromotionAction.whatsappMessage(whatsapp.linkUrl),
        'Halo, saya tertarik promo busur');
  });

  test('server lama tanpa jeda maupun label: bawaan', () async {
    final promotions = await _source(
      '{"success":true,"data":[{"id":1,"title":"Lama","subtitle":null,'
      '"image_url":null,"link_url":"/profile"}]}',
    ).source.fetchPromotions();

    expect(promotions.intervalHours, 24);
    expect(promotions.banners.single.button, 'Lihat Selengkapnya');
  });

  test('jeda tidak sah dari server: bawaan', () async {
    final promotions = await _source(
      '{"success":true,"data":[],"meta":{"interval_hours":0}}',
    ).source.fetchPromotions();

    expect(promotions.intervalHours, 24);
    expect(promotions.banners, isEmpty);
  });
}
