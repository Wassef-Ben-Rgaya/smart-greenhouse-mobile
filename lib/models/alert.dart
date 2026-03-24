import 'package:cloud_firestore/cloud_firestore.dart';

class Alert {
  final String id;
  final String type;
  final String message;
  final String status;
  final DateTime timestamp;
  final String? plantId;
  final String? environnementId;
  final String plantName;
  final String? plantScientificName;
  final String environnementName;
  final String severity;
  final double? value;
  final double? threshold;
  final String optimalRange;
  final DateTime? resolvedAt;
  final String? measurementId;

  Alert({
    required this.id,
    required this.type,
    required this.message,
    required this.status,
    required this.timestamp,
    this.plantId,
    this.environnementId,
    required this.plantName,
    this.plantScientificName,
    this.environnementName = '',
    required this.severity,
    this.value,
    this.threshold,
    required this.optimalRange,
    this.resolvedAt,
    this.measurementId,
  });

  String? get effectivePlantId {
    return plantId ?? environnementId;
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.parse(value);
      if (value is Timestamp) return value.toDate();
      if (value is Map<String, dynamic> && value['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          value['_seconds'] * 1000 + (value['_nanoseconds'] ~/ 1000000),
        );
      }
      return null;
    }

    return Alert(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      message: json['message'] ?? '',
      status: json['status'] ?? 'active',
      timestamp: parseDate(json['timestamp']) ?? DateTime.now(),
      plantId: json['plantId'],
      environnementId: json['environnementId'],
      plantName:
          json['plantName'] ??
          'Plante ${json['plantId'] ?? json['environnementId']}',
      plantScientificName: json['plantScientificName'],
      environnementName: json['environnementName'] ?? '',
      severity: json['severity'] ?? 'medium',
      value: json['value']?.toDouble(),
      threshold: json['threshold']?.toDouble(),
      optimalRange: json['optimalRange'] ?? 'N/A',
      resolvedAt: parseDate(json['resolvedAt']),
      measurementId: json['measurementId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'status': status,
      'timestamp':
          timestamp.toIso8601String(), // Convertir DateTime en chaîne ISO 8601
      'plantId': plantId,
      'environnementId': environnementId,
      'plantName': plantName,
      'plantScientificName': plantScientificName,
      'environnementName': environnementName,
      'severity': severity,
      'value': value,
      'threshold': threshold,
      'optimalRange': optimalRange,
      'resolvedAt':
          resolvedAt
              ?.toIso8601String(), // Convertir DateTime en chaîne ISO 8601 (peut être null)
      'measurementId': measurementId,
    };
  }

  Alert copyWith({
    String? id,
    String? type,
    String? message,
    String? status,
    DateTime? timestamp,
    String? plantId,
    String? environnementId,
    String? plantName,
    String? plantScientificName,
    String? environnementName,
    String? severity,
    double? value,
    double? threshold,
    String? optimalRange,
    DateTime? resolvedAt,
    String? measurementId,
  }) {
    return Alert(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      plantId: plantId ?? this.plantId,
      environnementId: environnementId ?? this.environnementId,
      plantName: plantName ?? this.plantName,
      plantScientificName: plantScientificName ?? this.plantScientificName,
      environnementName: environnementName ?? this.environnementName,
      severity: severity ?? this.severity,
      value: value ?? this.value,
      threshold: threshold ?? this.threshold,
      optimalRange: optimalRange ?? this.optimalRange,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      measurementId: measurementId ?? this.measurementId,
    );
  }

  @override
  String toString() {
    return 'Alert{id: $id, type: $type, plantId: $id, envId: $environnementId, plantName: $plantName, measurementId: $measurementId}';
  }
}
