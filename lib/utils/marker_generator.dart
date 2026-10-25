import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_theme.dart';
import '../models/gas_station.dart';

class MarkerGenerator {
  static final Map<String, BitmapDescriptor> _markerCache = {};

  /// Pre-generates all 6 combinations (2 brands x 3 statuses) for instant map loading
  static Future<void> preloadMarkers() async {
    for (final brand in GasBrand.values) {
      for (final status in StockStatus.values) {
        final key = '${brand.name}_${status.name}';
        if (!_markerCache.containsKey(key)) {
          final descriptor = await createCustomMarker(brand, status);
          _markerCache[key] = descriptor;
        }
      }
    }
  }

  /// Get cached or generate marker
  static Future<BitmapDescriptor> getMarker(GasBrand brand, StockStatus status) async {
    final key = '${brand.name}_${status.name}';
    if (_markerCache.containsKey(key)) {
      return _markerCache[key]!;
    }
    final descriptor = await createCustomMarker(brand, status);
    _markerCache[key] = descriptor;
    return descriptor;
  }

  /// Draws high-DPI custom vector pin using Canvas & PictureRecorder
  static Future<BitmapDescriptor> createCustomMarker(
    GasBrand brand,
    StockStatus status,
  ) async {
    const double size = 130.0;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final bool isLitro = brand == GasBrand.litro;
    final Color brandColor = isLitro ? AppColors.litroBlue : AppColors.laugfsYellow;
    final Color brandDark = isLitro ? AppColors.litroBlueDark : AppColors.laugfsYellowDark;

    Color badgeColor;
    String badgeSymbol;
    switch (status) {
      case StockStatus.available:
        badgeColor = AppColors.availableGreen;
        badgeSymbol = '✓';
        break;
      case StockStatus.outOfStock:
        badgeColor = AppColors.outOfStockRed;
        badgeSymbol = '✕';
        break;
      case StockStatus.unverified:
        badgeColor = AppColors.unverifiedAmber;
        badgeSymbol = '?';
        break;
    }

    // 1. Draw soft drop shadow for elevation
    final Path shadowPath = Path();
    shadowPath.addOval(Rect.fromCircle(center: const Offset(65, 60), radius: 46));
    canvas.drawShadow(shadowPath, Colors.black, 8.0, true);

    // 2. Pin pointer triangle at bottom
    final Path pinTail = Path();
    pinTail.moveTo(50, 85);
    pinTail.lineTo(65, 120);
    pinTail.lineTo(80, 85);
    pinTail.close();

    final Paint tailPaint = Paint()
      ..color = brandDark
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinTail, tailPaint);

    // 3. Main Pin Body Outer Ring
    final Paint outerRingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(65, 55), 44, outerRingPaint);

    // 4. Main Pin Gradient / Solid Fill
    final Paint bodyPaint = Paint()
      ..color = brandColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(65, 55), 40, bodyPaint);

    // 5. Brand text badge pill inside marker
    final TextPainter brandPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: isLitro ? 'LITRO' : 'LAUGFS',
        style: TextStyle(
          color: isLitro ? Colors.white : Colors.black87,
          fontSize: isLitro ? 17 : 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    )..layout();

    brandPainter.paint(
      canvas,
      Offset(
        65 - (brandPainter.width / 2),
        55 - (brandPainter.height / 2),
      ),
    );

    // 6. Top-Right Status Badge (Available / Out of Stock / Unverified)
    const Offset badgeCenter = Offset(94, 26);
    const double badgeRadius = 18.0;

    // Badge border (white outline)
    final Paint badgeBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius + 2.5, badgeBorderPaint);

    // Badge fill
    final Paint badgeFillPaint = Paint()
      ..color = badgeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(badgeCenter, badgeRadius, badgeFillPaint);

    // Badge icon text (✓, ✕, ?)
    final TextPainter statusPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: badgeSymbol,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    )..layout();

    statusPainter.paint(
      canvas,
      Offset(
        badgeCenter.dx - (statusPainter.width / 2),
        badgeCenter.dy - (statusPainter.height / 2),
      ),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
          size.toInt(),
          size.toInt(),
        );
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(pngBytes);
  }
}
