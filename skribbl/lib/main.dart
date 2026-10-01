import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skribbl/screens/homeScreen.dart';
import 'package:skribbl/service/apiService.dart';
import 'package:skribbl/state/gameProvider.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SkribblApp());
}

class SkribblApp extends StatelessWidget {
  const SkribblApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine backend host from current web window or default to local backend
    const String defaultHost = 'http://localhost:8000';
    const String defaultWs = 'ws://localhost:8000';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GameProvider(
            apiService: ApiService(baseUrl: defaultHost),
            wsUrl: defaultWs,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Skribbl Clone - Multiplayer Drawing Game',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF3B82F6),
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          canvasColor: const Color(0xFF1E293B),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          dividerColor: Colors.white12,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF3B82F6),
            secondary: Color(0xFFF59E0B),
            surface: Color(0xFF1E293B),
            error: Color(0xFFEF4444),
            onPrimary: Colors.white,
            onSurface: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF0F172A),
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
