import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../models/alert.dart';
import '../models/measurement.dart';
import 'package:flutter/foundation.dart';

class AlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Map<String, dynamic>> _environmentCache = {};
  static List<String>? _cachedPlantIds;

  // Convertir les Timestamp pour le debug
  Map<String, dynamic> serializeForDebug(Map<String, dynamic> data) {
    final serialized = Map<String, dynamic>.from(data);
    serialized.forEach((key, value) {
      if (value is Timestamp) {
        serialized[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        serialized[key] = serializeForDebug(Map<String, dynamic>.from(value));
      }
    });
    return serialized;
  }

  Future<List<Alert>> getAlerts({
    String? status,
    String? type,
    String? plantId,
    String? severity,
    String? environnementId,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (type != null) queryParams['type'] = type;
    if (plantId != null) queryParams['plantId'] = plantId;
    if (severity != null) queryParams['severity'] = severity;
    if (environnementId != null) {
      queryParams['environnementId'] = environnementId;
    }
    if (limit != null) queryParams['limit'] = limit.toString();

    final uri = Uri.parse(
      'http://192.168.1.50:5000/alerts',
    ).replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final alerts = await Future.wait(
        data.map((json) async {
          final alert = Alert.fromJson(json);
          if (alert.plantId != null &&
              (alert.plantName.isEmpty || alert.plantScientificName == null)) {
            return await _enrichAlertWithPlantData(alert);
          }
          return alert;
        }),
      );
      return alerts;
    } else {
      throw Exception('Failed to load alerts: ${response.statusCode}');
    }
  }

  Stream<List<Alert>> streamAlerts({String? status, int limit = 50}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query.snapshots().asyncMap((snapshot) async {
      return await Future.wait(
        snapshot.docs.map((doc) async {
          final alert = Alert.fromJson({...doc.data(), 'id': doc.id});
          if (alert.plantId != null &&
              (alert.plantName.isEmpty || alert.plantScientificName == null)) {
            return await _enrichAlertWithPlantData(alert);
          }
          return alert;
        }),
      );
    });
  }

  Future<Alert> _enrichAlertWithPlantData(Alert alert) async {
    if (alert.plantId == null || alert.plantId!.isEmpty) {
      debugPrint('No plantId in alert, skipping enrichment');
      return alert.copyWith(
        plantName:
            alert.plantName.isNotEmpty ? alert.plantName : 'Plante inconnue',
      );
    }

    try {
      debugPrint('Fetching plant data for ID: ${alert.plantId}');
      final envDoc =
          await _firestore
              .collection('environnements')
              .doc(alert.plantId)
              .get();
      String? actualPlantId = alert.plantId;

      if (envDoc.exists) {
        final envData = envDoc.data()!;
        actualPlantId = envData['plantId'] as String?;
        debugPrint('Found environnement, associated plantId: $actualPlantId');
      } else {
        debugPrint(
          'No environnement found with ID: ${alert.plantId}, assuming it is a plantId',
        );
      }

      if (actualPlantId == null) {
        debugPrint(
          'No associated plantId found for environnement: ${alert.plantId}',
        );
        return alert.copyWith(
          plantName:
              alert.plantName.isNotEmpty ? alert.plantName : 'Plante inconnue',
        );
      }

      final plantDoc =
          await _firestore.collection('plants').doc(actualPlantId).get();

      if (plantDoc.exists) {
        final plantData = plantDoc.data()!;
        debugPrint(
          'Plant data found: ${plantData['nom']}, ${plantData['nomScientifique']}',
        );
        return alert.copyWith(
          plantId: actualPlantId,
          plantName:
              plantData['nom']?.isNotEmpty == true
                  ? plantData['nom']
                  : 'Plante inconnue',
          plantScientificName: plantData['nomScientifique'] ?? '',
          environnementId: alert.plantId,
        );
      } else {
        debugPrint('No plant found in Firestore with ID: $actualPlantId');
        return alert.copyWith(plantName: 'Plante inconnue');
      }
    } catch (e) {
      debugPrint('Erreur enrichissement alerte: $e');
      return alert.copyWith(
        plantName:
            alert.plantName.isNotEmpty ? alert.plantName : 'Plante inconnue',
      );
    }
  }

  Future<Alert> createAlert(Alert alert) async {
    debugPrint('Avant enrichissement: ${alert.toString()}');
    final enrichedAlert =
        alert.plantId != null ? await _enrichAlertWithPlantData(alert) : alert;
    debugPrint('Après enrichissement: ${enrichedAlert.toString()}');

    try {
      final alertData = enrichedAlert.toJson();
      final docRef = await _firestore.collection('alerts').add(alertData);
      return enrichedAlert.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde dans Firestore: $e');
      throw Exception('Failed to create alert in Firestore: $e');
    }
  }

  Future<void> updateAlertStatus(String id, String status) async {
    try {
      final updateData = {
        'status': status,
        if (status == 'resolved')
          'resolvedAt': Timestamp.fromDate(DateTime.now()),
        if (status == 'active') 'resolvedAt': null,
      };
      await _firestore.collection('alerts').doc(id).update(updateData);
    } catch (e) {
      throw Exception('Failed to update alert status in Firestore: $e');
    }
  }

  Future<void> deleteAlert(String id) async {
    try {
      await _firestore.collection('alerts').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete alert in Firestore: $e');
    }
  }

  Future<Map<String, dynamic>> getAlertStats() async {
    try {
      final snapshot = await _firestore.collection('alerts').get();
      final totalAlerts = snapshot.docs.length;
      final activeAlerts =
          snapshot.docs.where((doc) => doc['status'] == 'active').length;
      final resolvedAlerts =
          snapshot.docs.where((doc) => doc['status'] == 'resolved').length;

      final bySeverity = {
        'critical':
            snapshot.docs.where((doc) => doc['severity'] == 'critical').length,
        'high': snapshot.docs.where((doc) => doc['severity'] == 'high').length,
        'medium':
            snapshot.docs.where((doc) => doc['severity'] == 'medium').length,
        'low': snapshot.docs.where((doc) => doc['severity'] == 'low').length,
      };

      return {
        'total': totalAlerts,
        'active': activeAlerts,
        'resolved': resolvedAlerts,
        'bySeverity': bySeverity,
      };
    } catch (e) {
      throw Exception('Failed to load alert stats from Firestore: $e');
    }
  }

  Future<List<Alert>> getAlertsForMeasurement(String measurementId) async {
    try {
      final snapshot =
          await _firestore
              .collection('alerts')
              .where('measurementId', isEqualTo: measurementId)
              .limit(50)
              .get();
      return snapshot.docs
          .map((doc) => Alert.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération des alertes pour la mesure $measurementId: $e',
      );
      rethrow;
    }
  }

  Future<List<Alert>> getAlertsForMeasurements(
    List<String> measurementIds,
  ) async {
    if (measurementIds.isEmpty) return [];

    try {
      const int batchSize = 10;
      final List<Alert> allAlerts = [];

      for (int i = 0; i < measurementIds.length; i += batchSize) {
        final batchIds = measurementIds.sublist(
          i,
          i + batchSize > measurementIds.length
              ? measurementIds.length
              : i + batchSize,
        );

        final snapshot =
            await _firestore
                .collection('alerts')
                .where('measurementId', whereIn: batchIds)
                .limit(50)
                .get();

        final batchAlerts =
            snapshot.docs
                .map((doc) => Alert.fromJson({...doc.data(), 'id': doc.id}))
                .toList();
        allAlerts.addAll(batchAlerts);
      }

      return allAlerts;
    } catch (e) {
      debugPrint(
        'Erreur lors de la récupération des alertes pour les mesures $measurementIds: $e',
      );
      rethrow;
    }
  }

  void refreshCaches() {
    _environmentCache.clear();
    _cachedPlantIds = null;
    debugPrint('Caches vidés');
  }

  Future<void> checkAndCreateAlert(
    Measurement measurement,
    Map<String, dynamic> aggregatedThresholds,
    String? plantId,
  ) async {
    if (measurement.id == null) {
      debugPrint('Measurement ID is null, cannot create alert');
      return;
    }

    debugPrint('=== Nouvelle vérification d\'alerte ===');
    debugPrint('Seuils agrégés reçus: ${jsonEncode(aggregatedThresholds)}');
    debugPrint('Mesure: ${measurement.toJson()}');
    debugPrint('Plant ID: $plantId');

    if (plantId != null) {
      await _checkForSinglePlant(measurement, plantId);
      return;
    }

    List<String> plantIds;
    if (_cachedPlantIds != null) {
      plantIds = _cachedPlantIds!;
      debugPrint(
        'Utilisation du cache pour les plantIds: ${plantIds.length} plantes',
      );
    } else {
      final plantDocs = await _firestore.collection('plants').limit(50).get();
      plantIds = plantDocs.docs.map((doc) => doc.id).toList();
      _cachedPlantIds = plantIds;
      debugPrint('Plantes chargées depuis Firestore: ${plantIds.length}');
    }

    debugPrint('Nombre de plantes à vérifier: ${plantIds.length}');

    const int batchSize = 10;
    for (int i = 0; i < plantIds.length; i += batchSize) {
      final batchIds = plantIds.sublist(
        i,
        i + batchSize > plantIds.length ? plantIds.length : i + batchSize,
      );

      final envDocs =
          await _firestore
              .collection('environnements')
              .where('plantId', whereIn: batchIds)
              .limit(50)
              .get();

      for (var envDoc in envDocs.docs) {
        final plantId = envDoc.data()['plantId'] as String?;
        if (plantId != null) {
          await _checkForSinglePlant(measurement, plantId);
        }
      }
    }

    if (aggregatedThresholds.isNotEmpty) {
      await _checkWithAggregatedThresholds(measurement, aggregatedThresholds);
    } else {
      debugPrint('Aucun seuil agrégé fourni, saute la vérification agrégée');
    }
  }

  Future<void> _checkForSinglePlant(
    Measurement measurement,
    String plantId,
  ) async {
    try {
      Map<String, dynamic>? envData;
      if (_environmentCache.containsKey(plantId)) {
        debugPrint(
          'Utilisation du cache pour environnement de plante: $plantId',
        );
        envData = _environmentCache[plantId];
      } else {
        final envDocs =
            await _firestore
                .collection('environnements')
                .where('plantId', isEqualTo: plantId)
                .limit(1)
                .get();
        if (envDocs.docs.isEmpty) {
          debugPrint('Aucun environnement trouvé pour la plante: $plantId');
          return;
        }
        envData = envDocs.docs.first.data();
        _environmentCache[plantId] = envData;
      }

      debugPrint(
        'Environnement pour $plantId: ${jsonEncode(serializeForDebug(envData!))}',
      );

      final tempThresholds =
          envData['temperature'] as Map<String, dynamic>? ?? {};
      final airThresholds =
          (envData['humidite']?['air'] as Map<String, dynamic>?) ?? {};
      final soilThreshold = (envData['humidite']?['sol'] as num?)?.toDouble();
      final lightThresholds = envData['lumiere'] as Map<String, dynamic>? ?? {};
      final lightOptimalRange =
          lightThresholds['optimalRange'] as Map<String, dynamic>? ?? {};

      final tempMax = (tempThresholds['max'] as num?)?.toDouble();
      final tempMin = (tempThresholds['min'] as num?)?.toDouble();
      final airMax = (airThresholds['max'] as num?)?.toDouble();
      final airMin = (airThresholds['min'] as num?)?.toDouble();
      final lightMin = 800.0;

      debugPrint('Seuils pour $plantId:');
      debugPrint('- Température: $tempMin°C - $tempMax°C');
      debugPrint('- Humidité air: $airMin% - $airMax%');
      debugPrint('- Humidité sol: ${soilThreshold == 1.0 ? 'Humide' : 'Sec'}');
      debugPrint('- Luminosité min: $lightMin lux');

      List<Map<String, dynamic>> alertsToCreate = [];
      final existingAlerts = await getAlertsForMeasurement(measurement.id!);
      debugPrint(
        'Alertes existantes pour mesure ${measurement.id}: ${existingAlerts.length}',
      );

      // Résolution automatique des alertes
      if (measurement.temperature != null &&
          tempMax != null &&
          tempMin != null) {
        debugPrint(
          'Vérification résolution température: ${measurement.temperature} dans [$tempMin, $tempMax]',
        );
        if (measurement.temperature! <= tempMax &&
            measurement.temperature! >= tempMin) {
          debugPrint(
            'Température dans les seuils, recherche alertes à résoudre',
          );
          for (var alert in existingAlerts) {
            if (alert.plantId == plantId &&
                (alert.type == 'temperature_high' ||
                    alert.type == 'temperature_low') &&
                alert.status == 'active') {
              debugPrint(
                'Résolution automatique de l\'alerte: ${alert.message} (ID: ${alert.id})',
              );
              await updateAlertStatus(alert.id, 'resolved');
            }
          }
        } else {
          debugPrint('Température hors seuils, pas de résolution');
        }
      }

      if (measurement.humidite != null && airMax != null && airMin != null) {
        debugPrint(
          'Vérification résolution humidité: ${measurement.humidite} dans [$airMin, $airMax]',
        );
        if (measurement.humidite! <= airMax &&
            measurement.humidite! >= airMin) {
          debugPrint('Humidité dans les seuils, recherche alertes à résoudre');
          for (var alert in existingAlerts) {
            if (alert.plantId == plantId &&
                (alert.type == 'humidity_high' ||
                    alert.type == 'humidity_low') &&
                alert.status == 'active') {
              debugPrint(
                'Résolution automatique de l\'alerte: ${alert.message} (ID: ${alert.id})',
              );
              await updateAlertStatus(alert.id, 'resolved');
            }
          }
        } else {
          debugPrint('Humidité hors seuils, pas de résolution');
        }
      }

      if (measurement.humiditeSol != null && soilThreshold != null) {
        debugPrint(
          'Vérification résolution humidité sol: ${measurement.humiditeSol} == $soilThreshold',
        );
        if (measurement.humiditeSol == soilThreshold) {
          debugPrint(
            'Humidité sol dans les seuils, recherche alertes à résoudre',
          );
          for (var alert in existingAlerts) {
            if (alert.plantId == plantId &&
                alert.type == 'soil_humidity' &&
                alert.status == 'active') {
              debugPrint(
                'Résolution automatique de l\'alerte: ${alert.message} (ID: ${alert.id})',
              );
              await updateAlertStatus(alert.id, 'resolved');
            }
          }
        } else {
          debugPrint('Humidité sol hors seuils, pas de résolution');
        }
      }

      if (measurement.luminosite != null) {
        final lightStart = (lightOptimalRange['start'] as num?)?.toInt() ?? 8;
        final lightEnd = (lightOptimalRange['end'] as num?)?.toInt() ?? 18;
        final currentHour = measurement.time.hour;
        final isInLightRange =
            currentHour >= lightStart && currentHour <= lightEnd;

        debugPrint(
          'Vérification résolution luminosité: ${measurement.luminosite} >= $lightMin, heure: $currentHour dans [$lightStart, $lightEnd]',
        );
        if (isInLightRange && measurement.luminosite! >= lightMin) {
          debugPrint(
            'Luminosité dans les seuils, recherche alertes à résoudre',
          );
          for (var alert in existingAlerts) {
            if (alert.plantId == plantId &&
                alert.type == 'light_low' &&
                alert.status == 'active') {
              debugPrint(
                'Résolution automatique de l\'alerte: ${alert.message} (ID: ${alert.id})',
              );
              await updateAlertStatus(alert.id, 'resolved');
            }
          }
        } else {
          debugPrint(
            'Luminosité hors seuils ou hors plage horaire, pas de résolution',
          );
        }
      }

      // Vérification des dépassements
      if (measurement.temperature != null &&
          tempMax != null &&
          tempMin != null) {
        if (measurement.temperature! > tempMax) {
          alertsToCreate.add({
            'type': 'temperature_high',
            'message':
                'Température trop élevée pour $plantId: ${measurement.temperature?.toStringAsFixed(1)}°C (max: ${tempMax.toStringAsFixed(1)}°C)',
            'value': measurement.temperature,
            'threshold': tempMax,
            'optimalRange':
                '${tempMin.toStringAsFixed(1)}°C - ${tempMax.toStringAsFixed(1)}°C',
            'severity': 'high',
          });
        } else if (measurement.temperature! < tempMin) {
          alertsToCreate.add({
            'type': 'temperature_low',
            'message':
                'Température trop basse pour $plantId: ${measurement.temperature?.toStringAsFixed(1)}°C (min: ${tempMin.toStringAsFixed(1)}°C)',
            'value': measurement.temperature,
            'threshold': tempMin,
            'optimalRange':
                '${tempMin.toStringAsFixed(1)}°C - ${tempMax.toStringAsFixed(1)}°C',
            'severity': 'high',
          });
        }
      }

      if (measurement.humidite != null && airMax != null && airMin != null) {
        if (measurement.humidite! > airMax) {
          alertsToCreate.add({
            'type': 'humidity_high',
            'message':
                'Humidité air trop élevée pour $plantId: ${measurement.humidite?.toStringAsFixed(1)}% (max: ${airMax.toStringAsFixed(1)}%)',
            'value': measurement.humidite,
            'threshold': airMax,
            'optimalRange':
                '${airMin.toStringAsFixed(1)}% - ${airMax.toStringAsFixed(1)}%',
            'severity': 'medium',
          });
        } else if (measurement.humidite! < airMin) {
          alertsToCreate.add({
            'type': 'humidity_low',
            'message':
                'Humidité air trop basse pour $plantId: ${measurement.humidite?.toStringAsFixed(1)}% (min: ${airMin.toStringAsFixed(1)}%)',
            'value': measurement.humidite,
            'threshold': airMin,
            'optimalRange':
                '${airMin.toStringAsFixed(1)}% - ${airMax.toStringAsFixed(1)}%',
            'severity': 'medium',
          });
        }
      }

      if (measurement.humiditeSol != null && soilThreshold != null) {
        if (measurement.humiditeSol != soilThreshold) {
          alertsToCreate.add({
            'type': 'soil_humidity',
            'message':
                'Humidité sol non optimale pour $plantId: ${measurement.humiditeSol == 1.0 ? 'Humide' : 'Sec'} (attendu: ${soilThreshold == 1.0 ? 'Humide' : 'Sec'})',
            'value': measurement.humiditeSol,
            'threshold': soilThreshold,
            'optimalRange': soilThreshold == 1.0 ? 'Humide' : 'Sec',
            'severity': 'medium',
          });
        }
      }

      if (measurement.luminosite != null) {
        final lightStart = (lightOptimalRange['start'] as num?)?.toInt() ?? 8;
        final lightEnd = (lightOptimalRange['end'] as num?)?.toInt() ?? 18;
        final currentHour = measurement.time.hour;
        final isInLightRange =
            currentHour >= lightStart && currentHour <= lightEnd;

        if (isInLightRange && measurement.luminosite! < lightMin) {
          alertsToCreate.add({
            'type': 'light_low',
            'message':
                'Luminosité trop faible pour $plantId: ${measurement.luminosite?.toStringAsFixed(1)} lux (min: ${lightMin.toStringAsFixed(1)}) pendant la plage optimale (${lightStart}h-${lightEnd}h)',
            'value': measurement.luminosite,
            'threshold': lightMin,
            'optimalRange':
                '${lightStart}h-${lightEnd}h (>${lightMin.toStringAsFixed(1)} lux)',
            'severity': 'medium',
          });
        }
      }

      for (var alertData in alertsToCreate) {
        try {
          final hasActiveAlert = existingAlerts.any((alert) {
            if (alert.type != alertData['type'] || alert.status != 'active') {
              return false;
            }
            if (alertData['threshold'] != null) {
              return alert.threshold == alertData['threshold'] &&
                  alert.measurementId == measurement.id &&
                  alert.plantId == plantId;
            }
            return true;
          });

          if (!hasActiveAlert) {
            final newAlert = Alert(
              id: DateTime.now().toIso8601String(),
              type: alertData['type'] as String,
              message: alertData['message'] as String,
              status: 'active',
              timestamp: DateTime.now(),
              plantId: plantId,
              plantName: '',
              plantScientificName: null,
              severity: alertData['severity'] as String,
              value: alertData['value']?.toDouble(),
              threshold: alertData['threshold']?.toDouble(),
              optimalRange: alertData['optimalRange']?.toString() ?? '',
              measurementId: measurement.id,
            );

            debugPrint(
              'Création d\'une nouvelle alerte pour $plantId: ${newAlert.message}',
            );
            await createAlert(newAlert);
          } else {
            debugPrint(
              'Alerte existante trouvée pour type: ${alertData['type']} et plante: $plantId',
            );
          }
        } catch (e) {
          debugPrint('Erreur lors de la création d\'alerte pour $plantId: $e');
        }
      }

      if (alertsToCreate.isEmpty) {
        debugPrint('Aucune alerte nécessaire pour la plante: $plantId');
      } else {
        debugPrint('Alertes créées pour $plantId: ${alertsToCreate.length}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification pour la plante $plantId: $e');
    }
  }

  Future<void> _checkWithAggregatedThresholds(
    Measurement measurement,
    Map<String, dynamic> thresholds,
  ) async {
    final airThresholds = thresholds['air'] as Map<String, dynamic>? ?? {};
    final temperatureThresholds =
        thresholds['temperature'] as Map<String, dynamic>? ?? {};
    final soilThreshold = (thresholds['sol'] as num?)?.toDouble();
    final lightThresholds =
        thresholds['lumiere'] as Map<String, dynamic>? ?? {};
    final lightOptimalRange =
        lightThresholds['optimalRange'] as Map<String, dynamic>? ?? {};

    final tempMax = (temperatureThresholds['max'] as num?)?.toDouble();
    final tempMin = (temperatureThresholds['min'] as num?)?.toDouble();
    final airMax = (airThresholds['max'] as num?)?.toDouble();
    final airMin = (airThresholds['min'] as num?)?.toDouble();
    final lightMin = 800.0;

    debugPrint('Vérification avec seuils agrégés:');
    debugPrint('- Température: $tempMin°C - $tempMax°C');
    debugPrint('- Humidité air: $airMin% - $airMax%');
    debugPrint('- Humidité sol: ${soilThreshold == 1.0 ? 'Humide' : 'Sec'}');
    debugPrint('- Luminosité min: $lightMin lux');

    List<Map<String, dynamic>> alertsToCreate = [];
    final existingAlerts = await getAlertsForMeasurement(measurement.id!);
    debugPrint(
      'Alertes existantes pour mesure ${measurement.id}: ${existingAlerts.length}',
    );

    // Résolution automatique pour seuils agrégés
    if (measurement.temperature != null && tempMax != null && tempMin != null) {
      debugPrint(
        'Vérification résolution température (agrégée): ${measurement.temperature} dans [$tempMin, $tempMax]',
      );
      if (measurement.temperature! <= tempMax &&
          measurement.temperature! >= tempMin) {
        debugPrint(
          'Température dans les seuils (agrégée), recherche alertes à résoudre',
        );
        for (var alert in existingAlerts) {
          if (alert.plantId == null &&
              (alert.type == 'temperature_high' ||
                  alert.type == 'temperature_low') &&
              alert.status == 'active') {
            debugPrint(
              'Résolution automatique de l\'alerte (agrégée): ${alert.message} (ID: ${alert.id})',
            );
            await updateAlertStatus(alert.id, 'resolved');
          }
        }
      } else {
        debugPrint('Température hors seuils (agrégée), pas de résolution');
      }
    }

    if (measurement.humidite != null && airMax != null && airMin != null) {
      debugPrint(
        'Vérification résolution humidité (agrégée): ${measurement.humidite} dans [$airMin, $airMax]',
      );
      if (measurement.humidite! <= airMax && measurement.humidite! >= airMin) {
        debugPrint(
          'Humidité dans les seuils (agrégée), recherche alertes à résoudre',
        );
        for (var alert in existingAlerts) {
          if (alert.plantId == null &&
              (alert.type == 'humidity_high' || alert.type == 'humidity_low') &&
              alert.status == 'active') {
            debugPrint(
              'Résolution automatique de l\'alerte (agrégée): ${alert.message} (ID: ${alert.id})',
            );
            await updateAlertStatus(alert.id, 'resolved');
          }
        }
      } else {
        debugPrint('Humidité hors seuils (agrégée), pas de résolution');
      }
    }

    if (measurement.humiditeSol != null && soilThreshold != null) {
      debugPrint(
        'Vérification résolution humidité sol (agrégée): ${measurement.humiditeSol} == $soilThreshold',
      );
      if (measurement.humiditeSol == soilThreshold) {
        debugPrint(
          'Humidité sol dans les seuils (agrégée), recherche alertes à résoudre',
        );
        for (var alert in existingAlerts) {
          if (alert.plantId == null &&
              alert.type == 'soil_humidity' &&
              alert.status == 'active') {
            debugPrint(
              'Résolution automatique de l\'alerte (agrégée): ${alert.message} (ID: ${alert.id})',
            );
            await updateAlertStatus(alert.id, 'resolved');
          }
        }
      } else {
        debugPrint('Humidité sol hors seuils (agrégée), pas de résolution');
      }
    }

    if (measurement.luminosite != null) {
      final lightStart = (lightOptimalRange['start'] as num?)?.toInt() ?? 8;
      final lightEnd = (lightOptimalRange['end'] as num?)?.toInt() ?? 18;
      final currentHour = measurement.time.hour;
      final isInLightRange =
          currentHour >= lightStart && currentHour <= lightEnd;

      debugPrint(
        'Vérification résolution luminosité (agrégée): ${measurement.luminosite} >= $lightMin, heure: $currentHour dans [$lightStart, $lightEnd]',
      );
      if (isInLightRange && measurement.luminosite! >= lightMin) {
        debugPrint(
          'Luminosité dans les seuils (agrégée), recherche alertes à résoudre',
        );
        for (var alert in existingAlerts) {
          if (alert.plantId == null &&
              alert.type == 'light_low' &&
              alert.status == 'active') {
            debugPrint(
              'Résolution automatique de l\'alerte (agrégée): ${alert.message} (ID: ${alert.id})',
            );
            await updateAlertStatus(alert.id, 'resolved');
          }
        }
      } else {
        debugPrint(
          'Luminosité hors seuils ou hors plage horaire (agrégée), pas de résolution',
        );
      }
    }

    // Vérification des dépassements
    if (measurement.temperature != null && tempMax != null && tempMin != null) {
      if (measurement.temperature! > tempMax) {
        alertsToCreate.add({
          'type': 'temperature_high',
          'message':
              'Température trop élevée: ${measurement.temperature?.toStringAsFixed(1)}°C (max: ${tempMax.toStringAsFixed(1)}°C)',
          'value': measurement.temperature,
          'threshold': tempMax,
          'optimalRange':
              '${tempMin.toStringAsFixed(1)}°C - ${tempMax.toStringAsFixed(1)}°C',
          'severity': 'high',
        });
      } else if (measurement.temperature! < tempMin) {
        alertsToCreate.add({
          'type': 'temperature_low',
          'message':
              'Température trop basse: ${measurement.temperature?.toStringAsFixed(1)}°C (min: ${tempMin.toStringAsFixed(1)}°C)',
          'value': measurement.temperature,
          'threshold': tempMin,
          'optimalRange':
              '${tempMin.toStringAsFixed(1)}°C - ${tempMax.toStringAsFixed(1)}°C',
          'severity': 'high',
        });
      }
    }

    if (measurement.humidite != null && airMax != null && airMin != null) {
      if (measurement.humidite! > airMax) {
        alertsToCreate.add({
          'type': 'humidity_high',
          'message':
              'Humidité air trop élevée: ${measurement.humidite?.toStringAsFixed(1)}% (max: ${airMax.toStringAsFixed(1)}%)',
          'value': measurement.humidite,
          'threshold': airMax,
          'optimalRange':
              '${airMin.toStringAsFixed(1)}% - ${airMax.toStringAsFixed(1)}%',
          'severity': 'medium',
        });
      } else if (measurement.humidite! < airMin) {
        alertsToCreate.add({
          'type': 'humidity_low',
          'message':
              'Humidité air trop basse: ${measurement.humidite?.toStringAsFixed(1)}% (min: ${airMin.toStringAsFixed(1)}%)',
          'value': measurement.humidite,
          'threshold': airMin,
          'optimalRange':
              '${airMin.toStringAsFixed(1)}% - ${airMax.toStringAsFixed(1)}%',
          'severity': 'medium',
        });
      }
    }

    if (measurement.humiditeSol != null && soilThreshold != null) {
      if (measurement.humiditeSol != soilThreshold) {
        alertsToCreate.add({
          'type': 'soil_humidity',
          'message':
              'Humidité sol non optimale: ${measurement.humiditeSol == 1.0 ? 'Humide' : 'Sec'} (attendu: ${soilThreshold == 1.0 ? 'Humide' : 'Sec'})',
          'value': measurement.humiditeSol,
          'threshold': soilThreshold,
          'optimalRange': soilThreshold == 1.0 ? 'Humide' : 'Sec',
          'severity': 'medium',
        });
      }
    }

    if (measurement.luminosite != null) {
      final lightStart = (lightOptimalRange['start'] as num?)?.toInt() ?? 8;
      final lightEnd = (lightOptimalRange['end'] as num?)?.toInt() ?? 18;
      final currentHour = measurement.time.hour;
      final isInLightRange =
          currentHour >= lightStart && currentHour <= lightEnd;

      if (isInLightRange && measurement.luminosite! < lightMin) {
        alertsToCreate.add({
          'type': 'light_low',
          'message':
              'Luminosité trop faible: ${measurement.luminosite?.toStringAsFixed(1)} lux (min: ${lightMin.toStringAsFixed(1)}) pendant la plage optimale (${lightStart}h-${lightEnd}h)',
          'value': measurement.luminosite,
          'threshold': lightMin,
          'optimalRange':
              '${lightStart}h-${lightEnd}h (>${lightMin.toStringAsFixed(1)} lux)',
          'severity': 'medium',
        });
      }
    }

    for (var alertData in alertsToCreate) {
      try {
        final hasActiveAlert = existingAlerts.any((alert) {
          if (alert.type != alertData['type'] || alert.status != 'active') {
            return false;
          }
          if (alertData['threshold'] != null) {
            return alert.threshold == alertData['threshold'] &&
                alert.measurementId == measurement.id &&
                alert.plantId == null;
          }
          return true;
        });

        if (!hasActiveAlert) {
          final newAlert = Alert(
            id: DateTime.now().toIso8601String(),
            type: alertData['type'] as String,
            message: alertData['message'] as String,
            status: 'active',
            timestamp: DateTime.now(),
            plantId: null,
            plantName: '',
            plantScientificName: null,
            severity: alertData['severity'] as String,
            value: alertData['value']?.toDouble(),
            threshold: alertData['threshold']?.toDouble(),
            optimalRange: alertData['optimalRange']?.toString() ?? '',
            measurementId: measurement.id,
          );

          debugPrint(
            'Création d\'une nouvelle alerte (agrégée): ${newAlert.message}',
          );
          await createAlert(newAlert);
        } else {
          debugPrint(
            'Alerte existante trouvée pour type: ${alertData['type']} (agrégée)',
          );
        }
      } catch (e) {
        debugPrint('Erreur lors de la création d\'alerte agrégée: $e');
      }
    }

    if (alertsToCreate.isEmpty) {
      debugPrint('Aucune alerte nécessaire pour les seuils agrégés');
    } else {
      debugPrint(
        'Alertes créées pour seuils agrégés: ${alertsToCreate.length}',
      );
    }
  }

  // Nouvelle méthode pour vérifier et résoudre une alerte
  Future<void> checkAndResolveAlert(
    Measurement measurement,
    String? plantId,
    Map<String, dynamic>? aggregatedThresholds,
  ) async {
    if (measurement.id == null) {
      debugPrint('ID de mesure nul, impossible de vérifier l\'alerte');
      return;
    }

    debugPrint(
      'Vérification de résolution pour mesure: ${measurement.id}, plantId: $plantId',
    );

    // Récupérer les alertes existantes pour la mesure
    final existingAlerts = await getAlertsForMeasurement(measurement.id!);
    debugPrint('Alertes existantes trouvées: ${existingAlerts.length}');

    if (plantId != null) {
      await _resolveForSinglePlant(measurement, plantId, existingAlerts);
    } else if (aggregatedThresholds != null &&
        aggregatedThresholds.isNotEmpty) {
      await _resolveWithAggregatedThresholds(
        measurement,
        aggregatedThresholds,
        existingAlerts,
      );
    } else {
      debugPrint(
        'Aucun plantId ou seuils agrégés fournis, vérification annulée',
      );
    }
  }

  Future<void> _resolveForSinglePlant(
    Measurement measurement,
    String plantId,
    List<Alert> existingAlerts,
  ) async {
    try {
      // Récupérer les seuils de l'environnement pour la plante
      Map<String, dynamic>? envData = _environmentCache[plantId];
      if (envData == null) {
        final envDocs =
            await _firestore
                .collection('environnements')
                .where('plantId', isEqualTo: plantId)
                .limit(1)
                .get();
        if (envDocs.docs.isEmpty) {
          debugPrint('Aucun environnement trouvé pour la plante: $plantId');
          return;
        }
        envData = envDocs.docs.first.data();
        _environmentCache[plantId] = envData;
      }

      debugPrint(
        'Environnement pour $plantId: ${jsonEncode(serializeForDebug(envData))}',
      );

      final tempThresholds =
          envData['temperature'] as Map<String, dynamic>? ?? {};
      final airThresholds =
          (envData['humidite']?['air'] as Map<String, dynamic>?) ?? {};
      final soilThreshold = (envData['humidite']?['sol'] as num?)?.toDouble();
      final lightThresholds = envData['lumiere'] as Map<String, dynamic>? ?? {};
      final lightOptimalRange =
          lightThresholds['optimalRange'] as Map<String, dynamic>? ?? {};

      final tempMax = (tempThresholds['max'] as num?)?.toDouble();
      final tempMin = (tempThresholds['min'] as num?)?.toDouble();
      final airMax = (airThresholds['max'] as num?)?.toDouble();
      final airMin = (airThresholds['min'] as num?)?.toDouble();
      final lightMin = 800.0;
      final lightStart = (lightOptimalRange['start'] as num?)?.toInt() ?? 8;
      final lightEnd = (lightOptimalRange['end'] as num?)?.toInt() ?? 18;

      debugPrint('Seuils pour $plantId:');
      debugPrint('- Température: $tempMin°C - $tempMax°C');
      debugPrint('- Humidité air: $airMin% - $airMax%');
      debugPrint('- Humidité sol: ${soilThreshold == 1.0 ? 'Humide' : 'Sec'}');
      debugPrint(
        '- Luminosité min: $lightMin lux, plage: ${lightStart}h-${lightEnd}h',
      );

      // Vérification et résolution des alertes
      if (measurement.temperature != null &&
          tempMax != null &&
          tempMin != null) {
        if (measurement.temperature! <= tempMax &&
            measurement.temperature! >= tempMin) {
          debugPrint('Température dans les seuils, résolution des alertes');
          for (var alert in existingAlerts) {
            if (alert.plantId == plantId &&
                (alert.type == 'temperature_high' ||
                    alert.type == 'temperature_low') &&
                alert.status == 'active') {
              debugPrint(
                'Résolution de l\'alerte: ${alert.message} (ID: ${alert.id})',
              );
              await updateAlertStatus(alert.id, 'resolved');
            }
          }
        }
      }

      if (measurement.humidite != null && airMax != null && airMin != null) {
        if (measurement.humidite! <= airMax &&
            measurement.humidite! >= airMin) {
          debugPrint('Humidité air dans les seuils, résolution des alertes');
          for (var alert in existingAlerts) {
            if (alert.plantId == plantId &&
                (alert.type == 'humidity_high' ||
                    alert.type == 'humidity_low') &&
                alert.status == 'active') {
              debugPrint(
                'Résolution de l\'alerte: ${alert.message} (ID: ${alert.id})',
              );
              await updateAlertStatus(alert.id, 'resolved');
            }
          }
        }
      }

      if (measurement.humiditeSol != null && soilThreshold != null) {
        if (measurement.humiditeSol == soilThreshold) {
          debugPrint('Humidité sol dans les seuils, résolution des alertes');
          for (var alert in existingAlerts) {
            if (alert.plantId == plantId &&
                alert.type == 'soil_humidity' &&
                alert.status == 'active') {
              debugPrint(
                'Résolution de l\'alerte: ${alert.message} (ID: ${alert.id})',
              );
              await updateAlertStatus(alert.id, 'resolved');
            }
          }
        }
      }

      if (measurement.luminosite != null) {
        final currentHour = measurement.time.hour;
        final isInLightRange =
            currentHour >= lightStart && currentHour <= lightEnd;
        if (isInLightRange && measurement.luminosite! >= lightMin) {
          debugPrint('Luminosité dans les seuils, résolution des alertes');
          for (var alert in existingAlerts) {
            if (alert.plantId == plantId &&
                alert.type == 'light_low' &&
                alert.status == 'active') {
              debugPrint(
                'Résolution de l\'alerte: ${alert.message} (ID: ${alert.id})',
              );
              await updateAlertStatus(alert.id, 'resolved');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification pour la plante $plantId: $e');
    }
  }

  Future<void> _resolveWithAggregatedThresholds(
    Measurement measurement,
    Map<String, dynamic> thresholds,
    List<Alert> existingAlerts,
  ) async {
    final airThresholds = thresholds['air'] as Map<String, dynamic>? ?? {};
    final temperatureThresholds =
        thresholds['temperature'] as Map<String, dynamic>? ?? {};
    final soilThreshold = (thresholds['sol'] as num?)?.toDouble();
    final lightThresholds =
        thresholds['lumiere'] as Map<String, dynamic>? ?? {};
    final lightOptimalRange =
        lightThresholds['optimalRange'] as Map<String, dynamic>? ?? {};

    final tempMax = (temperatureThresholds['max'] as num?)?.toDouble();
    final tempMin = (temperatureThresholds['min'] as num?)?.toDouble();
    final airMax = (airThresholds['max'] as num?)?.toDouble();
    final airMin = (airThresholds['min'] as num?)?.toDouble();
    final lightMin = 800.0;
    final lightStart = (lightOptimalRange['start'] as num?)?.toInt() ?? 8;
    final lightEnd = (lightOptimalRange['end'] as num?)?.toInt() ?? 18;

    debugPrint('Vérification avec seuils agrégés:');
    debugPrint('- Température: $tempMin°C - $tempMax°C');
    debugPrint('- Humidité air: $airMin% - $airMax%');
    debugPrint('- Humidité sol: ${soilThreshold == 1.0 ? 'Humide' : 'Sec'}');
    debugPrint(
      '- Luminosité min: $lightMin lux, plage: ${lightStart}h-${lightEnd}h',
    );

    // Vérification et résolution des alertes
    if (measurement.temperature != null && tempMax != null && tempMin != null) {
      if (measurement.temperature! <= tempMax &&
          measurement.temperature! >= tempMin) {
        debugPrint(
          'Température dans les seuils (agrégée), résolution des alertes',
        );
        for (var alert in existingAlerts) {
          if (alert.plantId == null &&
              (alert.type == 'temperature_high' ||
                  alert.type == 'temperature_low') &&
              alert.status == 'active') {
            debugPrint(
              'Résolution de l\'alerte: ${alert.message} (ID: ${alert.id})',
            );
            await updateAlertStatus(alert.id, 'resolved');
          }
        }
      }
    }

    if (measurement.humidite != null && airMax != null && airMin != null) {
      if (measurement.humidite! <= airMax && measurement.humidite! >= airMin) {
        debugPrint(
          'Humidité air dans les seuils (agrégée), résolution des alertes',
        );
        for (var alert in existingAlerts) {
          if (alert.plantId == null &&
              (alert.type == 'humidity_high' || alert.type == 'humidity_low') &&
              alert.status == 'active') {
            debugPrint(
              'Résolution de l\'alerte: ${alert.message} (ID: ${alert.id})',
            );
            await updateAlertStatus(alert.id, 'resolved');
          }
        }
      }
    }

    if (measurement.humiditeSol != null && soilThreshold != null) {
      if (measurement.humiditeSol == soilThreshold) {
        debugPrint(
          'Humidité sol dans les seuils (agrégée), résolution des alertes',
        );
        for (var alert in existingAlerts) {
          if (alert.plantId == null &&
              alert.type == 'soil_humidity' &&
              alert.status == 'active') {
            debugPrint(
              'Résolution de l\'alerte: ${alert.message} (ID: ${alert.id})',
            );
            await updateAlertStatus(alert.id, 'resolved');
          }
        }
      }
    }

    if (measurement.luminosite != null) {
      final currentHour = measurement.time.hour;
      final isInLightRange =
          currentHour >= lightStart && currentHour <= lightEnd;
      if (isInLightRange && measurement.luminosite! >= lightMin) {
        debugPrint(
          'Luminosité dans les seuils (agrégée), résolution des alertes',
        );
        for (var alert in existingAlerts) {
          if (alert.plantId == null &&
              alert.type == 'light_low' &&
              alert.status == 'active') {
            debugPrint(
              'Résolution de l\'alerte: ${alert.message} (ID: ${alert.id})',
            );
            await updateAlertStatus(alert.id, 'resolved');
          }
        }
      }
    }
  }
}
