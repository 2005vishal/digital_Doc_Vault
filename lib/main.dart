import 'package:flutter/material.dart';
import 'services/google_drive_service.dart';
import 'screens/login_screen.dart';
import 'screens/security_gate.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  // 1. Flutter engine aur plugins ko initialize
  WidgetsFlutterBinding.ensureInitialized();

  // 2. check in background gmail login or not

  final bool isLoggedIn = await GoogleDriveService.isUserLoggedIn();

  runApp(DigiSanchayApp(isLoggedIn: isLoggedIn));
}

class DigiSanchayApp extends StatelessWidget {
  final bool isLoggedIn;

  const DigiSanchayApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 🔥 APP NAME: "Digi Sanchay"
      title: 'Digi Sanchay',
      debugShowCheckedModeBanner: false,

      // Global Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
      ),

      // MAIN NAVIGATION LOGIC:

      home: isLoggedIn ? const SecurityGate() : const LoginScreen(),

      // Named routes: Navigation
      routes: {
        '/login': (context) => const LoginScreen(),
        '/security': (context) => const SecurityGate(),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
