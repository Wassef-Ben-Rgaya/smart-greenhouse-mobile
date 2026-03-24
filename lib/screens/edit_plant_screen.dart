import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/plant.dart';
import '../components/app_bar/gradient_app_bar.dart';

class EditPlantScreen extends StatefulWidget {
  final Plant plant;
  final Function() onPlantUpdated;

  const EditPlantScreen({
    super.key,
    required this.plant,
    required this.onPlantUpdated,
  });

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  // Couleurs personnalisées
  final Color _primaryColor = const Color(0xFF1A781F);

  // Variables du formulaire
  late String nom;
  late String nomScientifique;
  late String zone;
  late List<String> cultures;
  late List<String> environnements;

  @override
  void initState() {
    super.initState();
    // Initialisation des valeurs
    nom = widget.plant.nom;
    nomScientifique = widget.plant.nomScientifique;
    zone = widget.plant.zone;
    cultures = List.from(widget.plant.cultures);
    environnements = List.from(widget.plant.environnements);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Modifier la plante'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Informations de base', Icons.info),
                _buildTextFormField(
                  label: 'Nom commun*',
                  icon: Icons.eco,
                  iconColor: _primaryColor,
                  initialValue: nom,
                  validator: (value) =>
                      _validateRequired(value, 'Ce champ est requis'),
                  onSaved: (value) => nom = value ?? '',
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  label: 'Nom scientifique',
                  icon: Icons.science,
                  iconColor: _primaryColor,
                  initialValue: nomScientifique,
                  onSaved: (value) => nomScientifique = value ?? '',
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  value: zone,
                  label: 'Zone*',
                  icon: Icons.location_on,
                  iconColor: _primaryColor,
                  items: const [
                    'Zone A',
                    'Zone B',
                    'Zone C',
                    'Zone D',
                    'Zone E',
                    'Zone F',
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        zone = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.save, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'ENREGISTRER LES MODIFICATIONS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required String label,
    required String initialValue,
    IconData? icon,
    Color? iconColor,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: icon != null ? Icon(icon, color: iconColor) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    IconData? icon,
    Color? iconColor,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: icon != null ? Icon(icon, color: iconColor) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  String? _validateRequired(String? value, String errorMessage) {
    if (value == null || value.isEmpty) {
      return errorMessage;
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final updatedPlant = widget.plant.copyWith(
        nom: nom,
        nomScientifique: nomScientifique,
        zone: zone,
        cultures: cultures,
        environnements: environnements,
      );

      try {
        await _firestore
            .collection('plants')
            .doc(widget.plant.id)
            .update(updatedPlant.toFirestore());
        widget.onPlantUpdated();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
