import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

class MarkerService {
  /// Generate a custom arrow marker pointing in a specific direction
  /// direction: 0-360 degrees (0 = North, 90 = East, 180 = South, 270 = West)
  static Future<BitmapDescriptor> getArrowMarker(double direction, {Color color = Colors.green}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 100;

    // Draw circle background
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Draw white circle border
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Draw arrow pointing upward
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Arrow pointing up (before rotation)
    const Offset center = Offset(size / 2, size / 2);
    const double arrowLength = 25;
    const double arrowWidth = 15;

    // Main arrow line (pointing up)
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - arrowLength),
      paint,
    );

    // Arrow head - left side
    canvas.drawLine(
      Offset(center.dx, center.dy - arrowLength),
      Offset(center.dx - arrowWidth / 2, center.dy - arrowLength + 8),
      paint,
    );

    // Arrow head - right side
    canvas.drawLine(
      Offset(center.dx, center.dy - arrowLength),
      Offset(center.dx + arrowWidth / 2, center.dy - arrowLength + 8),
      paint,
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8list = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8list);
  }

  /// Get a simple direction arrow marker without rotation capability
  /// The rotation is handled by the marker's rotation property
  static Future<BitmapDescriptor> getSimpleArrowMarker({Color color = Colors.green}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 100;

    // Draw green circle background
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Draw white border
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );

    // Draw simple upward arrow
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const Offset center = Offset(size / 2, size / 2);

    // Main arrow line pointing up
    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - 28),
      paint,
    );

    // Left arrow head
    canvas.drawLine(
      Offset(center.dx, center.dy - 28),
      Offset(center.dx - 10, center.dy - 16),
      paint,
    );

    // Right arrow head
    canvas.drawLine(
      Offset(center.dx, center.dy - 28),
      Offset(center.dx + 10, center.dy - 16),
      paint,
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8list = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8list);
  }
}
