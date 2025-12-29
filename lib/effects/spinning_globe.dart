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
///
/// The [cameraLatitude] and [cameraLongitude] parameters allow viewing the
/// globe from different angles, as if moving the camera around a fixed sphere.
class SpinningGlobe with ParticleEffect {
  /// The radius of the globe. If null, it will be calculated based on container size.
  final double? radius;

  /// Rotation speed in radians per second. Default is π/2 (90 degrees per second).
  final double rotationSpeed;

  /// Camera latitude in radians. Positive values look down from above,
  /// negative values look up from below. Default is 0 (eye level).
  /// Range: [-π/2, π/2] (-90° to 90°)
  final double cameraLatitude;

  /// Camera longitude in radians. Positive values rotate the view to the right,
  /// negative values to the left. Default is 0 (front view).
  /// Range: [-π, π] (-180° to 180°)
  final double cameraLongitude;

  /// Animation speed multiplier.
  final double _animationSpeed;

  // Precomputed camera rotation values
  final double _cosCamLat;
  final double _sinCamLat;
  final double _cosCamLon;
  final double _sinCamLon;

  SpinningGlobe({
    this.radius,
    this.rotationSpeed = pi / 2,
    this.cameraLatitude = 0,
    this.cameraLongitude = 0,
    double animationSpeed = 1.0,
  })  : _animationSpeed = animationSpeed,
        _cosCamLat = cos(cameraLatitude),
        _sinCamLat = sin(cameraLatitude),
        _cosCamLon = cos(cameraLongitude),
        _sinCamLon = sin(cameraLongitude);

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

  /// Applies camera rotation to a 3D point and returns the transformed (x, y, z).
  /// First rotates around Y-axis (longitude), then around X-axis (latitude).
  (double, double, double) _applyCameraRotation(double x, double y, double z) {
    // Step 1: Rotate around Y-axis (camera longitude)
    // x' = x * cos(lon) + z * sin(lon)
    // z' = -x * sin(lon) + z * cos(lon)
    final x1 = x * _cosCamLon + z * _sinCamLon;
    final z1 = -x * _sinCamLon + z * _cosCamLon;

    // Step 2: Rotate around X-axis (camera latitude)
    // y' = y * cos(lat) - z * sin(lat)
    // z' = y * sin(lat) + z * cos(lat)
    final y2 = y * _cosCamLat - z1 * _sinCamLat;
    final z2 = y * _sinCamLat + z1 * _cosCamLat;

    return (x1, y2, z2);
  }

  @override
  Offset getAnimatedOffset(Particle particle, double animationProgress) {
    final globeParticle = particle as GlobeParticle;

    // Apply Y-axis rotation (globe spin): increment theta by rotation amount
    final rotationAngle = animationProgress * rotationSpeed;
    final newTheta = globeParticle.theta + rotationAngle;

    // Convert spherical to cartesian coordinates (on unit sphere)
    // x = cos(phi) * sin(theta)
    // y = sin(phi)
    // z = cos(phi) * cos(theta)
    final x = globeParticle.cosPhi * sin(newTheta);
    final y = globeParticle.sinPhi;
    final z = globeParticle.cosPhi * cos(newTheta);

    // Apply camera rotation
    final (camX, camY, _) = _applyCameraRotation(x, y, z);

    // Project to 2D screen (orthographic projection, drop Z)
    final newScreenX = globeParticle.center.dx + globeParticle.radius * camX;
    final newScreenY = globeParticle.center.dy - globeParticle.radius * camY;

    // Return offset from original position
    return Offset(
      newScreenX - globeParticle.originalPosition.dx,
      newScreenY - globeParticle.originalPosition.dy,
    );
  }

  @override
  double? getAnimatedOpacity(Particle particle, double animationProgress) {
    final globeParticle = particle as GlobeParticle;

    // Apply Y-axis rotation (globe spin)
    final rotationAngle = animationProgress * rotationSpeed;
    final newTheta = globeParticle.theta + rotationAngle;

    // Convert to cartesian
    final x = globeParticle.cosPhi * sin(newTheta);
    final y = globeParticle.sinPhi;
    final z = globeParticle.cosPhi * cos(newTheta);

    // Apply camera rotation and get the Z component (depth from camera's view)
    final (_, _, camZ) = _applyCameraRotation(x, y, z);

    // Map camZ from [-1, 1] to opacity [0.3, 1.0]
    // camZ = 1 (front center from camera view) -> opacity = 1.0
    // camZ = 0 (edge) -> opacity = 0.65
    // camZ = -1 (back center) -> opacity = 0.3
    // Back-facing particles remain visible but dimmed
    final opacity = 0.3 + (camZ + 1) / 2 * 0.7;

    return opacity.clamp(0.3, 1.0);
  }
}
