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
  bool isFormed = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
              SizedBox(height: 100),
              Expanded(
                child: SizedBox(
                  width: 500,
                  child: ParticleReform(
                    isFormed: isFormed,
                    child: Text(
                      'Hello World!',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
