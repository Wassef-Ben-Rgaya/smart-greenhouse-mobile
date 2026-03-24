import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'dart:convert';

class ManualControlScreen extends StatefulWidget {
  const ManualControlScreen({super.key});

  @override
  State<ManualControlScreen> createState() => _ManualControlScreenState();
}

class _ManualControlScreenState extends State<ManualControlScreen> {
  final String _baseUrl =
      'https://backend-serre-intelligente.onrender.com/api/actionneurs';
  final Color _activeColor = const Color.fromARGB(255, 76, 175, 80);

  bool pompe = false;
  bool ventilateur = false;
  bool chauffage = false;
  bool lampe = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActionneurs();
  }

  Future<void> _fetchActionneurs() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pompe = data['pompe'] ?? false;
          ventilateur = data['ventilateur'] ?? false;
          chauffage = data['chauffage'] ?? false;
          lampe = data['lampe'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching actuators: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateActionneur(String name, bool value) async {
    setState(() {
      if (name == 'pompe') pompe = value;
      if (name == 'ventilateur') ventilateur = value;
      if (name == 'chauffage') chauffage = value;
      if (name == 'lampe') lampe = value;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'value': value}),
      );

      if (response.statusCode != 200) {
        print('HTTP Error: ${response.statusCode} - ${response.body}');
        throw Exception(
          'Failed to update: ${response.statusCode} - ${response.body}',
        );
      } else {
        print('Success: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error updating: $e');
      setState(() {
        if (name == 'pompe') pompe = !value;
        if (name == 'ventilateur') ventilateur = !value;
        if (name == 'chauffage') chauffage = !value;
        if (name == 'lampe') lampe = !value;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating $name: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionneurCard(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    String lottiePath,
    Color iconColor,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: Lottie.asset(
                lottiePath,
                animate: value,
                repeat: value,
                frameRate: FrameRate(30),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value ? 'ON' : 'OFF',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: value ? _activeColor : Colors.red, // OFF in red
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: _activeColor,
              activeTrackColor: _activeColor.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildActionneurCard(
                'Water Pump',
                pompe,
                (value) => _updateActionneur('pompe', value),
                'assets/animations/water_pump.json',
                Colors.blue,
              ),
              _buildActionneurCard(
                'Fan',
                ventilateur,
                (value) => _updateActionneur('ventilateur', value),
                'assets/animations/fan.json',
                Colors.green,
              ),
              _buildActionneurCard(
                'Heater',
                chauffage,
                (value) => _updateActionneur('chauffage', value),
                'assets/animations/heater.json',
                Colors.red,
              ),
              _buildActionneurCard(
                'Lamp',
                lampe,
                (value) => _updateActionneur('lampe', value),
                'assets/animations/lightbulb.json',
                Colors.yellow[700]!,
              ),
            ],
          ),
        );
  }
}
