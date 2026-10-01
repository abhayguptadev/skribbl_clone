import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/stroke.dart';
import 'package:skribbl/state/gameProvider.dart';


class DrawingCanvasWidget extends StatelessWidget {
  const DrawingCanvasWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isDrawer = game.isMyTurn;

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasWidth = constraints.maxWidth;
        final canvasHeight = constraints.maxHeight;

        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: Colors.white,
            child: GestureDetector(
              onPanStart: isDrawer
                  ? (details) {
                final localPos = details.localPosition;
                final normX = (localPos.dx / canvasWidth).clamp(0.0, 1.0);
                final normY = (localPos.dy / canvasHeight).clamp(0.0, 1.0);
                game.onDrawStart(normX, normY);
              }
                  : null,
              onPanUpdate: isDrawer
                  ? (details) {
                final localPos = details.localPosition;
                final normX = (localPos.dx / canvasWidth).clamp(0.0, 1.0);
                final normY = (localPos.dy / canvasHeight).clamp(0.0, 1.0);
                game.onDrawMove(normX, normY);
              }
                  : null,
              onPanEnd: isDrawer
                  ? (details) {
                game.onDrawEnd();
              }
                  : null,
              child: CustomPaint(
                size: Size(canvasWidth, canvasHeight),
                painter: StrokePainter(
                  strokes: game.strokes,
                  canvasWidth: canvasWidth,
                  canvasHeight: canvasHeight,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class StrokePainter extends CustomPainter {
  final List<DrawPoint> strokes;
  final double canvasWidth;
  final double canvasHeight;

  StrokePainter({
    required this.strokes,
    required this.canvasWidth,
    required this.canvasHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    for (int i = 0; i < strokes.length; i++) {
      final current = strokes[i];
      if (current.isEnd) continue;

      final paint = Paint()
        ..color = current.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = current.size
        ..style = PaintingStyle.stroke;

      final p1 = Offset(current.x * canvasWidth, current.y * canvasHeight);

      if (i + 1 < strokes.length && !strokes[i + 1].isStart && !strokes[i + 1].isEnd) {
        final next = strokes[i + 1];
        final p2 = Offset(next.x * canvasWidth, next.y * canvasHeight);
        canvas.drawLine(p1, p2, paint);
      } else {
        // Draw a single dot for clicks
        canvas.drawCircle(p1, current.size / 2, paint..style = PaintingStyle.fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length ||
        oldDelegate.canvasWidth != canvasWidth ||
        oldDelegate.canvasHeight != canvasHeight;
  }
}
