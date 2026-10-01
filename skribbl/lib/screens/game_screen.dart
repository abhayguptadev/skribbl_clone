import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skribbl/state/game_provider.dart';
import 'package:skribbl/widget/drawing_canvas.dart';
import 'package:skribbl/widget/drawing_toolbar.dart';
import 'package:skribbl/widget/scoreboard.dart';
import 'package:skribbl/widget/chat.dart';
import 'leaderboard_screen.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final room = game.roomState;

    if (room == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    if (room.phase == 'game_over') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
        );
      });
    }

    final isDrawer = game.isMyTurn;
    final drawerName = room.currentDrawerName ?? 'Someone';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [

                _buildTopBar(context, room, isDrawer, drawerName),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ScoreboardWidget(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: const DrawingCanvasWidget(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (isDrawer)
                                const DrawingToolbarWidget()
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.info_outline_rounded, color: Colors.white38, size: 18),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Wait for your turn to draw! Guess the word to earn points.",
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        const ChatWidget(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (room.phase == 'word_choice')
              _buildWordChoiceOverlay(context, game, room, isDrawer, drawerName),

            if (room.phase == 'round_result')
              _buildRoundResultOverlay(context, room),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, dynamic room, bool isDrawer, String drawerName) {
    final timer = room.remainingTime;
    final timerColor = timer <= 10 
        ? const Color(0xFFEF4444) 
        : (timer <= 25 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Round Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ROUND', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text(
                '${room.round} of ${room.totalRounds}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          //word display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isDrawer)
                Column(
                  children: [
                    const Text('YOUR WORD TO DRAW', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      room.revealedWord?.toUpperCase() ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Text(
                      room.maskedWord.isEmpty ? '_ _ _' : room.maskedWord,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$drawerName is drawing...',
                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
            ],
          ),

          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: timerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: timerColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: timerColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$timer',
                  style: TextStyle(
                    color: timerColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordChoiceOverlay(BuildContext context, GameProvider game, dynamic room, bool isDrawer, String drawerName) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ColorFilter.mode(const Color(0xFF0F172A).withValues(alpha: 0.8), BlendMode.srcOver),
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDrawer ? 'PICK A WORD' : 'WAITING FOR DRAWER',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isDrawer 
                              ? 'Choose one of these words to start drawing' 
                              : '$drawerName is choosing a word...',
                          style: const TextStyle(color: Colors.white54, fontSize: 24),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        if (isDrawer)
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: (room.wordChoices as List<String>).map((word) {
                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                                  backgroundColor: const Color(0xFF3B82F6),
                                  elevation: 8,
                                  shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                                ),
                                onPressed: () => game.chooseWord(word),
                                child: Text(
                                  word.toUpperCase(),
                                  style: const TextStyle(letterSpacing: 2,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900),
                                ),
                              );
                            }).toList(),
                          )
                        else
                          const SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 3),
                          ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'TIME REMAINING: ${room.choiceTimeRemaining}s',
                            style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundResultOverlay(BuildContext context, dynamic room) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ColorFilter.mode(const Color(0xFF0F172A).withValues(alpha: 0.8), BlendMode.srcOver),
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, offset: const Offset(0, 20)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ROUND OVER',
                          style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
                        ),
                        const SizedBox(height: 8),
                        const Text('THE WORD WAS', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          (room.revealedWord ?? 'WORD').toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF22C55E),
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 24),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: (room.players as List).length,
                            separatorBuilder: (_, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final p = room.players[index];
                              if (p.roundScore <= 0) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(p.avatar, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                    ),
                                    Text(
                                      '+${p.roundScore}',
                                      style: const TextStyle(
                                        color: Color(0xFF22C55E),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'GET READY FOR THE NEXT ROUND...',
                          style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
