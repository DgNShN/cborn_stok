# CBORN Stok

A Flutter-based local inventory, sales, and purchase tracking application.

## Features

- Add, edit, and delete products
- Record stock-in and stock-out operations
- Create sales records and generate PDF delivery notes
- Query stock, review movement history, and monitor low-stock items
- Bulk import products from CSV/TXT files
- Track average cost, last cost, shelf location, and profit margin
- Get smart substitute suggestions within the same material group
- Create purchase orders from low-stock items and receive them into stock later
- Manage multiple suppliers per product with discounts and best-profit suggestions
- Attach and store product photos
- Use custom app icon, splash screen, and release banner visuals

## Tech Stack

- Flutter
- SQLite (`sqflite`)
- PDF generation (`pdf`)
- File picking (`file_picker`)

## Project Location

`c:\AI_PROJECTS\cborn_stok`

## APK

Latest release APK:

`build\app\outputs\flutter-apk\app-release.apk`

Notes:

- Android package id: `com.cborn.cborn_stok`
- The current release build is generated with debug signing. A production keystore is required for Play Store publishing.

## Branding Assets

Available project visuals:

- `assets/cborn_stok_logo.png`
- `assets/cborn_stok_banner.png`
- `assets/cborn_release_banner.png`

To regenerate the mobile app icons:

```powershell
cd c:\AI_PROJECTS\cborn_stok
dart run flutter_launcher_icons
```

To regenerate the splash screen:

```powershell
cd c:\AI_PROJECTS\cborn_stok
dart run flutter_native_splash:create
```

You can use `assets/cborn_release_banner.png` as the cover image on the GitHub release page.

## GitHub Preview

![CBORN Stok Banner](assets/cborn_release_banner.png)

## Run

```powershell
cd c:\AI_PROJECTS\cborn_stok
flutter pub get
flutter run -d windows
```

For Android:

```powershell
cd c:\AI_PROJECTS\cborn_stok
flutter run -d android
```

Release APK:

```powershell
cd c:\AI_PROJECTS\cborn_stok
flutter build apk --release
```

## Sample Data

Included import files:

- `ornek_urun_import.csv`
- `ornek_urun_import_uzun.csv`

## GitHub Note

If you want to upload this folder to GitHub from scratch:

```powershell
cd c:\AI_PROJECTS\cborn_stok
git init
git add .
git commit -m "Initial commit"
```
