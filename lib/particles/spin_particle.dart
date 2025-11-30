import 'dart:ui';

import 'package:particle_reform/particles/particle.dart';

class SpinParticle extends Particle {
  final Offset center;
  final double radius;
  Offset initialPosition;
  SpinParticle({
    required super.originalPosition,
    required super.color,
    required this.initialPosition,
    required this.center,
    required this.radius,
  });
}
