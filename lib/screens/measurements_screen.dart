import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/measurement.dart';
import '../models/plant.dart';
import '../services/measurement_service.dart';
import '../services/alert_service.dart';
import '../widgets/custom_drawer.dart';
import '../models/user.dart';
import '../components/app_bar/gradient_app_bar.dart';
import 'alerts_screen.dart';
import '../services/environnement_service.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  late Future<List<Measurement>> _measurementsFuture;
  final MeasurementService _measurementService = MeasurementService();
  final AlertService _alertService = AlertService();
  final EnvironnementService _environnementService = EnvironnementService();
  final Color _primaryColor = const Color(0xFF1A781F);
  final Color _secondaryColor = const Color(0xFF43A047);
  Map<String, bool> _hasAlertMap = {};
  DateTime? _lastRefresh;
  static const int _refreshCooldownSeconds = 30;
  static const int _pageLimit = 10;

  late Future<Map<String, dynamic>> _aggregatedThresholdsFuture;

  @override
  void initState() {
    super.initState();
    _measurementsFuture = _loadMeasurements();
    _aggregatedThresholdsFuture = _loadAggregatedThresholds();
  }

  Future<Map<String, dynamic>> _loadAggregatedThresholds() async {
    try {
      debugPrint('=== Starting to load aggregated thresholds ===');
      final plantDocs =
          await FirebaseFirestore.instance.collection('plants').get();
      final plants =
          plantDocs.docs.map((doc) => Plant.fromFirestore(doc)).toList();
      debugPrint('Number of plants loaded: ${plants.length}');

      List<double> tempMins = [];
      List<double> tempMaxs = [];
      List<double> airHumMins = [];
      List<double> airHumMaxs = [];
      List<double> soilHums = [];
      List<int> lightDurations = [];
      List<String> lightTypes = [];
      List<int> lightRangeStarts = [];
      List<int> lightRangeEnds = [];

      for (var plant in plants) {
        debugPrint('Processing plant: ${plant.id}');
        final env = await _environnementService.getEnvironnementForPlant(
          plant.id!,
        );
        if (env != null) {
          debugPrint(
            'Environment loaded for ${plant.id}: ${jsonEncode(env.toJson())}',
          );
          // Temperature
          if (env.temperature.min != null) {
            tempMins.add(env.temperature.min!);
            debugPrint('Minimum temperature: ${env.temperature.min}');
          } else {
            debugPrint('Minimum temperature is null for ${plant.id}');
          }
          if (env.temperature.max != null) {
            tempMaxs.add(env.temperature.max!);
            debugPrint('Maximum temperature: ${env.temperature.max}');
          } else {
            debugPrint('Maximum temperature is null for ${plant.id}');
          }
          // Air Humidity
          if (env.humidite.air.min != null) {
            airHumMins.add(env.humidite.air.min!);
            debugPrint('Minimum air humidity: ${env.humidite.air.min}');
          } else {
            debugPrint('Minimum air humidity is null for ${plant.id}');
          }
          if (env.humidite.air.max != null) {
            airHumMaxs.add(env.humidite.air.max!);
            debugPrint('Maximum air humidity: ${env.humidite.air.max}');
          } else {
            debugPrint('Maximum air humidity is null for ${plant.id}');
          }
          // Soil Moisture
          if (env.humidite.sol != null) {
            soilHums.add(env.humidite.sol!);
            debugPrint('Soil moisture: ${env.humidite.sol}');
          } else {
            debugPrint('Soil moisture is null for ${plant.id}');
          }
          // Light
          if (env.lumiere.duree != null) {
            lightDurations.add(env.lumiere.duree!);
            debugPrint('Light duration: ${env.lumiere.duree}');
          }
          if (env.lumiere.type != null) {
            lightTypes.add(env.lumiere.type!);
            debugPrint('Light type: ${env.lumiere.type}');
          }
          lightRangeStarts.add(env.lumiere.optimalRange.start);
          lightRangeEnds.add(env.lumiere.optimalRange.end);
          debugPrint(
            'Light range: ${env.lumiere.optimalRange.start}h-${env.lumiere.optimalRange.end}h',
          );
        } else {
          debugPrint('No environment found for plant: ${plant.id}');
        }
      }

      debugPrint('Collected values:');
      debugPrint('Min temp: $tempMins');
      debugPrint('Max temp: $tempMaxs');
      debugPrint('Min air humidity: $airHumMins');
      debugPrint('Max air humidity: $airHumMaxs');
      debugPrint('Soil moisture: $soilHums');
      debugPrint('Light duration: $lightDurations');
      debugPrint('Light type: $lightTypes');
      debugPrint('Light range start: $lightRangeStarts');
      debugPrint('Light range end: $lightRangeEnds');

      double? safeMin(List<double> values) =>
          values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : null;
      double? safeMax(List<double> values) =>
          values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : null;

      final aggregatedThresholds = {
        'air': {
          'min':
              safeMax(airHumMins) ?? 50.0, // Changed to safeMax to get min = 50
          'max': safeMax(airHumMaxs) ?? 90.0,
        },
        'sol': safeMax(soilHums) ?? 1.0,
        'lumiere': {
          'duree':
              lightDurations.isNotEmpty
                  ? lightDurations.reduce((a, b) => a > b ? a : b)
                  : 10,
          'optimalRange': {
            'start':
                lightRangeStarts.isNotEmpty
                    ? lightRangeStarts.reduce((a, b) => a < b ? a : b)
                    : 8,
            'end':
                lightRangeEnds.isNotEmpty
                    ? lightRangeEnds.reduce((a, b) => a > b ? a : b)
                    : 18,
          },
          'type':
              lightTypes.isNotEmpty
                  ? lightTypes.reduce((a, b) => a == 'Full' ? a : b)
                  : 'Full',
        },
        'temperature': {
          'min': safeMin(tempMins) ?? 10.0,
          'max': safeMax(tempMaxs) ?? 27.0,
        },
      };

      debugPrint(
        'Calculated aggregated thresholds: ${jsonEncode(aggregatedThresholds)}',
      );
      return aggregatedThresholds;
    } catch (e) {
      debugPrint('Error loading aggregated thresholds: $e');
      return {
        'air': {'min': 50.0, 'max': 90.0},
        'sol': 1.0,
        'lumiere': {
          'duree': 10,
          'optimalRange': {'start': 8, 'end': 18},
          'type': 'Full',
        },
        'temperature': {'min': 10.0, 'max': 27.0},
      };
    }
  }

  Future<List<Measurement>> _loadMeasurements({
    bool forceRefresh = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastFetch = prefs.getInt('lastFetch') ?? 0;
    const cacheDuration = 5 * 60 * 1000;

    if (!forceRefresh && now - lastFetch < cacheDuration) {
      final cachedMeasurements = prefs.getString('measurements');
      final cachedAlerts = prefs.getString('alertsMap');
      if (cachedMeasurements != null && cachedAlerts != null) {
        final measurements =
            (jsonDecode(cachedMeasurements) as List)
                .map((item) => Measurement.fromJson(item, item['id']))
                .toList();
        _hasAlertMap = Map<String, bool>.from(jsonDecode(cachedAlerts));
        return measurements;
      }
    }

    final measurements = await _measurementService.getMeasurements(
      limit: _pageLimit,
    );
    final thresholds = await _aggregatedThresholdsFuture;

    for (var measurement in measurements) {
      await _alertService.checkAndCreateAlert(measurement, thresholds, null);
    }

    final hasAlertMap = await _checkForAlerts(measurements);
    _hasAlertMap
      ..clear()
      ..addAll(hasAlertMap);

    await prefs.setInt('lastFetch', now);
    await prefs.setString(
      'measurements',
      jsonEncode(measurements.map((m) => m.toJson()).toList()),
    );
    await prefs.setString('alertsMap', jsonEncode(_hasAlertMap));
    return measurements;
  }

  void _refreshMeasurements() {
    final now = DateTime.now();
    if (_lastRefresh != null &&
        now.difference(_lastRefresh!).inSeconds < _refreshCooldownSeconds) {
      return;
    }
    _lastRefresh = now;
    setState(() {
      _measurementsFuture = _loadMeasurements(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _measurementService.dispose();
    super.dispose();
  }

  Future<Map<String, bool>> _checkForAlerts(
    List<Measurement> measurements,
  ) async {
    final measurementIds =
        measurements.where((m) => m.id != null).map((m) => m.id!).toList();
    if (measurementIds.isEmpty) return {};

    try {
      final alerts = await _alertService.getAlertsForMeasurements(
        measurementIds,
      );
      final Map<String, bool> hasAlertMap = {};
      for (var measurement in measurements) {
        if (measurement.id != null) {
          final hasAlert = alerts.any(
            (alert) =>
                alert.measurementId == measurement.id &&
                alert.status == 'active',
          );
          hasAlertMap[measurement.id!] = hasAlert;
        }
      }
      return hasAlertMap;
    } catch (e) {
      debugPrint('Error checking alerts: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final UserModel user =
        ModalRoute.of(context)!.settings.arguments as UserModel;
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Greenhouse Measurements',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMeasurements,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: CustomDrawer(user: user),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: FutureBuilder<List<Measurement>>(
          future: _measurementsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Error',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshMeasurements,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.thermostat, size: 50, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No Measurements Available',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Add a measurement to start'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _showAddMeasurementDialog,
                      child: const Text('Add Measurement'),
                    ),
                  ],
                ),
              );
            } else {
              final measurements = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: measurements.length,
                itemBuilder: (context, index) {
                  final measurement = measurements[index];
                  return _buildMeasurementCard(measurement);
                },
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMeasurementDialog,
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildMeasurementCard(Measurement measurement) {
    final hasTemperature = measurement.temperature != null;
    final hasHumidity = measurement.humidite != null;
    final hasSoilHumidity = measurement.humiditeSol != null;
    final hasLuminosity = measurement.luminosite != null;
    final hasAlert = _hasAlertMap[measurement.id] ?? false;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showMeasurementDetails(measurement);
        },
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDateTime(measurement.time),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            hasAlert
                                ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const AlertsScreen(),
                                      settings: RouteSettings(
                                        arguments:
                                            ModalRoute.of(
                                              context,
                                            )!.settings.arguments,
                                      ),
                                    ),
                                  );
                                }
                                : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                hasAlert ? Colors.orange[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasAlert ? Colors.orange : Colors.green,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasAlert)
                                Lottie.asset(
                                  'assets/animations/alerts.json',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                )
                              else
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green,
                                ),
                              const SizedBox(width: 4),
                              Text(
                                hasAlert ? 'Alert' : 'Normal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      hasAlert ? Colors.orange : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      if (hasTemperature)
                        _buildMeasurementTile(
                          icon: Icons.thermostat,
                          label: 'Temperature',
                          value:
                              '${measurement.temperature!.toStringAsFixed(2)}°C',
                          color: _getTemperatureColor(measurement.temperature!),
                        ),
                      if (hasHumidity)
                        _buildMeasurementTile(
                          icon: Icons.opacity,
                          label: 'Humidity',
                          value: '${measurement.humidite!.toStringAsFixed(2)}%',
                          color: _getHumidityColor(measurement.humidite!),
                        ),
                      if (hasSoilHumidity)
                        _buildMeasurementTile(
                          icon: Icons.water_drop,
                          label: 'Soil Moisture',
                          value: measurement.humiditeSol == 1.0 ? 'Wet' : 'Dry',
                          color:
                              measurement.humiditeSol == 1.0
                                  ? const Color(0xFF2196F3)
                                  : const Color(0xFFEF6C00),
                        ),
                      if (hasLuminosity)
                        _buildMeasurementTile(
                          icon: Icons.light_mode,
                          label: 'Luminosity',
                          value:
                              '${measurement.luminosite!.toStringAsFixed(2)} lux',
                          color: _getLightColor(measurement.luminosite!),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        color: _secondaryColor,
                        onPressed: () => _showMeasurementDetails(measurement),
                        tooltip: 'Details',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        color: _secondaryColor,
                        onPressed:
                            () => _showEditMeasurementDialog(measurement),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed:
                            () => _confirmDeleteMeasurement(measurement.id!),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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

  void _showMeasurementDetails(Measurement measurement) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Details - ${_formatDate(measurement.time)}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (measurement.temperature != null)
                    _buildDetailItem(
                      'Temperature',
                      '${measurement.temperature!.toStringAsFixed(2)}°C',
                      icon: Icons.thermostat,
                      color: _getTemperatureColor(measurement.temperature!),
                    ),
                  if (measurement.humidite != null)
                    _buildDetailItem(
                      'Air Humidity',
                      '${measurement.humidite!.toStringAsFixed(2)}%',
                      icon: Icons.opacity,
                      color: _getHumidityColor(measurement.humidite!),
                    ),
                  if (measurement.humiditeSol != null)
                    _buildDetailItem(
                      'Soil Moisture',
                      measurement.humiditeSol == 1.0 ? 'Wet' : 'Dry',
                      icon: Icons.water_drop,
                      color:
                          measurement.humiditeSol == 1.0
                              ? const Color(0xFF2196F3)
                              : const Color(0xFFEF6C00),
                    ),
                  if (measurement.luminosite != null)
                    _buildDetailItem(
                      'Luminosity',
                      '${measurement.luminosite!.toStringAsFixed(2)} lux',
                      icon: Icons.light_mode,
                      color: _getLightColor(measurement.luminosite!),
                    ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildDeviceStatus(
                    'Heating',
                    measurement.chauffage ?? false,
                    icon: Icons.heat_pump,
                  ),
                  _buildDeviceStatus(
                    'Lamp',
                    measurement.lampe ?? false,
                    icon: Icons.lightbulb,
                  ),
                  _buildDeviceStatus(
                    'Pump',
                    measurement.pompe ?? false,
                    icon: Icons.invert_colors,
                  ),
                  _buildDeviceStatus(
                    'Fan',
                    measurement.ventilateur ?? false,
                    icon: Icons.air,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    IconData? icon,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatus(String label, bool isOn, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon ?? (isOn ? Icons.power : Icons.power_off),
            color: isOn ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isOn ? Colors.green[50] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOn ? Colors.green : Colors.grey,
                width: 1,
              ),
            ),
            child: Text(
              isOn ? 'ON' : 'OFF',
              style: TextStyle(
                fontSize: 12,
                color:
                    isOn ? Colors.green : const Color.fromARGB(255, 218, 0, 0),
                fontWeight: FontWeight.bold,
              ),
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
    try {
      return DateFormat('MM/dd/yyyy HH:mm:ss').format(date);
    } catch (e) {
      debugPrint('Date formatting error: $e');
      return 'Unknown Date';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  void _confirmDeleteMeasurement(String id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Do you really want to delete this measurement?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteMeasurement(id);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showAddMeasurementDialog() {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    Measurement newMeasurement = Measurement(
      time: DateTime.now(),
      id: DateTime.now().toIso8601String(),
    );

    bool soilHumidityValue = false;

    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
          final newTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
          newMeasurement = newMeasurement.copyWith(
            time: newTime,
            id: newTime.toIso8601String(),
          );
        });
      }
    }

    Future<void> selectTime(BuildContext context) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );
      if (picked != null && picked != selectedTime) {
        setState(() {
          selectedTime = picked;
          final newTime = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
          newMeasurement = newMeasurement.copyWith(
            time: newTime,
            id: newTime.toIso8601String(),
          );
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Measurement'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Date'),
                              subtitle: Text(
                                '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                              ),
                              onTap: () => selectDate(context),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              leading: const Icon(Icons.access_time),
                              title: const Text('Time'),
                              subtitle: Text(
                                '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              ),
                              onTap: () => selectTime(context),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildNumberFieldWithIcon(
                        label: 'Temperature (°C)',
                        initialValue: '',
                        onSaved:
                            (value) =>
                                newMeasurement = newMeasurement.copyWith(
                                  temperature: double.parse(value!),
                                ),
                        icon: Icons.thermostat,
                        color: _getTemperatureColor(20),
                      ),
                      _buildNumberFieldWithIcon(
                        label: 'Humidity (%)',
                        initialValue: '',
                        onSaved:
                            (value) =>
                                newMeasurement = newMeasurement.copyWith(
                                  humidite: double.parse(value!),
                                ),
                        icon: Icons.opacity,
                        color: _getHumidityColor(50),
                      ),
                      _buildNumberFieldWithIcon(
                        label: 'Luminosity (lux)',
                        initialValue: '',
                        onSaved:
                            (value) =>
                                newMeasurement = newMeasurement.copyWith(
                                  luminosite: double.parse(value!),
                                ),
                        icon: Icons.light_mode,
                        color: _getLightColor(5000),
                      ),
                      _buildSoilHumiditySwitch(
                        initialValue: soilHumidityValue,
                        onChanged: (value) {
                          setState(() {
                            soilHumidityValue = value;
                            newMeasurement = newMeasurement.copyWith(
                              humiditeSol: value ? 1.0 : 0.0,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      try {
                        await _measurementService.createMeasurement(
                          newMeasurement,
                        );
                        final thresholds = await _aggregatedThresholdsFuture;
                        await _alertService.checkAndCreateAlert(
                          newMeasurement,
                          thresholds,
                          null, // Assumes nullable plantId
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        _refreshMeasurements();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Measurement added successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditMeasurementDialog(Measurement measurement) {
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = measurement.time;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(measurement.time);

    Measurement editedMeasurement = measurement.copyWith();
    bool soilHumidityValue = measurement.humiditeSol == 1.0;

    Future<void> selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
          editedMeasurement = editedMeasurement.copyWith(
            time: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            ),
          );
        });
      }
    }

    Future<void> selectTime(BuildContext context) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );
      if (picked != null && picked != selectedTime) {
        setState(() {
          selectedTime = picked;
          editedMeasurement = editedMeasurement.copyWith(
            time: DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            ),
          );
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Measurement'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Date'),
                              subtitle: Text(
                                '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                              ),
                              onTap: () => selectDate(context),
                            ),
                          ),
                          Expanded(
                            child: ListTile(
                              leading: const Icon(Icons.access_time),
                              title: const Text('Time'),
                              subtitle: Text(
                                '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                              ),
                              onTap: () => selectTime(context),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildNumberFieldWithIcon(
                        label: 'Temperature (°C)',
                        initialValue:
                            editedMeasurement.temperature?.toStringAsFixed(2) ??
                            '',
                        onSaved:
                            (value) =>
                                editedMeasurement = editedMeasurement.copyWith(
                                  temperature: double.parse(value!),
                                ),
                        icon: Icons.thermostat,
                        color: _getTemperatureColor(
                          editedMeasurement.temperature ?? 20,
                        ),
                      ),
                      _buildNumberFieldWithIcon(
                        label: 'Humidity (%)',
                        initialValue:
                            editedMeasurement.humidite?.toStringAsFixed(2) ??
                            '',
                        onSaved:
                            (value) =>
                                editedMeasurement = editedMeasurement.copyWith(
                                  humidite: double.parse(value!),
                                ),
                        icon: Icons.opacity,
                        color: _getHumidityColor(
                          editedMeasurement.humidite ?? 50,
                        ),
                      ),
                      _buildNumberFieldWithIcon(
                        label: 'Luminosity (lux)',
                        initialValue:
                            editedMeasurement.luminosite?.toStringAsFixed(2) ??
                            '',
                        onSaved:
                            (value) =>
                                editedMeasurement = editedMeasurement.copyWith(
                                  luminosite: double.parse(value!),
                                ),
                        icon: Icons.light_mode,
                        color: _getLightColor(
                          editedMeasurement.luminosite ?? 5000,
                        ),
                      ),
                      _buildSoilHumiditySwitch(
                        initialValue: soilHumidityValue,
                        onChanged: (value) {
                          setState(() {
                            soilHumidityValue = value;
                            editedMeasurement = editedMeasurement.copyWith(
                              humiditeSol: value ? 1.0 : 0.0,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      try {
                        await _measurementService.updateMeasurement(
                          editedMeasurement,
                        );
                        final thresholds = await _aggregatedThresholdsFuture;
                        await _alertService.checkAndCreateAlert(
                          editedMeasurement,
                          thresholds,
                          null, // Assumes nullable plantId
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        _refreshMeasurements();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Measurement updated successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSoilHumiditySwitch({
    required bool initialValue,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          const Text('Soil Moisture', style: TextStyle(fontSize: 16)),
          const Spacer(),
          Text(
            initialValue ? 'Wet' : 'Dry',
            style: TextStyle(
              color:
                  initialValue
                      ? const Color(0xFF2196F3)
                      : const Color(0xFFEF6C00),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: initialValue,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberFieldWithIcon({
    required String label,
    required String initialValue,
    required FormFieldSetter<String> onSaved,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              initialValue: initialValue,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                final numValue = double.tryParse(value);
                if (numValue == null) {
                  return 'Please enter a valid number';
                }
                if (label.contains('Humidity') &&
                    (numValue < 0 || numValue > 100)) {
                  return 'Must be between 0 and 100';
                }
                if (label.contains('Luminosity') && numValue < 0) {
                  return 'Must be positive';
                }
                return null;
              },
              onSaved: onSaved,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMeasurement(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Do you really want to delete this measurement?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _measurementService.deleteMeasurement(id);
        if (!mounted) return;
        _refreshMeasurements();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Measurement deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
