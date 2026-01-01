import 'dart:math';
import 'dart:ui';

import 'package:particle_reform/particles/particle.dart';
import 'package:particle_reform/particles/scatter_particle.dart';

import 'particle_effect.dart';

/// A particle effect that scatters pixels from their original positions.
///
/// This effect creates a scatter animation where each pixel/particle moves
/// in a random direction from its original position.
class Scatter with ParticleEffect {
  final double maxDistance;
  final int particleDensity;

  /// The effect works by generating a random offset within [maxDistance] for
  /// each pixel.
  ///
  /// The [particleDensity] parameter controls how many particles are visible
  /// when scattered:
  /// - 1: all particles visible (default)
  /// - 2: every 2nd particle visible (50% density)
  /// - 3: every 3rd particle visible (33% density)
  /// And so on...
  ///
  /// When particles reform, hidden particles smoothly fade in to full visibility.
  const Scatter({this.maxDistance = 100, this.particleDensity = 1});

  @override
  List<ScatterParticle> initialize({
    required Size container,
    required Color? Function(int x, int y) reader,
  }) {
    var random = Random();
    var particles = <ScatterParticle>[];

    // Guard against invalid density values
    final density = particleDensity < 1 ? 1 : particleDensity;
    int particleIndex = 0;

    for (int y = 0; y < container.height; y++) {
      for (int x = 0; x < container.width; x++) {
        final color = reader(x, y);
        if (color == null) continue;

        // Each particle gets its own unique random scatter position
        final scatterX = (random.nextDouble() - 0.5) * maxDistance;
        final scatterY = (random.nextDouble() - 0.5) * maxDistance;

        // Deterministic visibility: every Nth particle is visible
        final isVisible = particleIndex % density == 0;

        final particle = ScatterParticle(
          originalPosition: Offset(x.toDouble(), y.toDouble()),
          color: color,
          scatterOffset: Offset(scatterX, scatterY),
          isVisibleWhenScattered: isVisible,
        );
        particles.add(particle);
        particleIndex++;
      }
    }
    return particles;
  }

  @override
  double? getAnimatedOpacity(Particle particle, double animationProgress) {
    final scatterParticle = particle as ScatterParticle;
    // Return 1.0 for visible particles, 0.0 for hidden ones
    // The painter will interpolate this during animation
    return scatterParticle.isVisibleWhenScattered ? 1.0 : 0.0;
  }
}
