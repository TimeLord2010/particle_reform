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

    final width = container.width;
    final height = container.height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final color = reader(x, y);
        if (color == null) continue;

        // Random angle for even distribution in all directions
        final angle = random.nextDouble() * 2 * pi;

        // Calculate distance to exit the container in this direction
        // using ray-box intersection
        final cosA = cos(angle);
        final sinA = sin(angle);

        double tX = double.infinity;
        double tY = double.infinity;

        // Find where ray exits horizontally
        if (cosA > 0.0001) {
          tX = (width - x) / cosA; // hits right edge
        } else if (cosA < -0.0001) {
          tX = -x / cosA; // hits left edge
        }

        // Find where ray exits vertically
        if (sinA > 0.0001) {
          tY = (height - y) / sinA; // hits bottom edge
        } else if (sinA < -0.0001) {
          tY = -y / sinA; // hits top edge
        }

        // Distance to exit is the minimum of the two
        final distanceToExit = min(tX, tY);

        // Add buffer (1.2x to 1.5x) to ensure particle is fully outside
        final scatterDistance =
            distanceToExit * (1.2 + random.nextDouble() * 0.3);

        // Calculate scatter offset to place particle outside the view
        final scatterX = cosA * scatterDistance;
        final scatterY = sinA * scatterDistance;

        final particle = ScatterParticle(
          originalPosition: Offset(x.toDouble(), y.toDouble()),
          color: color,
          scatterOffset: Offset(scatterX, scatterY),
          isVisibleWhenScattered: true,
        );
        particles.add(particle);
      }
    }
    return particles;
  }
}
