import 'dart:convert';
import 'dart:io';

/// Layar pendeteksi nama daerah dan kota (Reverse Geocoding) tanpa memerlukan API Key.
class GeocodingService {
  /// Mencari nama lokasi dari titik koordinat GPS secara mandiri tanpa API Key.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    // 1. Coba lookup via OpenStreetMap Nominatim (Gratis & Bebas API Key)
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 2500);

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=14&addressdetails=1',
      );

      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'MyStrava/1.0 (Android; Offline-First)');
      final response = await request.close().timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final city = address['city'] ??
              address['town'] ??
              address['municipality'] ??
              address['city_district'] ??
              address['suburb'] ??
              address['county'];
          if (city != null && city.toString().trim().isNotEmpty) {
            return city.toString().trim();
          }
        }
      }
    } catch (_) {
      // Jika offline atau koneksi timeout, gunakan fallback offline lokal
    }

    // 2. Fallback offline berdasarkan bounding box wilayah kota-kota besar di Indonesia
    return _getOfflineCityEstimate(lat, lng);
  }

  /// Pendeteksi kota lokal berbasis bounding box koordinat (100% offline).
  static String? _getOfflineCityEstimate(double lat, double lng) {
    if (lat >= -6.37 && lat <= -6.08 && lng >= 106.68 && lng <= 106.97) {
      return 'Jakarta';
    } else if (lat >= -6.98 && lat <= -6.84 && lng >= 107.54 && lng <= 107.72) {
      return 'Bandung';
    } else if (lat >= -7.36 && lat <= -7.18 && lng >= 102.68 && lng <= 112.82) {
      return 'Surabaya';
    } else if (lat >= -7.86 && lat <= -7.74 && lng >= 110.33 && lng <= 110.42) {
      return 'Yogyakarta';
    } else if (lat >= -7.05 && lat <= -6.95 && lng >= 110.37 && lng <= 110.47) {
      return 'Semarang';
    } else if (lat >= -7.60 && lat <= -7.53 && lng >= 110.78 && lng <= 110.87) {
      return 'Solo';
    } else if (lat >= -8.85 && lat <= -8.50 && lng >= 115.10 && lng <= 115.35) {
      return 'Bali';
    } else if (lat >= -6.65 && lat <= -6.50 && lng >= 106.75 && lng <= 106.85) {
      return 'Bogor';
    } else if (lat >= -6.45 && lat <= -6.35 && lng >= 106.75 && lng <= 106.88) {
      return 'Depok';
    } else if (lat >= -6.28 && lat <= -6.15 && lng >= 106.58 && lng <= 106.72) {
      return 'Tangerang';
    } else if (lat >= -6.32 && lat <= -6.20 && lng >= 106.95 && lng <= 107.05) {
      return 'Bekasi';
    } else if (lat >= 3.50 && lat <= 3.70 && lng >= 98.60 && lng <= 98.75) {
      return 'Medan';
    } else if (lat >= -5.20 && lat <= -5.05 && lng >= 119.38 && lng <= 119.52) {
      return 'Makassar';
    } else if (lat >= -8.02 && lat <= -7.92 && lng >= 112.58 && lng <= 112.68) {
      return 'Malang';
    }
    return null;
  }
}
