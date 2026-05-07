import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class SecurityGate extends StatefulWidget {
  const SecurityGate({super.key});

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> {
  bool _isAuthFailed = false;

  @override
  void initState() {
    super.initState();
    // 🔥 Dashboard ko turant silent karein
    isPickingFileGlobal = true;

    // Build hone ke baad auth trigger karein
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateUser();
    });
  }

  Future<void> _authenticateUser() async {
    // Biometric prompt dikhayein
    bool authenticated = await AuthService.authenticate();

    if (authenticated) {
      if (mounted) {
        // 🔥 CRITICAL: Pehle navigation karein, flag ko navigate hone ke baad reset karein
        // Isse Dashboard ko resume event receive hone tak flag 'true' milega
        _handleNavigation();

        Future.delayed(const Duration(milliseconds: 500), () {
          isPickingFileGlobal = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isAuthFailed = true;
          isPickingFileGlobal = false; // User ko retry ka mauka dein
        });
      }
    }
  }

  void _handleNavigation() {
    if (!mounted) return;

    // Agar Dashboard ke upar overlay khula hai
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // Agar startup se app khuli hai
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Security lock bypass nahi kiya ja sakta
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1C1E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: Colors.indigoAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                "Vault is Locked",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please verify your identity",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 50),
              if (_isAuthFailed)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _isAuthFailed = false);
                    _authenticateUser();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try Again"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                  ),
                )
              else
                const CircularProgressIndicator(color: Colors.indigoAccent),
            ],
          ),
        ),
      ),
    );
  }
}
