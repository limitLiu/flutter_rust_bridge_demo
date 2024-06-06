import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge_demo/src/rust/api/bar_decoder.dart';

class Camera extends StatefulWidget {
  const Camera({super.key});

  @override
  State<StatefulWidget> createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController? _controller;
  bool _detecting = false;

  @override
  void initState() {
    super.initState();
    availableCameras().then((cameras) async {
      final description = cameras
          .firstWhere((e) => e.lensDirection == CameraLensDirection.back);
      _controller = CameraController(description, ResolutionPreset.max,
          enableAudio: false);
      await _controller?.initialize();
      if (!mounted) {
        return;
      }
      _controller?.startImageStream((CameraImage image) async {
        if (_detecting) {
          return;
        }
        _detecting = true;
        try {
          final result = await decode(
            bytes: image.bytes,
            width: image.width,
            height: image.height,
          );
          if (kDebugMode) {
            print("decode: $result");
          }
        } catch (e) {
          _detecting = false;
          if (e is CameraException) {
            if (kDebugMode) {
              print(e.code);
            }
          } else {
            if (kDebugMode) {
              print(e);
            }
          }
        }
      });
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: _controller != null && _controller!.value.isInitialized
          ? Center(
              child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  width: double.infinity,
                  height: width - 64,
                  child: CameraPreview(_controller!)),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller?.stopImageStream();
    _controller?.dispose();
  }
}

extension Bytes on CameraImage {
  List<int> get bytes {
    final buffer = List.filled(width * height * 3, 0);
    for (int x = 0; x < width; ++x) {
      for (int y = 0; y < height; ++y) {
        final pixelColor = planes[0].bytes[y * width + x];
        buffer[y * width + x] =
            (0xFF << 24) | (pixelColor << 16) | (pixelColor << 8) | pixelColor;
      }
    }
    return buffer;
  }
}
