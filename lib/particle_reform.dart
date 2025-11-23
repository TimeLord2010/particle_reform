import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:particle_reform/particle.dart';

/// Breaks down the target widget into pixels and animate then moving around
/// constantly.
/// When [isFormed] is set to `true`, they stop their movement and gather to
/// form the original widget.
class ParticleReform extends StatefulWidget {
  const ParticleReform({
    super.key,
    required this.child,
    required this.isFormed,
    this.maxDistance = 100,
  });

  final Widget child;
  final bool isFormed;
  final double maxDistance;

  @override
  State<ParticleReform> createState() => _ParticleReformState();
}

class _ParticleReformState extends State<ParticleReform>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<Particle> _particles = [];
  bool _isInitialized = false;

  // For capturing child pixels
  final GlobalKey _repaintKey = GlobalKey();
  Uint8List? _imageBytes;
  int? _imageWidth;
  int? _imageHeight;
  double? _imagePixelRatio;
  bool _isCapturing = false;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Set initial state based on isFormed
    // When not formed, controller should be at 1.0 (scattered)
    // When formed, controller should be at 0.0 (at original positions)
    if (!widget.isFormed) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ParticleReform oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isFormed != widget.isFormed) {
      if (widget.isFormed) {
        // Animate from scattered (1.0) to formed (0.0)
        _controller.animateTo(0.0);
      } else {
        // Animate from formed (0.0) to scattered (1.0)
        _controller.animateTo(1.0);
      }
    }

    // If the child widget instance changed, recapture pixels
    if (oldWidget.child.key != widget.child.key) {
      _imageBytes = null;
      _isInitialized = false;
      // next build/layout will trigger capture/initialize
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Trigger a capture once layout is available
          if (!_isCapturing && (_imageBytes == null)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _captureImage(constraints.maxWidth, constraints.maxHeight);
            });
          }

          if (!_isInitialized && _imageBytes != null) {
            // initialize particles once we have image bytes
            _initializeParticles(constraints.maxWidth, constraints.maxHeight);
            _isInitialized = true;
          }

          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                children: [
                  // The child rendered inside a RepaintBoundary so we can capture its pixels.
                  // This instance is used only for capture and lives beneath the particles.
                  if (_imageBytes == null)
                    Opacity(
                      opacity: 0.01,
                      child: RepaintBoundary(
                        key: _repaintKey,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: widget.child,
                        ),
                      ),
                    ),

                  // Particles painted on top. Hide them only when formed AND animation is complete.
                  if (!widget.isFormed || _controller.value > 0.0)
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _ParticlePainter(
                        particles: _particles,
                        animationValue: _animation.value,
                        isFormed: widget.isFormed,
                      ),
                    ),

                  // When formed and animation complete, show the real child and hide particles.
                  if (widget.isFormed && _controller.value == 0.0)
                    Positioned.fill(
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        child: widget.child,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _captureImage(double width, double height) async {
    if (_isCapturing) return;

    debugPrint('Capturing image');
    _isCapturing = true;

    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('No boundary');
        _isCapturing = false;
        return;
      }

      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        debugPrint('No byte data');
        _isCapturing = false;
        return;
      }

      _imageBytes = byteData.buffer.asUint8List();
      _imageWidth = image.width;
      _imageHeight = image.height;
      _imagePixelRatio = pixelRatio;

      // Trigger a rebuild so _initializeParticles runs in build
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isCapturing = false;
    }
  }

  void _initializeParticles(double width, double height) {
    if (_imageBytes == null || _imageWidth == null || _imageHeight == null) {
      return;
    }

    debugPrint('Initializing particles');
    _particles.clear();

    // particleSize in logical pixels. Using 1 will try to get every pixel.
    final double particleSize = 1.0;

    final cols = (width / particleSize).ceil();
    final rows = (height / particleSize).ceil();

    final imgW = _imageWidth!;
    final imgH = _imageHeight!;
    final pixelRatio = _imagePixelRatio ?? 1.0;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        // Map logical coordinate to image pixel coordinates
        final imgX = (x * particleSize * pixelRatio).floor();
        final imgY = (y * particleSize * pixelRatio).floor();

        if (imgX < 0 || imgX >= imgW || imgY < 0 || imgY >= imgH) {
          continue;
        }

        final index = (imgY * imgW + imgX) * 4;
        if (index + 3 >= _imageBytes!.length) continue;

        // rawRgba -> bytes are in R, G, B, A order
        final r = _imageBytes![index];
        final g = _imageBytes![index + 1];
        final b = _imageBytes![index + 2];
        final a = _imageBytes![index + 3];

        // Check if there is a pixel at the position (alpha threshold)
        // small threshold to ignore fully transparent pixels
        final hasPixelAtPosition = a > 10;
        if (!hasPixelAtPosition) {
          continue;
        }

        // Get the actual color at the position.
        final color = Color.fromARGB(a, r, g, b);

        // Precompute a scatter offset so each particle moves deterministically during animation
        final scatterX = (_random.nextDouble() - 0.5) * widget.maxDistance;
        final scatterY = (_random.nextDouble() - 0.5) * widget.maxDistance;

        final particle = Particle(
          originalPosition: Offset(x * particleSize, y * particleSize),
          color: color,
          scatterOffset: Offset(scatterX, scatterY),
        );
        _particles.add(particle);
      }
    }

    // After initializing particles, ensure the painter repaints
    // Do not call setState here — _initializeParticles may be invoked from build().
    // The build method sets _isInitialized = true after calling this method,
    // which prevents repeated initialization and ensures the painter will paint
    // with the newly created _particles.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final bool isFormed;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.isFormed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      // animationValue represents the scatter amount:
      // 0.0 = particles at original positions (formed)
      // 1.0 = particles scattered
      final progress = animationValue;

      final displayed = Offset(
        particle.originalPosition.dx + particle.scatterOffset.dx * progress,
        particle.originalPosition.dy + particle.scatterOffset.dy * progress,
      );

      canvas.drawRect(Rect.fromLTWH(displayed.dx, displayed.dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return true;
  }
}
