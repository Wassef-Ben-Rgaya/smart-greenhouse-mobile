import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../components/app_bar/gradient_app_bar.dart';

class PrivacyScreen extends StatefulWidget {
  final UserModel user;

  const PrivacyScreen({super.key, required this.user});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _profileVisible = true;
  bool _shareData = false;
  bool _allowAnalytics = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Charger les préférences actuelles si disponibles
    // Exemple : _profileVisible = widget.user.privacySettings['profileVisible'] ?? true;
  }

  Future<void> _savePreferences() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final preferences = {
        'profileVisible': _profileVisible,
        'shareData': _shareData,
        'allowAnalytics': _allowAnalytics,
      };

      final response = await http.put(
        Uri.parse(
          'https://backend-serre-intelligente.onrender.com/api/users/${widget.user.id}/privacy',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.user.id}',
        },
        body: json.encode(preferences),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres de confidentialité mis à jour'),
            backgroundColor: Color(0xFF1A781F),
          ),
        );
        Navigator.pop(context);
      } else {
        final responseBody = json.decode(response.body);
        setState(() {
          _errorMessage =
              responseBody['message'] ?? 'Erreur lors de la mise à jour';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de connexion au serveur. Veuillez réessayer.';
        });
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
        title: 'Paramètres de Confidentialité',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Paramètres de Confidentialité',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A781F),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Profil visible'),
              subtitle: const Text(
                'Rendre votre profil visible aux autres utilisateurs',
              ),
              value: _profileVisible,
              onChanged: (value) => setState(() => _profileVisible = value),
              activeColor: Color(0xFF1A781F),
            ),
            SwitchListTile(
              title: const Text('Partager les données'),
              subtitle: const Text(
                'Autoriser le partage de vos données avec des tiers',
              ),
              value: _shareData,
              onChanged: (value) => setState(() => _shareData = value),
              activeColor: Color(0xFF1A781F),
            ),
            SwitchListTile(
              title: const Text('Analytique'),
              subtitle: const Text(
                'Autoriser la collecte de données pour l\'analytique',
              ),
              value: _allowAnalytics,
              onChanged: (value) => setState(() => _allowAnalytics = value),
              activeColor: Color(0xFF1A781F),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _savePreferences,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF1A781F),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Enregistrer les préférences',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
