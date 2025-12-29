import 'package:example/usecase.dart';
import 'package:flutter/material.dart';
import 'package:particle_reform/particle_reform.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool useBackground = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 500,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            var effect = switch (index) {
              1 => ScatterDisappear(),
              2 => SpinningCircle(animationSpeed: 0.1, strokeWidth: 30),
              3 => SpinningGlobe(),
              _ => Scatter(),
            };

            var label = switch (index) {
              1 => 'Scatter disappear',
              2 => 'Spinning circle',
              3 => 'Spinning globe',
              _ => 'Scatter',
            };

            var item = Usecase(
              effect: effect,
              label: label,
              useBackground: useBackground,
            );
            return item;
          },
          itemCount: 4,
        ),
      ),
    );
  }
}
