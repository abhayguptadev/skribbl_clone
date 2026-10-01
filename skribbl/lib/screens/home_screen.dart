import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'create_room.dart';
import 'join_room_screen.dart';
import 'game_screen.dart';
import 'package:skribbl/state/game_provider.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nameController = TextEditingController(
    text: 'Player${DateTime.now().millisecond}',
  );

  String selectedAvatar = '🎨';

  final List<String> avatars = ['🎨', '🦊', '🚀', '🐼', '🐯', '⚡', '🌟', '🦄'];

  bool _isQuickJoining = false;
  Future<void> _quickJoin() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name first.')),
      );
      return;
    }
    setState(() {
      _isQuickJoining = true;
    });
    try {
      final game = context.read<GameProvider>();
      await game.quickJoinRoom(playerName: name, avatar: selectedAvatar);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GameScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isQuickJoining = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.brush, color: Colors.blueAccent, size: 36),
                    SizedBox(width: 12),
                    Text(
                      'Skribbl Clone',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Center(
                  child: Text(
                    'Multiplayer Drawing & Guessing Game',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Choose Your Display Name',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Colors.blueAccent,
                    ),
                    hintText: 'Enter name',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Choose Avatar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: avatars.map((a) {
                    final isSel = selectedAvatar == a;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAvatar = a;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel
                              ? Colors.blueAccent
                              : const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel
                                ? Colors.blueAccent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Text(a, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 28),

                // QUICK JOIN
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isQuickJoining ? null : _quickJoin,
                  child: _isQuickJoining
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flash_on),
                            SizedBox(width: 8),
                            Text(
                              'Quick Join',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 12),

                // CREATE ROOM
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();

                    if (name.isEmpty) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateRoomScreen(
                          playerName: name,
                          avatar: selectedAvatar,
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline),
                      SizedBox(width: 8),
                      Text(
                        'Create Room',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // JOIN ROOM
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final name = _nameController.text.trim();

                    if (name.isEmpty) return;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JoinRoomScreen(
                          playerName: name,
                          avatar: selectedAvatar,
                        ),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.meeting_room_outlined),
                      SizedBox(width: 8),
                      Text(
                        'Join Room',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
