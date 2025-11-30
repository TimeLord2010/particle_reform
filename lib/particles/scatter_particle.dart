import 'dart:ui';

import 'package:particle_reform/particles/particle.dart';

class ScatterParticle extends Particle {
  Offset scatterOffset;

  ScatterParticle({
    required super.originalPosition,
    required super.color,
    required this.scatterOffset,
  });
}
