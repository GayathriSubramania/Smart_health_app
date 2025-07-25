// 📁 File: services/audio_monitor.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class RealTimeAudioMonitor {
  final Interpreter interpreter;
  final void Function() onFallDetected;
  final FlutterAudioCapture _audioCapture = FlutterAudioCapture();
  final List<double> _buffer = [];
  final int sampleRate = 16000;
  final int bufferSize = 16000; // 1 second

  RealTimeAudioMonitor({
    required this.interpreter,
    required this.onFallDetected,
  });

  Future<void> start() async {
    await _audioCapture.start(listener, onError, sampleRate: sampleRate, bufferSize: 3000);
  }

  void listener(dynamic obj) {
    final buffer = Float32List.fromList(List<double>.from(obj));
    for (final sample in buffer) {
      _buffer.add(sample);
      if (_buffer.length >= bufferSize) {
        final input = _extractMFCC(_buffer); // TODO: replace with real MFCC
        final output = List.filled(1 * 1, 0.0).reshape([1, 1]);
        interpreter.run(input, output);
        final result = output[0][0];
        if (result > 0.5) {
          onFallDetected();
        }
        _buffer.clear();
      }
    }
  }

  void onError(Object e) {
    print("❌ Audio capture error: $e");
  }

  List<List<double>> _extractMFCC(List<double> signal) {
    // Replace with actual MFCC logic later
    return List.generate(1, (_) => List.filled(100, 0.0));
  }

  void stop() {
    _audioCapture.stop();
  }
}
