import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:serre_app/screens/add_plant_screen.dart';
import 'package:serre_app/screens/edit_plant_screen.dart';
import '../models/culture.dart';
import '../models/environnement.dart';
import '../models/plant.dart';
import '../widgets/custom_drawer.dart';
import '../models/user.dart';
import '../components/app_bar/gradient_app_bar.dart';
import '../components/buttons/gradient_button.dart';
import '../components/icons/edit_icon_button.dart';
import '../components/icons/delete_icon_button.dart';
import '../constants/styles.dart';

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Plant> _plants = [];
  List<Culture> _cultures = [];
  List<Environnement> _environnements = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _retryCount = 0;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  // Traduction des noms des plantes
  String _translatePlantName(String frenchName) {
    const translations = {
      'Laitue_Romaine': 'Romaine Lettuce',
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

  // Traduction des phases
  String _translatePhase(String frenchPhase) {
    const phaseTranslations = {
      'Germination': 'Germination',
      'Développement des feuilles': 'Leaf Development',
      'Floraison': 'Flowering',
      'Fructification': 'Fruiting',
      'Récolte': 'Harvest',
    };
    return phaseTranslations[frenchPhase] ?? frenchPhase;
  }

  // Traduction des types de lumière
  String _translateLightType(String? frenchType) {
    if (frenchType == null) return 'Unknown';
    const lightTypeTranslations = {
      'Lumière Naturelle': 'Natural Light',
      'LED': 'LED',
      'Fluorescent': 'Fluorescent',
      'Incandescent': 'Incandescent',
    };
    return lightTypeTranslations[frenchType] ?? frenchType;
  }

  // Traduction de l'humidité du sol
  String _translateSoilMoisture(double? soilMoisture) {
    if (soilMoisture == null) return 'Unknown';
    const soilMoistureTranslations = {'Humide': 'Wet', 'Sec': 'Dry'};
    String frenchValue = soilMoisture == 1.0 ? 'Humide' : 'Sec';
    return soilMoistureTranslations[frenchValue] ?? frenchValue;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les plantes
      final plantsSnapshot = await _firestore.collection('plants').get();
      final plants =
          plantsSnapshot.docs.map((doc) => Plant.fromFirestore(doc)).toList();

      // Charger les cultures
      final culturesSnapshot = await _firestore.collection('cultures').get();
      final cultures =
          culturesSnapshot.docs
              .map((doc) => Culture.fromFirestore(doc))
              .toList();

      // Charger les environnements
      final environnementsSnapshot =
          await _firestore.collection('environnements').get();
      final environnements =
          environnementsSnapshot.docs
              .map((doc) => Environnement.fromFirestore(doc))
              .toList();

      setState(() {
        _plants = plants;
        _cultures = cultures;
        _environnements = environnements;
        _isLoading = false;
        _retryCount = 0;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Échec du chargement. ${_retryCount < 3 ? 'Tapez pour réessayer' : 'Veuillez réessayer plus tard'}';
      });
    }
  }

  Culture? _getCultureForPlant(String plantId) {
    try {
      return _cultures.firstWhere((culture) => culture.planteId == plantId);
    } catch (e) {
      return null;
    }
  }

  Environnement? _getEnvironnementForPlant(String plantId) {
    try {
      return _environnements.firstWhere((env) => env.plantId == plantId);
    } catch (e) {
      return null;
    }
  }

  void _showAddPlantDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPlantScreen(onPlantAdded: _loadData),
      ),
    );
  }

  void _showEditPlantDialog(Plant plant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                EditPlantScreen(plant: plant, onPlantUpdated: _loadData),
      ),
    );
  }

  void _showPlantDetails(Plant plant) {
    final culture = _getCultureForPlant(plant.id!);
    final environnement = _getEnvironnementForPlant(plant.id!);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Détails de ${_translatePlantName(plant.nom)}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Nom scientifique', plant.nomScientifique),
                  _buildDetailRow('Zone', _translateZone(plant.zone)),
                  if (culture != null) ...[
                    _buildDetailRow(
                      'Date de plantation',
                      _dateFormat.format(culture.datePlantation),
                    ),
                    _buildDetailRow(
                      'Phase actuelle',
                      _translatePhase(culture.phaseActuelle),
                    ),
                  ],
                  if (environnement != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Environnement:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildDetailRow(
                      'Température',
                      '${environnement.temperature.min ?? 'Unknown'}°C - ${environnement.temperature.max ?? 'Unknown'}°C',
                    ),
                    _buildDetailRow(
                      'Humidité air',
                      '${environnement.humidite.air.min ?? 'Unknown'}% - ${environnement.humidite.air.max ?? 'Unknown'}%',
                    ),
                    _buildDetailRow(
                      'Humidité sol',
                      _translateSoilMoisture(environnement.humidite.sol),
                    ),
                    _buildDetailRow(
                      'Lumière',
                      '${environnement.lumiere.duree ?? 'Unknown'}h (${_translateLightType(environnement.lumiere.type)})',
                    ),
                    _buildDetailRow(
                      'Période lumineuse',
                      '${environnement.lumiere.optimalRange.start ?? 'Unknown'}h - ${environnement.lumiere.optimalRange.end ?? 'Unknown'}h',
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String plantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: const Text(
              'Voulez-vous vraiment supprimer cette plante ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Supprimer la plante et ses données associées
        await _firestore.collection('plants').doc(plantId).delete();

        // Supprimer les cultures associées
        final cultures = _cultures.where((c) => c.planteId == plantId);
        for (var culture in cultures) {
          await _firestore.collection('cultures').doc(culture.id).delete();
        }

        // Supprimer les environnements associés
        final environnements = _environnements.where(
          (e) => e.plantId == plantId,
        );
        for (var env in environnements) {
          await _firestore.collection('environnements').doc(env.id).delete();
        }

        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plante supprimée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Échec de la suppression: ${e.toString()}')),
          );
        }
      }
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Une erreur est survenue',
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          if (_retryCount < 3) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _retryCount++);
                _loadData();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.spa, size: 50, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucune plante enregistrée',
            style: TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _showAddPlantDialog,
            child: const Text('Ajouter une plante'),
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
        title: 'Plant Management',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: CustomDrawer(user: user),
      body: Column(
        children: [
          // En-tête avec bouton
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: const BoxDecoration(
              gradient: AppStyles.appBarGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.eco, color: Color(0xFF0CFF28)),
                    SizedBox(width: 10),
                    Text('List of Plants', style: AppStyles.appBarTitleStyle),
                  ],
                ),
                GradientButton(
                  text: 'Add',
                  icon: Icons.add,
                  onPressed: _showAddPlantDialog,
                ),
              ],
            ),
          ),

          // Corps de la page
          Expanded(
            child:
                _errorMessage != null
                    ? _buildErrorWidget()
                    : _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _plants.isEmpty
                    ? _buildEmptyState()
                    : _buildPlantsTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantsTable() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: false,
            dataRowMinHeight: 70,
            dataRowMaxHeight: 80,
            columnSpacing: 30,
            horizontalMargin: 12,
            columns: const [
              DataColumn(
                label: Text('Plante', style: AppStyles.dataTableHeaderStyle),
              ),
              DataColumn(
                label: Text('Zone', style: AppStyles.dataTableHeaderStyle),
              ),
              DataColumn(
                label: Text('Planté le', style: AppStyles.dataTableHeaderStyle),
              ),
              DataColumn(
                label: Text(
                  'Phase actuelle',
                  style: AppStyles.dataTableHeaderStyle,
                ),
              ),
              DataColumn(
                label: Text('Actions', style: AppStyles.dataTableHeaderStyle),
              ),
            ],
            rows:
                _plants.map((plant) {
                  final culture = _getCultureForPlant(plant.id!);
                  return DataRow(
                    onSelectChanged: (_) => _showPlantDetails(plant),
                    cells: [
                      DataCell(
                        GestureDetector(
                          onTap: () => _showPlantDetails(plant),
                          child: Row(
                            children: [
                              const Icon(Icons.eco, color: Colors.green),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _translatePlantName(plant.nom),
                                    style: AppStyles.plantNameStyle,
                                  ),
                                  if (plant.nomScientifique.isNotEmpty)
                                    Text(
                                      plant.nomScientifique,
                                      style: AppStyles.scientificNameStyle,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        GestureDetector(
                          onTap: () => _showPlantDetails(plant),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                _translateZone(plant.zone),
                                style: AppStyles.regularTextStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        GestureDetector(
                          onTap: () => _showPlantDetails(plant),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                culture != null
                                    ? _dateFormat.format(culture.datePlantation)
                                    : 'Non planté',
                                style: AppStyles.regularTextStyle,
                              ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(
                        GestureDetector(
                          onTap: () => _showPlantDetails(plant),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppStyles.statusColor.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info,
                                  color: const Color.fromARGB(255, 0, 131, 46),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  culture != null
                                      ? _translatePhase(culture.phaseActuelle)
                                      : 'Non planté',
                                  style: AppStyles.statusTextStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EditIconButton(
                              onPressed: () => _showEditPlantDialog(plant),
                            ),
                            const SizedBox(width: 8),
                            DeleteIconButton(
                              onPressed: () => _confirmDelete(plant.id!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}
