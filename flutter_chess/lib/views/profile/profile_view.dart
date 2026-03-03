import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/profile_controller.dart';
import '../../app/theme.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        final u = controller.user.value;
        if (u == null) return const Center(child: Text('User not found'));

        return SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.secondary, AppColors.accent]),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: controller.pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.gold,
                            backgroundImage: u.avatar.isNotEmpty ? NetworkImage(u.avatar) : null,
                            child: u.avatar.isEmpty ? Text(u.username[0].toUpperCase(),
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)) : null,
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                              child: Obx(() => controller.isUploading.value
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.camera_alt, size: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(u.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.star, color: AppColors.gold, size: 18),
                      const SizedBox(width: 4),
                      Text('${u.rating} Rating', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                  ],
                ),
              ),

              // Stats
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: _statCard('Wins', '${u.wins}', Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Losses', '${u.losses}', Colors.red)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Draws', '${u.draws}', Colors.orange)),
                ]),
              ),

              // Win rate
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Performance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Text('Total Games: ${u.totalGames}', style: const TextStyle(color: AppColors.grey)),
                        if (u.totalGames > 0) ...[
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: u.wins / u.totalGames,
                            backgroundColor: Colors.red.withOpacity(0.3),
                            color: Colors.green,
                          ),
                          const SizedBox(height: 4),
                          Text('Win Rate: ${(u.wins / u.totalGames * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.green)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Game History
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(alignment: Alignment.centerLeft,
                    child: Text('Recent Games', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
              ),
              Obx(() => ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.gameHistory.length,
                itemBuilder: (_, i) => _GameHistoryTile(game: controller.gameHistory[i], myId: u.id),
              )),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _statCard(String label, String value, Color color) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.grey)),
        ],
      ),
    ),
  );
}

class _GameHistoryTile extends StatelessWidget {
  final dynamic game;
  final String myId;
  const _GameHistoryTile({required this.game, required this.myId});

  @override
  Widget build(BuildContext context) {
    final white  = game['whitePlayer'];
    final black  = game['blackPlayer'];
    final winner = game['winner'];
    final status = game['status'];

    String result = 'Draw';
    Color  color  = Colors.orange;
    if (status == 'finished' && winner != null) {
      final isMyWin = winner['_id'] == myId;
      result = isMyWin ? 'Win' : 'Loss';
      color  = isMyWin ? Colors.green : Colors.red;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Center(child: Text(result[0], style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        ),
        title: Text('${white?['username'] ?? '?'} vs ${black?['username'] ?? '?'}',
            style: const TextStyle(color: Colors.white, fontSize: 13)),
        subtitle: Text(result, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        trailing: Text('${white?['rating'] ?? ''} vs ${black?['rating'] ?? ''}',
            style: const TextStyle(color: AppColors.grey, fontSize: 11)),
      ),
    );
  }
}
