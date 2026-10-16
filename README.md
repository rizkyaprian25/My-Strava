# My Strava — Personal GPS Fitness & Route Tracker

Aplikasi pelacak kebugaran dan rute GPS lari serta bersepeda mandiri (*Clean-Room Implementation*) yang dirancang khusus untuk penggunaan pribadi. Bebas iklan, bebas biaya langganan, dan beroperasi secara *offline-first* dengan privasi penuh.

---

## 🏃 Fitur Utama

- **Perekam GPS Real-Time (HUD Telemetri):**
  - Tampilan metrik langsung: Jarak kumulatif (km), Waktu bergerak (*moving time*), Kecepatan saat ini (km/jam), Pace real-time (min/km), Kenaikan elevasi (m), dan Estimasi kalori terbakar.
  - Filter anti-loncatan GPS (*GPS drift reduction*) berbasis formula geospasial Haversine.
  - Pilihan 4 jenis olahraga: Lari, Bersepeda, Jalan Kaki, dan Hiking.
- **Peta Interaktif & Visualisasi Rute (OpenStreetMap):**
  - Rendering jalur GPS langsung dengan polyline warna khas Strava Orange (`#FC5200`).
  - Pin posisi atlet real-time dengan tombol re-center GPS otomatis.
  - Bebas biaya API key (menggunakan OpenStreetMap tile layer).
- **Analitik Pecahan Jarak (KM Splits):**
  - Perhitungan otomatis waktu tempuh dan elevasi per kilometer (Split 1 km, 2 km, 3 km, dst.).
  - Kartu ringkasan metrik performa komprehensif.
- **Ekspor Dokumen GPX 1.1:**
  - Konversi otomatis rekaman aktivitas ke standar XML GPX 1.1.
  - Kompatibel penuh untuk diimpor ke Garmin Connect, Strava resmi, Google Earth, atau Komoot.
- **Penyimpanan Lokal Persisten (*Offline-First*):**
  - Seluruh data riwayat aktivitas tersimpan aman di penyimpanan lokal perangkat tanpa server pihak ketiga.
- **Dashboard Atlet & Target Mingguan:**
  - Indikator progres target jarak mingguan (misal 25 km/minggu).
  - Akumulasi waktu latihan, kalori, dan jarak all-time.

---

## 🛠️ Stack Teknologi

- **Framework:** Flutter 3.44+ (Dart 3.12+)
- **Arsitektur:** Clean Architecture / Feature-First Modular Structure
- **Design System:** Dark Theme terinspirasi dari Apple Human Interface Guidelines (HIG) & Strava Sports Signature
- **Geospasial & Peta:** `flutter_map` (OpenStreetMap / Leaflet Engine) & `latlong2`
- **GPS Location:** `geolocator`
- **Penyimpanan:** `path_provider` (JSON Persistence) & `shared_preferences`

---

## 📁 Struktur Direktori

```text
lib/
├── contracts/             # SSOT Data Model (ActivityModel, LocationPoint, KmSplit, SportType)
├── core/
│   ├── storage/           # ActivityRepository (Local JSON storage)
│   ├── theme/             # Design Tokens Apple HIG / Dark Theme & GlobalErrorBoundary
│   └── utils/             # GeoCalculator (Haversine) & GpxExporter
├── features/
│   ├── dashboard/         # Dashboard performa mingguan & target jarak
│   ├── history/           # Riwayat aktivitas, KM splits, dan detail rute
│   ├── recorder/          # Layar perekam GPS langsung & dialog simpan
│   └── shell/             # App Shell (Bottom Navigation Bar)
└── main.dart              # Entrypoint aplikasi & inisialisasi lokal
```

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
