import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';


import 'package:tflite_flutter/src/util/list_shape_extension.dart'; 

class EmergencyService {
  final int intervalMinutes;
  final String emergencyPhone;
  final void Function()? onEmergencyTriggered;

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  Interpreter? _interpreter;

  Timer? _intervalTimer;
  Timer? _responseTimer;
  Timer? _mlMonitorTimer;

  bool _waitingForReply = false;

  EmergencyService({
    required this.intervalMinutes,
    required this.emergencyPhone,
    this.onEmergencyTriggered,
  });

  Future<void> startMonitoring() async {
    await _loadModel();
    _startCheckCycle();
    _startMLMonitoring();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('fall_model.tflite');
      print('✅ Model loaded');
    } catch (e) {
      print('❌ Error loading model: $e');
    }
  }

  void _startCheckCycle() {
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _askIfOkay(),
    );
    _askIfOkay(); // first time
  }

  void _askIfOkay() async {
    if (_waitingForReply) return;
    _waitingForReply = true;

    await _tts.speak("Are you okay?");
    _responseTimer = Timer(const Duration(seconds: 30), () async {
      if (_waitingForReply) {
        await _tts.speak("Are you okay? Please respond.");
        _responseTimer = Timer(const Duration(seconds: 30), () {
          if (_waitingForReply) {
            triggerEmergency();
          }
        });
      }
    });
  }

  void userResponded() {
    _waitingForReply = false;
    _responseTimer?.cancel();
    _tts.speak("Thank you. Stay safe.");
  }

  void triggerEmergency() async {
    _waitingForReply = false;
    _responseTimer?.cancel();

    await _tts.speak("Emergency! Calling for help now.");
    await _player.setAsset('assets/alarm.mp3');
    _player.play();

    onEmergencyTriggered?.call();

    _makeCall(emergencyPhone);
  }

  void _makeCall(String number) async {
  await FlutterPhoneDirectCaller.callNumber(number);
}


  void _startMLMonitoring() {
    _mlMonitorTimer?.cancel();
    _mlMonitorTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _runFallDetection(),
    );
  }

  void _runFallDetection() {
if (_interpreter == null) return;

final input = List.filled(100, 0.0).reshape([1, 100]);
final output = List.filled(1, 0.0).reshape([1, 1]);

_interpreter!.run(input, output);

final result = output[0][0];
print('📈 ML Model Output: $result');

if (result > 0.5) {
print('⚠️ Fall detected!');
_askIfOkay();
}
}

  void dispose() {
    _intervalTimer?.cancel();
    _responseTimer?.cancel();
    _mlMonitorTimer?.cancel();
    _tts.stop();
    _player.dispose();
    _interpreter?.close();
  }
}


