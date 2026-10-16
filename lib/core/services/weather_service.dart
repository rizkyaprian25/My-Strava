import 'dart:convert';
import 'dart:io';

/// Model data kondisi cuaca sederhana.
class WeatherInfo {
  final double temperatureCelsius;
  final int humidityPercent;
  final String conditionDescription;

  const WeatherInfo({
    required this.temperatureCelsius,
    required this.humidityPercent,
    required this.conditionDescription,
  });

  String get formattedSummary =>
      '${temperatureCelsius.toStringAsFixed(0)}°C $conditionDescription';
}

/// Layanan cuaca otomatis tanpa memerlukan API Key menggunakan Open-Meteo API.
class WeatherService {
  /// Mengambil data suhu dan kondisi cuaca terkini berdasarkan koordinat GPS.
  static Future<WeatherInfo?> fetchWeather(double lat, double lng) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 2500);

      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,weather_code',
      );

      final request = await client.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>?;

        if (current != null) {
          final temp = (current['temperature_2m'] as num?)?.toDouble() ?? 27.0;
          final hum = (current['relative_humidity_2m'] as num?)?.toInt() ?? 70;
          final code = (current['weather_code'] as num?)?.toInt() ?? 0;

          return WeatherInfo(
            temperatureCelsius: temp,
            humidityPercent: hum,
            conditionDescription: _decodeWeatherCode(code),
          );
        }
      }
    } catch (_) {
      // Abaikan jika offline tanpa melemparkan error ke UI
    }

    return null;
  }

  /// Menerjemahkan kode cuaca WMO (World Meteorological Organization).
  static String _decodeWeatherCode(int code) {
    if (code == 0) return 'Cerah';
    if (code >= 1 && code <= 3) return 'Sebagian Berawan';
    if (code == 45 || code == 48) return 'Berkabut';
    if (code >= 51 && code <= 55) return 'Gerimis';
    if (code >= 61 && code <= 65) return 'Hujan';
    if (code >= 80 && code <= 82) return 'Hujan Deras';
    if (code >= 95 && code <= 99) return 'Hujan Badai';
    return 'Cerah Berawan';
  }
}
