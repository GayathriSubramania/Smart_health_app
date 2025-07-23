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
    _startFallDetectionSimulation(); // Replace this with actual ML detection later
  }

  void _startCheckCycle() {
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _askIfOkay(),
    );
    _askIfOkay(); // First check immediately
  }

  void _askIfOkay() async {
    if (_waitingForReply) return;

    _waitingForReply = true;
    await _tts.speak("Are you okay?");
    print("🔔 Voice prompt sent.");

    _responseTimer = Timer(const Duration(minutes: 1), () async {
      if (_waitingForReply) {
        print("🔁 Asking again...");
        await _tts.speak("Are you okay? Please respond.");
        _responseTimer = Timer(const Duration(minutes: 1), () {
          if (_waitingForReply) triggerEmergency();
        });
      }
    });
  }

  void userResponded() {
    print("✅ User confirmed okay.");
    _waitingForReply = false;
    _responseTimer?.cancel();
    _tts.speak("Thank you. Stay safe.");
  }

  void triggerEmergency() async {
    print("🚨 Emergency triggered!");
    _waitingForReply = false;
    _responseTimer?.cancel();
    await _tts.speak("Emergency! Contacting help now.");

    final player = AudioPlayer();
    await player.setAsset('assets/alarm.mp3');
    player.play();

    _makeCall("108");
    _makeCall(emergencyPhone);
    _sendLocation();
  }

  void _makeCall(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print("❌ Could not launch phone call.");
    }
  }

  void _sendLocation() async {
    const double lat = 12.9716;
    const double lng = 77.5946;
    final Uri mapUri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      print("❌ Could not launch location.");
    }
  }

  void _startFallDetectionSimulation() {
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
