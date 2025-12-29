A Flutter package that breaks down any widget into pixel particles and animates them with customizable effects. Watch your widgets scatter, spin, and reform with beautiful particle animations.

## Getting started

## Usage

Wrap any widget with `ParticleReform` and control the animation with the `isFormed` parameter:

```dart
import 'package:particle_reform/particle_reform.dart';
import 'package:particle_reform/effects/scatter.dart';

ParticleReform(
  isFormed: isFormed,
  effect: Scatter(),
  duration: Duration(seconds: 1),
  child: Text('Your Widget Here'),
)
```

Toggle `isFormed` to trigger the particle animation:

- `isFormed: true` - Particles reform into the original widget
- `isFormed: false` - Widget breaks into particles and scatters

See the `/example` folder for more comprehensive examples with different effects.

## Additional information

For more examples and information, check the `/example` folder in the repository.
