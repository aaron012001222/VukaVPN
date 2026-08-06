import 'package:dio/dio.dart';

class AuthRepository {
  AuthRepository({required this.dio, required this.baseUrl});
  final Dio dio;
  final String baseUrl;

  Future<String> login(String email, String password) async {
    final resp = await dio.post(
      '$baseUrl/api/v1/passport/auth/login',
      data: {'email': email, 'password': password},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (resp.statusCode == 200 && resp.data is Map) {
      final data = resp.data['data'];
      if (data is Map) {
        final token = data['auth_data'] ?? data['token'];
        if (token is String && token.isNotEmpty) return token;
      }
    }
    final msg = (resp.data is Map ? resp.data['message'] : null) ?? '登录失败';
    throw Exception('$msg');
  }

  Future<String> getSubscribeUrl(String token) async {
    final resp = await dio.get(
      '$baseUrl/api/v1/user/getSubscribe',
      options: Options(
        headers: {'Authorization': token},
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (resp.statusCode == 200 && resp.data is Map) {
      final data = resp.data['data'];
      if (data is Map) {
        final url = data['subscribe_url'];
        if (url is String && url.isNotEmpty) return url;
      }
    }
    final msg = (resp.data is Map ? resp.data['message'] : null) ?? '获取订阅失败';
    throw Exception('$msg');
  }

  Future<void> register({required String email, required String password, String? emailCode}) async {
    final data = {'email': email, 'password': password};
    if (emailCode != null && emailCode.isNotEmpty) data['email_code'] = emailCode;
    final resp = await dio.post(
      '$baseUrl/api/v1/passport/auth/register',
      data: data,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    if (resp.statusCode == 200) return;
    final msg = (resp.data is Map ? resp.data['message'] : null) ?? '注册失败';
    throw Exception('$msg');
  }
}
