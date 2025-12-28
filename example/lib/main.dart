import 'package:example/usecase.dart';
import 'package:flutter/material.dart';
import 'package:particle_reform/effects/scatter.dart';
import 'package:particle_reform/effects/scatter_disappear.dart';
import 'package:particle_reform/effects/spinning_circle.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 350,
            childAspectRatio: 2,
          ),
          itemBuilder: (context, index) {
            var effect = switch (index) {
              0 => Scatter(),
              1 => ScatterDisappear(),
              2 => SpinningCircle(),
              _ => Scatter(),
            };

            var label = switch (index) {
              1 => 'Scatter disappear',
              2 => 'SpinningCircle',
              _ => 'Scatter',
            };

            var item = Usecase(effect: effect, label: label);
            return item;
          },
          itemCount: 3,
        ),
      ),
    );
  }
}
