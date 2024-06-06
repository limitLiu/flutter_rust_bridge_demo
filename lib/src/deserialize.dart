import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge_demo/src/rust/api/simple.dart' as simple;

class Deserialize extends StatefulWidget {
  const Deserialize({super.key});

  @override
  State<StatefulWidget> createState() => _DeserializeState();
}

class _DeserializeState extends State<Deserialize> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('JSON Deserialize')),
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
      body: Center(
        child: ValueListenableBuilder(
          valueListenable: _text,
          builder: (context, v, _) => Text(v),
        ),
      ),
    );
  }
}
