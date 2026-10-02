import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skribbl/state/game_provider.dart';

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

    if (!game.isMyTurn) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Colors
            Wrap(
              spacing: 8,
              children: colors.map((c) {
                final isSelected =
                    !game.isEraser &&
                    game.currentColor.toARGB32() == c.toARGB32();

                return GestureDetector(
                  onTap: () => game.setDrawingColor(c),
                  child: Container(
                    width: 30,
                    height: 30,
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

            const SizedBox(width: 14),

            // Brushes
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [4.0, 8.0, 16.0, 24.0].map((size) {
                final isSelected = game.currentBrushSize == size;

                return IconButton(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
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

            const SizedBox(width: 8),

            // Eraser
            IconButton(
              tooltip: 'Eraser',
              icon: Icon(
                Icons.auto_fix_normal,
                color: game.isEraser ? Colors.amber : Colors.white70,
              ),
              onPressed: () => game.toggleEraser(),
            ),

            // Undo
            IconButton(
              tooltip: 'Undo',
              icon: const Icon(Icons.undo, color: Colors.white70),
              onPressed: () => game.undoStroke(),
            ),

            // Clear Canvas
            IconButton(
              tooltip: 'Clear Canvas',
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => game.clearCanvas(),
            ),
          ],
        ),
      ),
    );
  }
}
