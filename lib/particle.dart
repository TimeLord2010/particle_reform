import 'dart:ui';

class Particle {
  final Offset originalPosition;

  final Offset scatterOffset;

  final Color color;

  Particle({
    required this.originalPosition,
    required this.color,
    required this.scatterOffset,
  });
}
