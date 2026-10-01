import 'package:flutter/material.dart';

import '../models/player.dart';
import '../models/room.dart';
import '../models/stroke.dart';

import 'package:skribbl/models/chat_msg.dart';
import 'package:skribbl/service/api_service.dart';
import 'package:skribbl/service/web_socket_service.dart';

class GameProvider extends ChangeNotifier {
  final ApiService apiService;
  late final WebSocketService wsService;

  String? myPlayerId;
  String? myPlayerName;
  bool isHost = false;
  String currentRoomCode = '';

  RoomState? roomState;
  List<DrawPoint> strokes = [];
  List<ChatMessage> chatMessages = [];

  Color currentColor = const Color(0xFF000000);
  double currentBrushSize = 4.0;
  bool isEraser = false;

  bool get isMyTurn => roomState?.currentDrawerId == myPlayerId;

  GameProvider({required this.apiService, required String wsUrl}) {
    wsService = WebSocketService(serverUrl: wsUrl);

    wsService.addListener(_handleIncomingWebSocketMessage);
  }

  void setPlayer(String id, String name, bool host) {
    myPlayerId = id;
    myPlayerName = name;
    isHost = host;

    notifyListeners();
  }

  void setDrawingColor(Color color) {
    currentColor = color;
    isEraser = false;

    notifyListeners();
  }

  void setBrushSize(double size) {
    currentBrushSize = size;

    notifyListeners();
  }

  void toggleEraser() {
    isEraser = !isEraser;

    notifyListeners();
  }

  String myAvatar = '🎨';

  Future<void> createAndJoinRoom({
    required String playerName,
    String avatar = '🎨',
    int maxPlayers = 8,
    int rounds = 3,
    int drawTime = 60,
    int wordChoices = 3,
    bool hintsEnabled = true,
    bool isPrivate = false,
    String category = 'all',
  }) async {
    myAvatar = avatar;

    final res = await apiService.createRoom(
      playerName: playerName,
      avatar: avatar,
      maxPlayers: maxPlayers,
      rounds: rounds,
      drawTime: drawTime,
      wordChoices: wordChoices,
      hintsEnabled: hintsEnabled,
      isPrivate: isPrivate,
      category: category,
    );

    currentRoomCode = res['roomCode'];
    myPlayerId = res['playerId'];
    myPlayerName = playerName;
    isHost = true;

    roomState = RoomState.fromJson(res['room']);

    wsService.connect(currentRoomCode);

    wsService.sendEvent('join_room', currentRoomCode, {
      'roomCode': currentRoomCode,
      'playerId': myPlayerId,
      'playerName': myPlayerName,
      'avatar': myAvatar,
    });

    notifyListeners();
  }

  Future<void> joinExistingRoom({
    required String playerName,
    required String roomCode,
    String avatar = '🎨',
  }) async {
    myAvatar = avatar;

    final res = await apiService.joinRoom(
      playerName: playerName,
      roomCode: roomCode,
      avatar: avatar,
    );

    currentRoomCode = res['roomCode'];
    myPlayerId = res['playerId'];
    myPlayerName = playerName;
    isHost = false;

    roomState = RoomState.fromJson(res['room']);

    wsService.connect(currentRoomCode);

    wsService.sendEvent('join_room', currentRoomCode, {
      'roomCode': currentRoomCode,
      'playerId': myPlayerId,
      'playerName': myPlayerName,
      'avatar': myAvatar,
    });

    notifyListeners();
  }

  void startGame() {
    if (!isHost || currentRoomCode.isEmpty) {
      return;
    }

    wsService.sendEvent('start_game', currentRoomCode, {});
  }

  void chooseWord(String word) {
    if (!isMyTurn || currentRoomCode.isEmpty) {
      return;
    }

    wsService.sendEvent('word_chosen', currentRoomCode, {'word': word});
  }

  void onDrawStart(double x, double y) {
    if (!isMyTurn) {
      return;
    }

    final colorToUse = isEraser ? const Color(0xFFFFFFFF) : currentColor;

    final point = DrawPoint(
      x: x,
      y: y,
      color: colorToUse,
      size: isEraser ? currentBrushSize * 2 : currentBrushSize,
      isStart: true,
    );

    strokes.add(point);

    notifyListeners();

    wsService.sendEvent(
      'draw_start',
      currentRoomCode,
      point.toJson('draw_start'),
    );
  }

  void onDrawMove(double x, double y) {
    if (!isMyTurn) {
      return;
    }

    final colorToUse = isEraser ? const Color(0xFFFFFFFF) : currentColor;

    final point = DrawPoint(
      x: x,
      y: y,
      color: colorToUse,
      size: isEraser ? currentBrushSize * 2 : currentBrushSize,
    );

    strokes.add(point);

    notifyListeners();

    wsService.sendEvent(
      'draw_move',
      currentRoomCode,
      point.toJson('draw_move'),
    );
  }

  void onDrawEnd() {
    if (!isMyTurn) {
      return;
    }

    final point = DrawPoint(x: 0, y: 0, isEnd: true);

    strokes.add(point);

    notifyListeners();

    wsService.sendEvent('draw_end', currentRoomCode, point.toJson('draw_end'));
  }

  void clearCanvas() {
    if (!isMyTurn) {
      return;
    }

    strokes.clear();

    notifyListeners();

    wsService.sendEvent('canvas_clear', currentRoomCode, {});
  }

  void undoStroke() {
    if (!isMyTurn || strokes.isEmpty) {
      return;
    }

    while (strokes.isNotEmpty) {
      final removed = strokes.removeLast();

      if (removed.isStart) {
        break;
      }
    }

    notifyListeners();

    wsService.sendEvent('draw_undo', currentRoomCode, {});
  }

  void sendGuess(String text) {
    if (text.trim().isEmpty) {
      return;
    }

    wsService.sendEvent('guess', currentRoomCode, {'text': text.trim()});
  }

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) {
      return;
    }

    wsService.sendEvent('chat_message', currentRoomCode, {'text': text.trim()});
  }

  void _handleIncomingWebSocketMessage(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    final payload = data['payload'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'game_state':
        roomState = RoomState.fromJson(payload);

        notifyListeners();
        break;

      case 'player_joined':
        final joinedPlayer = Player.fromJson(payload['player']);

        chatMessages.add(
          ChatMessage(
            id: DateTime.now().toString(),
            senderId: 'system',
            senderName: 'System',
            text: '${joinedPlayer.name} joined the room!',
            isSystem: true,
          ),
        );

        if (payload['players'] != null) {
          final updatedPlayers = (payload['players'] as List)
              .map((p) => Player.fromJson(p as Map<String, dynamic>))
              .toList();

          if (roomState != null) {
            roomState = RoomState(
              roomId: roomState!.roomId,
              phase: roomState!.phase,
              hostId: roomState!.hostId,
              round: roomState!.round,
              totalRounds: roomState!.totalRounds,
              currentDrawerId: roomState!.currentDrawerId,
              currentDrawerName: roomState!.currentDrawerName,
              remainingTime: roomState!.remainingTime,
              choiceTimeRemaining: roomState!.choiceTimeRemaining,
              maskedWord: roomState!.maskedWord,
              revealedWord: roomState!.revealedWord,
              wordChoices: roomState!.wordChoices,
              players: updatedPlayers,
              settings: roomState!.settings,
            );
          }
        }

        notifyListeners();
        break;

      case 'player_left':
        final leftName = payload['playerName'] ?? 'A player';

        chatMessages.add(
          ChatMessage(
            id: DateTime.now().toString(),
            senderId: 'system',
            senderName: 'System',
            text: '$leftName left the room.',
            isSystem: true,
          ),
        );

        if (payload['newHostId'] == myPlayerId) {
          isHost = true;
        }

        notifyListeners();
        break;

      case 'draw_start':
        if (!isMyTurn) {
          strokes.add(DrawPoint.fromJson(payload));

          notifyListeners();
        }
        break;

      case 'draw_move':
        if (!isMyTurn) {
          strokes.add(DrawPoint.fromJson(payload));

          notifyListeners();
        }
        break;

      case 'draw_end':
        if (!isMyTurn) {
          strokes.add(DrawPoint.fromJson(payload));

          notifyListeners();
        }
        break;

      case 'canvas_clear':
        strokes.clear();

        notifyListeners();
        break;

      case 'draw_undo':
        if (payload['strokes'] != null) {
          strokes = (payload['strokes'] as List)
              .map((s) => DrawPoint.fromJson(s as Map<String, dynamic>))
              .toList();
        } else if (strokes.isNotEmpty) {
          while (strokes.isNotEmpty) {
            final p = strokes.removeLast();

            if (p.isStart) {
              break;
            }
          }
        }

        notifyListeners();
        break;

      case 'guess_result':
        final status = payload['status'];

        if (status == 'correct') {
          final guesserName = payload['playerName'] ?? 'Someone';

          final points = payload['points'] ?? 0;

          chatMessages.add(
            ChatMessage(
              id: DateTime.now().toString(),
              senderId: payload['playerId'] ?? '',
              senderName: guesserName,
              text: '$guesserName guessed the word! (+$points pts)',
              isCorrectGuess: true,
            ),
          );
        } else if (status == 'close') {
          chatMessages.add(
            ChatMessage(
              id: DateTime.now().toString(),
              senderId: 'system',
              senderName: 'Hint',
              text: payload['message'] ?? 'You are close!',
              isCloseGuess: true,
            ),
          );
        }

        notifyListeners();
        break;

      case 'chat_message':
        chatMessages.add(
          ChatMessage(
            id: DateTime.now().toString(),
            senderId: payload['playerId'] ?? '',
            senderName: payload['playerName'] ?? 'Player',
            text: payload['text'] ?? '',
          ),
        );

        notifyListeners();
        break;

      case 'timer_tick':
        if (roomState != null) {
          roomState = RoomState(
            roomId: roomState!.roomId,
            phase: payload['phase'] ?? roomState!.phase,
            hostId: roomState!.hostId,
            round: roomState!.round,
            totalRounds: roomState!.totalRounds,
            currentDrawerId: roomState!.currentDrawerId,
            currentDrawerName: roomState!.currentDrawerName,
            remainingTime: payload['remainingTime'] ?? roomState!.remainingTime,
            choiceTimeRemaining:
                payload['choiceTimeRemaining'] ??
                roomState!.choiceTimeRemaining,
            maskedWord: payload['maskedWord'] ?? roomState!.maskedWord,
            revealedWord: roomState!.revealedWord,
            wordChoices: roomState!.wordChoices,
            players: roomState!.players,
            settings: roomState!.settings,
          );

          notifyListeners();
        }
        break;
    }
  }

  @override
  void dispose() {
    wsService.disconnect();
    super.dispose();
  }
}
