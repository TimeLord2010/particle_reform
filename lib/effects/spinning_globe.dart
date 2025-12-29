import 'dart:math';
import 'dart:ui';

import 'package:particle_reform/particles/globe_particle.dart';
import 'package:particle_reform/particles/particle.dart';

import 'particle_effect.dart';

/// Particles form an image of a 3D globe spinning.
///
/// The effect maps the child widget's pixels onto a sphere surface and
/// rotates them around the Y-axis, creating a 3D spinning globe illusion.
/// Particles are randomly distributed across the entire sphere surface.
/// Back-facing particles have reduced opacity for depth perception.
class SpinningGlobe with ParticleEffect {
  /// The radius of the globe. If null, it will be calculated based on container size.
  final double? radius;

  /// Rotation speed in radians per second. Default is π/2 (90 degrees per second).
  final double rotationSpeed;

  /// Animation speed multiplier.
  final double _animationSpeed;

  const SpinningGlobe({
    this.radius,
    this.rotationSpeed = pi / 2,
    double animationSpeed = 1.0,
  }) : _animationSpeed = animationSpeed;

  @override
  bool get hasAnimation => true;

  @override
  double get animationSpeed => _animationSpeed;

  @override
  List<Particle> initialize({
    required Size container,
    required Color? Function(int x, int y) reader,
  }) {
    final particles = <GlobeParticle>[];
    final centerX = container.width / 2;
    final centerY = container.height / 2;
    final center = Offset(centerX, centerY);

    // Calculate globe radius based on container size if not provided
    final globeRadius = radius ?? min(container.width, container.height) / 2.5;

    final random = Random();

    // Iterate through all pixels in the container
    for (int y = 0; y < container.height; y++) {
      for (int x = 0; x < container.width; x++) {
        final color = reader(x, y);
        if (color == null) continue;

        // Randomly distribute particles across the ENTIRE sphere surface
        // Using uniform sphere point picking:
        // theta: random angle around Y-axis [0, 2π]
        // phi: latitude using asin(uniform(-1, 1)) for uniform distribution
        final theta = random.nextDouble() * 2 * pi; // Range: [0, 2π]
        final phi = asin(random.nextDouble() * 2 - 1); // Range: [-π/2, π/2]

        final particle = GlobeParticle(
          originalPosition: Offset(x.toDouble(), y.toDouble()),
          color: color,
          theta: theta,
          phi: phi,
          center: center,
          radius: globeRadius,
        );
        particles.add(particle);
      }
    }

    return particles;
  }

  @override
  Offset getAnimatedOffset(Particle particle, double animationProgress) {
    final globeParticle = particle as GlobeParticle;

    // Apply Y-axis rotation: increment theta by rotation amount
    final rotationAngle = animationProgress * rotationSpeed;
    final newTheta = globeParticle.theta + rotationAngle;

    // Convert rotated spherical coords back to 2D screen position
    // Using orthographic projection (drop Z component)
    // screenX = centerX + radius * cos(phi) * sin(theta)
    // screenY = centerY + radius * sin(phi)
    final newScreenX =
        globeParticle.center.dx + globeParticle.radius * globeParticle.cosPhi * sin(newTheta);
    final newScreenY =
        globeParticle.center.dy + globeParticle.radius * globeParticle.sinPhi;

    // Return offset from original position
    return Offset(
      newScreenX - globeParticle.originalPosition.dx,
      newScreenY - globeParticle.originalPosition.dy,
    );
  }

  @override
  double? getAnimatedOpacity(Particle particle, double animationProgress) {
    final globeParticle = particle as GlobeParticle;

    // Apply rotation to theta
    final rotationAngle = animationProgress * rotationSpeed;
    final newTheta = globeParticle.theta + rotationAngle;

    // Calculate Z component (depth) after rotation
    // z = cos(phi) * cos(theta)
    // z > 0 means front-facing, z < 0 means back-facing
    final z = globeParticle.cosPhi * cos(newTheta);

    // Map z from [-1, 1] to opacity [0.3, 1.0]
    // z = 1 (front center) -> opacity = 1.0
    // z = 0 (edge) -> opacity = 0.65
    // z = -1 (back center) -> opacity = 0.3
    // Back-facing particles remain visible but dimmed
    final opacity = 0.3 + (z + 1) / 2 * 0.7;

    return opacity.clamp(0.3, 1.0);
  }
}
