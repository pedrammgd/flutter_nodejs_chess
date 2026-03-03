import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/theme.dart';
import '../models/user_model.dart';

class ApiService {



  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ))..interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (DioException e, handler) {
      handler.next(e);
    },
  ))..interceptors.add(PrettyDioLogger(responseBody: true));

  static bool _interceptorAdded = false;

  /// Call once from AuthController.onInit()
  static Future<void> init() async {
    if (_interceptorAdded) return;
    _interceptorAdded = true;

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
      onError: (DioException e, handler) {
        handler.next(e);
      },
    ));

    // Uncomment to debug requests:
    _dio.interceptors.add(PrettyDioLogger(responseBody: true));
  }

  // ── AUTH ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final res = await _dio.post('/api/auth/register',
        data: {'username': username, 'email': email, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await _dio.post('/api/auth/login',
        data: {'email': email, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  // ── USERS ─────────────────────────────────────────────────
  static Future<List<UserModel>> searchUsers(String q) async {
    final res =
        await _dio.get('/api/users/search', queryParameters: {'q': q});
    return (res.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  static Future<UserModel?> randomUser() async {
    try {
      final res = await _dio.get('/api/users/random');
      return UserModel.fromJson(res.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<List<UserModel>> leaderboard() async {
    final res = await _dio.get('/api/users/leaderboard');
    return (res.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> userProfile(String userId) async {
    final res = await _dio.get('/api/users/$userId');
    return res.data as Map<String, dynamic>;
  }

  static Future<String?> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar':
          await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
    });
    final res = await _dio.put('/api/users/avatar', data: formData);
    return (res.data as Map<String, dynamic>)['avatar'] as String?;
  }


}
