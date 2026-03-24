import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../components/app_bar/gradient_app_bar.dart';

class AddUserScreen extends StatefulWidget {
  final Function()? onUserAdded;

  const AddUserScreen({super.key, this.onUserAdded});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  // États
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _gender = 'Homme';
  String _selectedCountry = 'Tunisie';
  String _selectedRole = 'utilisateur';
  Map<String, String> _fieldErrors = {};

  // Listes de sélection
  final List<String> _countries = [
    'Tunisie',
    'France',
    'Allemagne',
    'USA',
    'Italie',
  ];
  final List<String> _genders = ['Homme', 'Femme', 'Autre'];
  final List<String> _roles = ['admin', 'technicien', 'utilisateur'];

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A781F),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      setState(() {
        _birthDateController.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  // Validation des champs
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est obligatoire';
    }
    if (value.length < 4) {
      return 'Minimum 4 caractères';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Caractères autorisés: lettres, chiffres et _';
    }
    return _validateField('username', value);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est obligatoire';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email invalide';
    }
    return _validateField('email', value);
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est obligatoire';
    }
    if (value.length < 6) {
      return 'Minimum 6 caractères';
    }
    return _validateField('password', value);
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est obligatoire';
    }
    if (!RegExp(r'^[a-zA-ZÀ-ÿ -]+$').hasMatch(value)) {
      return 'Caractères non autorisés';
    }
    return _validateField(fieldName, value);
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le téléphone est obligatoire';
    }
    if (!RegExp(r'^[0-9 +]+$').hasMatch(value)) {
      return 'Format invalide';
    }
    return _validateField('phoneNumber', value);
  }

  String? _validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'adresse est obligatoire';
    }
    return _validateField('address', value);
  }

  String? _validateCity(String? value) {
    if (value == null || value.isEmpty) {
      return 'La ville est obligatoire';
    }
    if (!RegExp(r'^[a-zA-ZÀ-ÿ -]+$').hasMatch(value)) {
      return 'Caractères non autorisés';
    }
    return _validateField('city', value);
  }

  String? _validatePostalCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code postal est obligatoire';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Uniquement des chiffres';
    }
    return _validateField('postalCode', value);
  }

  String? _validateBirthDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'La date de naissance est obligatoire';
    }
    return _validateField('birthDate', value);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _fieldErrors = {};
    });

    try {
      final response = await http.post(
        Uri.parse('https://backend-serre-intelligente.onrender.com/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'gender': _gender,
          'birthDate': _birthDateController.text,
          'phoneNumber': _phoneController.text,
          'address': _addressController.text,
          'city': _cityController.text,
          'country': _selectedCountry,
          'postalCode': _postalCodeController.text,
          'role': _selectedRole,
        }),
      );

      await _handleResponse(response);
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResponse(http.Response response) async {
    final responseBody = json.decode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Utilisateur créé avec succès'),
          backgroundColor: Color(0xFF1A781F),
        ),
      );

      widget.onUserAdded?.call();
      Navigator.pop(context);
    } else if (response.statusCode == 400) {
      if (responseBody.containsKey('errors')) {
        setState(() {
          _fieldErrors = Map<String, String>.from(responseBody['errors']);
        });
        _showSnackBar('Veuillez corriger les erreurs dans le formulaire');
      } else {
        _showSnackBar(responseBody['message'] ?? 'Erreur lors de la création');
      }
    } else {
      _showSnackBar(responseBody['message'] ?? 'Erreur lors de la création');
    }
  }

  void _handleError(dynamic error) {
    debugPrint('Erreur: $error');
    _showSnackBar('Erreur de connexion au serveur. Veuillez réessayer.');
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  String? _validateField(String fieldName, String? value) {
    if (value != null && _fieldErrors.containsKey(fieldName)) {
      return _fieldErrors[fieldName];
    }
    return null;
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Color(0xFF1A781F)),
      suffixIcon: suffixIcon,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF1A781F)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A781F),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Ajouter un utilisateur',
        actions: [
          TextButton(
            onPressed: () => _showCancelConfirmation(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Section Identifiants
              _buildSectionHeader('Identifiants', Icons.person_outline),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: _inputDecoration(
                  'Nom d\'utilisateur',
                  Icons.person,
                ),
                validator: _validateUsername,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email', Icons.email),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  'Mot de passe',
                  Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed:
                        () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  ),
                ),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: _inputDecoration(
                  'Confirmer le mot de passe',
                  Icons.lock,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed:
                        () => setState(
                          () =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                        ),
                  ),
                ),
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: _inputDecoration('Rôle', Icons.verified_user),
                items:
                    _roles.map((String role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(
                          role == 'admin'
                              ? 'Administrateur'
                              : role == 'technicien'
                              ? 'Technicien'
                              : 'Utilisateur',
                        ),
                      );
                    }).toList(),
                onChanged:
                    (String? value) => setState(() => _selectedRole = value!),
                validator:
                    (value) =>
                        value == null ? 'Ce champ est obligatoire' : null,
              ),
              const SizedBox(height: 24),

              // Section Informations personnelles
              _buildSectionHeader(
                'Informations personnelles',
                Icons.info_outline,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: _inputDecoration(
                        'Prénom',
                        Icons.person_outline,
                      ),
                      validator: (value) => _validateName(value, 'firstName'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: _inputDecoration('Nom', Icons.person_outline),
                      validator: (value) => _validateName(value, 'lastName'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: _inputDecoration('Genre', Icons.transgender),
                items:
                    _genders.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? value) => setState(() => _gender = value!),
                validator:
                    (value) =>
                        value == null ? 'Ce champ est obligatoire' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                decoration: _inputDecoration(
                  'Date de naissance',
                  Icons.calendar_today,
                ),
                onTap: () => _selectBirthDate(context),
                validator: _validateBirthDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Téléphone', Icons.phone),
                validator: _validatePhone,
              ),
              const SizedBox(height: 24),

              // Section Adresse
              _buildSectionHeader('Adresse', Icons.home),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('Adresse', Icons.home),
                validator: _validateAddress,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: _inputDecoration(
                        'Ville',
                        Icons.location_city,
                      ),
                      validator: _validateCity,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        'Code postal',
                        Icons.local_post_office,
                      ),
                      validator: _validatePostalCode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: _inputDecoration('Pays', Icons.public),
                items:
                    _countries.map((String country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                onChanged:
                    (String? value) =>
                        setState(() => _selectedCountry = value!),
                validator:
                    (value) =>
                        value == null ? 'Ce champ est obligatoire' : null,
              ),
              const SizedBox(height: 32),

              // Bouton de création
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A781F),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Créer l\'utilisateur',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Annuler la création'),
            content: const Text(
              'Voulez-vous vraiment annuler la création de cet utilisateur ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Non'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Oui', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }
}
