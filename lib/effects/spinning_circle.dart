import 'dart:math';
import 'dart:ui';

import 'package:particle_reform/particles/particle.dart';
import 'package:particle_reform/particles/spin_particle.dart';

import 'particle_effect.dart';

/// Particles are animated into a single circle.
class SpinningCircle with ParticleEffect {
  /// The radius of the globe. If null, it will be calculated based on container size.
  final double? radius;

  const SpinningCircle({this.radius});

  @override
  List<Particle> initialize({
    required Size container,
    required Color? Function(int x, int y) reader,
  }) {
    final centerX = container.width / 2;
    final centerY = container.height / 2;
    final center = Offset(centerX, centerY);

    final circleRadius = radius ?? min(container.width, container.height) / 2.5;

    final particles = <SpinParticle>[];
    // Iterate through all pixels in the container
    for (int y = 0; y < container.height; y++) {
      for (int x = 0; x < container.width; x++) {
        final color = reader(x, y);
        if (color == null) continue;
        final particle = SpinParticle(
          originalPosition: Offset(x.toDouble(), y.toDouble()),
          color: color,
          initialPosition: Offset.zero, // Placeholder value
          center: center,
          radius: circleRadius,
        );
        particles.add(particle);
      }
    }

    if (particles.isEmpty) {
      print('Empty particles');
      return particles;
    }

    /// Compute the angle of each particle in order for being space evenly.
    var angles = 360 / particles.length;
    for (int i = 0; i < particles.length; i++) {
      var angle = (angles * i) * pi / 180; // Convert degrees to radians

      // Compute position based on the angle + radius
      // x = centerX + radius * cos(angle)
      // y = centerY + radius * sin(angle)
      var x = centerX + circleRadius * cos(angle);
      var y = centerY + circleRadius * sin(angle);
      Offset scatterPos = Offset(x, y);
      // print('[$i]: Scatter pos: $scatterPos');

      var particle = particles[i];
      particle.initialPosition = scatterPos;
    }
    return particles;
  }

  @override
  bool get hasAnimation => true;

  @override
  Offset getAnimatedOffset(Particle particle, double animationProgress) {
    SpinParticle spinParticle = particle as SpinParticle;

    // Calculate the initial angle from center to initialPosition
    final dx = spinParticle.initialPosition.dx - spinParticle.center.dx;
    final dy = spinParticle.initialPosition.dy - spinParticle.center.dy;
    final initialAngle = atan2(dy, dx);

    // Add rotation based on animation progress (full rotation = 2π)
    final rotation = animationProgress * 2 * pi;
    final newAngle = initialAngle + rotation;

    // Calculate new position on the circle
    final x = spinParticle.center.dx + spinParticle.radius * cos(newAngle);
    final y = spinParticle.center.dy + spinParticle.radius * sin(newAngle);

    return spinParticle.originalPosition;
    // return Offset(x, y); // Commented for debuging
  }
}
