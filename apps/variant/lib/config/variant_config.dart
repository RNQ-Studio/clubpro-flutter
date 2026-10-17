import 'package:core/core.dart';

class VariantConfig extends AppConfig {
  @override
  Environment get environment => Environment.fromString(
        const String.fromEnvironment('ENV', defaultValue: 'dev'),
      );

  @override
  String get baseUrl => switch (environment) {
        Environment.dev => 'https://anaklangit.manahpro.web.id/api/',
        Environment.staging => 'https://anaklangit.manahpro.web.id/api/',
        Environment.prod => 'https://anaklangit.manahpro.web.id/api/',
      };
}
