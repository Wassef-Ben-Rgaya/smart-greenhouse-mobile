import 'package:flutter/material.dart';
import '../models/plant.dart';
import '../models/environnement.dart';
import '../services/environnement_service.dart';

class AddEnvironnementScreen extends StatefulWidget {
  final Plant plant;

  const AddEnvironnementScreen({super.key, required this.plant});

  @override
  State<AddEnvironnementScreen> createState() => _AddEnvironnementScreenState();
}

class _AddEnvironnementScreenState extends State<AddEnvironnementScreen> {
  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = const Color(0xFF1A781F);
  final Color _secondaryColor = const Color(0xFF43A047);
  final Color _alertColor = const Color(0xFFEF6C00);

  // Valeurs par défaut
  double _tempMin = 18.0;
  double _tempMax = 25.0;
  double _humidityAirMin = 40.0;
  double _humidityAirMax = 70.0;
  double? _humiditySoil;
  int _lightStart = 7;
  int _lightEnd = 19;
  String? _lightType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvel environnement pour ${widget.plant.nom}'),
        backgroundColor: _primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  'Paramètres environnementaux',
                  Icons.settings,
                ),

                _buildSubSectionTitle('Température (°C)'),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        label: 'Min',
                        icon: Icons.thermostat,
                        iconColor: const Color(0xFF2196F3),
                        initialValue: _tempMin.toStringAsFixed(1),
                        validator:
                            (value) => _validateTemperature(value, _tempMax),
                        onChanged:
                            (value) =>
                                _tempMin = double.tryParse(value) ?? _tempMin,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        label: 'Max',
                        icon: Icons.thermostat,
                        iconColor: const Color(0xFFF44336),
                        initialValue: _tempMax.toStringAsFixed(1),
                        validator:
                            (value) => _validateTemperature(
                              value,
                              _tempMin,
                              isMax: true,
                            ),
                        onChanged:
                            (value) =>
                                _tempMax = double.tryParse(value) ?? _tempMax,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSubSectionTitle('Humidité de l\'air (%)'),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        label: 'Min',
                        icon: Icons.opacity,
                        iconColor: const Color(0xFFFF9800),
                        initialValue: _humidityAirMin.toStringAsFixed(1),
                        validator:
                            (value) =>
                                _validateHumidity(value, _humidityAirMax),
                        onChanged:
                            (value) =>
                                _humidityAirMin =
                                    double.tryParse(value) ?? _humidityAirMin,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        label: 'Max',
                        icon: Icons.opacity,
                        iconColor: const Color(0xFF2196F3),
                        initialValue: _humidityAirMax.toStringAsFixed(1),
                        validator:
                            (value) => _validateHumidity(
                              value,
                              _humidityAirMin,
                              isMax: true,
                            ),
                        onChanged:
                            (value) =>
                                _humidityAirMax =
                                    double.tryParse(value) ?? _humidityAirMax,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildSubSectionTitle('Humidité du sol'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.water_drop, color: const Color(0xFF2196F3)),
                      const SizedBox(width: 12),
                      const Text('État:', style: TextStyle(fontSize: 16)),
                      const Spacer(),
                      Switch(
                        value: _humiditySoil == 1.0,
                        onChanged:
                            (value) => setState(
                              () => _humiditySoil = value ? 1.0 : 0.0,
                            ),
                        activeColor: const Color(0xFF2196F3),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _humiditySoil == 1.0 ? 'Humide' : 'Sec',
                        style: TextStyle(
                          color:
                              _humiditySoil == 1.0
                                  ? const Color(0xFF2196F3)
                                  : _alertColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildSubSectionTitle('Lumière'),
                _buildDropdown(
                  value: _lightType,
                  label: 'Type de lumière',
                  icon: Icons.light_mode,
                  iconColor: _getLightTypeColor(),
                  items: ['Pleine', 'Mi-ombre', 'Ombre'],
                  onChanged: (value) => setState(() => _lightType = value),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Plage horaire',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildNumberField(
                        label: 'Début (h)',
                        icon: Icons.access_time,
                        iconColor: const Color(0xFF9C27B0),
                        initialValue: _lightStart.toString(),
                        validator: (value) => _validateHour(value),
                        onChanged:
                            (value) =>
                                _lightStart =
                                    int.tryParse(value) ?? _lightStart,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildNumberField(
                        label: 'Fin (h)',
                        icon: Icons.access_time,
                        iconColor: const Color(0xFF9C27B0),
                        initialValue: _lightEnd.toString(),
                        validator: (value) => _validateHour(value),
                        onChanged:
                            (value) =>
                                _lightEnd = int.tryParse(value) ?? _lightEnd,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Durée: ${_lightEnd - _lightStart} heures',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                Center(
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      backgroundColor: _primaryColor,
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
                          'SAUVEGARDER',
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

  // Widgets helper
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

  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String initialValue,
    IconData? icon,
    Color? iconColor,
    String? Function(String?)? validator,
    required Function(String) onChanged,
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
      initialValue: initialValue,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    IconData? icon,
    Color? iconColor,
    required List<String> items,
    required Function(String?) onChanged,
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
      items:
          items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
      onChanged: onChanged,
    );
  }

  // Méthodes helper
  Color _getLightTypeColor() {
    switch (_lightType) {
      case 'Pleine':
        return Colors.yellow[700]!;
      case 'Mi-ombre':
        return Colors.orange;
      case 'Ombre':
        return Colors.grey;
      default:
        return _secondaryColor;
    }
  }

  String? _validateTemperature(
    String? value,
    double compareValue, {
    bool isMax = false,
  }) {
    if (value == null || value.isEmpty) return 'Requis';
    final numValue = double.tryParse(value);
    if (numValue == null) return 'Nombre invalide';

    if (isMax && numValue <= compareValue) {
      return 'Doit être > min';
    } else if (!isMax && numValue >= compareValue) {
      return 'Doit être < max';
    }
    return null;
  }

  String? _validateHumidity(
    String? value,
    double compareValue, {
    bool isMax = false,
  }) {
    if (value == null || value.isEmpty) return 'Requis';
    final numValue = double.tryParse(value);
    if (numValue == null) return 'Nombre invalide';
    if (numValue < 0 || numValue > 100) return 'Doit être entre 0-100';

    if (isMax && numValue <= compareValue) {
      return 'Doit être > min';
    } else if (!isMax && numValue >= compareValue) {
      return 'Doit être < max';
    }
    return null;
  }

  String? _validateHour(String? value) {
    if (value == null || value.isEmpty) return 'Requis';
    final numValue = int.tryParse(value);
    if (numValue == null) return 'Nombre invalide';
    if (numValue < 0 || numValue > 23) return 'Doit être entre 0-23';
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final environnement = Environnement(
          plantId: widget.plant.id!,
          temperature: Temperature(min: _tempMin, max: _tempMax),
          humidite: Humidite(
            air: HumiditeAir(min: _humidityAirMin, max: _humidityAirMax),
            sol: _humiditySoil,
          ),
          lumiere: Lumiere(
            optimalRange: TimeRange(start: _lightStart, end: _lightEnd),
            type: _lightType,
          ),
        );

        await EnvironnementService().saveEnvironnementForPlant(
          widget.plant.id!,
          environnement,
        );

        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
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
