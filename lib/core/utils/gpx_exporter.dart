import '../../contracts/activity_model.dart';

/// Utilitas untuk menghasilkan representasi XML standar GPS Exchange Format (GPX).
class GpxExporter {
  /// Mengonversi ActivityModel menjadi string dokumen GPX 1.1.
  static String exportToGpx(ActivityModel activity) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
      '<gpx version="1.1" creator="My Strava Personal" '
      'xmlns="http://www.topografix.com/GPX/1/1" '
      'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
      'xsi:schemaLocation="http://www.topografix.com/GPX/1/1 '
      'http://www.topografix.com/GPX/1/1/gpx.xsd">',
    );

    buffer.writeln('  <metadata>');
    buffer.writeln('    <name>${_escapeXml(activity.title)}</name>');
    buffer.writeln('    <desc>${_escapeXml(activity.description)}</desc>');
    buffer.writeln('    <time>${activity.startTime.toUtc().toIso8601String()}</time>');
    buffer.writeln('  </metadata>');

    buffer.writeln('  <trk>');
    buffer.writeln('    <name>${_escapeXml(activity.title)}</name>');
    buffer.writeln('    <type>${activity.sportType.name.toUpperCase()}</type>');
    buffer.writeln('    <trkseg>');

    for (final point in activity.routePoints) {
      buffer.write('      <trkpt lat="${point.latitude}" lon="${point.longitude}">');
      buffer.write('<ele>${point.altitude.toStringAsFixed(1)}</ele>');
      buffer.write('<time>${point.timestamp.toUtc().toIso8601String()}</time>');
      buffer.writeln('</trkpt>');
    }

    buffer.writeln('    </trkseg>');
    buffer.writeln('  </trk>');
    buffer.writeln('</gpx>');

    return buffer.toString();
  }

  /// Sanitasi karakter khusus XML.
  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
