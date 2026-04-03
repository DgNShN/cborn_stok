# CBORN Stok v1.0.0

## Ozet

Yerel veri tabanli stok, satis, siparis ve tedarikci yonetimi uygulamasi.

## One Cikan Ozellikler

- Stok girisi, stok cikisi ve stok sorgulama
- Satis kaydi ve PDF irsaliye
- Dusuk stok takibi
- CSV/TXT ile toplu urun importu
- Ortalama maliyet, son maliyet, raf ve kar yuzdesi
- Muadil urun asistani
- Dusuk stoktan siparis verme
- Bekleyen siparis ve teslim alma akisi
- Coklu tedarikci, indirimli alis ve en karli tedarikci onerisi
- Urun fotografi destegi
- Yeni uygulama ikonu ve splash ekran

## Release Dosyasi

- Android APK: `app-release.apk`
- Release banner: `assets/cborn_release_banner.png`

## Teknik Not

- Package id: `com.cborn.cborn_stok`
- Bu build debug signing ile uretilmistir
- Play Store yayini icin production keystore ile yeniden imzalanmasi onerilir

## Gorsel Kullanim

- GitHub Release acarken kapak gorseli veya tanitim gorseli olarak `assets/cborn_release_banner.png` eklenebilir.
- Uygulama ikonu `assets/cborn_stok_logo.png` dosyasindan uretilir.
- Splash ekran ayni marka diliyle `pubspec.yaml` icindeki `flutter_native_splash` ayarlariyla uretilebilir.
