import 'dart:ui';

import 'package:particle_reform/particle.dart';

mixin ParticleEffect {
  List<Particle> initialize({
    required Size container,
    required Color? Function(int x, int y) reader,
  });

  /// Optional: Override this method for continuous animation effects.
  /// Returns an animated offset for the particle based on elapsed time.
  /// If null is returned, the static scatterOffset will be used instead.
  ///
  /// [particle] - The particle to animate
  /// [time] - Elapsed time in seconds since animation started
  Offset? getAnimatedOffset(Particle particle, double time) => null;
}
