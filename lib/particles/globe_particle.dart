import 'dart:math';
import 'dart:ui';

import 'package:particle_reform/particles/particle.dart';

/// A particle used by the SpinningGlobe effect.
///
/// Stores spherical coordinates and precomputed values for efficient
/// 3D globe rotation calculations.
class GlobeParticle extends Particle {
  /// Initial theta angle (longitude) in radians. Range: [-π, π]
  final double theta;

  /// Phi angle (latitude) in radians. Range: [-π/2, π/2]
  /// This remains constant during Y-axis rotation.
  final double phi;

  /// Precomputed cos(phi) for performance.
  final double cosPhi;

  /// Precomputed sin(phi) for performance.
  final double sinPhi;

  /// The center point of the globe.
  final Offset center;

  /// The radius of the globe.
  final double radius;

  GlobeParticle({
    required super.originalPosition,
    required super.color,
    required this.theta,
    required this.phi,
    required this.center,
    required this.radius,
  })  : cosPhi = cos(phi),
        sinPhi = sin(phi);
}
