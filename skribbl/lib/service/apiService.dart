import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = ''});

  Future<Map<String, dynamic>> createRoom({
    required String playerName,
    String avatar = '🎨',
    int maxPlayers = 8,
    int rounds = 3,
    int drawTime = 60,
    int wordChoices = 3,
    bool hintsEnabled = true,
    bool isPrivate = false,
    List<String> customWords = const [],
    String category = 'all',
  }) async {
    final uri = Uri.parse('$baseUrl/api/rooms/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'playerName': playerName,
        'avatar': avatar,
        'maxPlayers': maxPlayers,
        'rounds': rounds,
        'drawTime': drawTime,
        'wordChoices': wordChoices,
        'hintsEnabled': hintsEnabled,
        'isPrivate': isPrivate,
        'customWords': customWords,
        'category': category,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create room: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> joinRoom({
    required String playerName,
    required String roomCode,
    String avatar = '🎨',
  }) async {
    final uri = Uri.parse('$baseUrl/api/rooms/join/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'playerName': playerName,
        'roomCode': roomCode.toUpperCase(),
        'avatar': avatar,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to join room: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getRoomDetail(String roomCode) async {
    final uri = Uri.parse('$baseUrl/api/rooms/$roomCode/');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Room not found');
    }
  }
}
