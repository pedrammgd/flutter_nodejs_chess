import 'package:advanced_chess_board/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:advanced_chess_board/advanced_chess_board.dart';
import '../../controllers/game_controller.dart';
import '../../app/theme.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(

          automaticallyImplyLeading: false,
          title: Obx(() => Text(
              'vs ${controller.opponentName.value} (${controller.opponentRating.value})',
              style: const TextStyle(fontSize: 15))),
          actions: [
            TextButton(
              onPressed: controller.resign,
              child: const Text('Resign', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.gameOver.value) return _GameOverScreen(ctrl: controller);
          return Column(
            children: [
              // Turn indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                color: controller.isMyTurn.value
                    ? AppColors.gold.withOpacity(0.15)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    controller.isMyTurn.value ? '♟ Your Turn' : '⏳ Opponent\'s Turn',
                    style: TextStyle(
                      color: controller.isMyTurn.value ? AppColors.gold : AppColors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Board
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: AdvancedChessBoard(
                  controller: controller.boardController,

                  boardOrientation: controller.myColor.value == 'white'
                      ? PlayerColor.white
                      : PlayerColor.black,
                  lightSquareColor: AppColors.lightSquare,
                  darkSquareColor: AppColors.darkSquare,
                  enableMoves: controller.isMyTurn.value,
                ),
              ),

              // Chat
              Expanded(child: _ChatPanel(ctrl: controller)),
            ],
          );
        }),
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  final GameController ctrl;
  const _ChatPanel({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() => ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: ctrl.messages.length,
            itemBuilder: (_, i) {
              final msg  = ctrl.messages[i];
              final isMe = msg['isMe'] == 'true';
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.gold.withOpacity(0.85) : AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white)),
                ),
              );
            },
          )),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: ctrl.chatCtrl,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => ctrl.sendMessage(ctrl.chatCtrl.text),
              icon: const Icon(Icons.send, color: AppColors.gold),
            ),
          ]),
        ),
      ],
    );
  }
}

class _GameOverScreen extends StatelessWidget {
  final GameController ctrl;
  const _GameOverScreen({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ctrl.resultText.value,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Obx(() {
                  final c = ctrl.ratingChange.value;
                  return Text(
                    c >= 0 ? '+$c Rating' : '$c Rating',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: c >= 0 ? Colors.green : Colors.red,
                    ),
                  );
                }),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: ctrl.goHome, child: const Text('Back to Home')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
