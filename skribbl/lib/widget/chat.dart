import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skribbl/state/gameProvider.dart';


class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage(GameProvider game) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (game.isMyTurn) {
      game.sendChatMessage(text);
    } else {
      game.sendGuess(text);
    }
    _controller.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final isDrawer = game.isMyTurn;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: const Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.blueAccent, size: 20),
                SizedBox(width: 8),
                Text(
                  'Guesses & Chat',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: game.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = game.chatMessages[index];

                Color bgColor = Colors.transparent;
                Color textColor = Colors.white;

                if (msg.isCorrectGuess) {
                  bgColor = const Color(0xFF065F46);
                  textColor = Colors.greenAccent;
                } else if (msg.isCloseGuess) {
                  bgColor = const Color(0xFF78350F);
                  textColor = Colors.amberAccent;
                } else if (msg.isSystem) {
                  textColor = Colors.lightBlueAccent;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${msg.senderName}: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: msg.isSystem ? Colors.lightBlueAccent : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: msg.text,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: isDrawer ? 'Chat with players...' : 'Type your guess here...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(game),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent, size: 20),
                  onPressed: () => _sendMessage(game),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
