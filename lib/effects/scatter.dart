import 'dart:math';
import 'dart:ui';

import 'package:particle_reform/particles/scatter_particle.dart';

import 'particle_effect.dart';

/// A particle effect that scatters pixels from their original positions.
///
/// This effect creates a scatter animation where each pixel/particle moves
/// in a random direction from its original position.
class Scatter with ParticleEffect {
  final double maxDistance;

  /// The effect works by generating a random offset within [maxDistance] for
  /// each pixel.
  const Scatter({this.maxDistance = 100});

  @override
  List<ScatterParticle> initialize({
    required Size container,
    required Color? Function(int x, int y) reader,
  }) {
    var random = Random();
    var particles = <ScatterParticle>[];
    for (int y = 0; y < container.height; y++) {
      for (int x = 0; x < container.width; x++) {
        final color = reader(x, y);
        if (color == null) continue;

        // Precompute a scatter offset so each particle moves deterministically during animation
        final scatterX = (random.nextDouble() - 0.5) * maxDistance;
        final scatterY = (random.nextDouble() - 0.5) * maxDistance;

        final particle = ScatterParticle(
          originalPosition: Offset(x.toDouble(), y.toDouble()),
          color: color,
          scatterOffset: Offset(scatterX, scatterY),
        );
        particles.add(particle);
      }
    }
    return particles;
  }
}
