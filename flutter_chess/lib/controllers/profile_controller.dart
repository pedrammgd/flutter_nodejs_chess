import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../app/theme.dart';

class ProfileController extends GetxController {
  final user        = Rxn<UserModel>();
  final gameHistory = <dynamic>[].obs;
  final isLoading   = false.obs;
  final isUploading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final userId = Get.arguments as String?;
    if (userId != null) {
      loadProfile(userId);
    } else {
      _loadMyProfile();
    }
  }

  Future<void> _loadMyProfile() async {
    isLoading.value = true;
    try {
      final prefs    = await SharedPreferences.getInstance();
      final userJson = prefs.getString(AppConstants.userKey);
      if (userJson != null) {
        final u = UserModel.fromJson(jsonDecode(userJson));
        await loadProfile(u.id);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadProfile(String userId) async {
    isLoading.value = true;
    try {
      final data   = await ApiService.userProfile(userId);
      user.value   = UserModel.fromJson(data['user']);
      gameHistory.value = data['games'] ?? [];
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return;

    isUploading.value = true;
    try {
      final url = await ApiService.uploadAvatar(picked.path); // pass path, Dio handles multipart
      if (url != null) {
        final prefs    = await SharedPreferences.getInstance();
        final userJson = prefs.getString(AppConstants.userKey);
        if (userJson != null) {
          final map = jsonDecode(userJson) as Map<String, dynamic>;
          map['avatar'] = '${AppConstants.baseUrl}$url';
          await prefs.setString(AppConstants.userKey, jsonEncode(map));
          user.value = UserModel.fromJson(map);
        }
        Get.snackbar('✅ Success', 'Avatar updated!');
      }
    } catch (e) {
      Get.snackbar('Error', 'Upload failed: $e');
    } finally {
      isUploading.value = false;
    }
  }
}
