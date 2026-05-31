# Knjizalica Mobile

Flutter member app for the Knjizalica library system.

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and add it to your `PATH`.
2. From this folder, run platform scaffolding:

```powershell
.\setup.ps1
flutter pub get
```

If Flutter is not in `PATH`, run `setup.ps1` after installing Flutter, or manually:

```powershell
flutter create . --org com.knjizalica --project-name knjizalica_mobile
flutter pub get
```

## Run

Default API base URL targets the Android emulator host (`10.0.2.2:5000`):

```powershell
flutter run
```

Override API URL:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000
```

Ensure the backend is running and CORS allows your client origin.

## Features

- Login / register (JWT)
- Home: featured + popular recommendations
- Search with master-detail layout on wide screens
- Book detail with color-coded availability calendar and reservations
- My loans (active / history) with status badges
- Profile editing, password change, membership info
- Notifications list + SignalR push (`NotificationReceived`)

## Note on registration cities

`GET /api/referencedata/cities` requires authentication. The register screen falls back to a **City ID** field when cities cannot be loaded (use seeded id `1` in development).
