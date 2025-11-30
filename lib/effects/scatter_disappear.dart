import 'dart:math';
import 'dart:ui';

import 'package:particle_reform/particles/scatter_particle.dart';

import 'particle_effect.dart';

/// Scatters the particles outside the viewable parts of the widget.
class ScatterDisappear with ParticleEffect {
  const ScatterDisappear();

  @override
  List<ScatterParticle> initialize({
    required Size container,
    required Color? Function(int x, int y) reader,
  }) {
    var random = Random();
    var particles = <ScatterParticle>[];

    // Calculate the diagonal distance from center to corner
    // This ensures particles go far enough to be outside the view
    final distanceToEdge = sqrt(
      pow(container.width / 2, 2) + pow(container.height / 2, 2),
    );

    for (int y = 0; y < container.height; y++) {
      for (int x = 0; x < container.width; x++) {
        final color = reader(x, y);
        if (color == null) continue;

        // Random angle for even distribution in all directions
        final angle = random.nextDouble() * 2 * pi;

        // Random distance with some variation (1.2x to 1.5x the distance to edge)
        final scatterDistance =
            distanceToEdge * (1.5 + random.nextDouble() * 0.3);

        // Calculate scatter offset to place particle outside the view
        final scatterX = cos(angle) * scatterDistance;
        final scatterY = sin(angle) * scatterDistance;

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
