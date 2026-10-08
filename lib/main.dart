import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'services/gemini_service.dart';
import 'services/pantry_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    return ChangeNotifierProvider(
      create: (_) => PantryProvider(
        geminiService: GeminiService(apiKey: apiKey),
      ),
      child: MaterialApp(
        title: 'PantrySnap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const AuthGate(),
      ),
    );
  }
}