import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SharedUserForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController genderController;
  final TextEditingController birthDateController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController countryController;
  final TextEditingController postalCodeController;
  final String role;
  final ValueChanged<String> onRoleChanged;
  final bool isEditing;
  final DateTime? selectedBirthDate;
  final ValueChanged<DateTime?> onBirthDateSelected;
  final List<String> countries;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final ValueChanged<bool> onObscurePasswordChanged;
  final ValueChanged<bool> onObscureConfirmPasswordChanged;

  const SharedUserForm({
    super.key,
    required this.formKey,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.usernameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.genderController,
    required this.birthDateController,
    required this.phoneController,
    required this.addressController,
    required this.cityController,
    required this.countryController,
    required this.postalCodeController,
    required this.role,
    required this.onRoleChanged,
    required this.isEditing,
    required this.selectedBirthDate,
    required this.onBirthDateSelected,
    this.countries = const ['Tunisie', 'France', 'Allemagne', 'USA', 'Italie'],
    this.obscurePassword = true,
    this.obscureConfirmPassword = true,
    required this.onObscurePasswordChanged,
    required this.onObscureConfirmPasswordChanged,
    required List<String> genders,
  });

  @override
  State<SharedUserForm> createState() => _SharedUserFormState();
}

class _SharedUserFormState extends State<SharedUserForm> {
  String? _gender;
  final List<String> _genders = ['Homme', 'Femme', 'Autre'];
  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.selectedBirthDate ?? DateTime.now(),
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

    if (picked != null && picked != widget.selectedBirthDate) {
      widget.onBirthDateSelected(picked);
      widget.birthDateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(picked); // Formater la date ici
    }
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
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1A781F), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
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

  List<String> _getUniqueCountries(List<String> countries) {
    return countries
        .toSet()
        .toList(); // Convertir en Set pour éliminer les doublons
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Identifiants
          _buildSectionHeader('Identifiants', Icons.person_outline),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.usernameController,
            decoration: _inputDecoration("Nom d'utilisateur", Icons.person),
            validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.emailController,
            decoration: _inputDecoration('Email', Icons.email),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value!.isEmpty) return 'Champ obligatoire';
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.passwordController,
            obscureText: widget.obscurePassword,
            decoration: _inputDecoration(
              widget.isEditing ? 'Nouveau mot de passe' : 'Mot de passe',
              Icons.lock,
              suffixIcon: IconButton(
                icon: Icon(
                  widget.obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed:
                    () => widget.onObscurePasswordChanged(
                      !widget.obscurePassword,
                    ),
              ),
            ),
            validator: (value) {
              if (!widget.isEditing && value!.isEmpty) {
                return 'Champ obligatoire';
              }
              if (value!.isNotEmpty && value.length < 6) {
                return '6 caractères minimum';
              }
              return null;
            },
          ),
          if (!widget.isEditing) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.confirmPasswordController,
              obscureText: widget.obscureConfirmPassword,
              decoration: _inputDecoration(
                'Confirmer le mot de passe',
                Icons.lock,
                suffixIcon: IconButton(
                  icon: Icon(
                    widget.obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed:
                      () => widget.onObscureConfirmPasswordChanged(
                        !widget.obscureConfirmPassword,
                      ),
                ),
              ),
              validator: (value) {
                if (!widget.isEditing &&
                    value != widget.passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),

          // Section Role
          _buildSectionHeader('Rôle', Icons.security),
          const SizedBox(height: 8),
          // In the DropdownButtonFormField for role:
          DropdownButtonFormField<String>(
            value:
                widget
                    .role, // This should match one of the values in your items
            onChanged: (value) {
              setState(() {
                widget.onRoleChanged(value!);
              });
            },
            decoration: _inputDecoration(
              'Choisir le rôle',
              Icons.account_circle,
            ),
            items:
                ['utilisateur', 'admin', 'technicien'].map((role) {
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
            validator: (value) => value == null ? 'Champ obligatoire' : null,
          ),
          const SizedBox(height: 16),

          // Section Informations personnelles
          _buildSectionHeader('Informations personnelles', Icons.info_outline),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.firstNameController,
                  decoration: _inputDecoration('Prénom', Icons.person_outline),
                  validator:
                      (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: widget.lastNameController,
                  decoration: _inputDecoration('Nom', Icons.person_outline),
                  validator:
                      (value) => value!.isEmpty ? 'Champ obligatoire' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _gender, // Utilise la valeur actuelle du genre
                decoration: _inputDecoration('Genre', Icons.transgender),
                items:
                    _genders.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _gender = value; // Met à jour le genre sélectionné
                    widget.genderController.text =
                        value!; // Met à jour le contrôleur de texte
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _selectBirthDate(context),
            child: AbsorbPointer(
              child: TextFormField(
                controller: widget.birthDateController,
                decoration: _inputDecoration(
                  'Date de naissance',
                  Icons.calendar_today,
                ),
                validator:
                    (value) => value!.isEmpty ? 'Champ obligatoire' : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.phoneController,
            decoration: _inputDecoration('Téléphone', Icons.phone),
            keyboardType: TextInputType.phone,
            validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Adresse', Icons.location_on_outlined),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.addressController,
            decoration: _inputDecoration('Adresse', Icons.home),
            validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.cityController,
            decoration: _inputDecoration('Ville', Icons.location_city),
            validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value:
                widget.countryController.text.isEmpty
                    ? null
                    : widget.countryController.text,
            onChanged: (value) {
              widget.countryController.text = value!;
            },
            decoration: _inputDecoration('Pays', Icons.language),
            items:
                _getUniqueCountries(widget.countries).map((country) {
                  return DropdownMenuItem<String>(
                    value: country,
                    child: Text(country),
                  );
                }).toList(),
            validator: (value) => value == null ? 'Champ obligatoire' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.postalCodeController,
            decoration: _inputDecoration('Code postal', Icons.pin_drop),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
          ),
        ],
      ),
    );
  }
}
