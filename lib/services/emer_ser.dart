import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyService {
  final int intervalMinutes;
  final String emergencyPhone;
  final void Function()? onEmergencyTriggered;

  final FlutterTts _tts = FlutterTts();
  Timer? _intervalTimer;
  Timer? _responseTimer;
  bool _waitingForReply = false;

  EmergencyService({
    required this.intervalMinutes,
    required this.emergencyPhone,
    this.onEmergencyTriggered,
  });

  void startMonitoring() {
    _startCheckCycle();
    _startFallDetectionSimulation(); // Replace with actual ML model trigger
  }

  void _startCheckCycle() {
    _intervalTimer?.cancel();
    _intervalTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _askIfOkay(),
    );
    _askIfOkay(); // first check
  }

  void _askIfOkay() async {
    if (_waitingForReply) return;

    _waitingForReply = true;
    await _tts.speak("Are you okay?");
    _responseTimer = Timer(const Duration(minutes: 1), () async {
      if (_waitingForReply) {
        await _tts.speak("Are you okay? Please respond.");
        _responseTimer = Timer(const Duration(minutes: 1), () {
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

    final player = AudioPlayer();
    await player.setAsset('assets/alarm.mp3');
    player.play();

    onEmergencyTriggered?.call(); // update UI

    _makeCall(emergencyPhone);
  }

  void _makeCall(String number) async {
    final Uri uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _startFallDetectionSimulation() {
    Future.delayed(const Duration(seconds: 30), () {
      _askIfOkay();
    });
  }

  void dispose() {
    _intervalTimer?.cancel();
    _responseTimer?.cancel();
    _tts.stop();
  }
}
