import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:particle_reform/effects/particle_effect.dart';
import 'package:particle_reform/effects/scatter.dart';
import 'package:particle_reform/particles/particle.dart';
import 'package:particle_reform/particles/scatter_particle.dart';

/// Breaks down the target widget into pixels and animate then moving around
/// constantly.
/// When [isFormed] is set to `true`, they stop their movement and gather to
/// form the original widget.
class ParticleReform extends StatefulWidget {
  const ParticleReform({
    super.key,
    required this.child,
    required this.isFormed,
    this.effect = const Scatter(),
    this.duration = const Duration(seconds: 1),
    this.curve = Curves.easeOut,
  });

  final Widget child;
  final bool isFormed;
  final ParticleEffect effect;
  final Duration duration;
  final Curve curve;

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

  // For continuous animation effects
  Ticker? _continuousTicker;
  double _elapsedTime = 0.0;
  bool _needsContinuousAnimation = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
    // ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

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
    _continuousTicker?.dispose();
    super.dispose();
  }

  void _startContinuousAnimation() {
    if (_continuousTicker != null && _continuousTicker!.isActive) return;

    _continuousTicker?.dispose();
    _continuousTicker = createTicker((elapsed) {
      setState(() {
        _elapsedTime = elapsed.inMilliseconds / 1000.0;
      });
    });
    _continuousTicker!.start();
  }

  void _stopContinuousAnimation() {
    _continuousTicker?.stop();
    _continuousTicker?.dispose();
    _continuousTicker = null;
    _elapsedTime = 0.0;
  }

  @override
  void didUpdateWidget(covariant ParticleReform oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isFormed != widget.isFormed) {
      if (widget.isFormed) {
        // Animate from scattered (1.0) to formed (0.0)
        _controller.animateTo(0.0);
        // Stop continuous animation when forming
        if (_needsContinuousAnimation) {
          _stopContinuousAnimation();
        }
      } else {
        // Animate from formed (0.0) to scattered (1.0)
        _controller.animateTo(1.0);
        // Start continuous animation when scattering
        if (_needsContinuousAnimation) {
          _startContinuousAnimation();
        }
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
                        elapsedTime: _elapsedTime,
                        effect: widget.effect,
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

    final imgW = _imageWidth!;
    final imgH = _imageHeight!;
    final pixelRatio = _imagePixelRatio ?? 1.0;

    var particles = widget.effect.initialize(
      container: Size(width, height),
      reader: (x, y) {
        final imgX = (x * pixelRatio).floor();
        final imgY = (y * pixelRatio).floor();

        if (imgX < 0 || imgX >= imgW || imgY < 0 || imgY >= imgH) {
          return null;
        }

        final index = (imgY * imgW + imgX) * 4;
        if (index + 3 >= _imageBytes!.length) return null;

        // rawRgba -> bytes are in R, G, B, A order
        final r = _imageBytes![index];
        final g = _imageBytes![index + 1];
        final b = _imageBytes![index + 2];
        final a = _imageBytes![index + 3];

        // Check if there is a pixel at the position (alpha threshold)
        // small threshold to ignore fully transparent pixels
        final hasPixelAtPosition = a > 10;
        if (!hasPixelAtPosition) return null;

        return Color.fromARGB(a, r, g, b);
      },
    );
    _particles.addAll(particles);

    // Check if this effect needs continuous animation
    // Test with a dummy particle to see if getAnimatedOffset returns non-null
    var effect = widget.effect;
    if (_particles.isNotEmpty && effect.hasAnimation) {
      _needsContinuousAnimation = true;

      // Start continuous animation if needed and not formed
      if (_needsContinuousAnimation && !widget.isFormed) {
        _startContinuousAnimation();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final double elapsedTime;
  final ParticleEffect effect;

  _ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.elapsedTime,
    required this.effect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      ui.Offset getOffset() {
        if (effect.hasAnimation) {
          return effect.getAnimatedOffset(particle, elapsedTime * effect.animationSpeed);
        }
        if (particle is ScatterParticle) {
          return particle.scatterOffset;
        }
        return Offset.zero;
      }

      ui.Offset animatedOffset = getOffset();

      // Use time-based animation from effect
      // animationValue still controls the transition between formed and scattered
      // When animationValue = 0.0 (formed), show original position
      // When animationValue = 1.0 (scattered), show animated position
      final displayed = Offset(
        particle.originalPosition.dx + animatedOffset.dx * animationValue,
        particle.originalPosition.dy + animatedOffset.dy * animationValue,
      );

      canvas.drawRect(Rect.fromLTWH(displayed.dx, displayed.dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return true;
  }
}
