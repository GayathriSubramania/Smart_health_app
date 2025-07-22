import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';


import 'package:url_launcher/url_launcher.dart';

class EmergencyService {
  final int intervalMinutes;
  final String emergencyPhone;

  final FlutterTts _tts = FlutterTts();
  Timer? _intervalTimer;
  Timer? _responseTimer;
  bool _waitingForReply = false;

  EmergencyService({
    required this.intervalMinutes,
    required this.emergencyPhone,
  });

  void startMonitoring() {
    _startCheckCycle();
    _startFallDetectionSimulation(); // Start background simulation
  }

  void _startCheckCycle() {
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _askIfOkay(),
    );
    _askIfOkay(); // immediate check on start
  }

  void _askIfOkay() async {
    if (_waitingForReply) return; // already waiting

    _waitingForReply = true;
    await _tts.speak("Are you okay?");
    print("⏳ Waiting 1 minute for user response...");

    _responseTimer = Timer(const Duration(minutes: 1), () {
      if (_waitingForReply) {
        triggerEmergency();
      }
    });
  }

  void userResponded() {
    print("✅ User confirmed OK");
    _waitingForReply = false;
    _responseTimer?.cancel();
    _tts.speak("Thank you. Stay safe.");
  }

  void triggerEmergency() {
    print("🚨 Emergency triggered!");
    _waitingForReply = false;
    _responseTimer?.cancel();
    _tts.speak("Emergency! Calling now.");
    final player = AudioPlayer();
    player.setAsset('assets/alarm.mp3');
    player.play();

    _makeCall();
  }

  void _makeCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: emergencyPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      print("❌ Could not launch call.");
    }
  }

  void _startFallDetectionSimulation() {
    // Replace this with actual AI model trigger in future
    Future.delayed(const Duration(seconds: 30), () {
      print("🔴 Simulated fall detected.");
      _askIfOkay();
    });
  }

  void dispose() {
    _intervalTimer?.cancel();
    _responseTimer?.cancel();
    _tts.stop();
  }
}
