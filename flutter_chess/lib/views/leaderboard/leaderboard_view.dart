import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/leaderboard_controller.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';
import '../../models/user_model.dart';

class LeaderboardView extends GetView<LeaderboardController> {
  const LeaderboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🏆 Leaderboard')),
      body: Obx(() {
        if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
        if (controller.players.isEmpty) return const Center(child: Text('No players yet'));

        return ListView(
          shrinkWrap: true,
          children: [
            // Top 3 podium
            if (controller.players.length >= 3)
              Container(
                // height: 160,
                margin: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _PodiumItem(user: controller.players[1], rank: 2, height: 110)),
                    const SizedBox(width: 8),
                    Expanded(child: _PodiumItem(user: controller.players[0], rank: 1, height: 140)),
                    const SizedBox(width: 8),
                    Expanded(child: _PodiumItem(user: controller.players[2], rank: 3, height: 90)),
                  ],
                ),
              ),

            // Full list
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: controller.players.length,
                itemBuilder: (_, i) => _LeaderRow(user: controller.players[i], rank: i + 1),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final UserModel user;
  final int rank;
  final double height;
  const _PodiumItem({required this.user, required this.rank, required this.height});

  @override
  Widget build(BuildContext context) {
    final colors = {1: AppColors.gold, 2: const Color(0xFFC0C0C0), 3: const Color(0xFFCD7F32)};
    final color  = colors[rank] ?? Colors.white;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.profile, arguments: user.id),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color,
            backgroundImage: user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
            child: user.avatar.isEmpty ? Text(user.username[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)) : null,
          ),
          const SizedBox(height: 4),
          Text(user.username, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11)),
          Text('${user.rating}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Center(child: Text('$rank', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  final UserModel user;
  final int rank;
  const _LeaderRow({required this.user, required this.rank});

  @override
  Widget build(BuildContext context) {
    final medalColors = {1: AppColors.gold, 2: const Color(0xFFC0C0C0), 3: const Color(0xFFCD7F32)};
    final color = medalColors[rank];

    return ListTile(
      onTap: () => Get.toNamed(AppRoutes.profile, arguments: user.id),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color?.withOpacity(0.2) ?? AppColors.accent.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Center(child: Text('$rank', style: TextStyle(
          color: color ?? AppColors.grey,
          fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
        ))),
      ),
      title: Text(user.username, style: const TextStyle(color: Colors.white)),
      subtitle: Text('W: ${user.wins}  L: ${user.losses}  D: ${user.draws}', style: const TextStyle(color: AppColors.grey, fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: user.isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${user.rating}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
              const Text('rating', style: TextStyle(color: AppColors.grey, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
