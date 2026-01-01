import 'dart:ui';

import 'package:particle_reform/particles/particle.dart';

class ScatterParticle extends Particle {
  final Offset scatterOffset;

  /// Whether this particle should be visible when in scattered state.
  /// When forming, all particles gradually become visible.
  final bool isVisibleWhenScattered;

  ScatterParticle({
    required super.originalPosition,
    required super.color,
    required this.scatterOffset,
    required this.isVisibleWhenScattered,
  });
}
