import 'dart:ui';

import 'package:particle_reform/particles/particle.dart';

mixin ParticleEffect {
  List<Particle> initialize({
    required Size container,
    required Color? Function(int x, int y) reader,
  });

  bool get hasAnimation => false;

  /// Optional: Override this method for continuous animation effects.
  /// Returns an animated offset for the particle based on elapsed time.
  /// If null is returned, the static scatterOffset will be used instead.
  ///
  /// [particle] - The particle to animate
  /// [animationProgress] - Varies from 0 to 1
  Offset getAnimatedOffset(Particle particle, double animationProgress) {
    throw Exception('Not implemented');
  }
}
