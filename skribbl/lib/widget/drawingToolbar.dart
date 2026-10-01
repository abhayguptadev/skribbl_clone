import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skribbl/state/gameProvider.dart';

class DrawingToolbarWidget extends StatelessWidget {
  const DrawingToolbarWidget({super.key});

  static const List<Color> colors = [
    Colors.black,
    Colors.grey,
    Colors.red,
    Colors.yellow,
    Colors.orange,
    Colors.lightBlue,
    Colors.green,
    Colors.blueAccent,
    Colors.pink,
    Colors.white,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    if (!game.isMyTurn) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Colors
          Wrap(
            spacing: 6,
            children: colors.map((c) {
              final isSelected = !game.isEraser && game.currentColor.value == c.value;
              return GestureDetector(
                onTap: () => game.setDrawingColor(c),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.black45,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 16),
          // Brushes
          Row(
            children: [4.0, 8.0, 16.0, 24.0].map((size) {
              final isSelected = game.currentBrushSize == size;
              return IconButton(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Container(
                  width: size + 4,
                  height: size + 4,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amber : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                onPressed: () => game.setBrushSize(size),
              );
            }).toList(),
          ),
          const Spacer(),

          IconButton(
            tooltip: 'Eraser',
            icon: Icon(
              Icons.auto_fix_normal,
              color: game.isEraser ? Colors.amber : Colors.white70,
            ),
            onPressed: () => game.toggleEraser(),
          ),

          IconButton(
            tooltip: 'Undo',
            icon: const Icon(Icons.undo, color: Colors.white70),
            onPressed: () => game.undoStroke(),
          ),

          IconButton(
            tooltip: 'Clear Canvas',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => game.clearCanvas(),
          ),
        ],
      ),
    );
  }
}
