import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../app/theme.dart';

class SocketService {
  static IO.Socket? _socket;

  static void connect(String token) {
    if (_socket != null) { _socket!.dispose(); _socket = null; }
    _socket = IO.io(AppConstants.socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .disableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(5)
        .build());
    _socket!.connect();
  }

  static void disconnect() { _socket?.dispose(); _socket = null; }

  static void emit(String event, [dynamic data]) => _socket?.emit(event, data);

  static void on(String event, Function(dynamic) handler) {
    _socket?.off(event);   // ← مهمترین خط - جلوی duplicate listener
    _socket?.on(event, handler);
  }

  static void off(String event) => _socket?.off(event);
}