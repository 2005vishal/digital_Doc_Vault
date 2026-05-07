# Digi Sanchay (Digital Vault) 🛡️

**Digi Sanchay** is a highly secure, Flutter-based mobile document vault designed to help users organize, secure, and sync their important documents. Built with a focus on privacy, it utilizes local biometric authentication and Google Drive integration for seamless backups.

## 🚀 Features

- **Biometric Security:** Integrated `SecurityGate` that triggers on app launch and lifecycle changes to keep your data private.
- **Google Drive Sync:** Automatic and manual synchronization of folders and files to your personal Google Drive.
- **Smart Folder Management:** Create, Rename, and Delete folders locally with real-time mirroring on the cloud.
- **Multi-File Sharing:** Easily share entire folders or specific documents via any communication app.
- **Automated Restoring:** Re-installs all your documents automatically when you log in on a new device.
- **Adaptive UI:** Fully optimized for both Portrait and Landscape modes.

## 📸 Screenshots

| Dashboard | Security Lock | Folder Detail |
|-----------|---------------|---------------|
| 

[Image of Mobile App Dashboard]
 |  |  |

## 🛠️ Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **Database:** SQLite (for local metadata) & SharedPreferences
- **Cloud:** Google Drive API (v3)
- **Auth:** Google Sign-In

## 📋 Prerequisites

To run this project, you will need:
- Flutter SDK (v3.0.0 or higher)
- A Google Cloud Project with Drive API enabled.
- SHA-1 and SHA-256 fingerprints for your debug/release keys (for Google Auth).

## ⚙️ Setup & Installation

1. **Clone the repo:**
   ```bash
   git clone [https://github.com/YOUR_USERNAME/Digi-Sanchay.git](https://github.com/YOUR_USERNAME/Digi-Sanchay.git)
   cd Digi-Sanchay

2. **Add Configuration Files:**
- Due to security reasons, private configuration files are not included in this repository. You must add:

  - Android: Place your google-services.json in android/app/.

  - iOS: Place your GoogleService-Info.plist in ios/Runner/.
 
3. **Install Dependencies:**
   ```bash
   flutter pub get

4. **Generate App Icons:**
   ```bash
   flutter pub run flutter_launcher_icons

5. **Run the App:**
   ```bash
  flutter run

## 🔐 Security & Privacy
- This project follows strict privacy protocols:

  - Zero Data Logging: No data is sent to external servers except your own Google Drive.

  - Credential Masking: All API keys and sensitive configuration files are ignored via .gitignore.

  - Auto-Lock: The app automatically locks itself when minimized or placed in the background.

## 🤝 Contributing
- Contributions are welcome! If you find any bugs or have feature requests, please open an issue or create a pull request.

## 📄 License
- This project is licensed under the MIT License - see the LICENSE file for details.


## Most Important part ## 
#### 🛠️ Configuration & Environment Setup
This project requires Google Services to handle Authentication and Drive Sync. Due to security best practices, the configuration files are excluded from this repository. To run the project locally, follow these steps:

### A. Firebase & Google JSON Setup
 1. Go to the Firebase Console and create a new project named Digi Sanchay.

 2. Add an Android App to the project.

 3. Package Name: Ensure it matches your build.gradle (usually com.example.doc_app).

 4. SHA-1 Fingerprint: This is required for Google Sign-In. Generate it by running:
    ```bash
    keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  5. Download the google-services.json file and place it in:
android/app/google-services.json

B. Enabling Google Drive API
 1. Go to the Google Cloud Console.

 2. Select your Firebase project.

 3. Navigate to APIs & Services > Library.

 4. Search for "Google Drive API" and click Enable.
