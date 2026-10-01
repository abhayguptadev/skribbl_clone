import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skribbl/state/game_provider.dart';


class ScoreboardWidget extends StatelessWidget {
  const ScoreboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final players = game.roomState?.players ?? [];
    final currentDrawerId = game.roomState?.currentDrawerId;

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                SizedBox(width: 8),
                Text(
                  'Players',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final isDrawer = player.id == currentDrawerId;
                final isMe = player.id == game.myPlayerId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: player.hasGuessed
                        ? const Color(0xFF065F46) // Green for guessed
                        : (isMe ? const Color(0xFF334155) : const Color(0xFF1E293B)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isMe ? Colors.indigoAccent : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('#${index + 1}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 6),
                      Text(player.avatar, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    player.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                if (player.isHost)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.star, color: Colors.amber, size: 12),
                                  ),
                              ],
                            ),
                            Text(
                              '${player.score} pts',
                              style: const TextStyle(color: Colors.amber, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (isDrawer)
                        const Tooltip(
                          message: 'Drawing now',
                          child: Icon(Icons.edit, color: Colors.blueAccent, size: 16),
                        )
                      else if (player.hasGuessed)
                        const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
