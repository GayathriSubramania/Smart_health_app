// File: lib/services/emer_ser.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:url_launcher/url_launcher.dart';

class EmergencyService {
  final int intervalMinutes;
  final String emergencyPhone;
  final void Function() showEmergencyPopup;

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  Timer? _intervalTimer;
  Timer? _responseTimer;
  bool _waitingForReply = false;

  Interpreter? _interpreter;
  bool _isFallDetected = false;

  EmergencyService({
    required this.intervalMinutes,
    required this.emergencyPhone,
    required this.showEmergencyPopup,
  });

  Future<void> startMonitoring() async {
    await _loadModel();
    _startCheckCycle();
    _startFallDetectionLoop();
  }

  Future<void> _loadModel() async {
    _interpreter = await Interpreter.fromAsset('fall_model.tflite');
    print('✅ ML model loaded');
  }

  void _startCheckCycle() {
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _askIfOkay(),
    );
    _askIfOkay(); // Immediate first check
  }

  void _askIfOkay() async {
    if (_waitingForReply) return;

    _waitingForReply = true;
    await _tts.speak("Are you okay?");
    print("🔔 Voice prompt sent. Waiting for response");

    _listenForResponse();

    _responseTimer = Timer(const Duration(minutes: 1), () async {
      if (_waitingForReply) {
        await _tts.speak("Are you okay? Please respond.");
        _listenForResponse();

        _responseTimer = Timer(const Duration(minutes: 1), () {
          if (_waitingForReply) {
            triggerEmergency();
          }
        });
      }
    });
  }

  void _listenForResponse() async {
    bool available = await _speech.initialize();
    if (!available) return;

    _speech.listen(onResult: (result) {
      final spoken = result.recognizedWords.toLowerCase();
      print("🎙️ User said: $spoken");

      if (spoken.contains("fine") || spoken.contains("i am fine") || spoken.contains("okay")) {
        userResponded();
      }
    });
  }

  void userResponded() {
    print("✅ User confirmed okay");
    _waitingForReply = false;
    _responseTimer?.cancel();
    _speech.stop();
    _tts.speak("Thank you. Stay safe.");
  }

  void triggerEmergency() async {
    print("🚨 Emergency triggered");
    _waitingForReply = false;
    _responseTimer?.cancel();
    _speech.stop();

    await _tts.speak("Emergency! Help is on the way.");

    showEmergencyPopup();

    Future.delayed(const Duration(seconds: 4), () async {
      await _makeCall(emergencyPhone);
      await _tts.speak("This is an emergency. The elder is in danger.");
    });
  }

  Future<void> _makeCall(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("❌ Could not launch phone call");
    }
  }

  void _startFallDetectionLoop() async {
    Timer.periodic(const Duration(seconds: 10), (_) async {
      // Simulate input audio signal as 1D float array if needed
      final input = List.filled(100, 0.0).reshape([1, 100]);
      final output = List.filled(1, 0.0).reshape([1, 1]);

      _interpreter?.run(input, output);

      if (output[0][0] > 0.9 && !_waitingForReply) {
        print("🔴 Fall Detected by ML model");
        _askIfOkay();
      }
    });
  }

  void dispose() {
    _intervalTimer?.cancel();
    _responseTimer?.cancel();
    _tts.stop();
    _speech.stop();
    _interpreter?.close();
  }
}
