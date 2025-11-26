import 'package:flutter/material.dart';
import 'package:particle_reform/effects/scatter_disappear.dart';
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
  bool isFormed = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  isFormed = !isFormed;
                  setState(() {});
                },
                child: Text(isFormed ? 'Unform' : 'Form'),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ParticleReform(
                  isFormed: isFormed,
                  effect: ScatterDisappear(),
                  duration: Duration(seconds: 1, milliseconds: 500),
                  curve: Curves.easeIn,
                  child: Center(child: _content()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    return Padding(
      key: ValueKey('text'),
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blueAccent,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Text(
          'Hello World!',
          style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
