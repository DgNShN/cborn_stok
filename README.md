# CBORN Stok

Flutter ile gelistirilmis yerel veri tabanli stok, satis ve siparis takip uygulamasi.

## Ozellikler

- Urun ekleme, duzenleme ve silme
- Stok girisi ve stok cikisi
- Satis kaydi ve PDF irsaliye olusturma
- Stok sorgulama, hareket gecmisi ve dusuk stok takibi
- CSV/TXT ile toplu urun ice aktarma
- Ortalama maliyet, son maliyet, raf yeri ve kar yuzdesi takibi
- Ayni malzeme grubunda akilli muadil urun onerileri
- Dusuk stoktan siparis olusturma ve teslim alinca stoga isleme
- Urun bazli coklu tedarikci, indirimli alis ve en karli tedarikci onerisi

## Teknoloji

- Flutter
- SQLite (`sqflite`)
- PDF olusturma (`pdf`)
- Dosya secme (`file_picker`)

## Proje Konumu

`c:\AI_PROJECTS\cborn_stok`

## APK

Son olusturulan release APK:

`build\app\outputs\flutter-apk\app-release.apk`

Not:

- Android package id: `com.cborn.cborn_stok`
- Mevcut release build debug signing ile uretiliyor. Play Store icin gercek keystore ile imzalanmasi gerekir.

## Calistirma

```powershell
cd c:\AI_PROJECTS\cborn_stok
flutter pub get
flutter run -d windows
```

Android icin:

```powershell
cd c:\AI_PROJECTS\cborn_stok
flutter run -d android
```

Release APK:

```powershell
cd c:\AI_PROJECTS\cborn_stok
flutter build apk --release
```

## Ornek Veri

Hazir import dosyalari:

- `ornek_urun_import.csv`
- `ornek_urun_import_uzun.csv`

## GitHub Notu

Bu klasor su an otomatik olarak bir `git` reposu degil. GitHub'a yuklemek icin:

```powershell
cd c:\AI_PROJECTS\cborn_stok
git init
git add .
git commit -m "Initial commit"
```
