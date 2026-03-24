import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/kpi.dart';

class KPIService with ChangeNotifier {
  KPI? _kpi;
  List<KPI> _kpiHistory = [];
  WebSocketChannel? _channel;
  bool _isLoading = false;
  bool _isLoadingHistory = false;
  String? _error;
  String? _historyError;

  KPI? get kpi => _kpi;
  List<KPI> get kpiHistory => _kpiHistory;
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;
  String? get historyError => _historyError;

  // URL de base de l'API
  final String baseUrl =
      'https://backend-serre-intelligente.onrender.com/api/serre_mesures/kpis';
  final String historyUrl =
      'https://backend-serre-intelligente.onrender.com/api/serre_mesures/kpis/history';
  final String wsUrl =
      'ws://backend-serre-intelligente.onrender.com/kpis/updates';

  KPIService() {
    debugPrint('Initialisation de KPIService...');
    fetchKPIs();
    connectToWebSocket();
  }

  Future<void> fetchKPIs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('Tentative de récupération des KPI à $baseUrl');
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Délai de connexion dépassé');
            },
          );

      debugPrint('Réponse HTTP: ${response.statusCode}');
      debugPrint('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) {
          throw Exception('Données JSON vides ou mal formées');
        }
        _kpi = KPI.fromJson(data);
        debugPrint('KPI récupéré avec succès: ${data.toString()}');
      } else {
        _error =
            'Erreur lors de la récupération des KPI: ${response.statusCode}';
      }
    } on SocketException catch (e) {
      _error = 'Erreur réseau: Impossible de se connecter au serveur ($e)';
      debugPrint('Erreur réseau: $e');
    } on FormatException catch (e) {
      _error = 'Erreur lors du parsing des données JSON: $e';
      debugPrint('Erreur JSON: $e');
    } catch (e) {
      _error = 'Erreur lors de la récupération des KPI: $e';
      debugPrint('Erreur inattendue: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchKPIHistory() async {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();

    try {
      debugPrint(
        'Tentative de récupération de l\'historique des KPI à $historyUrl',
      );
      final response = await http
          .get(Uri.parse(historyUrl))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Délai de connexion dépassé');
            },
          );

      debugPrint('Réponse HTTP (historique): ${response.statusCode}');
      debugPrint('Corps de la réponse (historique): ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data.isEmpty) {
          _kpiHistory = [];
          debugPrint('Aucun historique disponible');
        } else {
          _kpiHistory =
              data.entries
                  .map((entry) => KPI.fromJson(entry.value, date: entry.key))
                  .toList()
                ..sort(
                  (a, b) => b.date!.compareTo(a.date!),
                ); // Tri décroissant par date
          debugPrint(
            'Historique KPI récupéré avec succès: ${_kpiHistory.length} entrées',
          );
        }
      } else {
        _historyError =
            'Erreur lors de la récupération de l\'historique: ${response.statusCode}';
      }
    } on SocketException catch (e) {
      _historyError =
          'Erreur réseau: Impossible de se connecter au serveur ($e)';
      debugPrint('Erreur réseau (historique): $e');
    } on FormatException catch (e) {
      _historyError = 'Erreur lors du parsing des données JSON: $e';
      debugPrint('Erreur JSON (historique): $e');
    } catch (e) {
      _historyError = 'Erreur lors de la récupération de l\'historique: $e';
      debugPrint('Erreur inattendue (historique): $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  void connectToWebSocket() {
    try {
      debugPrint('Connexion au WebSocket à $wsUrl');
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        (message) {
          debugPrint('Message WebSocket reçu: $message');
          final data = jsonDecode(message);
          if (data['type'] == 'kpi_update') {
            _kpi = KPI.fromJson(data['data']);
            notifyListeners();
            debugPrint('KPI mis à jour via WebSocket');
          }
        },
        onError: (error) {
          _error = 'Erreur WebSocket: $error';
          notifyListeners();
          debugPrint('Erreur WebSocket: $error');
        },
        onDone: () {
          _error = 'Connexion WebSocket fermée';
          notifyListeners();
          debugPrint('Connexion WebSocket fermée');
        },
      );
    } catch (e) {
      _error = 'Erreur lors de la connexion WebSocket: $e';
      notifyListeners();
      debugPrint('Erreur lors de la connexion WebSocket: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('Fermeture du WebSocket');
    _channel?.sink.close();
    super.dispose();
  }
}
