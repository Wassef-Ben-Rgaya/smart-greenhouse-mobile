import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../widgets/shared_user_form.dart';
import '../components/app_bar/gradient_app_bar.dart';

class EditUserScreen extends StatefulWidget {
  final UserModel user;
  final String token;
  final Function()? onUserUpdated;

  const EditUserScreen({
    super.key,
    required this.user,
    required this.token,
    this.onUserUpdated,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _genderController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _postalCodeController;

  String _role =
      'utilisateur'; // Initialisation avec un rôle par défaut (utilisateur)
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  DateTime? _selectedBirthDate;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);
    _usernameController = TextEditingController(text: widget.user.username);
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _genderController = TextEditingController(text: widget.user.gender);
    _birthDateController = TextEditingController(
      text:
          widget.user.birthDate != null
              ? DateTime.parse(
                widget.user.birthDate!,
              ).toLocal().toString().split(' ')[0]
              : null,
    );
    _phoneController = TextEditingController(text: widget.user.phoneNumber);
    _addressController = TextEditingController(text: widget.user.address);
    _cityController = TextEditingController(text: widget.user.city);
    _countryController = TextEditingController(text: widget.user.country);
    _postalCodeController = TextEditingController(text: widget.user.postalCode);

    // Assurez-vous de récupérer et d'initialiser le rôle de l'utilisateur
    _role = widget.user.role ?? 'user'; // Récupérer le rôle de l'utilisateur
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint("Validation du formulaire échouée");
      return;
    }

    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final updateData = {
        "username": _usernameController.text.trim(),
        "email": _emailController.text.trim(),
        "role": _role, // Utilisation de _role au lieu de isAdmin
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "gender":
            _genderController.text.isNotEmpty
                ? _genderController.text
                : "Non spécifié",
        "birthDate": _selectedBirthDate?.toUtc().toIso8601String(),
        "phoneNumber": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "city": _cityController.text.trim(),
        "country": _countryController.text.trim(),
        "postalCode": _postalCodeController.text.trim(),
        if (_passwordController.text.isNotEmpty)
          "password": _passwordController.text,
      };

      debugPrint("Envoi des données: ${jsonEncode(updateData)}");

      final response = await http.put(
        Uri.parse(
          'https://backend-serre-intelligente.onrender.com/api/users/${widget.user.id}',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode(updateData),
      );

      debugPrint(
        "Réponse du serveur (${response.statusCode}): ${response.body}",
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        widget.onUserUpdated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur mis à jour avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Échec de la mise à jour');
      }
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Modifier l\'utilisateur',
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _confirmDelete),
          TextButton(
            onPressed: _confirmCancel,
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateUser,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Color(0xFF1A781F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.update, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Mettre à jour',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Voulez-vous vraiment supprimer ${widget.user.firstName} ${widget.user.lastName} ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Annuler les modifications'),
            content: const Text(
              'Voulez-vous vraiment annuler les modifications ?',
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _genderController.dispose();
    _birthDateController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }
}
