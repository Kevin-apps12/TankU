// Draws the TankU launcher icon — a graduation cap (Tank University) with a
// gold tassel over a blue water gradient — and writes two source PNGs:
//   assets/icon/tanku_icon.png        full-bleed gradient + cap (iOS/web/legacy)
//   assets/icon/tanku_foreground.png  transparent + cap, sized for the Android
//                                     adaptive-icon safe zone
//
// Run after `flutter pub get`:
//   dart run tool/generate_icon.dart
// then `dart run flutter_launcher_icons` to slice them per platform.

import 'dart:io';

import 'package:image/image.dart' as img;

const _size = 1024;

final _white = img.ColorRgba8(255, 255, 255, 255);
final _gold = img.ColorRgba8(0xFF, 0xD5, 0x4F, 255);

int _lerp(int a, int b, double t) => (a + (b - a) * t).round();

/// Diagonal cyan → deep-blue water gradient across the whole canvas.
void _fillGradient(img.Image image) {
  for (var y = 0; y < _size; y++) {
    for (var x = 0; x < _size; x++) {
      final t = ((x + y) / (2 * _size)).clamp(0.0, 1.0);
      image.setPixelRgba(
        x,
        y,
        _lerp(0x4F, 0x02, t), // R: 4F..02
        _lerp(0xC3, 0x77, t), // G: C3..77
        _lerp(0xF7, 0xBD, t), // B: F7..BD
        255,
      );
    }
  }
}

/// A stylized mortarboard centered at (cx, cy). [s] is the board half-width.
void _drawCap(img.Image image, double cx, double cy, double s) {
  final bw = s;
  final bh = s * 0.5;
  final boardCy = cy - s * 0.13;

  // Head band: a short trapezoid peeking below the board (drawn first; the
  // board overlaps its top edge so only the lower lip shows).
  img.fillPolygon(image, vertices: [
    img.Point(cx - bw * 0.4, boardCy + bh * 0.4),
    img.Point(cx + bw * 0.4, boardCy + bh * 0.4),
    img.Point(cx + bw * 0.5, boardCy + bh + s * 0.22),
    img.Point(cx - bw * 0.5, boardCy + bh + s * 0.22),
  ], color: _white);

  // Board: a flattened diamond (top of the cap, seen in perspective).
  img.fillPolygon(image, vertices: [
    img.Point(cx - bw, boardCy),
    img.Point(cx, boardCy - bh),
    img.Point(cx + bw, boardCy),
    img.Point(cx, boardCy + bh),
  ], color: _white);

  // Tassel: from the centre button to the right edge, then hanging down.
  final th = (s * 0.045).round();
  final edgeX = (cx + bw * 0.6).round();
  final edgeY = (boardCy + bh * 0.2).round();
  img.drawLine(image,
      x1: cx.round(),
      y1: boardCy.round(),
      x2: edgeX,
      y2: edgeY,
      color: _gold,
      thickness: th,
      antialias: true);
  img.drawLine(image,
      x1: edgeX,
      y1: edgeY,
      x2: edgeX,
      y2: (boardCy + bh + s * 0.4).round(),
      color: _gold,
      thickness: th,
      antialias: true);
  img.fillCircle(image,
      x: edgeX,
      y: (boardCy + bh + s * 0.45).round(),
      radius: (s * 0.08).round(),
      color: _gold,
      antialias: true);

  // Centre button.
  img.fillCircle(image,
      x: cx.round(),
      y: boardCy.round(),
      radius: (s * 0.085).round(),
      color: _gold,
      antialias: true);
}

void _write(String path, img.Image image) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  stdout.writeln('wrote $path');
}

void main() {
  // Full-bleed icon: gradient background + cap.
  final icon = img.Image(width: _size, height: _size, numChannels: 4);
  _fillGradient(icon);
  _drawCap(icon, 512, 470, 300);
  _write('assets/icon/tanku_icon.png', icon);

  // Adaptive foreground: transparent, cap scaled into the central safe zone.
  final fg = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0));
  _drawCap(fg, 512, 520, 235);
  _write('assets/icon/tanku_foreground.png', fg);
}
