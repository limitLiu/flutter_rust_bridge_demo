import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge_demo/src/deserialize.dart';
import 'package:flutter_rust_bridge_demo/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Main(),
    );
  }
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo List')),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Deserialize"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const Deserialize(),
                  settings: const RouteSettings(name: '/Deserialize'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
