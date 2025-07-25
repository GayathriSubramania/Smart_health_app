import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:telephony/telephony.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'audio_monitor.dart';

class EmergencyService {
  final int intervalMinutes;
  final String emergencyPhone;
  final Telephony telephony = Telephony.instance;

  final void Function()? onEmergencyTriggered;
  late RealTimeAudioMonitor _audioMonitor;

  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  Interpreter? _interpreter;

  Timer? _intervalTimer;
  Timer? _responseTimer;

  bool _waitingForReply = false;

  EmergencyService({
    required this.intervalMinutes,
    required this.emergencyPhone,
    this.onEmergencyTriggered,
  });

  Future<void> startMonitoring() async {
    await _loadModel();
    _startCheckCycle();

    _audioMonitor = RealTimeAudioMonitor(
      interpreter: _interpreter!,
      onFallDetected: () {
        print('🎤 Fall detected from real-time audio!');
        _askIfOkay();
      },
    );
    _audioMonitor.start();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('fall_model.tflite');
      print('✅ Model loaded');
    } catch (e) {
      print('❌ Error loading model: \$e');
    }
  }

  void _startCheckCycle() {
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _askIfOkay(),
    );
    _askIfOkay(); // immediate first-time check
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

  Future<void> sendEmergencySMS(String number, String message) async {
    final bool? permission = await telephony.requestSmsPermissions;

    if (permission != null && permission) {
      try {
        telephony.sendSms(
          to: number,
          message: message,
          statusListener: (SendStatus status) {
            if (status == SendStatus.SENT) {
              print("📩 SMS sent to \$number");
              Fluttertoast.showToast(msg: "📤 SMS sent to \$number");
            } else if (status == SendStatus.DELIVERED) {
              print("✅ SMS delivered to \$number");
              Fluttertoast.showToast(msg: "✅ SMS delivered");
            } else {
              print("❌ SMS failed");
              Fluttertoast.showToast(msg: "❌ SMS failed");
            }
          },
        );
      } catch (e) {
        print("❌ Error sending SMS: \$e");
        Fluttertoast.showToast(msg: "❌ Error sending SMS");
      }
    } else {
      print("❌ SMS permission not granted");
      Fluttertoast.showToast(msg: "❌ SMS permission not granted");
    }
  }

  void triggerEmergency() async {
    _waitingForReply = false;
    _responseTimer?.cancel();

    await _tts.speak("Emergency! Calling for help now.");
    await _player.setAsset('assets/alarm.mp3');
    _player.play();

    onEmergencyTriggered?.call();

    // Step 1: Call emergency number
    await FlutterPhoneDirectCaller.callNumber(emergencyPhone);

    // Step 2: Wait 10 seconds then send SMS
    Future.delayed(const Duration(seconds: 10), () {
      sendEmergencySMS(
        emergencyPhone,
        "🚨 Emergency Alert!\nThe elder is not responding. Ambulance has been called.\nPlease check immediately!",
      );
    });
  }

  void dispose() {
    _intervalTimer?.cancel();
    _responseTimer?.cancel();
    _tts.stop();
    _player.dispose();
    _interpreter?.close();
    _audioMonitor.stop();
  }
}
