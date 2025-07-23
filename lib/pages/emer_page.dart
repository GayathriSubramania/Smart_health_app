// File: lib/pages/emer_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // ← required for CupertinoTimerPicker
import 'package:smart_health/services/emer_ser.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  Duration? _selectedInterval;
  String? _emergencyPhone;
  EmergencyService? emergencyService;
  final TextEditingController phoneController = TextEditingController();
  bool _showEmergencyOverlay = false;

  @override
  void dispose() {
    phoneController.dispose();
    emergencyService?.dispose();
    super.dispose();
  }

  void _showEmergencyPopup() {
    setState(() {
      _showEmergencyOverlay = true;
    });
    Future.delayed(const Duration(seconds: 4), () {
      setState(() => _showEmergencyOverlay = false);
    });
  }

  Future<void> _pickInterval() async {
    final Duration? picked = await showModalBottomSheet<Duration>(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        Duration tempDuration = const Duration(minutes: 30);
        return Container(
          height: 250,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              const Text(
                'Select Interval',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: CupertinoTimerPicker(
                  mode: CupertinoTimerPickerMode.hm,
                  initialTimerDuration: tempDuration,
                  onTimerDurationChanged: (Duration newDuration) {
                    tempDuration = newDuration;
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(tempDuration);
                },
                child: const Text('Set Interval'),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedInterval = picked;
      });
    }
  }

  Future<void> _setPhoneNumber() async {
    final TextEditingController tempController = TextEditingController(text: _emergencyPhone);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Emergency Phone Number'),
        content: TextField(
          controller: tempController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(hintText: 'Enter phone number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => _emergencyPhone = tempController.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _startMonitoring() {
    if (_selectedInterval == null || _emergencyPhone == null || _emergencyPhone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set interval and phone number')),
      );
      return;
    }

    emergencyService = EmergencyService(
      intervalMinutes: _selectedInterval!.inMinutes,
      emergencyPhone: _emergencyPhone!,
      showEmergencyPopup: _showEmergencyPopup,
    );
    emergencyService!.startMonitoring();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Monitoring started")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF0F8F7),
          appBar: AppBar(
            title: const Text('Emergency Monitor'),
            backgroundColor: const Color(0xFF26A69A),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Colors.white,
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      _emergencyPhone == null || _emergencyPhone!.isEmpty
                          ? 'No phone number set'
                          : 'Phone: $_emergencyPhone',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _setPhoneNumber,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Colors.white,
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      _selectedInterval == null
                          ? 'No interval set'
                          : 'Interval: ${_selectedInterval!.inMinutes} min',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: _pickInterval,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _startMonitoring,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        child: const Text('Start Monitoring'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => emergencyService?.userResponded(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                        child: const Text('I am Okay'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => emergencyService?.triggerEmergency(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Trigger Alarm Now'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              await _setPhoneNumber();
              await _pickInterval();
            },
            tooltip: 'Edit Settings',
            backgroundColor: const Color(0xFF26A69A),
            child: const Icon(Icons.edit),
          ),
        ),
        if (_showEmergencyOverlay)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: Container(
                color: Colors.black.withOpacity(0.4),
                alignment: Alignment.center,
                child: Card(
                  elevation: 8,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.warning, color: Colors.red, size: 48),
                        SizedBox(height: 16),
                        Text(
                          'Calling 108 & Sharing Location…',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
