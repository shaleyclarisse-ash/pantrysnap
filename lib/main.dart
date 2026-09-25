import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'screens/splash_screen.dart';
import 'services/gemini_service.dart';
import 'services/pantry_provider.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loads GEMINI_API_KEY from .env (see .env.example). Missing the file
  // is non-fatal here so the app still launches and can show a clear
  // in-app error rather than crashing on boot.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not found - GeminiService will surface a friendly error when used.
  }

  await StorageService.instance.init();

  runApp(const PantrySnapApp());
}

class PantrySnapApp extends StatelessWidget {
  const PantrySnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    return ChangeNotifierProvider(
      create: (_) => PantryProvider(
        geminiService: GeminiService(apiKey: apiKey),
      ),
      child: MaterialApp(
        title: 'PantrySnap',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2E7D32),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
