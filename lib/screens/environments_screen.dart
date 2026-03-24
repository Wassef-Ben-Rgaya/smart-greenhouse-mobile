import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/environnement_service.dart';
import '../services/plant_service.dart';
import '../widgets/custom_drawer.dart';
import '../models/user.dart';
import '../models/plant.dart';
import '../models/environnement.dart';
import '../screens/add_environnement_screen.dart';
import '../screens/edit_environnement_screen.dart';

class MyEnvironnementsScreen extends StatefulWidget {
  const MyEnvironnementsScreen({super.key});

  @override
  State<MyEnvironnementsScreen> createState() => _MyEnvironnementsScreenState();
}

class _MyEnvironnementsScreenState extends State<MyEnvironnementsScreen> {
  final PlantService _plantService = PlantService();
  final Map<String, Environnement?> _plantEnvironnements = {};
  List<Plant> _plants = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  final Color _primaryColor = const Color(0xFF1A781F);

  // Traduction des noms des plantes
  String _translatePlantName(String frenchName) {
    const translations = {
      'Laitue Romaine': 'Romaine Lettuce',
      'Epinard': 'Spinach',
      'Radis': 'Radish',
    };
    return translations[frenchName] ?? frenchName;
  }

  // Traduction des zones
  String _translateZone(String frenchZone) {
    const zoneTranslations = {
      'Serre Principale': 'Main Greenhouse',
      'Serre Secondaire': 'Secondary Greenhouse',
      'Zone Extérieure': 'Outdoor Zone',
    };
    return zoneTranslations[frenchZone] ?? frenchZone;
  }

  // Traduction des types de lumière
  String _translateLightType(String frenchType) {
    const lightTypeTranslations = {
      'Lumière Naturelle': 'Natural Light',
      'LED': 'LED',
      'Fluorescent': 'Fluorescent',
      'Incandescent': 'Incandescent',
    };
    return lightTypeTranslations[frenchType] ?? frenchType;
  }

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  int _calculateLightDuration(Environnement environnement) {
    return environnement.lumiere.optimalRange.end -
        environnement.lumiere.optimalRange.start;
  }

  Future<void> _refreshAllData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await _loadPlants();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refresh Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _loadPlants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _plants = await _plantService.getPlants();
      _plantEnvironnements.clear();

      for (final plant in _plants) {
        if (plant.id == null) continue;

        try {
          final environnement = await EnvironnementService()
              .getEnvironnementForPlant(plant.id!);
          _plantEnvironnements[plant.id!] = environnement;
        } catch (e) {
          if (kDebugMode) {
            print("Error loading environnement for ${plant.id}: $e");
          }
          _plantEnvironnements[plant.id!] = null;
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load plants: ${e.toString()}";
      });
    }
  }

  List<Plant> _getPlantsWithoutEnvironnements() {
    return _plants
        .where((plant) => _plantEnvironnements[plant.id] == null)
        .toList();
  }

  Future<void> _deleteEnvironnement(
    BuildContext context,
    Plant plant,
    Environnement environnement,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text(
              'Do you really want to delete this environment?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await EnvironnementService().deleteEnvironnementForPlant(
        environnement.id!,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Environment deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadPlants();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during deletion: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String value, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color ?? _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color ?? _primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeInfoRow(
    IconData icon,
    String title,
    double min,
    double max, {
    String unit = '',
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color ?? _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$min - $max $unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color ?? _primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironnementCard(
    BuildContext context,
    Plant plant,
    Environnement environnement,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, size: 36, color: _primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translatePlantName(plant.nom),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plant.nomScientifique.isNotEmpty)
                        Text(
                          plant.nomScientifique,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (plant.zone.isNotEmpty)
              _buildInfoRow(
                Icons.location_on,
                'Zone',
                _translateZone(plant.zone),
                color: Colors.blue,
              ),
            const SizedBox(height: 12),
            _buildRangeInfoRow(
              Icons.thermostat,
              'Temperature',
              environnement.temperature.min ?? 0,
              environnement.temperature.max ?? 0,
              unit: '°C',
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            _buildRangeInfoRow(
              Icons.opacity,
              'Air Humidity',
              environnement.humidite.air.min ?? 0,
              environnement.humidite.air.max ?? 0,
              unit: '%',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            if (environnement.humidite.sol != null)
              _buildInfoRow(
                Icons.water_drop,
                'Soil Moisture',
                environnement.humidite.sol == 1 ? 'Wet' : 'Dry',
                color: Colors.blue,
              ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.light_mode,
              'Light Duration',
              '${_calculateLightDuration(environnement)}h (${environnement.lumiere.optimalRange.start}h-${environnement.lumiere.optimalRange.end}h)',
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            if (environnement.lumiere.type != null)
              _buildInfoRow(
                Icons.lightbulb,
                'Light Type',
                _translateLightType(environnement.lumiere.type!),
                color: Colors.amber,
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => EditEnvironnementScreen(
                                environnement: environnement,
                                plant: plant,
                              ),
                        ),
                      ).then((_) => _loadPlants()),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed:
                      () => _deleteEnvironnement(context, plant, environnement),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantWithoutEnvironnementCard(
    BuildContext context,
    Plant plant,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, size: 36, color: _primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _translatePlantName(plant.nom),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (plant.nomScientifique.isNotEmpty)
                        Text(
                          plant.nomScientifique,
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (plant.zone.isNotEmpty)
              _buildInfoRow(
                Icons.location_on,
                'Zone',
                _translateZone(plant.zone),
                color: Colors.blue,
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => AddEnvironnementScreen(plant: plant),
                    ),
                  ).then((_) => _loadPlants());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Create an Environment',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
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
    final plantsWithoutEnvironnements = _getPlantsWithoutEnvironnements();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Environments', style: TextStyle(fontSize: 22)),
        backgroundColor: _primaryColor,
        actions: [
          _isRefreshing
              ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refreshAllData,
                tooltip: 'Refresh All Data',
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
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator(color: _primaryColor))
                : _errorMessage != null
                ? _buildErrorView()
                : _plants.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                  onRefresh: _refreshAllData,
                  color: _primaryColor,
                  child: CustomScrollView(
                    slivers: [
                      // Section for plants with environments
                      if (_plants.any(
                        (plant) => _plantEnvironnements[plant.id] != null,
                      ))
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'Configured Environments',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final plant =
                                _plants
                                    .where(
                                      (p) => _plantEnvironnements[p.id] != null,
                                    )
                                    .toList()[index];
                            final environnement =
                                _plantEnvironnements[plant.id]!;
                            return _buildEnvironnementCard(
                              context,
                              plant,
                              environnement,
                            );
                          },
                          childCount:
                              _plants
                                  .where(
                                    (p) => _plantEnvironnements[p.id] != null,
                                  )
                                  .length,
                        ),
                      ),
                      // Section for plants without environments
                      if (plantsWithoutEnvironnements.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: Text(
                              'Plants without Environment',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final plant = plantsWithoutEnvironnements[index];
                          return _buildPlantWithoutEnvironnementCard(
                            context,
                            plant,
                          );
                        }, childCount: plantsWithoutEnvironnements.length),
                      ),
                    ],
                  ),
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_plants.isNotEmpty) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => _buildPlantSelectionBottomSheet(),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No plants available')),
            );
          }
        },
        backgroundColor: Colors.grey.shade200,
        foregroundColor: Colors.black,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlantSelectionBottomSheet() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select a Plant',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ..._plants.map(
            (plant) => ListTile(
              leading: Icon(Icons.eco, color: _primaryColor),
              title: Text(
                _translatePlantName(plant.nom),
                style: const TextStyle(fontSize: 18),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEnvironnementScreen(plant: plant),
                  ),
                ).then((_) => _loadPlants());
              },
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryColor,
              side: BorderSide(color: _primaryColor),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.eco, size: 80, color: _primaryColor),
          const SizedBox(height: 20),
          Text(
            'No Plants Registered',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start by adding a plant to configure an environment',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
          const SizedBox(height: 20),
          const Text(
            'Loading Error',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadPlants,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Retry', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
