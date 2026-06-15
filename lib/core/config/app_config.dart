enum AppFlavor { dev, staging, prod }

class AppConfig {
  final AppFlavor flavor;
  final String appName;
  final String baseUrl;

  AppConfig({
    required this.flavor,
    required this.appName,
    required this.baseUrl,
  });

  static late final AppConfig _instance;

  static AppConfig get instance => _instance;

  static void setConfiguration(AppConfig config) {
    _instance = config;
  }

  bool get isDev => flavor == AppFlavor.dev;
  bool get isStaging => flavor == AppFlavor.staging;
  bool get isProd => flavor == AppFlavor.prod;
}
