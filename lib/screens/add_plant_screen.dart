import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant.dart';
import '../components/app_bar/gradient_app_bar.dart';

class AddPlantScreen extends StatefulWidget {
  final Function() onPlantAdded;

  const AddPlantScreen({super.key, required this.onPlantAdded});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Couleurs personnalisées
  final Color _primaryColor = const Color(0xFF1A781F);

  // Variables du formulaire
  String nom = '';
  String nomScientifique = '';
  String zone = 'Zone A';
  List<String> cultures = [];
  List<String> environnements = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: 'Ajouter une plante'),
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
                  validator: (value) =>
                      _validateRequired(value, 'Ce champ est requis'),
                  onSaved: (value) => nom = value ?? '',
                ),
                const SizedBox(height: 16),
                _buildTextFormField(
                  label: 'Nom scientifique',
                  icon: Icons.science,
                  iconColor: _primaryColor,
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
                        Icon(Icons.add, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'AJOUTER LA PLANTE',
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
    IconData? icon,
    Color? iconColor,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
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

      final newPlant = Plant(
        nom: nom,
        nomScientifique: nomScientifique,
        zone: zone,
        cultures: cultures,
        environnements: environnements,
      );

      try {
        await _firestore.collection('plants').add(newPlant.toFirestore());
        widget.onPlantAdded();
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
