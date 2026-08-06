import 'package:dio/dio.dart';
import 'package:hiddify/core/preferences/general_preferences.dart';
import 'package:hiddify/features/auth/data/auth_repository.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_notifier.g.dart';

const kVukaVpnApiBase = 'https://panel.vukavpn.com';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'User-Agent': 'VukaVPN/0.3'},
    ),
  );
  return AuthRepository(dio: dio, baseUrl: kVukaVpnApiBase);
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier with AppLogger {
  @override
  AsyncValue<bool> build() {
    final token = ref.watch(Preferences.authToken);
    return AsyncData(token != null && token.isNotEmpty);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      loggy.info('logging in $email');
      final token = await repo.login(email.trim(), password);
      loggy.info('login ok, saving token');
      await ref.read(Preferences.authToken.notifier).update(token);

      loggy.info('fetching subscribe url');
      final subUrl = await repo.getSubscribeUrl(token);
      loggy.info('got sub url, injecting as profile silently');

      await ref.read(addProfileNotifierProvider.notifier).addClipboard(subUrl);

      await ref.read(Preferences.introCompleted.notifier).update(true);
      return true;
    });
  }

  Future<void> register({required String email, required String password, String? emailCode}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      await repo.register(email: email.trim(), password: password, emailCode: emailCode);
      final token = await repo.login(email.trim(), password);
      await ref.read(Preferences.authToken.notifier).update(token);
      final subUrl = await repo.getSubscribeUrl(token);
      await ref.read(addProfileNotifierProvider.notifier).addClipboard(subUrl);
      await ref.read(Preferences.introCompleted.notifier).update(true);
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(Preferences.authToken.notifier).update(null);
    state = const AsyncData(false);
  }
}
