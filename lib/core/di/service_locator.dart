import 'package:get_it/get_it.dart';
import '../storage/secure_storage.dart';
import '../api/api_client.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  getIt.registerLazySingleton<SecureStorage>(() => SecureStorage());

  getIt.registerLazySingleton<ApiClient>(() => ApiClient(secureStorage: getIt<SecureStorage>()));
}
