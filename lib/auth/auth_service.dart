import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  /// 📥 Connexion utilisateur
  Future<String?> login(String email, String password) async {
    final url = Uri.parse(
      'https://backend-serre-intelligente.onrender.com/api/users/login',
    ); // Assure-toi que l'IP locale est utilisée

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      );
      print('Réponse: ${response.statusCode}');
      print('Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['token'] != null) {
        await _storage.write(key: 'jwt_token', value: responseData['token']);
        return null; // Connexion réussie
      } else if (response.statusCode == 401) {
        return 'Mot de passe incorrect';
      } else if (response.statusCode == 404) {
        return 'Utilisateur non trouvé';
      } else if (response.statusCode == 400) {
        return 'Champs email ou mot de passe manquants';
      } else {
        return 'Erreur serveur: ${responseData['error'] ?? 'inconnue'}';
      }
    } catch (e) {
      return 'Erreur de connexion: ${e.toString()}';
    }
  }

  /// 🔐 Récupère le token stocké
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  /// 🚪 Déconnexion utilisateur
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  /// 🔍 Vérifie si un utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  signup(
    String text,
    String text2,
    String text3, {
    required String firstName,
    required String lastName,
    required String gender,
    DateTime? birthDate,
    required String phoneNumber,
    required String address,
    required String city,
    required String country,
    required String postalCode,
    required bool isAdmin,
  }) {}
}
