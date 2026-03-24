import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../widgets/shared_user_form.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
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
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'user';
  DateTime? _selectedBirthDate;

  final List<String> _countries = [
    'Tunisie',
    'France',
    'Allemagne',
    'USA',
    'Italie',
  ];

  @override
  void initState() {
    super.initState();
    _countryController.text = 'Tunisie';
    _genderController.text = 'Homme';
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Veuillez corriger les erreurs dans le formulaire');
      return;
    }

    // Vérification manuelle de la correspondance des mots de passe
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Les mots de passe ne correspondent pas');
      return;
    }

    // Vérification de la longueur minimale du mot de passe
    if (_passwordController.text.length < 6) {
      _showSnackBar('Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer un utilisateur avec Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // Enregistrer les informations supplémentaires dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'id':
                userCredential
                    .user!
                    .uid, // Utilise id pour correspondre à UserModel
            'username': _usernameController.text,
            'email': _emailController.text,
            'firstName': _firstNameController.text,
            'lastName': _lastNameController.text,
            'gender': _genderController.text,
            'birthDate': _birthDateController.text,
            'phoneNumber': _phoneController.text,
            'address': _addressController.text,
            'city': _cityController.text,
            'country': _countryController.text,
            'postalCode': _postalCodeController.text,
            'role': _selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      // Créer l'instance UserModel
      final user = UserModel(
        id: userCredential.user!.uid,
        username: _usernameController.text,
        email: _emailController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        gender: _genderController.text,
        birthDate: _birthDateController.text,
        phoneNumber: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        country: _countryController.text,
        postalCode: _postalCodeController.text,
        role: _selectedRole,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (mounted) {
        _showSuccessDialog(user);
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } on FirebaseException catch (e) {
      _handleFirestoreError(e);
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'email-already-in-use':
        message = 'Cet email est déjà utilisé.';
        break;
      case 'invalid-email':
        message = 'L\'email est invalide.';
        break;
      case 'weak-password':
        message = 'Le mot de passe est trop faible (minimum 6 caractères).';
        break;
      default:
        message = 'Erreur lors de l\'inscription: ${e.message}';
    }
    _showSnackBar(message);
  }

  void _handleFirestoreError(FirebaseException e) {
    String message;
    switch (e.code) {
      case 'permission-denied':
        message = 'Permission refusée. Vérifiez les règles de Firestore.';
        break;
      default:
        message =
            'Erreur lors de l\'enregistrement dans Firestore: ${e.message}';
    }
    _showSnackBar(message);
  }

  void _handleError(dynamic error) {
    debugPrint('Erreur: $error');
    _showSnackBar('Erreur de connexion au serveur. Veuillez réessayer.');
  }

  void _showSuccessDialog(UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF1A781F)),
                SizedBox(width: 10),
                Text('Inscription réussie'),
              ],
            ),
            content: const Text(
              'Votre compte a été créé avec succès. Vous pouvez maintenant vous connecter.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(
                    context,
                    '/login',
                    arguments: user,
                  );
                },
                child: const Text(
                  'OK',
                  style: TextStyle(color: Color(0xFF1A781F)),
                ),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF1A781F),
        ),
      );
    }
  }

  Widget _buildLogoHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/greenhouse-icon.jpg',
          width: 120,
          height: 120,
        ),
        const SizedBox(height: 8),
        const Text(
          'Serre Intelligente',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A781F),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Créez votre compte',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inscription"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1A781F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            _buildLogoHeader(),
            const SizedBox(height: 24),
            const SizedBox(height: 32),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1A781F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                onPressed: _isLoading ? null : _signup,
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'S\'INSCRIRE',
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
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed:
                    () => Navigator.pushReplacementNamed(context, '/login'),
                child: RichText(
                  text: const TextSpan(
                    text: 'Déjà un compte ? ',
                    style: TextStyle(color: Colors.black54),
                    children: [
                      TextSpan(
                        text: 'Connectez-vous',
                        style: TextStyle(
                          color: Color(0xFF1A781F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
    _genderController.dispose();
    _countryController.dispose();
    super.dispose();
  }
}
