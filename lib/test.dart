import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/culture_service.dart';
import '../services/plant_service.dart';
import '../widgets/custom_drawer.dart';
import '../models/user.dart';
import '../models/culture.dart';
import '../models/plant.dart';
import '../screens/add_culture_screen.dart';
import '../screens/edit_culture_screen.dart';

class MyCulturesScreen extends StatefulWidget {
  const MyCulturesScreen({super.key});

  @override
  State<MyCulturesScreen> createState() => _MyCulturesScreenState();
}

class _MyCulturesScreenState extends State<MyCulturesScreen> {
  final PlantService _plantService = PlantService();
  final Map<String, List<Culture>> _plantCultures = {};
  List<Plant> _plants = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  final Color _primaryColor = const Color(0xFF1A781F);
  Timer? _phaseUpdateTimer;

  @override
  void initState() {
    super.initState();
    _loadPlants();
    _setupPhaseAutoUpdate();
  }

  @override
  void dispose() {
    _phaseUpdateTimer?.cancel();
    super.dispose();
  }

  void _setupPhaseAutoUpdate() {
    _phaseUpdateTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      if (mounted) _checkAndUpdatePhases();
    });
  }

  Future<void> _checkAndUpdatePhases() async {
    try {
      for (final plant in _plants) {
        if (plant.id == null) continue;
        final cultures = _plantCultures[plant.id!] ?? [];
        for (final culture in cultures) {
          if (culture.id != null) {
            await CultureService(
              plantId: plant.id!,
            ).updateCulturePhase(culture.id!);
          }
        }
      }
      if (mounted) await _loadPlants();
    } catch (e) {
      if (kDebugMode) print("Error updating phases: $e");
    }
  }

  Future<void> _refreshAllData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      await _checkAndUpdatePhases();
      await _loadPlants();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing: ${e.toString()}'),
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
      _plantCultures.clear();

      for (final plant in _plants) {
        if (plant.id == null) continue;

        try {
          final cultures =
              await CultureService(plantId: plant.id!).getCulturesByPlant();
          _plantCultures[plant.id!] = cultures;
        } catch (e) {
          if (kDebugMode) print("Error loading cultures for ${plant.id}: $e");
          _plantCultures[plant.id!] = [];
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

  List<Plant> _getPlantsWithoutCultures() {
    return _plants.where((plant) {
      final cultures = _plantCultures[plant.id] ?? [];
      return cultures.isEmpty;
    }).toList();
  }

  Future<void> _deleteCulture(
    BuildContext context,
    Plant plant,
    Culture culture,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Deletion'),
            content: const Text('Do you really want to delete this crop?'),
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
      await CultureService(plantId: plant.id!).deleteCulture(culture.id!);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crop deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadPlants();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting: ${e.toString()}'),
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

  Widget _buildCultureCard(BuildContext context, Plant plant, Culture culture) {
    final currentPhase = culture.phases.firstWhere(
      (phase) => phase.nom == culture.phaseActuelle,
      orElse: () => culture.phases.first,
    );

    final datePlanted =
        culture.datePlantation is Timestamp
            ? (culture.datePlantation as Timestamp).toDate()
            : culture.datePlantation;

    final daysInPhase = _calculateDaysInCurrentPhase(culture, currentPhase);
    final phaseProgress = (daysInPhase / currentPhase.duree).clamp(0.0, 1.0);

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
                        plant.nom,
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
                plant.zone,
                color: Colors.blue,
              ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Planted On',
              _formatDate(datePlanted),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.flag,
              'Current Phase',
              culture.phaseActuelle,
              color: _getPhaseColor(culture.phaseActuelle),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: phaseProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPhaseColor(culture.phaseActuelle),
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Day $daysInPhase of ${currentPhase.duree}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text(
                'Phase Details',
                style: TextStyle(fontSize: 16),
              ),
              children:
                  culture.phases
                      .map(
                        (phase) => ListTile(
                          leading: Icon(
                            Icons.circle,
                            size: 12,
                            color: _getPhaseColor(phase.nom),
                          ),
                          title: Text(
                            phase.nom,
                            style: const TextStyle(fontSize: 16),
                          ),
                          trailing: Text(
                            '${phase.duree} days',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 8),
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
                              (context) => EditCultureScreen(
                                culture: culture,
                                plantId: plant.id!,
                                plantName: plant.nom,
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
                  onPressed: () => _deleteCulture(context, plant, culture),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlantWithoutCultureCard(BuildContext context, Plant plant) {
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
                        plant.nom,
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
                plant.zone,
                color: Colors.blue,
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddCultureScreen(plant: plant),
                    ),
                  ).then((_) => _loadPlants());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 32, 146, 37),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Create a Crop',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateDaysSincePlantation(DateTime date) {
    return DateTime.now().difference(date).inDays;
  }

  int _calculateDaysInCurrentPhase(Culture culture, Phase phase) {
    final totalDays = _calculateDaysSincePlantation(
      culture.datePlantation is Timestamp
          ? (culture.datePlantation as Timestamp).toDate()
          : culture.datePlantation,
    );

    final currentPhaseIndex = culture.phases.indexWhere(
      (p) => p.nom == culture.phaseActuelle,
    );
    int previousDays = 0;

    for (int i = 0; i < currentPhaseIndex; i++) {
      previousDays += culture.phases[i].duree;
    }

    return (totalDays - previousDays).clamp(1, phase.duree);
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getPhaseColor(String phaseName) {
    const colors = {
      'Germination': Color(0xFF42A5F5),
      'Emergence': Color(0xFF4FC3F7),
      'Leaf Development': Color(0xFF66BB6A),
      'Stem and Root Growth': Color(0xFF43A047),
      'Tillering': Color(0xFF9CCC65),
      'Head Formation': Color(0xFFFFEB3B),
      'Flowering': Color(0xFFFFC107),
      'Pollination': Color(0xFFFFA726),
      'Fruiting': Color(0xFFFB8C00),
      'Maturation': Color(0xFFF4511E),
      'Harvest': Color(0xFFE53935),
      'Senescence': Color(0xFF8D6E63),
      'Exhausted': Color(0xFF5D4037),
    };
    return colors[phaseName] ?? _primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final UserModel user =
        ModalRoute.of(context)!.settings.arguments as UserModel;
    final plantsWithoutCultures = _getPlantsWithoutCultures();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Crops', style: TextStyle(fontSize: 22)),
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
      body:
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
                    // Section for plants with cultures
                    if (_plants.any(
                      (plant) => (_plantCultures[plant.id] ?? []).isNotEmpty,
                    ))
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'My Active Crops',
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
                                    (p) =>
                                        (_plantCultures[p.id] ?? []).isNotEmpty,
                                  )
                                  .toList()[index];
                          final cultures = _plantCultures[plant.id] ?? [];
                          return Column(
                            children:
                                cultures
                                    .map(
                                      (culture) => _buildCultureCard(
                                        context,
                                        plant,
                                        culture,
                                      ),
                                    )
                                    .toList(),
                          );
                        },
                        childCount:
                            _plants
                                .where(
                                  (p) =>
                                      (_plantCultures[p.id] ?? []).isNotEmpty,
                                )
                                .length,
                      ),
                    ),
                    // Section for plants without cultures
                    if (plantsWithoutCultures.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text(
                            'Available Plants',
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
                        final plant = plantsWithoutCultures[index];
                        return _buildPlantWithoutCultureCard(context, plant);
                      }, childCount: plantsWithoutCultures.length),
                    ),
                  ],
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
              title: Text(plant.nom, style: const TextStyle(fontSize: 18)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCultureScreen(plant: plant),
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
              'Start by adding a plant to create crops',
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
