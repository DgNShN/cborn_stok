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
- Urun kartina fotograf ekleme ve saklama
- Ozel uygulama ikonu, splash ekran ve release banner gorselleri

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

## Marka Gorselleri

Projede hazir gorseller:

- `assets/cborn_stok_logo.png`
- `assets/cborn_stok_banner.png`
- `assets/cborn_release_banner.png`

Telefon ikonlarini yeniden uretmek icin:

```powershell
cd c:\AI_PROJECTS\cborn_stok
dart run flutter_launcher_icons
```

Splash ekranini yeniden uretmek icin:

```powershell
cd c:\AI_PROJECTS\cborn_stok
dart run flutter_native_splash:create
```

GitHub release sayfasinda kapak gorseli olarak `assets/cborn_release_banner.png` kullanabilirsin.

## GitHub Onizleme

![CBORN Stok Banner](assets/cborn_release_banner.png)

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
