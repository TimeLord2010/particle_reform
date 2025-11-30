import 'dart:math';
import 'dart:ui';

import 'package:particle_reform/particles/particle.dart';
import 'package:particle_reform/particles/scatter_particle.dart';

import 'particle_effect.dart';

/// Particles form an image of a 3D globe spinning.
///
/// The effect maps the child widget's pixels onto a sphere surface and
/// rotates them around the Y-axis, creating a 3D spinning globe illusion.
class SpinningGlobe with ParticleEffect {
  /// The radius of the globe. If null, it will be calculated based on container size.
  final double? radius;

  /// Rotation speed in radians per second. Default is π/2 (90 degrees per second).
  final double rotationSpeed;

  const SpinningGlobe({this.radius, this.rotationSpeed = pi / 2});

  @override
  List<Particle> initialize({
    required Size container,
    required Color? Function(int x, int y) reader,
  }) {
    final particles = <Particle>[];
    final centerX = container.width / 2;
    final centerY = container.height / 2;

    // Calculate globe radius based on container size if not provided
    final globeRadius = radius ?? min(container.width, container.height) / 2.5;

    // Iterate through all pixels in the container
    for (int y = 0; y < container.height; y++) {
      for (int x = 0; x < container.width; x++) {
        final color = reader(x, y);
        if (color == null) continue;

        // Convert 2D pixel position to position relative to center
        final relX = x - centerX;
        final relY = y - centerY;

        // Only map pixels that fall within the globe radius
        final distFromCenter = sqrt(relX * relX + relY * relY);
        if (distFromCenter > globeRadius) continue;

        // Normalize coordinates to [-1, 1] range based on globe radius
        final normX = relX / globeRadius;
        final normY = relY / globeRadius;

        // Calculate normZ from sphere equation: x² + y² + z² = 1
        final normDistSq = normX * normX + normY * normY;
        final normZ = sqrt(1.0 - normDistSq);

        // Convert to spherical coordinates
        // theta: angle in XZ plane from Z-axis (longitude)
        // phi: angle from XZ plane (latitude)
        final theta = atan2(normX, normZ); // Range: [-π, π]
        final phi = asin(normY); // Range: [-π/2, π/2]

        // Encode: dx = theta, dy = phi + globeRadius * 100
        // phi is in [-π/2, π/2] ≈ [-1.57, 1.57]
        // globeRadius * 100 shifts it to a range where we can extract globeRadius
        // Assuming globeRadius < 1000, globeRadius * 100 < 100000
        // So dy = phi + globeRadius * 100 is in [globeRadius*100 - 1.57, globeRadius*100 + 1.57]
        // To decode: globeRadius = round(dy / 100), phi = dy - globeRadius * 100
        final encodedDy = phi + globeRadius * 100;

        final particle = ScatterParticle(
          originalPosition: Offset(x.toDouble(), y.toDouble()),
          color: color,
          scatterOffset: Offset(theta, encodedDy),
        );
        particles.add(particle);
      }
    }

    return particles;
  }

  @override
  Offset getAnimatedOffset(Particle particle, double animationProgress) {
    throw Exception('Not implemented');
  }
}
