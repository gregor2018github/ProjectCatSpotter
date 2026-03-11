# Cat Spotter App — Claude Instructions

## Project Overview
A Flutter Android app for spotting and tracking cats by location. Users photograph cats, tag their GPS location, assign them a profile, and view sighting history on a map.

**App root:** `C:\Programming\ClaudeCode\Cat_Spotter_App\cat_spotter\`

## Tech Stack
- **Flutter / Dart** — Android only (minSdk uses flutter default; targets Pixel 6 / Galaxy A56)
- **flutter_map ^7.0.2** + OpenStreetMap tiles (no API key required)
- **sqflite ^2.3.3** — local SQLite database (foreign keys ON)
- **flutter_riverpod ^2.5.1** — state management (no code-gen; AsyncNotifier / StateNotifier)
- **image_picker ^1.1.2** — camera capture
- **geolocator ^13.0.2** — GPS location
- **google_fonts ^6.2.1** — Nunito typeface
- **uuid ^4.5.1**, **intl ^0.20.1**, **path_provider ^2.1.4**, **permission_handler ^11.4.0**

## Design System
- Background: `#FFF8F0`
- Accent: `#FF8C42`
- Text: `#3D2B1F`
- Font: Nunito (via google_fonts)
- Theme defined in `lib/core/theme.dart`; constants in `lib/core/constants.dart`

## Architecture

### State Management
- Riverpod with **no code generation** — use `ref.watch` / `ref.read` directly
- Key providers:
  - `catProfilesProvider` (`cat_profiles_provider.dart`) — AsyncNotifier for all profiles
  - `catSightingsProvider` (`cat_sightings_provider.dart`) — AsyncNotifier for sightings
  - `addSightingProvider` (`add_sighting_provider.dart`) — StateNotifier for add-sighting wizard state
  - `appDocsDirProvider` (`app_providers.dart`) — FutureProvider<Directory> for docs dir

### Image Storage
- Images saved by `ImageStorageService.saveImage()`, which returns a **relative path** (e.g. `cat_photos/uuid.jpg`)
- Relative paths are stored in the DB; resolved to absolute at runtime via `getApplicationDocumentsDirectory()`
- `LocalImage` widget watches `appDocsDirProvider` to resolve paths without repeated async calls

### Database
- `DatabaseHelper` — singleton, opens DB, enables foreign keys
- `CatProfileDao` — CRUD for cat profiles
- `CatSightingDao` — CRUD for sightings
- **Cascade delete**: SQLite CASCADE removes sighting rows when a profile is deleted; app code manually deletes image files before calling `deleteProfile()`
- `deleteSighting()` is a top-level function in `cat_sightings_provider.dart` — deletes image file, then DB row, then invalidates both providers

### GPS / Location
- GPS fetch starts concurrently in `Step1Camera.initState()`
- 15-second timeout → falls back to `getLastKnownPosition()`
- Map pin can be repositioned by tapping (flutter_map `onTap`)

## File Structure
```
cat_spotter/
  pubspec.yaml
  android/
    app/build.gradle.kts          (Java 17, compileSdk via flutter default)
    app/src/main/AndroidManifest.xml
    app/src/main/res/xml/file_paths.xml
  lib/
    main.dart
    core/
      theme.dart
      constants.dart
    models/
      cat_profile.dart
      cat_sighting.dart
    data/
      database_helper.dart
      cat_profile_dao.dart
      cat_sighting_dao.dart
    services/
      location_service.dart
      image_storage_service.dart
      camera_service.dart
    providers/
      app_providers.dart
      cat_profiles_provider.dart
      cat_sightings_provider.dart
      add_sighting_provider.dart
    widgets/
      local_image.dart
      loading_indicator.dart
      error_display.dart
      confirmation_dialog.dart
    screens/
      home/
        home_screen.dart
        cat_profile_card.dart
      cat_detail/
        cat_detail_screen.dart
        mini_map_widget.dart
        sighting_thumbnail.dart
      cat_form/
        cat_form_screen.dart
      add_sighting/
        add_sighting_screen.dart
        step1_camera.dart
        step2_assign_cat.dart
        step3_map_finetune.dart
      distribution_map/
        distribution_map_screen.dart
```

## flutter_map v7 API (common gotchas)
- `MapOptions(initialCenter:, initialZoom:, onTap:)`
- `MapOptions(interactionOptions: InteractionOptions(flags: InteractiveFlag.none))` — to disable interaction
- `CameraFit.bounds(bounds: LatLngBounds.fromPoints([...]), padding: EdgeInsets.all(50))`
- `Marker(point:, width:, height:, child:)` — no built-in `onTap`; wrap `child` in `GestureDetector`
- `mapController.move(center, zoom)`

## Running the App
```bash
cd C:\Programming\ClaudeCode\Cat_Spotter_App\cat_spotter
flutter pub get
flutter run          # requires Android device with USB debugging enabled
```

## Known Limitations / Future Work
- No offline tile caching (would need `flutter_map_tile_caching`)
- No custom app icon (would need `flutter_launcher_icons`)
- Distribution map marker tap relies on `GestureDetector` inside `Marker` child
