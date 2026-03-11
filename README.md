# Cat Spotter

A Flutter Android app for spotting and tracking cats by location. Photograph cats, tag their GPS position, assign them a profile, and browse their sighting history on an interactive map.

## Features

- **Cat profiles** — name, colour tag, and photo for each cat
- **Sighting log** — capture a photo, auto-detect GPS location, fine-tune the pin on a map
- **Per-cat detail screen** — mini-map + scrollable sighting thumbnails
- **All-cats distribution map** — see every sighting across all profiles at once
- Fully offline — OpenStreetMap tiles (internet needed for tile loading, no API key required)
- Local SQLite storage — no account or cloud service needed

## Tech Stack

| Layer | Library |
|---|---|
| UI / framework | Flutter (Dart), Android only |
| Maps | [flutter_map](https://pub.dev/packages/flutter_map) ^7.0.2 + OpenStreetMap |
| Database | [sqflite](https://pub.dev/packages/sqflite) ^2.3.3 (SQLite, foreign keys ON) |
| State management | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) ^2.5.1 |
| Camera | [image_picker](https://pub.dev/packages/image_picker) ^1.1.2 |
| GPS | [geolocator](https://pub.dev/packages/geolocator) ^13.0.2 |
| Fonts | [google_fonts](https://pub.dev/packages/google_fonts) ^6.2.1 (Nunito) |

## Prerequisites

### 1. Java Development Kit 17

Download and install [JDK 17](https://adoptium.net/temurin/releases/?version=17) (Temurin recommended).
Add `JAVA_HOME` to your environment variables and add `%JAVA_HOME%\bin` to `PATH`.

### 2. Android Studio

1. Download [Android Studio](https://developer.android.com/studio).
2. During setup (or via **SDK Manager**), install:
   - **Android SDK** — API level 33, 34, or 35
   - **Android SDK Build-Tools**
   - **Google USB Driver** (Windows only, under SDK Tools)
3. Accept all SDK licences:
   ```bash
   flutter doctor --android-licenses
   ```

### 3. Flutter SDK

1. Download the [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) and extract it (e.g. `C:\flutter`).
2. Add `C:\flutter\bin` to your `PATH`.
3. Verify the installation:
   ```bash
   flutter doctor
   ```
   All items should be green (or at least the Android toolchain and connected device).

## Setup

```bash
# Clone the repository
git clone https://github.com/<your-username>/Cat_Spotter_App.git
cd Cat_Spotter_App/cat_spotter

# Fetch dependencies
flutter pub get
```

## Running the App

1. Enable **Developer Options** on your Android phone and turn on **USB Debugging**.
2. Connect the phone via USB and accept the "Allow USB debugging?" prompt.
3. Verify Flutter can see your device:
   ```bash
   flutter devices
   ```
4. Run the app:
   ```bash
   cd cat_spotter
   flutter run
   ```

For a release APK:
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Required Android Permissions

Declared in `AndroidManifest.xml` — the OS will prompt the user at runtime:

| Permission | Purpose |
|---|---|
| `CAMERA` | Take cat photos |
| `READ/WRITE_EXTERNAL_STORAGE` | Save photos (Android < 13) |
| `ACCESS_FINE_LOCATION` | GPS for sighting location |
| `ACCESS_COARSE_LOCATION` | Fallback coarse location |
| `INTERNET` | Load OpenStreetMap tiles |

## Project Structure

```
cat_spotter/
├── android/                  # Android host project
├── lib/
│   ├── main.dart
│   ├── core/                 # Theme & constants
│   ├── models/               # CatProfile, CatSighting
│   ├── data/                 # SQLite DAOs & DatabaseHelper
│   ├── services/             # Camera, GPS, image storage
│   ├── providers/            # Riverpod providers
│   ├── widgets/              # Shared widgets
│   └── screens/
│       ├── home/             # Profile list
│       ├── cat_detail/       # Per-cat map + sightings
│       ├── cat_form/         # Create / edit profile
│       ├── add_sighting/     # 3-step wizard (photo → assign → map)
│       ├── all_cats_map/     # Full distribution map
│       └── distribution_map/ # Per-cat distribution
├── pubspec.yaml
└── analysis_options.yaml
```

## Design

| Token | Value |
|---|---|
| Background | `#FFF8F0` |
| Accent | `#FF8C42` |
| Text | `#3D2B1F` |
| Font | Nunito (via google_fonts) |

## Known Limitations

- No offline tile caching (would require `flutter_map_tile_caching`)
- No custom launcher icon
- Android only (no iOS support planned)

## License

MIT
