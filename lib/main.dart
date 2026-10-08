import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/gemini_service.dart';
import 'services/local_providers.dart';
import 'services/pantry_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await StorageService.instance.init();

  runApp(const PantrySnapApp());
}

class PantrySnapApp extends StatelessWidget {
  const PantrySnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => PantryProvider(
            geminiService: GeminiService(apiKey: apiKey),
          ),
        ),
        ChangeNotifierProvider(create: (_) => PantryInventoryProvider()),
        ChangeNotifierProvider(create: (_) => ShoppingListProvider()),
        ChangeNotifierProvider(create: (_) => MealPlanProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: Consumer<ProfileProvider>(
        builder: (context, profile, _) {
          return MaterialApp(
            title: 'PantrySnap',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            // The Profile screen's "Dark mode" switch drives this directly,
            // rather than only following the system setting.
            themeMode: profile.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
