import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

/// Root routing widget. Listens to Firebase's auth state stream and shows
/// either the login flow or the main app (starting at SplashScreen, which
/// then hands off to ScanScreen) accordingly. Sign-out from anywhere in
/// the app automatically drops the user back to LoginScreen because this
/// widget rebuilds whenever the stream emits.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final signedIn = snapshot.data != null;
        return signedIn ? const SplashScreen() : const LoginScreen();
      },
    );
  }
}