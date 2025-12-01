import 'package:flutter/material.dart';
import 'package:particle_reform/effects/particle_effect.dart';
import 'package:particle_reform/particle_reform.dart';

class Usecase extends StatefulWidget {
  const Usecase({super.key, required this.effect});

  final ParticleEffect effect;

  @override
  State<Usecase> createState() => _UsecaseState();
}

class _UsecaseState extends State<Usecase> {
  bool isFormed = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              effect: widget.effect,
              duration: Duration(seconds: 1, milliseconds: 500),
              curve: Curves.easeIn,
              child: _content(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return Center(
      child: Padding(
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
      ),
    );
  }
}
