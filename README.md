Weight & BMI Tracker - Flutter App
==================================

A Flutter mobile app for tracking weight and BMI with charts and data export.

=== FEATURES ===
- Track weight and BMI over time
- Interactive line charts
- Set personal health goals
- Add daily/weekly entries
- Export data to CSV
- Dark/Light theme support

=== INSTALLATION ===
PREREQUISITES:
- Flutter SDK (latest stable)
- Android Studio or Xcode

STEPS:
1. Clone repository:
   git clone https://github.com/1prabhakarpal/BodyMetrics.git
   cd weight-tracker

2. Install dependencies:
   flutter pub get

3. Run app:
   flutter run

=== BUILDING APK ===
1. Generate signing key:
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key

2. Configure android/app/build.gradle with signing info

3. Build release APK:
   flutter build apk --release

APK Location: build/app/outputs/flutter-apk/app-release.apk

=== PROJECT STRUCTURE ===
weight_tracker/
  android/       - Android specific files
  assets/        - Images/fonts
  ios/           - iOS specific files  
  lib/
    screens/     - All app screens
    models/      - Data models
    services/    - Business logic
    main.dart    - App entry point
  test/          - Test files
  pubspec.yaml   - Dependencies

=== KEY DEPENDENCIES ===
- sqflite: Local database
- fl_chart: Data visualization  
- intl: Date formatting
- share_plus: Data export
- flutter_launcher_icons: App icon

=== CONTRIBUTING ===
1. Fork the project
2. Create feature branch
3. Commit changes
4. Push to branch
5. Open pull request

=== SCREENSHOTS ===
Home Screen: View/add entries
Charts Screen: View trends
Health Info: View BMI stats

=== SUPPORT ===
Star the repo if you find it useful!