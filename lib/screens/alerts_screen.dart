import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../components/app_bar/gradient_app_bar.dart' show GradientAppBar;
import '../models/alert.dart';
import '../models/user.dart';
import '../models/plant.dart';
import '../services/alert_service.dart';
import '../services/plant_service.dart';
import '../widgets/custom_drawer.dart' show CustomDrawer;

class AlertCard extends StatelessWidget {
  final Alert alert;
  final String plantName;
  final VoidCallback onTap;
  final VoidCallback onUpdateStatus;
  final VoidCallback onDelete;
  final Color cardColor;
  final IconData typeIcon;
  final Color severityColor;

  const AlertCard({
    super.key,
    required this.alert,
    required this.plantName,
    required this.onTap,
    required this.onUpdateStatus,
    required this.onDelete,
    required this.cardColor,
    required this.typeIcon,
    required this.severityColor,
  });

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text.isEmpty ? 'Not Specified' : text,
            style: TextStyle(color: color ?? Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }

  // New method to translate alert type to a readable text
  String _getAlertTypeDisplayName(String type) {
    switch (type) {
      case 'temperature_high':
      case 'temperature_low':
        return 'TEMPERATURE OUT OF RANGE';
      case 'humidity_high':
      case 'humidity_low':
        return 'HUMIDITY OUT OF RANGE';
      case 'light_low':
        return 'LUMINOSITY OUT OF RANGE';
      case 'soil_humidity':
        return 'SOIL MOISTURE OUT OF RANGE';
      default:
        return 'UNKNOWN ALERT';
    }
  }

  // New method to extract min and max from optimal range
  (double min, double max) _parseOptimalRange(String range) {
    final parts = range.split('-');
    if (parts.length != 2) {
      return (0.0, 0.0); // Default values if format is incorrect
    }
    final min = double.tryParse(parts[0]) ?? 0.0;
    final max = double.tryParse(parts[1]) ?? 0.0;
    return (min, max);
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = alert.status == 'resolved';

    // Get translated alert type
    final alertType = _getAlertTypeDisplayName(alert.type);

    // Format value with two decimals
    final valueStr =
        alert.value != null ? alert.value!.toStringAsFixed(2) : 'Not Specified';

    // Extract min and max from optimal range
    final (min, max) = _parseOptimalRange(alert.optimalRange);

    // Create two-line title
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          alertType,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isResolved ? Colors.grey[800] : Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$valueStr (min: ${min.toStringAsFixed(2)}, max: ${max.toStringAsFixed(2)})',
          style: TextStyle(
            fontSize: 14,
            color: isResolved ? Colors.grey[800] : Colors.white70,
          ),
        ),
      ],
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isResolved ? Colors.grey[200] : cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    typeIcon,
                    color: isResolved ? Colors.grey : Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: titleWidget, // Use the new title widget
                  ),
                  if (!isResolved)
                    Chip(
                      backgroundColor: severityColor,
                      label: Text(
                        alert.severity.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (isResolved)
                    Chip(
                      backgroundColor: Colors.green[100],
                      label: Text(
                        'RESOLVED',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.local_florist,
                alert.plantId != null
                    ? 'Plant: $plantName'
                    : 'Aggregated thresholds (all plants)',
                color: isResolved ? Colors.grey[600] : Colors.white70,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.access_time,
                _formatDate(alert.timestamp),
                color: isResolved ? Colors.grey[600] : Colors.white70,
              ),
              if (alert.value != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.show_chart,
                  'Measured Value: ${alert.value!.toStringAsFixed(2)}', // Format with two decimals
                  color: isResolved ? Colors.grey[600] : Colors.white70,
                ),
              ],
              if (alert.threshold != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.timeline,
                  'Threshold: ${alert.threshold!.toStringAsFixed(2)}', // Format with two decimals
                  color: isResolved ? Colors.grey[600] : Colors.white70,
                ),
              ],
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.linear_scale,
                'Optimal Range: ${alert.optimalRange}',
                color: isResolved ? Colors.grey[600] : Colors.white70,
              ),
              if (alert.resolvedAt != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.check_circle,
                  'Resolved On: ${_formatDate(alert.resolvedAt!)}',
                  color: Colors.green,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      isResolved ? Icons.undo : Icons.check,
                      color: isResolved ? Colors.grey : Colors.white,
                    ),
                    onPressed: onUpdateStatus,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: isResolved ? Colors.grey : Colors.white,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  AlertsScreenState createState() => AlertsScreenState();
}

class AlertsScreenState extends State<AlertsScreen> {
  final AlertService _alertService = AlertService();
  final PlantService _plantService = PlantService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, Plant> _plantLookup = {};
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _selectedStatus;
  String _sortBy = 'timestamp';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final plants = await _plantService.getPlants();
      setState(() {
        _plantLookup = {for (var plant in plants) plant.id!: plant};
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<String> _getPlantDisplayName(Alert alert) async {
    debugPrint(
      'Retrieving plant name for alert: ${alert.id}, plantId: ${alert.plantId}',
    );
    if (alert.plantName.isNotEmpty && alert.plantName != 'Unknown Plant') {
      final looksLikeId = RegExp(
        r'^Plant [A-Za-z0-9]{20,}$',
      ).hasMatch(alert.plantName);
      if (!looksLikeId) {
        return alert.plantScientificName?.isNotEmpty ?? false
            ? '${alert.plantName} (${alert.plantScientificName})'
            : alert.plantName;
      }
    }

    if (alert.plantId == null || alert.plantId!.isEmpty) {
      debugPrint('No plantId for the alert, returning "Unknown Plant"');
      return 'Unknown Plant';
    }

    try {
      String? actualPlantId;
      final envDoc =
          await _firestore
              .collection('environnements')
              .doc(alert.plantId)
              .get();
      if (envDoc.exists) {
        actualPlantId = envDoc.data()!['plantId'] as String?;
        debugPrint('Environment found, associated plantId: $actualPlantId');
      } else {
        actualPlantId = alert.plantId;
        debugPrint('No environment found, using plantId: $actualPlantId');
      }

      if (actualPlantId == null) {
        debugPrint('No associated plantId found');
        return 'Unknown Plant';
      }

      final plant = _plantLookup[actualPlantId];
      if (plant != null &&
          plant.nom.isNotEmpty &&
          plant.nom != 'Unknown Plant') {
        debugPrint('Plant found in lookup: ${plant.nom}');
        return plant.nomScientifique.isNotEmpty
            ? '${plant.nom} (${plant.nomScientifique})'
            : plant.nom;
      }

      final plantDoc =
          await _firestore.collection('plants').doc(actualPlantId).get();
      if (plantDoc.exists) {
        final plantData = plantDoc.data()!;
        final nom =
            plantData['nom']?.isNotEmpty == true
                ? plantData['nom']
                : 'Unknown Plant';
        final nomScientifique = plantData['nomScientifique'] as String? ?? '';
        debugPrint('Plant found in Firestore: $nom ($nomScientifique)');
        return nomScientifique.isNotEmpty ? '$nom ($nomScientifique)' : nom;
      }
      debugPrint('No plant found for plantId: $actualPlantId');
      return 'Unknown Plant';
    } catch (e) {
      debugPrint('Error retrieving plant name: $e');
      return 'Unknown Plant';
    }
  }

  Future<void> _updateAlertStatus(String id, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Modification'),
            content: Text(
              status == 'resolved'
                  ? 'Do you want to mark this alert as resolved?'
                  : 'Do you want to reactivate this alert?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _alertService.updateAlertStatus(id, status);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alert status updated')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  Future<void> _deleteAlert(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Do you want to delete this alert?'),
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

    if (confirmed != true) return;

    try {
      await _alertService.deleteAlert(id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alert deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting alert: $e')));
    }
  }

  Future<void> _resolveAllActiveAlerts() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Resolve All Alerts'),
            content: const Text(
              'Do you want to mark all active alerts as resolved?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final snapshot =
          await _firestore
              .collection('alerts')
              .where('status', isEqualTo: 'active')
              .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active alerts to resolve')),
        );
        return;
      }

      for (var doc in snapshot.docs) {
        await _alertService.updateAlertStatus(doc.id, 'resolved');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${snapshot.docs.length} alert(s) resolved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error during resolution: $e')));
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.yellow;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'temperature_high':
      case 'temperature_low':
        return Icons.thermostat;
      case 'humidity_high':
      case 'humidity_low':
        return Icons.water_drop;
      case 'light_low':
        return Icons.wb_sunny;
      case 'soil_humidity':
        return Icons.grass;
      default:
        return Icons.warning;
    }
  }

  Color _getCardColor(Alert alert) {
    if (alert.status == 'resolved') return const Color(0xFF35A043);
    switch (alert.severity) {
      case 'critical':
        return const Color(0xFFD32F2F);
      case 'high':
        return const Color(0xFFF57C00);
      case 'medium':
        return const Color(0xFF1976D2);
      case 'low':
        return const Color(0xFF388E3C);
      default:
        return const Color(0xFF424242);
    }
  }

  Future<void> _showStatsDialog() async {
    try {
      final stats = await _alertService.getAlertStats();
      if (!mounted) return;

      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Alert Statistics'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem('Total', stats['total'].toString()),
                  _buildStatItem('Active', stats['active'].toString()),
                  _buildStatItem('Resolved', stats['resolved'].toString()),
                  const SizedBox(height: 16),
                  const Text(
                    'By Severity:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildStatItem(
                    'Critical',
                    stats['bySeverity']['critical'].toString(),
                  ),
                  _buildStatItem(
                    'High',
                    stats['bySeverity']['high'].toString(),
                  ),
                  _buildStatItem(
                    'Medium',
                    stats['bySeverity']['medium'].toString(),
                  ),
                  _buildStatItem('Low', stats['bySeverity']['low'].toString()),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading statistics: $e')));
    }
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _showCreateAlertDialog() async {
    String type = 'temperature_high';
    String message = '';
    Plant? selectedPlant;
    String severity = 'medium';
    String optimalRange = 'N/A';
    double? value;
    double? threshold;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Alert'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(
                          value: 'temperature_high',
                          child: Text('High Temperature'),
                        ),
                        DropdownMenuItem(
                          value: 'temperature_low',
                          child: Text('Low Temperature'),
                        ),
                        DropdownMenuItem(
                          value: 'humidity_high',
                          child: Text('High Humidity'),
                        ),
                        DropdownMenuItem(
                          value: 'humidity_low',
                          child: Text('Low Humidity'),
                        ),
                        DropdownMenuItem(
                          value: 'light_low',
                          child: Text('Low Luminosity'),
                        ),
                        DropdownMenuItem(
                          value: 'soil_humidity',
                          child: Text('Soil Moisture'),
                        ),
                      ],
                      onChanged: (value) => setState(() => type = value!),
                      decoration: const InputDecoration(
                        labelText: 'Alert Type',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Message'),
                      onChanged: (value) => message = value,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Plant>(
                      value: selectedPlant,
                      items:
                          _plantLookup.isEmpty
                              ? [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('No Plants Available'),
                                ),
                              ]
                              : _plantLookup.values.map((plant) {
                                return DropdownMenuItem(
                                  value: plant,
                                  child: Text(
                                    plant.nom.isNotEmpty
                                        ? '${plant.nom} (${plant.nomScientifique})'
                                        : 'Unknown Plant',
                                  ),
                                );
                              }).toList(),
                      onChanged:
                          (value) => setState(() => selectedPlant = value),
                      decoration: const InputDecoration(labelText: 'Plant'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Value (optional)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged:
                          (val) =>
                              value = val.isEmpty ? null : double.tryParse(val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Threshold (optional)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged:
                          (val) =>
                              threshold =
                                  val.isEmpty ? null : double.tryParse(val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Optimal Range',
                      ),
                      onChanged: (value) => optimalRange = value,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: severity,
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(
                          value: 'critical',
                          child: Text('Critical'),
                        ),
                      ],
                      onChanged: (value) => setState(() => severity = value!),
                      decoration: const InputDecoration(labelText: 'Severity'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (message.isEmpty || selectedPlant == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message and plant required'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || !mounted) return;

    try {
      final alert = Alert(
        id: '',
        type: type,
        message: message,
        status: 'active',
        timestamp: DateTime.now(),
        plantId: selectedPlant?.id,
        plantName: selectedPlant!.nom,
        plantScientificName: selectedPlant!.nomScientifique,
        severity: severity,
        value: value,
        threshold: threshold,
        optimalRange: optimalRange,
      );

      await _alertService.createAlert(alert);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alert created')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating alert: $e')));
    }
  }

  Future<void> _showFilterDialog() async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filter Alerts'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Alerts')),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text('Active Only'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resolved Only'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _selectedStatus = value),
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(
                      value: 'timestamp',
                      child: Text('Date (most recent first)'),
                    ),
                    DropdownMenuItem(
                      value: 'severity',
                      child: Text('Severity (critical first)'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _sortBy = value!),
                  decoration: const InputDecoration(labelText: 'Sort By'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }

  void _showAlertDetails(Alert alert, String plantName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _getCardColor(alert),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Alert Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailItem('Type', alert.type.split('_').last.capitalize()),
              _buildDetailItem('Plant', plantName),
              _buildDetailItem(
                'Date',
                '${alert.timestamp.month}/${alert.timestamp.day}/${alert.timestamp.year} ${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
              ),
              _buildDetailItem('Severity', alert.severity.capitalize()),
              if (alert.value != null)
                _buildDetailItem(
                  'Value',
                  alert.value!.toStringAsFixed(2),
                ), // Format with two decimals
              if (alert.threshold != null)
                _buildDetailItem(
                  'Threshold',
                  alert.threshold!.toStringAsFixed(2),
                ), // Format with two decimals
              _buildDetailItem('Optimal Range', alert.optimalRange),
              if (alert.resolvedAt != null)
                _buildDetailItem(
                  'Resolved On',
                  '${alert.resolvedAt!.month}/${alert.resolvedAt!.day}/${alert.resolvedAt!.year} ${alert.resolvedAt!.hour}:${alert.resolvedAt!.minute.toString().padLeft(2, '0')}',
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _getCardColor(alert),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not Specified' : value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserModel user =
        ModalRoute.of(context)!.settings.arguments as UserModel;

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Alerts',
        actions: [
          IconButton(
            icon:
                _isRefreshing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : () => _loadData(isRefresh: true),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _showStatsDialog,
            tooltip: 'Statistics',
          ),
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: _resolveAllActiveAlerts,
            tooltip: 'Resolve All Active Alerts',
          ),
        ],
      ),
      drawer: CustomDrawer(user: user),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                stream:
                    _selectedStatus == null
                        ? _firestore
                            .collection('alerts')
                            .orderBy('timestamp', descending: true)
                            .limit(50)
                            .snapshots()
                        : _firestore
                            .collection('alerts')
                            .where('status', isEqualTo: _selectedStatus)
                            .orderBy('timestamp', descending: true)
                            .limit(50)
                            .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final alerts =
                      snapshot.data!.docs
                          .map(
                            (doc) => Alert.fromJson({
                              ...doc.data() as Map<String, dynamic>,
                              'id': doc.id,
                            }),
                          )
                          .toList();

                  if (alerts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Alerts Found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  alerts.sort((a, b) {
                    if (_sortBy == 'severity') {
                      const severityOrder = {
                        'critical': 0,
                        'high': 1,
                        'medium': 2,
                        'low': 3,
                      };
                      return severityOrder[a.severity]!.compareTo(
                        severityOrder[b.severity]!,
                      );
                    }
                    return b.timestamp.compareTo(a.timestamp);
                  });

                  return RefreshIndicator(
                    onRefresh: () => _loadData(isRefresh: true),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return FutureBuilder<String>(
                          future: _getPlantDisplayName(alert),
                          builder: (context, snapshot) {
                            final plantName = snapshot.data ?? 'Loading...';
                            return AlertCard(
                              alert: alert,
                              plantName: plantName,
                              onTap: () => _showAlertDetails(alert, plantName),
                              onUpdateStatus:
                                  () => _updateAlertStatus(
                                    alert.id,
                                    alert.status == 'active'
                                        ? 'resolved'
                                        : 'active',
                                  ),
                              onDelete: () => _deleteAlert(alert.id),
                              cardColor: _getCardColor(alert),
                              typeIcon: _getTypeIcon(alert.type),
                              severityColor: _getSeverityColor(alert.severity),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAlertDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
