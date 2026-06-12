import 'package:flutter/material.dart';
import 'services/session_service.dart';
import 'screens/role_router.dart';
import 'screens/splash_screen.dart';

// ═══════════════════════════════════════════════════════════════════
//  QmedCO — App Entry Point
//  File: lib/main.dart
// ═══════════════════════════════════════════════════════════════════

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QmedCOApp());
}

class QmedCOApp extends StatelessWidget {
  const QmedCOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'QmedCO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3:             true,
        scaffoldBackgroundColor:  const Color(0xFF080C14),
        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFF0D6B5E),
          secondary: Color(0xFF12877A),
        ),
      ),
      home: const StartupGate(),
    );
  }
}

class StartupGate extends StatelessWidget {
  const StartupGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: SessionService.instance.restore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF080C14),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = SessionService.instance.user;
        if (user != null) {
          return RoleRouter.destinationFor(user);
        }
        return const SplashScreen();
      },
    );
  }
}
