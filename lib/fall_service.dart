// File: lib/fall_service.dart

import 'package:tflite_flutter/tflite_flutter.dart';

class FallDetectorService {
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('fall_model.tflite');
      print('Model loaded');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  Future<bool> isFallDetected(List<List<double>> inputData) async {
    var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    _interpreter.run(inputData, output);

    print('Model output: ${output[0][0]}');

    return output[0][0] > 0.7; // adjust threshold based on your model
  }
}
