import 'package:advanced_chess_board/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:advanced_chess_board/advanced_chess_board.dart';
import '../../controllers/game_controller.dart';
import '../../app/theme.dart';

class OfflineGameView extends GetView<GameController> {
  const OfflineGameView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async { Get.back(); return false; },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() =>
              Text(controller.offlineMode.value == 'ai' ? '♟ vs AI' : '♟ Local 2 Player')),
          actions: [
            TextButton(
              onPressed: controller.resign,
              child: const Text('Resign', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.gameOver.value) {
            return Center(
              child: Card(
                margin: const EdgeInsets.all(32),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(controller.resultText.value,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: controller.goHome,
                        child: const Text('Back to Home'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              // Turn banner
              Container(
                color: AppColors.accent.withOpacity(0.3),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Obx(() => Text(
                    controller.offlineMode.value == 'ai'
                        ? (controller.isMyTurn.value ? '♟ Your Turn (White)' : '🤖 AI is thinking...')
                        : (controller.isMyTurn.value ? '⬜ White\'s Turn' : '⬛ Black\'s Turn'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  )),
                ),
              ),

              // Board
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: AdvancedChessBoard(
                      controller: controller.boardController,
                      boardOrientation: PlayerColor.white,
                      lightSquareColor: AppColors.lightSquare,
                      darkSquareColor: AppColors.darkSquare,
                      enableMoves: controller.offlineMode.value == 'ai'
                          ? controller.isMyTurn.value
                          : true,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
