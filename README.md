# Weight & BMI Tracker - Flutter App 📊

A Flutter-based mobile application for tracking weight and BMI (Body Mass Index) with data visualization.

---

## ✨ Features

- 📈 Track weight and BMI over time  
- 📊 Interactive charts for weight & BMI trends  
- 🏆 Set and monitor health goals  
- 🗕️ Date-based entries with historical data  
- 📄 Export data to CSV for sharing  
- 🌙 Dark/Light theme support  

---

## ⚙️ Installation

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version)
- Android Studio / Xcode (for emulators)
- Physical device (optional but recommended)

### Steps

Clone the repository:

```bash
git clone https://github.com/1prabhakarpal/BodyMetrics.git
cd BodyMetrics
```

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

---

## 💪 Building the APK

To build a release APK:

### 1. Generate a keystore (if you don't have one):

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key
```

### 2. Configure signing in `android/app/build.gradle`

```gradle
android {
  ...
  signingConfigs {
    release {
      keyAlias 'my-key'
      keyPassword 'your-key-password'
      storeFile file('upload-keystore.jks')
      storePassword 'your-store-password'
    }
  }
  buildTypes {
    release {
      signingConfig signingConfigs.release
    }
  }
}
```

### 3. Build the APK:

```bash
flutter build apk --release
```

The APK will be generated at:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📂 Project Structure

```
weight_tracker/
├── android/            # Android specific files
├── assets/             # Static files (icons, fonts)
├── ios/                # iOS specific files
├── lib/                # Main application code
│   ├── screens/        # All screen widgets
│   ├── models/         # Data models
│   ├── services/       # Business logic
│   └── main.dart       # App entry point
├── test/               # Test files
└── pubspec.yaml        # Dependencies configuration
```

---

## 🛆 Dependencies

Main packages used:

- [`sqflite`](https://pub.dev/packages/sqflite) – Local database storage  
- [`fl_chart`](https://pub.dev/packages/fl_chart) – Data visualization  
- [`intl`](https://pub.dev/packages/intl) – Date formatting  
- [`share_plus`](https://pub.dev/packages/share_plus) – Data export functionality  
- [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons) – App icon generation  

---

## 🤝 Contributing

Contributions are welcome!  
---

---

## 💖 Support

If you like this project, give it a ⭐ on GitHub!

**Happy Tracking! 🎯**