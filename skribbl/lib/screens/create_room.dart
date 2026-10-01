import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skribbl/state/game_provider.dart';
import 'package:skribbl/screens/lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  final String playerName;
  final String avatar;

  const CreateRoomScreen({super.key, required this.playerName, required this.avatar});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  int maxPlayers = 8;
  int rounds = 3;
  int drawTime = 60;
  int wordChoices = 3;
  bool hintsEnabled = true;
  bool isPrivate = false;
  String category = 'all';
  bool isLoading = false;
  String? errorMessage;

  Future<void> _handleCreate() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final game = context.read<GameProvider>();
      await game.createAndJoinRoom(
        playerName: widget.playerName,
        avatar: widget.avatar,
        maxPlayers: maxPlayers,
        rounds: rounds,
        drawTime: drawTime,
        wordChoices: wordChoices,
        hintsEnabled: hintsEnabled,
        isPrivate: isPrivate,
        category: category,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LobbyScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('CREATE ROOM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                    ),
                    child: Text(errorMessage!, style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                  ),

                _buildSectionTitle('GAME SETTINGS'),
                const SizedBox(height: 20),

                _buildSlider(
                  label: 'Maximum Players',
                  value: maxPlayers.toDouble(),
                  min: 2,
                  max: 20,
                  displayValue: '$maxPlayers',
                  onChanged: (val) => setState(() => maxPlayers = val.toInt()),
                ),

                _buildSlider(
                  label: 'Rounds',
                  value: rounds.toDouble(),
                  min: 2,
                  max: 10,
                  displayValue: '$rounds',
                  onChanged: (val) => setState(() => rounds = val.toInt()),
                ),

                _buildSlider(
                  label: 'Draw Time',
                  value: drawTime.toDouble(),
                  min: 30,
                  max: 180,
                  displayValue: '${drawTime}s',
                  onChanged: (val) => setState(() => drawTime = val.toInt()),
                ),

                _buildSlider(
                  label: 'Word Choices',
                  value: wordChoices.toDouble(),
                  min: 1,
                  max: 5,
                  displayValue: '$wordChoices',
                  onChanged: (val) => setState(() => wordChoices = val.toInt()),
                ),

                const SizedBox(height: 12),
                const Text('Word Category', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: category,
                      dropdownColor: const Color(0xFF1E293B),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Categories')),
                        DropdownMenuItem(value: 'animals', child: Text('Animals')),
                        DropdownMenuItem(value: 'food', child: Text('Food & Drinks')),
                        DropdownMenuItem(value: 'objects', child: Text('Everyday Objects')),
                        DropdownMenuItem(value: 'places', child: Text('Places & Nature')),
                        DropdownMenuItem(value: 'technology', child: Text('Technology')),
                        DropdownMenuItem(value: 'actions', child: Text('Actions & Verbs')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => category = val);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _buildToggle(
                  title: 'Enable Hints',
                  subtitle: 'Reveals letters over time',
                  value: hintsEnabled,
                  onChanged: (val) => setState(() => hintsEnabled = val),
                ),
                _buildToggle(
                  title: 'Private Room',
                  subtitle: 'Invite only via code',
                  value: isPrivate,
                  onChanged: (val) => setState(() => isPrivate = val),
                ),

                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleCreate,
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('CREATE & ENTER LOBBY'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
              Text(displayValue, style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: const Color(0xFF3B82F6),
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        value: value,
        activeThumbColor: const Color(0xFF3B82F6),
        activeTrackColor: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        inactiveThumbColor: Colors.white60,
        inactiveTrackColor: Colors.white10,
        onChanged: onChanged,
      ),
    );
  }
}
