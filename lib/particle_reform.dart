import 'package:flutter/widgets.dart';

/// Breaks down the target widget into pixels and animate then moving around.
/// When [isFormed] is set to `true`, they stop their moviment and gather to
/// form the original widget.
class ParticleReform extends StatefulWidget {
  const ParticleReform({
    super.key,
    required this.child,
    required this.isFormed,
  });

  final Widget child;
  final bool isFormed;

  @override
  State<ParticleReform> createState() => _ParticleReformState();
}

class _ParticleReformState extends State<ParticleReform> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
