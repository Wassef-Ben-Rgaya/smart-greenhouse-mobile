import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/kpi_service.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KPIService(),
      child: Consumer<KPIService>(
        builder: (context, kpiService, child) {
          if (kpiService.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
              floatingActionButton: _RefreshButton(),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
            );
          }

          if (kpiService.error != null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      kpiService.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => kpiService.fetchKPIs(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              floatingActionButton: const _RefreshButton(),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
            );
          }

          final kpi = kpiService.kpi;
          if (kpi == null) {
            return const Scaffold(
              body: Center(child: Text('No data available')),
              floatingActionButton: _RefreshButton(),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
            );
          }

          return Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildKPICard(
                    context,
                    'Average Temperature (Last Hour)',
                    '${kpi.avgTemperature.toStringAsFixed(1)} °C',
                    Icons.thermostat,
                    Colors.blue,
                    explanation:
                        'Average temperature recorded in the greenhouse during the last hour.',
                  ),
                  _buildKPICard(
                    context,
                    'Average Humidity (Last Hour)',
                    '${kpi.avgHumidity.toStringAsFixed(1)} %',
                    Icons.opacity,
                    Colors.green,
                    explanation:
                        'Average humidity measured in the greenhouse during the last hour.',
                  ),
                  _buildKPICard(
                    context,
                    'Average Luminosity (Last Hour)',
                    '${kpi.avgLuminosity.toStringAsFixed(0)} lux',
                    Icons.light_mode,
                    Colors.orange,
                    explanation:
                        'Average luminosity detected in the greenhouse during the last hour.',
                  ),
                  _buildKPICard(
                    context,
                    'Soil Moisture (Current)',
                    kpi.soilHumidity == 1 ? 'Wet' : 'Dry',
                    Icons.grass,
                    Colors.brown,
                    explanation:
                        'Current soil state: "Wet" if water is present, otherwise "Dry".',
                  ),
                  _buildKPICard(
                    context,
                    'Lighting Duration (Today)',
                    '${kpi.lampDuration.toStringAsFixed(2)} h',
                    Icons.lightbulb,
                    Colors.yellow,
                    explanation: 'Total lamp activation time today (in hours).',
                  ),
                  _buildKPICard(
                    context,
                    'Ventilation Duration (Today)',
                    '${kpi.ventilationDuration.toStringAsFixed(2)} h',
                    Icons.air,
                    Colors.cyan,
                    explanation: 'Total fan usage time today (in hours).',
                  ),
                  _buildKPICard(
                    context,
                    'Heating Duration (Today)',
                    '${kpi.heatingDuration.toStringAsFixed(2)} h',
                    Icons.local_fire_department,
                    Colors.red,
                    explanation:
                        'Total heater operation time today (in hours).',
                  ),
                  _buildKPICard(
                    context,
                    'Watering Duration (Today)',
                    '${kpi.pumpDuration.toStringAsFixed(2)} h',
                    Icons.water_drop,
                    Colors.blueGrey,
                    explanation:
                        'Total watering pump operation time today (in hours).',
                  ),
                  _buildKPICard(
                    context,
                    'Total Water Volume (Monthly)',
                    '${kpi.totalWaterVolume.toStringAsFixed(2)} L',
                    Icons.opacity,
                    Colors.teal,
                    explanation:
                        'Total water volume used for watering this month (in liters).',
                  ),
                  _buildKPICard(
                    context,
                    'Average Watering Interval',
                    '${kpi.avgWateringInterval.toStringAsFixed(2)} h',
                    Icons.timer,
                    Colors.purple,
                    explanation:
                        'Average time elapsed between two waterings (in hours).',
                  ),
                  _buildKPICard(
                    context,
                    'Energy Consumption (Monthly)',
                    '${kpi.energyConsumption.toStringAsFixed(2)} kWh',
                    Icons.bolt,
                    Colors.red,
                    explanation:
                        'Total energy consumption of all equipment this month (in kWh).',
                  ),
                  _buildKPICard(
                    context,
                    'Manual Interventions',
                    '${kpi.manualInterventionCount}',
                    Icons.handshake,
                    Colors.amber,
                    explanation:
                        'Number of manual interventions triggered in the last hour.',
                  ),
                  _buildKPICard(
                    context,
                    'Light Efficiency (Today)',
                    kpi.lightEfficiency.toStringAsFixed(2),
                    Icons.lightbulb_outline,
                    Colors.yellow,
                    explanation:
                        'Ratio of artificial lighting duration to estimated light requirement.',
                  ),
                  _buildKPICard(
                    context,
                    'Sunlight Duration (Today)',
                    '${kpi.sunlightDuration.toStringAsFixed(2)} h',
                    Icons.wb_sunny,
                    Colors.orange,
                    explanation:
                        'Time during which natural light exceeded 800 lux today.',
                  ),
                  _buildKPICard(
                    context,
                    'Low Light Duration (Today)',
                    '${kpi.lowLightDuration.toStringAsFixed(2)} h',
                    Icons.brightness_low,
                    Colors.grey,
                    explanation:
                        'Total duration when luminosity was below 800 lux.',
                  ),
                  const SizedBox(height: 20),
                  _buildInfoCard('Last Update', kpi.updatedAt ?? 'N/A'),
                ],
              ),
            ),
            floatingActionButton: Stack(
              children: [
                // Refresh Button
                const Positioned(
                  bottom: 16,
                  right: 16,
                  child: _RefreshButton(),
                ),
                // History Button (unchanged, as it was commented out)
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKPICard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? explanation,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16.5)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (explanation != null)
                        IconButton(
                          icon: const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text(title),
                                    content: Text(explanation),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                            );
                          },
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

  Widget _buildInfoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.info, size: 40, color: Colors.grey),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16)),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        final kpiService = Provider.of<KPIService>(context, listen: false);
        kpiService.fetchKPIs();
      },
      tooltip: 'Refresh',
      child: const Icon(Icons.refresh),
    );
  }
}
