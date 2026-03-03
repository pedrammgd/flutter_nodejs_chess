import 'dart:async';
import 'package:chess/chess.dart' as ch;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:advanced_chess_board/chess_board_controller.dart';
import '../services/socket_service.dart';
import '../app/routes.dart';

class GameController extends GetxController {
  final boardController = ChessBoardController();

  final myColor = 'white'.obs;
  final gameId = ''.obs;
  final isMyTurn = true.obs;
  final gameOver = false.obs;
  final resultText = ''.obs;
  final ratingChange = 0.obs;

  final opponentName = ''.obs;
  final opponentRating = 0.obs;

  final messages = <Map<String, String>>[].obs;
  final chatCtrl = TextEditingController();

  final isOffline = false.obs;
  final offlineMode = 'local'.obs;

  final whiteTime = 0.obs;
  final blackTime = 0.obs;
  final hasTimer = false.obs;
  Timer? _timer;

  int _lastMoveCount = 0;
  bool _navigating = false; // جلوی double navigate

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args == null) return;

    if (args.containsKey('mode')) {
      isOffline.value = true;
      offlineMode.value = args['mode'] as String;
      myColor.value = 'white';
      isMyTurn.value = true;
    } else {
      gameId.value = args['gameId']?.toString() ?? '';
      myColor.value = args['color'] as String? ?? 'white';
      opponentName.value = args['opponent']['username'] as String? ?? '';
      opponentRating.value = args['opponent']['rating'] as int? ?? 0;
      isMyTurn.value = myColor.value == 'white';

      final timeLimit = args['timeLimit'] as int? ?? 0;
      if (timeLimit > 0) {
        hasTimer.value = true;
        whiteTime.value = timeLimit;
        blackTime.value = timeLimit;
        _startTimer();
      }

      _listenSocket();
    }

    boardController.addListener(_onBoardChange);
  }

  // ── Timer ───────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (gameOver.value) {
        _timer?.cancel();
        return;
      }
      if (isMyTurn.value) {
        if (myColor.value == 'white') {
          whiteTime.value--;
          if (whiteTime.value <= 0) _onTimeout('white');
        } else {
          blackTime.value--;
          if (blackTime.value <= 0) _onTimeout('black');
        }
      } else {
        if (myColor.value == 'white') {
          blackTime.value--;
          if (blackTime.value <= 0) _onTimeout('black');
        } else {
          whiteTime.value--;
          if (whiteTime.value <= 0) _onTimeout('white');
        }
      }
    });
  }

  void _onTimeout(String loserColor) {
    _timer?.cancel();
    SocketService.emit('time_out', {'gameId': gameId.value, 'loserColor': loserColor});
  }

  String formatTime(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // ── Board ───────────────────────────────────────────────
  void _onBoardChange() {
    final game = boardController.game;
    final history = game.getHistory({'verbose': true}) as List;
    if (history.length <= _lastMoveCount) return;
    _lastMoveCount = history.length;
    final lastSan = (history.last as Map)['san'] as String? ?? '';
    if (!isOffline.value) {
      if (!isMyTurn.value) return;
      SocketService.emit('make_move', {'gameId': gameId.value, 'move': lastSan, 'fen': game.fen});
      isMyTurn.value = false;
    } else {
      if (offlineMode.value == 'local')
        isMyTurn.value = !isMyTurn.value;
      else {
        isMyTurn.value = false;
        Future.delayed(const Duration(milliseconds: 500), _makeAiMove);
      }
    }
    _checkGameOver();
  }

  // _makeAiMove:
  void _makeAiMove() {
    final moves = boardController.game.moves() as List;
    if (moves.isEmpty) return;
    moves.shuffle();
    boardController.game.move(moves.first as String);
    boardController.notifyListeners();
    isMyTurn.value = true;
    _checkGameOver();
  }

  // _applyOpponentMove:
  void _applyOpponentMove(String san) {
    boardController.game.move(san);
    boardController.notifyListeners();
    _lastMoveCount = (boardController.game.getHistory({'verbose': true}) as List).length;
    isMyTurn.value = true;
    _checkGameOver();
  }

  // _checkGameOver:
  void _checkGameOver() {
    final game = boardController.game;
    if (!game.game_over) return;
    if (game.in_checkmate) {
      final winner = game.turn == ch.Color.WHITE ? 'black' : 'white';
      if (isOffline.value)
        resultText.value = '${winner.toUpperCase()} wins!';
      else
        SocketService.emit('game_over', {'gameId': gameId.value, 'result': winner});
    } else {
      if (isOffline.value)
        resultText.value = "Draw!";
      else
        SocketService.emit('game_over', {'gameId': gameId.value, 'result': 'draw'});
    }
    gameOver.value = true;
  }

  // ── Socket ──────────────────────────────────────────────
  void _listenSocket() {
    SocketService.on('opponent_move', (data) {
      _applyOpponentMove(data['move'] as String);
    });

    SocketService.on('game_ended', (data) {
      _timer?.cancel();
      final result = data['result'] as String? ?? '';
      final reason = data['reason'] as String? ?? '';
      ratingChange.value = data['ratingChange'] as int? ?? 0;

      if (result == 'draw') {
        resultText.value = "It's a Draw! 🤝";
      } else if (result == myColor.value) {
        resultText.value = reason == 'disconnect'
            ? 'Opponent disconnected. You Win! 🎉'
            : reason == 'resign'
            ? 'Opponent resigned. You Win! 🎉'
            : 'You Win! 🎉';
      } else {
        resultText.value = reason == 'timeout' ? "Time's Up! You Lose ⏰" : 'You Lose 😔';
      }
      gameOver.value = true;
    });

    SocketService.on('new_message', (data) {
      messages.add({'sender': data['senderId'] as String? ?? '', 'text': data['message'] as String? ?? '', 'isMe': 'false'});
    });
  }

  // ── Actions ─────────────────────────────────────────────
  void sendMessage(String text) {
    if (text.trim().isEmpty || isOffline.value) return;
    SocketService.emit('send_message', {'gameId': gameId.value, 'message': text.trim()});
    messages.add({'sender': 'me', 'text': text.trim(), 'isMe': 'true'});
    chatCtrl.clear();
  }

  void resign() {
    if (isOffline.value) {
      _timer?.cancel();
      resultText.value = 'You resigned.';
      gameOver.value = true;
    } else {
      // فقط emit - سرور game_ended برمیگردونه و اونجا gameOver=true میشه
      SocketService.emit('resign', {'gameId': gameId.value});
    }
  }

  void goHome() {
    if (_navigating) return; // جلوی double navigate
    _navigating = true;
    _timer?.cancel();
    _offListeners(); // اول off، بعد navigate
    Get.offAllNamed(AppRoutes.home);
  }

  void _offListeners() {
    SocketService.off('opponent_move');
    SocketService.off('game_ended');
    SocketService.off('new_message');
  }

  @override
  void onClose() {
    _timer?.cancel();
    boardController.removeListener(_onBoardChange);
    boardController.dispose();
    chatCtrl.dispose();
    if (!isOffline.value) _offListeners();
    super.onClose();
  }
}
