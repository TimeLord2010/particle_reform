import 'dart:ui';

import 'package:particle_reform/particles/particle.dart';

class SpinParticle extends Particle {
  final Offset center;
  final double baseRadius;
  final double oscillationOffset;
  final double oscillationAmplitude;
  Offset initialPosition;

  SpinParticle({
    required super.originalPosition,
    required super.color,
    required this.initialPosition,
    required this.center,
    required this.baseRadius,
    required this.oscillationOffset,
    required this.oscillationAmplitude,
  });
}
