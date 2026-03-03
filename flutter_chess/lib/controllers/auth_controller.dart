import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../app/routes.dart';
import '../app/theme.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;
  final user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    final p = await SharedPreferences.getInstance();
    final token = p.getString(AppConstants.tokenKey);
    final userJson = p.getString(AppConstants.userKey);
    if (token != null && userJson != null) {
      user.value = UserModel.fromJson(jsonDecode(userJson));
      SocketService.connect(token);
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> register(String username, String email, String password) async {
    isLoading.value = true;
    try {
      final res = await ApiService.register(username, email, password);
      if (res['token'] != null) {
        await _saveSession(res);
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.snackbar('Error', res['message'] ?? 'Registration failed');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      final res = await ApiService.login(email, password);
      if (res['token'] != null) {
        await _saveSession(res);
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.snackbar('Error', res['message'] ?? 'Login failed');
      }
    } catch (e) {
      Get.snackbar('Error', 'Cannot connect to server');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    SocketService.disconnect();
    user.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> _saveSession(Map<String, dynamic> res) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(AppConstants.tokenKey, res['token']);
    await p.setString(AppConstants.userKey, jsonEncode(res['user']));
    user.value = UserModel.fromJson(res['user']);
    SocketService.connect(res['token']);
  }
}
