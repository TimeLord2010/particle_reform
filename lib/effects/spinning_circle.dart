import 'dart:math';
import 'dart:ui';

import 'package:particle_reform/particles/particle.dart';
import 'package:particle_reform/particles/spin_particle.dart';

import 'particle_effect.dart';

/// Particles are animated into a ring with Gaussian distribution.
class SpinningCircle with ParticleEffect {
  /// The radius of the ring center. If null, it will be calculated based on container size.
  final double? radius;

  /// The thickness of the ring. If null, defaults to 20% of the radius.
  final double? strokeWidth;

  const SpinningCircle({this.radius, this.strokeWidth});

  /// Generates a Gaussian random value using Box-Muller transform.
  double _gaussianRandom(Random random, double mean, double stdDev) {
    final u1 = random.nextDouble();
    final u2 = random.nextDouble();
    final z = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    return mean + z * stdDev;
  }

  @override
  List<Particle> initialize({
    required Size container,
    required Color? Function(int x, int y) reader,
  }) {
    final centerX = container.width / 2;
    final centerY = container.height / 2;
    final center = Offset(centerX, centerY);

    final circleRadius = radius ?? min(container.width, container.height) / 2.5;
    final ringWidth = strokeWidth ?? circleRadius * 0.2;
    final innerRadius = circleRadius - ringWidth / 2;
    final outerRadius = circleRadius + ringWidth / 2;

    final random = Random();
    final particles = <SpinParticle>[];

    // Iterate through all pixels in the container
    for (int y = 0; y < container.height; y++) {
      for (int x = 0; x < container.width; x++) {
        final color = reader(x, y);
        if (color == null) continue;

        // Generate radius with Gaussian distribution centered on circleRadius
        // stdDev = ringWidth/3 means ~99% of particles fall within the ring
        var particleRadius = _gaussianRandom(random, circleRadius, ringWidth / 3);
        particleRadius = particleRadius.clamp(innerRadius, outerRadius);

        // Random oscillation parameters
        final oscillationOffset = random.nextDouble() * 2 * pi;
        final oscillationAmplitude = ringWidth * 0.15 * (0.5 + random.nextDouble());

        final particle = SpinParticle(
          originalPosition: Offset(x.toDouble(), y.toDouble()),
          color: color,
          initialPosition: Offset.zero, // Placeholder value
          center: center,
          baseRadius: particleRadius,
          oscillationOffset: oscillationOffset,
          oscillationAmplitude: oscillationAmplitude,
        );
        particles.add(particle);
      }
    }

    if (particles.isEmpty) {
      return particles;
    }

    /// Compute the angle of each particle in order for being spaced evenly.
    var angles = 360 / particles.length;
    for (int i = 0; i < particles.length; i++) {
      var angle = (angles * i) * pi / 180; // Convert degrees to radians

      // Compute position based on the angle + particle's assigned radius
      var particle = particles[i];
      var px = centerX + particle.baseRadius * cos(angle);
      var py = centerY + particle.baseRadius * sin(angle);
      particle.initialPosition = Offset(px, py);
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

    // Add rotation based on elapsed time (one full rotation per second)
    // animationProgress here represents elapsed time in seconds
    final rotation = animationProgress * 2 * pi;
    final newAngle = initialAngle + rotation;

    // Calculate oscillating radius
    final oscillation = sin(animationProgress * 3 * pi + spinParticle.oscillationOffset);
    final currentRadius = spinParticle.baseRadius + oscillation * spinParticle.oscillationAmplitude;

    // Calculate new position on the circle with oscillating radius
    final x = spinParticle.center.dx + currentRadius * cos(newAngle);
    final y = spinParticle.center.dy + currentRadius * sin(newAngle);

    // Return offset from original position to the rotating circle position
    return Offset(x, y) - spinParticle.originalPosition;
  }
}
