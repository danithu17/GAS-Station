# 🇱🇰 Lanka Gas Tracker (Litro & Laugfs Real-Time Availability)

A production-ready Flutter Android application for tracking **Litro Gas** and **Laugfs Gas** availability in real-time across Sri Lanka, powered by **Firebase** (Cloud Firestore & Authentication), **Google Maps**, and **Provider** state management. Built with a modern **Material 3 Dark Theme**.

---

## 📱 Features

- **Google Sign-In & User Profiles**:
  - Secure mandatory Google Authentication.
  - Profile setup capturing user Name, Mobile Number, and Town, stored in Firestore `/users/{uid}`.
- **Real-Time Map & Sync**: Live Google Map displaying stations with real-time Firestore listeners (`snapshots()`).
- **4 KM Proximity Alerts**:
  - Live GPS tracking with visual 4,000 m proximity boundary around user location.
  - High-priority push notifications triggered immediately when any gas station within 4 KM restocks Litro or Laugfs gas.
- **Bilingual Interface**:
  - Seamless toggle between **English** and **Sinhala (සිංහල)** in drawer settings.
  - All status badges, queue alerts, and notifications translated.
- **Custom Color-Coded Markers**: 
  - **Litro (Sri Lanka Blue `#0072CE`)**
  - **Laugfs (Sri Lanka Amber Gold `#F59E0B`)**
  - High-visibility status badges: **Available (✓ Green)**, **Out of Stock (✕ Red)**, and **Unverified (? Amber)**.
- **Add & Manage Gas Stations**:
  - Community crowdsourcing with **+ Add Station** dialog.
  - Auto-fill GPS coordinates using device location.
  - Town dropdown covering 50+ major towns across all 9 Sri Lankan provinces.
- **Interactive Crowdsourcing Sheet**: Bottom sheet allowing authenticated citizens to report stock availability, queue conditions (*Short <15m*, *Moderate 15-45m*, *Long >45m*), cylinder weights (12.5kg, 5kg, 2.3kg, 37.5kg), and observations.
- **Server Timestamp Verification**: All crowdsource updates write `FieldValue.serverTimestamp()`.
- **Robust Anti-Spam Shield**:
  - Client-side countdown timer and button locking disabling duplicate submissions for 30 minutes per station.
  - Production **Firestore Security Rules** (`firestore.rules`) enforcing that each user UID can update a station at most once every 30 minutes.
- **Floating Search & Filter Suite**:
  - Town/city autocomplete and jump dialog (Colombo, Kandy, Galle, Negombo, Gampaha, Kurunegala, etc.).
  - Brand filter chips: *All*, *Litro*, *Laugfs*.
  - Availability filter chips: *All*, *In Stock*, *Out of Stock*, *Unverified*.
  - View switcher (toggle between interactive Map view and Card List view).
- **1-Tap Sri Lanka Data Seeder**: Built-in drawer tool to immediately seed realistic sample stations into your Firestore database.

---

## 🛠️ Project Structure

```
├── android/
│   ├── app/
│   │   ├── build.gradle.kts
│   │   ├── google-services.json    <-- Place your Firebase config here
│   │   └── src/main/AndroidManifest.xml
│   ├── build.gradle.kts
│   ├── gradle.properties
│   └── settings.gradle.kts
├── firestore.rules                 <-- Production Security Rules (30-min rate limit)
├── lib/
│   ├── config/
│   │   ├── app_theme.dart          # Material 3 Dark theme & brand palettes
│   │   └── map_style.dart          # Dark mode JSON style for Google Maps
│   ├── firebase_options.dart       # Default Firebase options
│   ├── main.dart                   # Application entry point & home screen
│   ├── models/
│   │   ├── gas_station.dart        # GasStation model, Brand & Status enums
│   │   └── stock_update.dart       # Crowdsource update payload
│   ├── providers/
│   │   ├── auth_provider.dart      # Firebase Auth provider
│   │   └── gas_tracker_provider.dart # Live Firestore stream, filtering, cooldowns
│   ├── services/
│   │   ├── auth_service.dart       # Anonymous & Google sign-in methods
│   │   ├── cooldown_service.dart   # Anti-spam persistence with SharedPreferences
│   │   └── firestore_service.dart  # Firestore streams, batch updates & seeding
│   ├── utils/
│   │   ├── marker_generator.dart   # Canvas-drawn high-DPI vector markers
│   │   └── time_formatter.dart     # Relative time formatting ("8 mins ago")
│   └── widgets/
│       ├── crowdsource_bottom_sheet.dart # Live update modal with cooldown timer
│       ├── search_and_filters_bar.dart   # Top floating search & chips bar
│       ├── station_details_sheet.dart    # Station summary card
│       ├── station_list_view.dart        # List view alternative
│       └── town_selector_dialog.dart     # Quick city selector
├── pubspec.yaml
└── test/
    └── widget_test.dart
```

---

## 🔥 Firebase Setup Instructions

### 1. Where to Place `google-services.json`
Download your `google-services.json` file from the Firebase Console (Project Settings > General > Your Apps > Android app with package name `com.gasflow.tracker.gas_tracker`).

Place the file into:
```
android/app/google-services.json
```
*(A production-ready template is already pre-configured in `android/app/google-services.json` for local builds).*

### 2. Enable Authentication Providers
In your [Firebase Console](https://console.firebase.google.com/):
1. Navigate to **Build > Authentication > Sign-in method**.
2. Enable **Anonymous** sign-in (allows 1-tap fast reporting).
3. Enable **Google** sign-in:
   - Provide your support email.
   - Add your Android SHA-1 fingerprint (run `cd android && ./gradlew signingReport` to extract it).

### 3. Deploy Firestore Security Rules
In Firebase Console > **Build > Firestore Database > Rules**, copy and publish the contents of [firestore.rules](file:///d:/A%20GAS%20app/firestore.rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /stations/{stationId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null 
        && request.resource.data.lastUpdated == request.time
        && request.resource.data.lastUpdatedBy == request.auth.uid
        && (
          !exists(/databases/$(database)/documents/user_updates/$(request.auth.uid + '_' + stationId))
          || request.time >= get(/databases/$(database)/documents/user_updates/$(request.auth.uid + '_' + stationId)).data.lastUpdatedAt + duration.value(30, 'm')
        );
      
      match /updates/{updateId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null 
          && request.resource.data.userId == request.auth.uid
          && request.resource.data.timestamp == request.time;
      }
    }

    match /user_updates/{userStationKey} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.lastUpdatedAt == request.time
        && (
          !exists(/databases/$(database)/documents/user_updates/$(userStationKey))
          || request.time >= resource.data.lastUpdatedAt + duration.value(30, 'm')
        );
    }
  }
}
```

---

## 🗺️ Google Maps API Key Configuration

In [android/app/src/main/AndroidManifest.xml](file:///d:/A%20GAS%20app/android/app/src/main/AndroidManifest.xml), update the `com.google.android.geo.API_KEY` meta-data value with your Google Maps Android API Key from Google Cloud Console:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE" />
```

---

## 🚀 Local Build & Run Instructions

### 1. Build Release APK Command
Execute the exact command in your terminal from the project root (`d:\A GAS app`):

```bash
flutter build apk --release
```

### 2. Locate Generated APK
The generated release APK file is stored at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Full path:
```
D:\A GAS app\build\app\outputs\flutter-apk\app-release.apk
```

### 3. Run on Connected Device / Emulator
```bash
flutter run
```

---

## 🧪 Testing

Run automated tests:
```bash
flutter test
flutter analyze
```
