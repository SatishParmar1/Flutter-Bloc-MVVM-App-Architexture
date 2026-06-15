import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/config/app_config.dart';

void main() {
  test('AppConfig sets up correctly', () {
    AppConfig.setConfiguration(
      AppConfig(
        flavor: AppFlavor.dev,
        appName: 'Test App',
        baseUrl: 'https://test-api.example.com',
      ),
    );

    expect(AppConfig.instance.flavor, AppFlavor.dev);
    expect(AppConfig.instance.appName, 'Test App');
    expect(AppConfig.instance.baseUrl, 'https://test-api.example.com');
  });
}
