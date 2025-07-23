import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';

class FallModelTester {
late Interpreter interpreter;

Future<void> loadModel() async {
interpreter = await Interpreter.fromAsset('fall_model.tflite');
print('✅ Model loaded');
}

Future<void> runTest() async {
// Dummy input - change based on your model’s real input shape
var input = List.generate(40, (index) => 0.5).reshape([1, 40]);
var output = List.filled(1 * 2, 0.0).reshape([1, 2]);

lua
Copy
Edit
interpreter.run(input, output);

print('🧠 Model Output: $output');

if (output[0][0] > output[0][1]) {
  print('🟢 No Fall Detected');
} else {
  print('🔴 Fall Detected');
}
}

void close() {
interpreter.close();
}
}