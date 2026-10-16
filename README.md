# My Strava — Personal GPS Fitness & Route Tracker

Aplikasi pelacak kebugaran dan rute GPS lari serta bersepeda mandiri (*Clean-Room Implementation*) yang dirancang khusus untuk penggunaan pribadi. Bebas iklan, bebas biaya langganan, dan beroperasi secara *offline-first* dengan privasi penuh.

---

## 🏃 Fitur Utama

- **Perekaman Latar Belakang & Notifikasi Lock Screen (Foreground Service):**
  - Aplikasi tetap merekam GPS saat layar terkunci atau aplikasi diminimalkan.
  - Notifikasi persisten publik di lock screen dengan kontrol interaktif: **Pause**, **Resume**, dan **Stop** langsung tanpa perlu membuka kunci layar.
  - Telemetri live pada notifikasi: update jarak (km), waktu bergerak (mm:ss), dan pace rata-rata secara real-time.
- **Studio Berbagi Strava (Share Transparan & Photo Overlay):**
  - **Mode Stiker PNG Transparan:** Menghasilkan stiker overlay transparan dengan watermark dan teks bayangan kontras untuk ditempel di atas foto/video Instagram Stories, WhatsApp Status, atau TikTok.
  - **Mode Foto Atlet & Strava Dark:** Pilihan latar belakang foto atau warna gelap khas Strava.
  - **Format Rasio:** Pilihan format Story 9:16 atau Feed Kotak 1:1.
  - Tombol simpan langsung file PNG Ultra HD ke penyimpanan perangkat.
- **3D Route Flyover Replay & Profil Ketinggian 3D:**
  - **3D Flyover Replay:** Animasi putar ulang rute dari start hingga finish dengan kamera auto-follow, avatar atlet bergerak, scrubber waktu, dan pilihan kecepatan putar (1x, 2x, 5x, 10x).
  - **Grafik Profil Elevasi 3D Interaktif:** Kurva area ketinggian bergradien yang sinkron dengan penunjuk lokasi di peta saat disentuh (*touch scrubber*).
  - **Gradien Warna Polyline Rute:** Pilihan pewarnaan jalur rute berdasarkan *Strava Orange Klasik*, *Gradien Kecepatan (Speed)*, atau *Gradien Ketinggian 3D (Elevation)*.
- **Peta Multi-Layer (Map Layer Switcher):**
  - Pilihan 4 tipe lapisan peta langsung dengan tombol floating:
    * **Citra Satelit 3D** (Esri World Imagery resolusi tinggi)
    * **Topografi / Kontur Alami** (OpenTopoMap)
    * **Strava Dark Matter** (CartoDB Dark Theme kontras tinggi)
    * **Standar OSM** (OpenStreetMap Carto)
- **Personal Heatmap (Peta Panas Pribadi):**
  - Menggabungkan seluruh jejak rute yang pernah Anda lewati ke dalam satu peta gelap dengan garis neon oranye menyala bertumpuk (*glow overlay*).
  - Filter berdasarkan olahraga dan ringkasan total kilometer terpetakan.
- **Segmen Lintasan & Mahkota KOM (King of the Mountain):**
  - Deteksi otomatis saat sesi latihan melewati titik start dan finish segmen lintasan.
  - Papan rekor waktu terbaik (PR), pencatatan percobaan, dan mahkota KOM.
  - Fitur pembuatan segmen kustom baru.
- **Perekam GPS Real-Time (HUD Telemetri):**
  - Tampilan metrik langsung: Jarak kumulatif (km), Waktu bergerak (*moving time*), Kecepatan saat ini (km/jam), Pace real-time (min/km), Kenaikan elevasi (m), dan Estimasi kalori terbakar.
  - **Auto-Pause Cerdas:** Otomatis menjeda perekaman saat atlet berhenti atau kecepatan di bawah 0.45 m/s (cth: lampu merah), dan melanjutkan otomatis saat mulai bergerak kembali.
  - Filter anti-loncatan GPS (*GPS drift reduction*) berbasis formula geospasial Haversine.
- **Profil Atlet & Manajemen Perlengkapan (Gear Tracker):**
  - Pelacak pemakaian sepatu lari dan sepeda dengan batas rekomendasi jarak pakai (cth: 600 km).
  - Akumulasi jarak otomatis ke perlengkapan default setiap kali sesi latihan selesai disimpan.
  - Indikator visual keausan perlengkapan dan peringatan saat perlengkapan aus (*worn out*).
- **Piala Rekor Pribadi (Personal Best / PR):**
  - Deteksi dan pembaruan rekor otomatis: 1 km, 5 km, 10 km, Half Marathon (21 km), Jarak Terjauh, dan Kecepatan Puncak.
- **Analitik Pecahan Jarak (KM Splits):**
  - Perhitungan otomatis waktu tempuh dan elevasi per kilometer (Split 1 km, 2 km, 3 km, dst.).
- **Ekspor Dokumen GPX 1.1:**
  - Konversi otomatis rekaman aktivitas ke standar XML GPX 1.1 yang kompatibel dengan Garmin Connect, Strava resmi, dan Google Earth.
- **Penyimpanan Lokal Persisten (*Offline-First*):**
  - Seluruh data riwayat aktivitas, segmen, dan profil tersimpan aman di penyimpanan lokal tanpa server pihak ketiga.

---

## 🛠️ Stack Teknologi

- **Framework:** Flutter 3.44+ (Dart 3.12+)
- **Arsitektur:** Clean Architecture / Feature-First Modular Structure
- **Design System:** Dark Theme terinspirasi dari Apple Human Interface Guidelines (HIG) & Strava Sports Signature
- **Background Service:** `flutter_foreground_task` (Android Foreground Service with Lock Screen Controls)
- **Geospasial & Peta:** `flutter_map` (OpenStreetMap, Esri Satellite, OpenTopoMap, CartoDB Dark) & `latlong2`
- **GPS Location:** `geolocator`
- **Penyimpanan:** `path_provider` (JSON Persistence) & `shared_preferences`

---

## 📁 Struktur Direktori

```text
lib/
├── contracts/             # SSOT Data Model (ActivityModel, GearModel, PersonalRecord, SegmentModel, MapStyle)
├── core/
│   ├── services/          # BackgroundServiceManager & Lock Screen Task Handler
│   ├── storage/           # ActivityRepository, ProfileGearRepository & SegmentRepository
│   ├── theme/             # Design Tokens Apple HIG / Dark Theme & GlobalErrorBoundary
│   ├── utils/             # GeoCalculator, GpxExporter, ImageSaver, RouteGradientHelper & ShareCardDialog
│   └── widgets/           # ElevationProfileChart & MapLayerSelectorButton
├── features/
│   ├── dashboard/         # Dashboard performa mingguan, target jarak, pintasan Heatmap & Segmen
│   ├── heatmap/           # Personal Heatmap rute neon menyala
│   ├── history/           # Riwayat aktivitas, KM splits, detail rute, layer switcher & GPX export
│   ├── profile/           # Profil atlet, Gear Tracker, & Rekor Pribadi (PR)
│   ├── recorder/          # Layar perekam GPS langsung, HUD telemetri, layer switcher & auto-pause
│   ├── replay/            # 3D Route Flyover Replay animasi pergerakan rute penuh
│   ├── segments/          # Eksplorasi Segmen Lintasan & Mahkota KOM
│   └── shell/             # App Shell (Bottom Navigation Bar 4-Tab)
└── main.dart              # Entrypoint aplikasi & inisialisasi Foreground Task
```

---

## 🛡️ Arsitektur Zero-API-Key (100% Bebas API Key & Biaya Server)

Aplikasi **My Strava** didesain dengan prinsip kemandirian penuh (*self-sufficient clean-room*). Anda **TIDAK PERLU** mendaftar akun Google Cloud, Mapbox, Strava Developer, ataupun memasukkan kartu kredit:

| Komponen Fitur | Solusi Tanpa API Key My Strava | Layanan Komersial Biasa (Yang Dihindari) |
|---|---|---|
| **Peta & Citra Satelit** | Tile Layer Publik Bebas Token (OpenStreetMap, Esri Satellite 3D, Carto Dark, OpenTopoMap) | Google Maps SDK / Mapbox API (Berbayar) |
| **GPS & Altimeter** | Chip Satelit Native GNSS Hardware HP (`geolocator` & Haversine on-device) | Google Elevation API (Berbayar) |
| **Deteksi Kota & Lokasi** | OSM Nominatim & Offline City Bounding Box (`GeocodingService`) | Google Geocoding API (Berbayar) |
| **Prakiraan Suhu & Cuaca** | Open-Meteo REST API (Sains Terbuka Global Bebas Kunci & Lisensi) | OpenWeatherMap API (Wajib Token) |
| **Database & Riwayat** | Local Sandbox JSON Encapsulation (`path_provider` & `shared_preferences`) | Firebase Firestore / AWS Cloud |
| **Format Berbagi / Ekspor** | Standar Internasional XML GPX 1.1 & Stiker PNG Transparan Ultra HD | Strava OAuth 2.0 Cloud Sync |

---

## 🚀 Panduan Menjalankan & Membangun APK

### 1. Menjalankan di Mode Debug / Perangkat
Pastikan perangkat Android terhubung via USB dengan mode debugging aktif:
```bash
flutter run
```

### 2. Membangun APK Android
Untuk membuat file APK mandiri yang dapat langsung diinstal di smartphone:
```bash
flutter build apk --debug
```
File APK siap instal akan berada di:
`build/app/outputs/flutter-apk/app-debug.apk` (atau salinan `MyStrava.apk` di root direktori).

---

## 🧪 Menjalankan Pengujian

```bash
flutter test
```
Seluruh pengujian unit (kalkulasi jarak Haversine, estimasi kalori, serialisasi kontrak data, dan verifikasi dokumen GPX) serta smoke test widget telah tervalidasi 100% lulus.

---

## 📄 Lisensi

Proyek ini dibangun secara mandiri untuk keperluan pribadi (*Personal Use*).
