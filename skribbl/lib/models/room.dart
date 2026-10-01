import 'player.dart';

class RoomSettings {
  final int maxPlayers;
  final int rounds;
  final int drawTime;
  final int wordChoices;
  final bool hintsEnabled;
  final bool isPrivate;
  final List<String> customWords;
  final String category;

  RoomSettings({
    this.maxPlayers = 8,
    this.rounds = 3,
    this.drawTime = 60,
    this.wordChoices = 3,
    this.hintsEnabled = true,
    this.isPrivate = false,
    this.customWords = const [],
    this.category = 'all',
  });

  factory RoomSettings.fromJson(Map<String, dynamic> json) {
    return RoomSettings(
      maxPlayers: json['maxPlayers'] as int? ?? 8,
      rounds: json['rounds'] as int? ?? 3,
      drawTime: json['drawTime'] as int? ?? 60,
      wordChoices: json['wordChoices'] as int? ?? 3,
      hintsEnabled: json['hintsEnabled'] as bool? ?? true,
      isPrivate: json['isPrivate'] as bool? ?? false,
      customWords: (json['customWords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      category: json['category']?.toString() ?? 'all',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxPlayers': maxPlayers,
      'rounds': rounds,
      'drawTime': drawTime,
      'wordChoices': wordChoices,
      'hintsEnabled': hintsEnabled,
      'isPrivate': isPrivate,
      'customWords': customWords,
      'category': category,
    };
  }
}

class RoomState {
  final String roomId;
  final String phase; // lobby, word_choice, drawing, round_result, game_over
  final String hostId;
  final int round;
  final int totalRounds;
  final String? currentDrawerId;
  final String? currentDrawerName;
  final int remainingTime;
  final int choiceTimeRemaining;
  final String maskedWord;
  final String? revealedWord;
  final List<String> wordChoices;
  final List<Player> players;
  final RoomSettings settings;

  RoomState({
    required this.roomId,
    required this.phase,
    required this.hostId,
    this.round = 1,
    this.totalRounds = 3,
    this.currentDrawerId,
    this.currentDrawerName,
    this.remainingTime = 60,
    this.choiceTimeRemaining = 15,
    this.maskedWord = '',
    this.revealedWord,
    this.wordChoices = const [],
    this.players = const [],
    required this.settings,
  });

  factory RoomState.fromJson(Map<String, dynamic> json) {
    return RoomState(
      roomId: json['roomId']?.toString() ?? '',
      phase: json['phase']?.toString() ?? 'lobby',
      hostId: json['hostId']?.toString() ?? '',
      round: json['round'] as int? ?? 1,
      totalRounds: json['totalRounds'] as int? ?? 3,
      currentDrawerId: json['currentDrawerId']?.toString(),
      currentDrawerName: json['currentDrawerName']?.toString(),
      remainingTime: json['remainingTime'] as int? ?? 60,
      choiceTimeRemaining: json['choiceTimeRemaining'] as int? ?? 15,
      maskedWord: json['maskedWord']?.toString() ?? '',
      revealedWord: json['revealedWord']?.toString(),
      wordChoices: (json['wordChoices'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      players: (json['players'] as List<dynamic>?)?.map((p) => Player.fromJson(p as Map<String, dynamic>)).toList() ?? [],
      settings: RoomSettings.fromJson(json['settings'] as Map<String, dynamic>? ?? {}),
    );
  }
}
