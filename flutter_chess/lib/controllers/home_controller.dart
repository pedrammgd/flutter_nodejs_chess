import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../app/routes.dart';
import '../app/theme.dart';

class HomeController extends GetxController {
  final searchResults = <UserModel>[].obs;
  final isSearching   = false.obs;
  final isMatchmaking = false.obs;
  final selectedTime  = 600.obs;
  bool _barOpen = false;

  final timeLimits = const [
    {'label': '3 min',  'value': 180},
    {'label': '5 min',  'value': 300},
    {'label': '10 min', 'value': 600},
    {'label': '30 min', 'value': 1800},
  ];

  @override
  void onInit() {
    super.onInit();
    _listenSocket();
  }

  void _listenSocket() {
    SocketService.on('game_start', (data) {
      isMatchmaking.value = false;
      _closeBar();
      // offAllNamed: home رو از stack پاک میکنه - هر دو طرف وارد بازی میشن
      Get.offAllNamed(AppRoutes.game, arguments: data);
    });

    SocketService.on('waiting_for_opponent', (_) {
      isMatchmaking.value = true;
    });

    SocketService.on('game_invite', (data) {
      _showIncomingBar(data);
    });

    SocketService.on('invite_declined', (_) {
      _closeBar();
      isMatchmaking.value = false;
      Get.snackbar(
        'Declined',
        'Player declined your invite.',
        backgroundColor: Colors.red.withOpacity(0.85),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );
    });

    // وقتی target آفلاینه - وارد صف بشو
    SocketService.on('invite_failed', (_) {
      _closeBar();
      joinQueue();
    });
  }

  // ── Incoming invite bar (گیرنده) ─────────────────────────
  void _showIncomingBar(dynamic data) {
    _closeBar();
    _barOpen = true;

    final fromName   = data['from']['username'] ?? '?';
    final fromRating = data['from']['rating']   ?? 0;
    final timeLimit  = data['timeLimit']        ?? 600;
    final socketId   = data['socketId'];
    final fromId     = data['from']['id'];

    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 30),
      backgroundColor: AppColors.secondary,
      borderColor: AppColors.gold,
      borderWidth: 1.5,
      borderRadius: 12,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      messageText: Row(children: [
        const Icon(Icons.sports_esports, color: AppColors.gold, size: 26),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$fromName ($fromRating) invited you!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text('Time: ${timeLimit ~/ 60} min',
                style: const TextStyle(color: AppColors.gold, fontSize: 12)),
          ],
        )),
        TextButton(
          onPressed: () {
            _closeBar();
            SocketService.emit('decline_invite', {'fromSocketId': socketId});
          },
          child: const Text('Decline',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        ElevatedButton(
          onPressed: () {
            _closeBar();
            SocketService.emit('accept_invite', {
              'fromSocketId': socketId,
              'fromUserId':   fromId,
              'timeLimit':    timeLimit,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          child: const Text('Accept',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ]),
    );
  }

  // ── Outgoing invite bar (فرستنده) ────────────────────────
  void _showOutgoingBar(String username) {
    _closeBar();
    _barOpen = true;

    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 30),
      backgroundColor: AppColors.secondary,
      borderColor: AppColors.accent,
      borderWidth: 1.5,
      borderRadius: 12,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      showProgressIndicator: true,
      progressIndicatorValueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
      progressIndicatorBackgroundColor: AppColors.accent.withOpacity(0.2),
      messageText: Row(children: [
        const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Invite sent to $username',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const Text('Waiting for response...',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        )),
        TextButton(
          onPressed: () {
            _closeBar();
            isMatchmaking.value = false;
          },
          child: const Text('Cancel',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ]),
    );
  }

  // ── Queue bar ────────────────────────────────────────────
  void _showQueueBar() {
    _closeBar();
    _barOpen = true;

    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      duration: const Duration(minutes: 10),
      backgroundColor: AppColors.secondary,
      borderColor: AppColors.accent,
      borderWidth: 1.5,
      borderRadius: 12,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      showProgressIndicator: true,
      progressIndicatorValueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
      progressIndicatorBackgroundColor: AppColors.accent.withOpacity(0.2),
      messageText: Row(children: [
        const SizedBox(width: 18, height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
        const SizedBox(width: 12),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Searching for opponent...',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text('You are in the queue',
                style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        )),
        TextButton(
          onPressed: leaveQueue,
          child: const Text('Cancel',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ]),
    );
  }

  void _closeBar() {
    if (_barOpen) {
      Get.closeCurrentSnackbar();
      _barOpen = false;
    }
  }

  // ── Actions ──────────────────────────────────────────────
  Future<void> searchUsers(String q) async {
    if (q.isEmpty) { searchResults.clear(); return; }
    isSearching.value = true;
    try {
      searchResults.value = await ApiService.searchUsers(q);
    } finally {
      isSearching.value = false;
    }
  }

  void inviteUser(UserModel u) {
    isMatchmaking.value = true;
    SocketService.emit('invite_user', {
      'targetUserId': u.id,
      'timeLimit': selectedTime.value,
    });
    _showOutgoingBar(u.username);
  }

  Future<void> findRandom() async {
    isMatchmaking.value = true;
    final user = await ApiService.randomUser();
    if (user != null) {
      SocketService.emit('invite_user', {
        'targetUserId': user.id,
        'timeLimit': selectedTime.value,
      });
      _showOutgoingBar(user.username);
    } else {
      joinQueue();
    }
  }

  void joinQueue() {
    isMatchmaking.value = true;
    SocketService.emit('join_queue', {'timeLimit': selectedTime.value});
    _showQueueBar();
  }

  void leaveQueue() {
    isMatchmaking.value = false;
    _closeBar();
    SocketService.emit('leave_queue');
  }

  void startOfflineVsAI()  => Get.toNamed(AppRoutes.offlineGame, arguments: {'mode': 'ai'});
  void startOfflineLocal() => Get.toNamed(AppRoutes.offlineGame, arguments: {'mode': 'local'});

  @override
  void onClose() {
    _closeBar();
    SocketService.off('game_start');
    SocketService.off('waiting_for_opponent');
    SocketService.off('game_invite');
    SocketService.off('invite_declined');
    SocketService.off('invite_failed');
    super.onClose();
  }
}