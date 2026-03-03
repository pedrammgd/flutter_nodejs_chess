import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class LeaderboardController extends GetxController {
  final players   = <UserModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      players.value = await ApiService.leaderboard();
    } finally {

      isLoading.value = false;
    }
  }
}
