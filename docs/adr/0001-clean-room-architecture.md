# ADR 0001: Arsitektur Rekonstruksi Bersih (Clean-Room Implementation) My Strava

## Konteks
Aplikasi My Strava dibangun untuk penggunaan pribadi guna merekam aktivitas lari dan bersepeda dengan performa tinggi, hemat baterai, dan menjaga privasi penuh tanpa ketergantungan pada backend berbayar atau API peta komersial.

## Keputusan Teknis & Trade-Off

1. **Framework: Flutter Mobile (Android Native)**
   - *Keputusan:* Menggunakan Flutter 3.44+ dengan kompilasi native Android APK.
   - *Trade-off:* Memerlukan lingkungan SDK Android, namun memberikan akses penuh ke sensor GPS native, latensi rendah pada layar HUD, dan performa GPU 60fps.

2. **Mesin Peta: Flutter Map (OpenStreetMap Leaflet Engine)**
   - *Keputusan:* Menggunakan `flutter_map` dengan raster tile OpenStreetMap, bukan Google Maps SDK atau Mapbox SDK.
   - *Trade-off:* Menghindari kebutuhan kartu kredit, API token berbayar, dan kuota request bulanan. Peta gratis dan bebas dipakai mandiri.

3. **Penyimpanan: Offline-First Local JSON Persistence**
   - *Keputusan:* Menyimpan data trek koordinat GPS dan sesi latihan ke file lokal `my_strava_activities.json` via `ActivityRepository` dan `path_provider`.
   - *Trade-off:* Tidak memerlukan database cloud kompleks; data 100% aman di perangkat atlet dan mudah diekspor ke standar GPX 1.1.

4. **Kalkulasi Geospasial: Formula Haversine & Anti-Drift**
   - *Keputusan:* Menggunakan formula Haversine untuk kalkulasi jarak kurvatur bumi dan filter ambang batas perpindahan (1.5m - 50m) untuk mengeliminasi loncatan sinyal GPS.
   - *Trade-off:* Konsumsi CPU sangat minimal dibandingkan filter Kalman penuh, namun cukup presisi untuk lari dan bersepeda.

## Status
Diterima & Diimplementasikan (Accepted).
