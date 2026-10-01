class Player {
  final String id;
  final String name;
  final int score;
  final int roundScore;
  final bool isHost;
  final bool isConnected;
  final bool isReady;
  final bool hasGuessed;
  final String avatar;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.roundScore = 0,
    this.isHost = false,
    this.isConnected = true,
    this.isReady = true,
    this.hasGuessed = false,
    this.avatar = '🎨',
  });

  String get displayName => name.length > 15 ? '${name.substring(0, 12)}...' : name;

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Player',
      score: json['score'] as int? ?? 0,
      roundScore: json['roundScore'] as int? ?? 0,
      isHost: json['isHost'] as bool? ?? false,
      isConnected: json['isConnected'] as bool? ?? true,
      isReady: json['isReady'] as bool? ?? true,
      hasGuessed: json['hasGuessed'] as bool? ?? false,
      avatar: json['avatar']?.toString() ?? '🎨',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'roundScore': roundScore,
      'isHost': isHost,
      'isConnected': isConnected,
      'isReady': isReady,
      'hasGuessed': hasGuessed,
      'avatar': avatar,
    };
  }
}
