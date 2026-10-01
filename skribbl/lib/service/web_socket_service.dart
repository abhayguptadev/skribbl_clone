import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

typedef WebSocketCallback = void Function(Map<String, dynamic> data);

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  final String serverUrl;

  bool _isConnected = false;

  final List<WebSocketCallback> _listeners = [];
  Timer? _reconnectTimer;

  bool get isConnected => _isConnected;

  WebSocketService({
    required this.serverUrl,
  });

  void addListener(WebSocketCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(WebSocketCallback callback) {
    _listeners.remove(callback);
  }

  void connect(String roomCode) {
    try {
      final wsUrl = '$serverUrl/ws/room/$roomCode/';

      _channel = WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );

      _isConnected = true;

      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data =
                jsonDecode(message.toString()) as Map<String, dynamic>;

            for (final listener in _listeners) {
              listener(data);
            }
          } catch (e) {
            // Ignore invalid JSON messages.
          }
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect(roomCode);
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect(roomCode);
    }
  }

  void _scheduleReconnect(String roomCode) {
    _reconnectTimer?.cancel();

    _reconnectTimer = Timer(
      const Duration(seconds: 3),
      () {
        if (!_isConnected) {
          connect(roomCode);
        }
      },
    );
  }

  void sendEvent(
    String type,
    String roomId,
    Map<String, dynamic> payload,
  ) {
    if (_channel != null && _isConnected) {
      final message = jsonEncode({
        'type': type,
        'roomId': roomId,
        'payload': payload,
      });

      _channel!.sink.add(message);
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();

    _isConnected = false;
  }
}