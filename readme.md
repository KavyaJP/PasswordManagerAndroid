# 🔐 Flutter Password Manager

A secure and minimal open-source password manager built with Flutter.  
It uses AES encryption and local Hive storage to protect user data, with optional backup and restore functionality via Google Drive (SAF).

---

## 📲 Features

- 🔐 **Secure Local Storage**: AES-256 encryption with unique keys
- 🔑 **Master Password**: Required to unlock stored credentials
- ☁️ **Cloud Sync**: Backup and restore data to Google Drive
- 🧠 **Minimalist UI**: Intuitive, clutter-free design
- 🔍 **Search Functionality**: Quickly find saved credentials
- 🛡️ **Secure Storage**: Uses `flutter_secure_storage` for storing sensitive values

---

## 🛠️ Tech Stack

| Layer        | Package / Tool                                             |
| ------------ | ---------------------------------------------------------- |
| UI           | Flutter (Material Design)                                  |
| Local Storage| Hive (NoSQL)                                               |
| Encryption   | `encrypt`, `flutter_secure_storage`                        |
| Cloud Sync   | Google Sign-In, Storage Access Framework (SAF)             |
| State Mgmt   | SetState (basic)                                           |

---

## 📂 Folder Structure

```
lib/
├── main.dart                # App entry point
├── models/                 # Data models (e.g., Credential)
├── screens/                # UI screens (home, login, add/edit)
├── services/               # Business logic: encryption, auth, storage
└── widgets/                # Reusable UI components
```

---

## 🚀 Getting Started

### 📋 Prerequisites

- Flutter 3.19 or higher
- Dart SDK
- Android Studio or VS Code
- Android device or emulator (API 23+)

### 🧑‍💻 Installation

```bash
git clone https://github.com/KavyaJP/PasswordManagerAndroid.git
cd PasswordManagerAndroid
flutter pub get
flutter run
```

Note: You will have to give your own SHA-1 Key to OAuth Client of google if you want google sign in features to work

---

## 🔐 Security Implementation

- AES-256 encryption for password data
- Master password stored securely using `flutter_secure_storage`
- Backups are encrypted and uploaded only after user confirmation
- Files are handled via Android's Storage Access Framework (SAF)

---

## 📱 Android Target

- **Min SDK**: 23 (Android 6.0)
- **Target SDK**: 35 (Android 15)
- **Compile SDK**: 35

---

## 🧪 Testing

- Manual testing on Android emulators and physical devices
- Master password verification and backup integrity tested
- File encryption and decryption verified against tampering

---

## 🔧 Features Yet to Be Implemented

Here are some suggested features that can improve the app further. They are divided into practical, security-focused, and UX-related categories.

---

- [ ] **Windows Support**
- [ ] **Linux Support**

### ✅ Practical Features

- [x] **Search & Filter Vault**
   - Search by service, username, or note.
   - Filter favorites or entries with images only.

- [ ] **Category/Folder Support**
   - Organize entries under tags or folders like “Finance,” “Social,” “Crypto,” etc.

- [ ] **Password Generator**
   - Built-in secure password generator with configurable rules (length, symbols, etc.).

- [ ] **Auto-fill Integration (Android)**
   - Support Android’s autofill framework for direct login to apps and browsers.

- [ ] **QR Code Support**
   - Generate QR codes for credentials.
   - Scan QR codes to import (e.g., crypto wallets, Wi-Fi logins).

---

### 🔐 Security-Focused Features

- [ ] **Field-Level Encryption**
   - Encrypt sensitive fields like password and notes separately.

- [ ] **Self-Destruct Vault**
   - Option to wipe vault after X failed biometric or PIN attempts.

- [ ] **Encrypted Export Format**
   - Allow exporting vault as `.vault` file encrypted with a passphrase.

- [ ] **Security Logs**
   - Track vault access times, modification history, and restore logs.

---

### 🌟 UX & UI Improvements

- [x] **Dark Mode Toggle**
   - Manual toggle in-app (if not already following system).

- [x] **Cloud Sync to User’s Own Google Drive Folder**
   - Let users store backups in visible Drive folders instead of `appDataFolder`.

- [ ] **In-app Onboarding / Walkthrough**
   - A short guide for new users explaining features like adding entries, backup, etc.

- [ ] **Backup Reminder**
   - Show periodic reminders to backup vault (banner or notification).

- [ ] **Undo Delete**
   - Provide undo option for a few seconds after deleting an entry.

- [x] **Biometric Timeout**
   - Auto-lock the vault after X minutes of inactivity, requiring fingerprint again.

---

## 📜 License

MIT License © 2025

---

## 🙌 Contributions

Contributions are welcome! Feel free to fork the repo and submit pull requests.  
For bugs or feature suggestions, open an [issue](https://github.com/KavyaJP/PasswordManagerAndroid/issues).