import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:skribbl/screens/home_screen.dart';
import 'package:skribbl/service/api_service.dart';
import 'package:skribbl/state/game_provider.dart';
import 'package:skribbl/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SkribblApp());
}

class SkribblApp extends StatelessWidget {
  const SkribblApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GameProvider(
            apiService: ApiService(
              baseUrl: AppConfig.apiBaseUrl,
            ),
            wsUrl: AppConfig.websocketUrl,
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
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.dark().textTheme,
          ),
          dividerColor: Colors.white12,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF3B82F6),
            secondary: Color(0xFFF59E0B),
            surface: Color(0xFF1E293B),
            error: Color(0xFFEF4444),
            onPrimary: Colors.white,
            onSurface: Colors.white,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}