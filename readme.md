# 🔐 Flutter Password Manager

A secure password manager app built with Flutter.  
It stores encrypted credentials locally using Hive and allows cloud sync via Google Drive so users can restore their data on other devices securely.

---

## 📱 Features

- 🔐 AES-encrypted password storage
- 🔑 Master password with secure local storage
- ☁️ Backup and restore via Google Drive (Storage Access Framework)
- 🧠 Minimal, clean Flutter UI
- 📁 Data saved using Hive (local NoSQL database)

---

## 🚀 Getting Started

### Prerequisites

- Flutter 3.19+ (latest stable)
- Dart SDK
- Android Studio (or VS Code)
- Android device or emulator (API 23 or higher)

### Project Setup

1. Clone the repo

   ```bash
   git clone https://github.com/KavyaJP/PasswordManagerAndroid.git
   cd PasswordManagerAndroid
   ```

2. Get dependencies

   ```bash
   flutter pub get
   ```

3. Run the app

   ```bash
   flutter run
   ```

---

## 🛠 Tech Stack

| Layer      | Tool                                                        |
| ---------- | ----------------------------------------------------------- |
| UI         | Flutter                                                     |
| Local DB   | Hive                                                        |
| Encryption | encrypt, flutter_secure_storage                             |
| Cloud Sync | Google Sign-In, Google Drive API / Storage Access Framework |

---

## 📂 Folder Structure

```
lib/
├── main.dart
├── models/
├── screens/
├── services/
└── widgets/
```

---

## 📱 Android Version Targeting

- `minSdkVersion`: **23** (Android 6.0 Marshmallow)
- `targetSdkVersion`: **35** (Android 15)
- `compileSdkVersion`: **35**

---

## 🔒 Security Notes

- All passwords are AES-encrypted before storing locally or backing up
- Master password is securely stored using flutter_secure_storage
- Encrypted files are uploaded to Google Drive using SAF (user-picked location)

---

## 📜 License

MIT License © 2025
