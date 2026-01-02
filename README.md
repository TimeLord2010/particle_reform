A Flutter package that breaks down any widget into pixel particles and animates them with customizable effects. Watch your widgets scatter, spin, and reform with beautiful particle animations.

https://github.com/user-attachments/assets/c65ae00e-3161-4117-a785-09e6adf86be0

## Available Effects

### 1. **Scatter**

Scatters pixels from their original positions in random directions.

### 2. **ScatterDisappear**

Scatters particles outside the viewable area of the widget.

### 3. **SpinningCircle**

Animates particles into a spinning ring with Gaussian distribution.

### 4. **SpinningGlobe**

Creates a 3D spinning globe effect with depth perception.

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
