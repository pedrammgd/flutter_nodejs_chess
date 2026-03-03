import 'package:get/get.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/home/home_view.dart';
import '../views/game/game_view.dart';
import '../views/game/offline_game_view.dart';
import '../views/profile/profile_view.dart';
import '../views/leaderboard/leaderboard_view.dart';
import '../controllers/auth_controller.dart';
import '../controllers/home_controller.dart';
import '../controllers/game_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/leaderboard_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => AuthController(), fenix: true);
}

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => HomeController());
  }
}

class GameBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => GameController());
}

class ProfileBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => ProfileController());
}

class LeaderboardBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => LeaderboardController());
}

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const game = '/game';
  static const offlineGame = '/offline-game';
  static const profile = '/profile';
  static const leaderboard = '/leaderboard';

  static final pages = [
    GetPage(name: login, page: () => LoginView(), binding: AuthBinding()),
    GetPage(name: register, page: () => RegisterView(), binding: AuthBinding()),
    GetPage(name: home, page: () => HomeView(), binding: HomeBinding()),
    GetPage(name: game, page: () => const GameView(), binding: GameBinding()),
    GetPage(name: offlineGame, page: () => const OfflineGameView(), binding: GameBinding()),
    GetPage(name: profile, page: () => const ProfileView(), binding: ProfileBinding()),
    GetPage(name: leaderboard, page: () => const LeaderboardView(), binding: LeaderboardBinding()),
  ];
}
