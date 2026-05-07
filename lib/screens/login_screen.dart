import 'package:flutter/material.dart';
import '../services/google_drive_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // 🔥 Integrated Handle: Login + Auto-Sync
  void _handleSignInAndSync() async {
    setState(() => _isLoading = true);

    try {
      // 1. Google Drive Login ensure karein
      bool success = await GoogleDriveService.loginUser();

      if (success) {
        // 2. 🔥 Automatic Restore: User ko bina bataye piche se sync chalu
        // Ye tab kaam aayega jab user ne app reinstall kiya ho
        await GoogleDriveService.syncDataFromDrive();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Sign-In Failed. Check your connection.")),
          );
        }
      }
    } catch (e) {
      debugPrint("Auth/Sync Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ☁️ Professional Cloud Icon
              const Icon(
                Icons.cloud_done_rounded,
                size: 110,
                color: Colors.indigo,
              ),
              const SizedBox(height: 30),

              // 🏷️ App Title
              const Text(
                "Vault Pro Cloud",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 15),

              // 📝 Subtitle
              const Text(
                "Sync your documents to Google Drive and access them anywhere seamlessly.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.blueGrey, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 50),

              if (_isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.indigo),
                    SizedBox(height: 20),
                    Text("Connecting and Syncing Data...",
                        style: TextStyle(
                            color: Colors.indigo, fontWeight: FontWeight.w500)),
                  ],
                )
              else
                // 🔥 Single Primary Button: Continue with Google
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _handleSignInAndSync,
                    icon: const Icon(Icons.g_mobiledata, size: 35),
                    label: const Text(
                      "Continue with Google",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),

              // Note: Green "Restore" button permanent remove
            ],
          ),
        ),
      ),
    );
  }
}
