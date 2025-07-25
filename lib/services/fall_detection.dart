import 'package:tflite_flutter/tflite_flutter.dart';

class FallDetectorService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('fall_model.tflite');
  }

  bool predict(List<double> audioInput) {
    if (_interpreter == null) return false;

    var input = [audioInput];
    var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

    _interpreter!.run(input, output);

    return output[0][0] > 0.5;
  }

  void dispose() {
    _interpreter?.close();
  }
}
