import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

  @override
  void dispose() {
    phoneController.dispose();
    emergencyService?.dispose();
    super.dispose();
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
    final TextEditingController tempController =
        TextEditingController(text: _emergencyPhone);
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _emergencyPhone = tempController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _startMonitoring() {
    if (_selectedInterval == null ||
        _emergencyPhone == null ||
        _emergencyPhone!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set interval and phone number')),
      );
      return;
    }

    emergencyService = EmergencyService(
      intervalMinutes: _selectedInterval!.inMinutes,
      emergencyPhone: _emergencyPhone!,
      onEmergencyTriggered: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("📞 Calling 108 and 📍 Location shared"),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
    );
    emergencyService!.startMonitoring();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Monitoring started")),
    );
  }

  @override
  Widget build(BuildContext context) {
    const lavender = Color(0xFFE6D6FA);
    const purple = Color.fromARGB(255, 147, 91, 237);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Emergency Monitor'),
        backgroundColor: purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: lavender,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  _emergencyPhone == null || _emergencyPhone!.isEmpty
                      ? 'No phone number set'
                      : 'Phone: $_emergencyPhone',
                  style: const TextStyle(color: Colors.black),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  onPressed: _setPhoneNumber,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: lavender,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  _selectedInterval == null
                      ? 'No interval set'
                      : 'Interval: ${_selectedInterval!.inMinutes} min',
                  style: const TextStyle(color: Colors.black),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time, color: Colors.black),
                  onPressed: _pickInterval,
                ),
              ),
            ),
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: _startMonitoring,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(color: Colors.white),
                      ),
                      child: const Text('Start Monitoring',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => emergencyService?.userResponded(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('I am Okay',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width:200,
                    child: ElevatedButton(
                      onPressed: () => emergencyService?.triggerEmergency(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Trigger Alarm Now',
                          style: TextStyle(color: Colors.white)),
                    ),
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
        backgroundColor: purple,
        child: const Icon(Icons.edit),
      ),
    );
  }
}
