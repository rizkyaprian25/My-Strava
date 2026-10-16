import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

/// Helper untuk merender widget Flutter ke file gambar PNG berkualitas tinggi.
class ImageSaver {
  /// Mengambil screenshot widget yang dibungkus oleh RepaintBoundary key.
  static Future<String?> captureAndSavePng(GlobalKey boundaryKey,
      {String filenamePrefix = 'my_strava_share'}) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Pixel ratio 3.0 untuk hasil sangat jernih (Ultra HD)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/${filenamePrefix}_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      return file.path;
    } catch (_) {
      return null;
    }
  }
}
