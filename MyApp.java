import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:deserialize_demo/src/rust/api/simple.dart' as simple;
import 'package:deserialize_demo/src/rust/frb_generated.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _text = ValueNotifier("");

  String get text => _text.value;
  set text(String newValue) {
    if (newValue == text) {
      return;
    }
    _text.value = newValue;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final options = Options(responseType: ResponseType.plain);
            final res =
                await Dio().post("http://127.0.0.1:3000", options: options);
            final result = await simple.Response.from(json: res.data);
            if (result.err == null) {
              text = "None";
            } else {
              text = result.err!.msg;
            }
          },
          child: const Icon(Icons.send),
        ),
        appBar: AppBar(title: const Text('JSON Deserialize')),
        body: Center(
          child: ValueListenableBuilder(
            valueListenable: _text,
            builder: (context, v, _) => Text(v),
          ),
        ),
      ),
    );
  }
}
