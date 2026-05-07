import 'package:local_auth/local_auth.dart';

class AuthService {
  static final _auth = LocalAuthentication();

  static Future<bool> authenticate() async {
    final isAvailable = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();

    if (!isAvailable && !isDeviceSupported) return false;

    try {
      return await _auth.authenticate(
        localizedReason:
            'Unlock your screen  with PIN,pattern,password,face or fingerprint',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
