import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/culture.dart';
import '../services/culture_service.dart';
import '../services/plant_service.dart';

class EditCultureScreen extends StatefulWidget {
  final Culture culture;
  final String plantId;
  final String? plantName;
  final String? scientificName;

  const EditCultureScreen({
    super.key,
    required this.culture,
    required this.plantId,
    this.plantName,
    this.scientificName,
  });

  @override
  State<EditCultureScreen> createState() => _EditCultureScreenState();
}

class _EditCultureScreenState extends State<EditCultureScreen> {
  late DateTime _plantationDate;
  late List<Phase> _phases;
  bool _isSaving = false;
  final _phaseDurationController = TextEditingController();
  String _plantName = 'Chargement...';
  String _scientificName = 'Chargement...';
  final Color _primaryColor = const Color.fromARGB(255, 57, 157, 61);
  final Color _alertColor = const Color(0xFFEF6C00);

  final Map<String, Color> _availablePhases = const {
    'Germination': Color(0xFF42A5F5),
    'Levée': Color(0xFF4FC3F7),
    'Développement des feuilles': Color(0xFF66BB6A),
    'Croissance des tiges et racines': Color(0xFF43A047),
    'Montaison': Color(0xFF9CCC65),
    'Formation de la tête': Color(0xFFFFEB3B),
    'Floraison': Color(0xFFFFC107),
    'Pollinisation': Color(0xFFFFA726),
    'Fructification': Color(0xFFFB8C00),
    'Maturation': Color(0xFFF4511E),
    'Récolte': Color(0xFFE53935),
    'Sénescence': Color(0xFF8D6E63),
    'Épuisé': Color(0xFF5D4037),
  };

  @override
  void initState() {
    super.initState();
    _plantationDate = widget.culture.datePlantation;
    _phases = widget.culture.phases
        .map((phase) => Phase(nom: phase.nom, duree: phase.duree))
        .toList();
    if (widget.plantName == null || widget.scientificName == null) {
      _loadPlantInfo();
    } else {
      _plantName = widget.plantName!;
      _scientificName = widget.scientificName!;
    }
  }

  @override
  void dispose() {
    _phaseDurationController.dispose();
    super.dispose();
  }

  Future<void> _loadPlantInfo() async {
    try {
      final plants = await PlantService().getPlants();
      if (plants.isNotEmpty) {
        final plant = plants.firstWhere(
          (p) => p.id == widget.plantId,
          orElse: () => plants.first,
        );
        if (mounted) {
          setState(() {
            _plantName = plant.nom;
            _scientificName = plant.nomScientifique;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _plantName = 'Nom inconnu';
          _scientificName = 'Nom scientifique inconnu';
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _plantationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _plantationDate) {
      setState(() => _plantationDate = picked);
    }
  }

  void _editPhaseDuration(int index, int newDuration) {
    setState(() {
      _phases[index] = Phase(
        nom: _phases[index].nom,
        duree: newDuration,
      );
    });
  }

  void _removePhase(int index) {
    setState(() => _phases.removeAt(index));
  }

  void _addNewPhase() {
    String? selectedPhase;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ajouter une nouvelle phase'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedPhase,
                  decoration: const InputDecoration(
                    labelText: 'Phase',
                    border: OutlineInputBorder(),
                  ),
                  items: _availablePhases.keys
                      .where((phase) => !_phases.any((p) => p.nom == phase))
                      .map((phase) => DropdownMenuItem(
                            value: phase,
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  margin: const EdgeInsets.only(right: 8),
                                ),
                                Text(
                                  phase,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                )
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedPhase = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phaseDurationController,
                  decoration: const InputDecoration(
                    labelText: 'Durée (jours)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedPhase == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Veuillez sélectionner une phase'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  final duration =
                      int.tryParse(_phaseDurationController.text) ?? 0;

                  if (duration <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('La durée doit être un nombre positif'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    _phases.add(Phase(nom: selectedPhase!, duree: duration));
                    _phaseDurationController.clear();
                  });

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                ),
                child: const Text(
                  'Ajouter',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_phases.isEmpty) {
      _showError('Ajoutez au moins une phase de croissance');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedCulture = widget.culture.copyWith(
        datePlantation: _plantationDate,
        phases: _phases,
      );

      await CultureService(plantId: widget.plantId)
          .updateCulture(widget.culture.id!, updatedCulture);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('Erreur lors de la mise à jour: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Color _getPhaseColor(String phaseName) {
    return _availablePhases[phaseName] ?? _primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la culture'),
        backgroundColor: _primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Informations de base', Icons.info),
                _buildPlantInfoCard(),
                _buildDatePickerField(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionHeader(
                        'Phases de croissance', Icons.trending_up),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _addNewPhase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                        elevation: 2,
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ..._phases
                    .asMap()
                    .entries
                    .map((entry) => _buildPhaseCard(entry.value, entry.key)),
                const SizedBox(height: 80), // Espace pour le bouton flottant
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          onPressed: _saveChanges,
          backgroundColor: _primaryColor,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildPlantInfoCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: _primaryColor),
                const SizedBox(width: 8),
                const SizedBox(height: 8),
                Text(
                  _plantName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              _scientificName,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: () => _selectDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de plantation',
          prefixIcon: Icon(Icons.calendar_today, color: _primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(_plantationDate),
              style: const TextStyle(fontSize: 16),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseCard(Phase phase, int index) {
    final durationController =
        TextEditingController(text: phase.duree.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: 7),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: _getPhaseColor(phase.nom),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(right: 6),
                    ),
                    Text(
                      phase.nom,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getPhaseColor(phase.nom),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: _alertColor, size: 20),
                  onPressed: () => _removePhase(index),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Durée (jours)',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final newDuration = int.tryParse(value);
                      if (newDuration != null && newDuration > 0) {
                        _editPhaseDuration(index, newDuration);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                const Text('jours', style: TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
