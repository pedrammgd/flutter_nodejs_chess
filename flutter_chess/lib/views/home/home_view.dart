import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../models/user_model.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('♟ ${auth.user.value?.username ?? "Chess"}')),
        actions: [
          IconButton(icon: const Icon(Icons.leaderboard), onPressed: () => Get.toNamed(AppRoutes.leaderboard)),
          IconButton(icon: const Icon(Icons.person), onPressed: () => Get.toNamed(AppRoutes.profile)),
          IconButton(icon: const Icon(Icons.logout), onPressed: auth.logout),
        ],
      ),
      body: Column(
        children: [
          // Rating Card
          Obx(() {
            final u = auth.user.value;
            if (u == null) return const SizedBox();
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.accent, AppColors.gold.withOpacity(0.3)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCol('Rating', '${u.rating}', Icons.star),
                  _statCol('Wins', '${u.wins}', Icons.emoji_events),
                  _statCol('Losses', '${u.losses}', Icons.close),
                  _statCol('Draws', '${u.draws}', Icons.handshake),
                ],
              ),
            );
          }),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: controller.searchUsers,
              decoration: const InputDecoration(
                hintText: 'Search players...',
                prefixIcon: Icon(Icons.search, color: AppColors.grey),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Search Results
          Obx(() {
            if (controller.isSearching.value) return const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator());
            if (controller.searchResults.isEmpty) return const SizedBox();
            return SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.searchResults.length,
                itemBuilder: (_, i) => _PlayerCard(
                  user: controller.searchResults[i],
                  onInvite: () => controller.inviteUser(controller.searchResults[i]),
                ),
              ),
            );
          }),

          const Spacer(),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Online matchmaking
                Obx(() => controller.isMatchmaking.value
                    ? _MatchmakingCard(onCancel: controller.leaveQueue)
                    : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: controller.joinQueue,
                              icon: const Icon(Icons.public),
                              label: const Text('Play Online (Random)'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: controller.findRandom,
                              icon: const Icon(Icons.shuffle),
                              label: const Text('Find Random Player'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                            ),
                          ),
                        ],
                      )),
                const SizedBox(height: 12),

                // Offline buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.startOfflineLocal,
                      icon: const Icon(Icons.people, color: Colors.white),
                      label: const Text('Local 2P', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.startOfflineVsAI,
                      icon: const Icon(Icons.smart_toy, color: Colors.white),
                      label: const Text('vs AI', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white30)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCol(String label, String value, IconData icon) => Column(
    children: [
      Icon(icon, color: AppColors.gold, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 11)),
    ],
  );
}

class _PlayerCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onInvite;
  const _PlayerCard({required this.user, required this.onInvite});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.profile, arguments: user.id),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.accent,
              backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
              child: user.avatar.isEmpty ? Text(user.username[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)) : null,
            ),
            const SizedBox(height: 6),
            Text(user.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11)),
            Text('⭐ ${user.rating}', style: const TextStyle(color: AppColors.gold, fontSize: 11)),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: user.isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(user.isOnline ? 'Online' : 'Offline', style: const TextStyle(color: AppColors.grey, fontSize: 10)),
            ]),
            if (user.isOnline) ...[
              const SizedBox(height: 6),
              GestureDetector(onTap: onInvite, child: const Icon(Icons.send, size: 16, color: AppColors.gold)),
            ]
          ],
        ),
      ),
    );
  }
}

class _MatchmakingCard extends StatelessWidget {
  final VoidCallback onCancel;
  const _MatchmakingCard({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.gold),
          const SizedBox(height: 12),
          const Text('Finding opponent...', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 12),
          TextButton(onPressed: onCancel, child: const Text('Cancel', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
