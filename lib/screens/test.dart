import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import '../widgets/custom_drawer.dart';
import '../models/user.dart';
import '../models/measurement.dart';
import '../services/measurement_service.dart';
import '../services/alert_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _baseUrl = 'http://192.168.1.50:5000/api/actionneurs';
  final MeasurementService _measurementService = MeasurementService();
  final AlertService _alertService = AlertService();
  final Color _primaryColor = const Color.fromARGB(255, 57, 157, 61);
  final Color _activeColor = const Color.fromARGB(255, 76, 175, 80);
  final Color _inactiveColor = Colors.grey;

  // État des actionneurs
  bool pompe = false;
  bool ventilateur = false;
  bool chauffage = false;
  bool lampe = false;

  // Dernière mesure
  Measurement? _latestMeasurement;
  bool _isLoading = true;
  bool _hasAlert = false;

  @override
  void initState() {
    super.initState();
    _fetchActionneurs();
    _fetchLatestMeasurement();
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
        });
      }
    } catch (e) {
      print('Erreur de récupération des actionneurs: $e');
    }
  }

  Future<void> _fetchLatestMeasurement() async {
    try {
      final measurements = await _measurementService.getMeasurements(limit: 1);
      if (measurements.isNotEmpty) {
        // Vérifier s'il y a une alerte pour cette mesure
        final alerts = await _alertService.getAlertsForMeasurements([
          measurements.first.id!,
        ]);
        final hasAlert = alerts.any((alert) => alert.status == 'active');

        setState(() {
          _latestMeasurement = measurements.first;
          _hasAlert = hasAlert;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Erreur de récupération des mesures: $e');
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
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      print('Erreur de mise à jour: $e');
      // Annuler les changements en cas d'échec
      setState(() {
        if (name == 'pompe') pompe = !value;
        if (name == 'ventilateur') ventilateur = !value;
        if (name == 'chauffage') chauffage = !value;
        if (name == 'lampe') lampe = !value;
      });
    }
  }

  Widget _buildActionneurCard(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    String lottiePath,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: value ? _activeColor : _inactiveColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Lottie.asset(
                lottiePath,
                animate: value,
                repeat: value,
                frameRate: FrameRate(30),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: value ? _activeColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ? 'Activé' : 'Désactivé',
                    style: TextStyle(
                      color: value ? _activeColor : _inactiveColor,
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
    final UserModel user =
        ModalRoute.of(context)!.settings.arguments as UserModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: _primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      drawer: CustomDrawer(user: user),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // En-tête
                    Card(
                      color: _primaryColor.withOpacity(0.1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Bienvenue, ${user.firstName ?? ''}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Statut actuel de votre serre',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dernière mesure (style identique à MeasurementsScreen)
                    if (_latestMeasurement != null) ...[
                      Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDateTime(_latestMeasurement!.time),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  // Indicateur Normale/Alerte
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _hasAlert
                                              ? Colors.orange[50]
                                              : Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            _hasAlert
                                                ? Colors.orange
                                                : Colors.green,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _hasAlert
                                              ? Icons.warning
                                              : Icons.check_circle,
                                          size: 16,
                                          color:
                                              _hasAlert
                                                  ? Colors.orange
                                                  : Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _hasAlert ? 'Alerte' : 'Normale',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                _hasAlert
                                                    ? Colors.orange
                                                    : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                childAspectRatio: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                children: [
                                  if (_latestMeasurement!.temperature != null)
                                    _buildMeasurementTile(
                                      icon: Icons.thermostat,
                                      label: 'Température',
                                      value:
                                          '${_latestMeasurement!.temperature!.toStringAsFixed(1)}°C',
                                      color: _getTemperatureColor(
                                        _latestMeasurement!.temperature!,
                                      ),
                                    ),
                                  if (_latestMeasurement!.humidite != null)
                                    _buildMeasurementTile(
                                      icon: Icons.opacity,
                                      label: 'Humidité air',
                                      value:
                                          '${_latestMeasurement!.humidite!.toStringAsFixed(1)}%',
                                      color: _getHumidityColor(
                                        _latestMeasurement!.humidite!,
                                      ),
                                    ),
                                  if (_latestMeasurement!.humiditeSol != null)
                                    _buildMeasurementTile(
                                      icon: Icons.water_drop,
                                      label: 'Humidité sol',
                                      value:
                                          _latestMeasurement!.humiditeSol == 1.0
                                              ? 'Humide'
                                              : 'Sec',
                                      color:
                                          _latestMeasurement!.humiditeSol == 1.0
                                              ? const Color(0xFF2196F3)
                                              : const Color(0xFFEF6C00),
                                    ),
                                  if (_latestMeasurement!.luminosite != null)
                                    _buildMeasurementTile(
                                      icon: Icons.light_mode,
                                      label: 'Luminosité',
                                      value:
                                          '${_latestMeasurement!.luminosite!.toStringAsFixed(0)} lux',
                                      color: _getLightColor(
                                        _latestMeasurement!.luminosite!,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Section actionneurs
                    const Text(
                      'Commandes manuelles',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionneurCard('Pompe à eau', pompe, (value) {
                      _updateActionneur('pompe', value);
                    }, 'assets/animations/water_pump.json'),
                    _buildActionneurCard('Ventilateur', ventilateur, (value) {
                      _updateActionneur('ventilateur', value);
                    }, 'assets/animations/fan.json'),
                    _buildActionneurCard('Chauffage', chauffage, (value) {
                      _updateActionneur('chauffage', value);
                    }, 'assets/animations/heater.json'),
                    _buildActionneurCard('Lampe', lampe, (value) {
                      _updateActionneur('lampe', value);
                    }, 'assets/animations/lightbulb.json'),
                  ],
                ),
              ),
    );
  }

  Widget _buildMeasurementTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 15) return Colors.blue;
    if (temp > 30) return Colors.red;
    return Colors.orange;
  }

  Color _getHumidityColor(double humidity) {
    if (humidity < 30) return Colors.orange;
    if (humidity > 80) return Colors.blue;
    return Colors.green;
  }

  Color _getLightColor(double light) {
    if (light < 1000) return Colors.blueGrey;
    if (light > 10000) return Colors.yellow[700]!;
    return Colors.orange;
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
