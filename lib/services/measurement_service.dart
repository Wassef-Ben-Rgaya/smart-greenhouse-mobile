import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/measurement.dart';

class MeasurementService {
  static const String _baseUrl =
      'http://backend-serre-intelligente.onrender.com/api/serre_mesures';
  final http.Client _client;

  MeasurementService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Measurement>> getMeasurements({int limit = 10}) async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl?limit=$limit'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Raw API response: ${data.length} items');

        // Process all measurements - utilise directement l'id comme timestamp
        final measurements =
            data.map((item) {
              final id =
                  item['id']?.toString() ?? DateTime.now().toIso8601String();
              return Measurement.fromJson(item, id);
            }).toList();

        // Le tri se fait naturellement car le timestamp est dans l'id
        measurements.sort((a, b) => b.time.compareTo(a.time));

        // Debug
        print('Processed ${measurements.length} measurements');
        for (var m in measurements) {
          print('${m.id} - ${m.time} - Temp: ${m.temperature}');
        }

        return measurements;
      } else {
        throw Exception('HTTP status ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMeasurements: $e');
      rethrow;
    }
  }

  Future<Measurement> createMeasurement(Measurement measurement) async {
    try {
      final timestamp = measurement.time.toIso8601String();
      final response = await _client.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': timestamp, // Utilise le timestamp comme id
          'Température': measurement.temperature,
          'Humidité': measurement.humidite,
          'Humidité du sol': measurement.humiditeSol,
          'Luminosité': measurement.luminosite,
          'Chauffage': measurement.chauffage! ? 1 : 0, // Convertit en int
          'Lampe': measurement.lampe! ? 1 : 0,
          'Pompe': measurement.pompe! ? 1 : 0,
          'Ventilateur': measurement.ventilateur! ? 1 : 0,
          'time': timestamp, // Pour compatibilité
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Measurement.fromJson(data, data['id']); // Utilise l'id reçu
      } else {
        throw Exception('Failed to create measurement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create measurement: $e');
    }
  }

  Future<Measurement> updateMeasurement(Measurement measurement) async {
    try {
      final timestamp = measurement.time.toIso8601String();
      final response = await _client.put(
        Uri.parse('$_baseUrl/${measurement.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': timestamp, // Maintient la cohérence de l'id
          'Température': measurement.temperature,
          'Humidité': measurement.humidite,
          'Humidité du sol': measurement.humiditeSol,
          'Luminosité': measurement.luminosite,
          'Chauffage': measurement.chauffage! ? 1 : 0,
          'Lampe': measurement.lampe! ? 1 : 0,
          'Pompe': measurement.pompe! ? 1 : 0,
          'Ventilateur': measurement.ventilateur! ? 1 : 0,
          'time': timestamp,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Measurement.fromJson(data, data['id']);
      } else {
        throw Exception('Failed to update measurement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update measurement: $e');
    }
  }

  Future<void> deleteMeasurement(String id) async {
    try {
      final response = await _client.delete(Uri.parse('$_baseUrl/$id'));

      if (response.statusCode != 200) {
        throw Exception('Failed to delete measurement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete measurement: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
