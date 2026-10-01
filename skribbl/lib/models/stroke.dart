import 'dart:ui';

class DrawPoint {
  final double x; // Normalized 0.0 to 1.0 for multi-resolution support
  final double y;
  final Color color;
  final double size;
  final bool isStart;
  final bool isEnd;

  DrawPoint({
    required this.x,
    required this.y,
    this.color = const Color(0xFF000000),
    this.size = 4.0,
    this.isStart = false,
    this.isEnd = false,
  });

  Map<String, dynamic> toJson(String type) {
    return {
      'type': type,
      'x': x,
      'y': y,
      'color': '#${color.r.toInt().toRadixString(16).padLeft(2, '0')}${color.g.toInt().toRadixString(16).padLeft(2, '0')}${color.b.toInt().toRadixString(16).padLeft(2, '0')}',
      'size': size,
      'isStart': isStart,
      'isEnd': isEnd,
    };
  }

  factory DrawPoint.fromJson(Map<String, dynamic> json) {
    Color parsedColor = const Color(0xFF000000);
    if (json['color'] != null) {
      String hex = json['color'].toString().replaceAll('#', '');
      if (hex.length == 6) {
        parsedColor = Color(int.parse('0xFF$hex'));
      }
    }
    return DrawPoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      color: parsedColor,
      size: (json['size'] as num?)?.toDouble() ?? 4.0,
      isStart: json['type'] == 'draw_start' || json['isStart'] == true,
      isEnd: json['type'] == 'draw_end' || json['isEnd'] == true,
    );
  }
}
