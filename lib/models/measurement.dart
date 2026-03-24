import 'package:intl/intl.dart';

class Measurement {
  final String? id;
  final bool? chauffage;
  final double? humidite;
  final double? humiditeSol;
  final bool? lampe;
  final double? luminosite;
  final bool? pompe;
  final double? temperature;
  final bool? ventilateur;
  final DateTime time;

  Measurement({
    this.id,
    this.chauffage,
    this.humidite,
    this.humiditeSol,
    this.lampe,
    this.luminosite,
    this.pompe,
    this.temperature,
    this.ventilateur,
    required this.time,
  });

  static bool toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value == 'true') return true;
    if (value == 'false') return false;
    return false;
  }

  factory Measurement.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseTime(dynamic time) {
      if (time is int) {
        return DateTime.fromMillisecondsSinceEpoch(time).toLocal();
      }
      if (time is String) {
        final cleanedTime = time.trim().replaceAll("'", '');
        try {
          return DateTime.parse(cleanedTime).toLocal();
        } catch (e) {
          try {
            return DateFormat(
              'dd/MM/yyyy HH:mm:ss',
            ).parse(cleanedTime).toLocal();
          } catch (e) {
            print('Failed to parse time: $time');
            return DateTime.now().toLocal();
          }
        }
      }
      return DateTime.now().toLocal();
    }

    // Helper to get double value
    double? getDoubleValue(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Measurement(
      id: id,
      time: parseTime(id), // Utilise l'id comme timestamp principal
      temperature: getDoubleValue(json['Température']),
      humidite: getDoubleValue(json['Humidité']),
      humiditeSol: getDoubleValue(json['Humidité du sol']),
      luminosite: getDoubleValue(json['Luminosité']),
      chauffage: toBool(json['Chauffage']),
      lampe: toBool(json['Lampe']),
      pompe: toBool(json['Pompe']),
      ventilateur: toBool(json['Ventilateur']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Conserve l'id comme timestamp
      'Chauffage': chauffage,
      'Humidité': humidite,
      'Humidité du sol': humiditeSol,
      'Lampe': lampe,
      'Luminosité': luminosite,
      'Pompe': pompe,
      'Température': temperature,
      'Ventilateur': ventilateur,
      'time': time.toIso8601String(), // Pour compatibilité
    };
  }

  Measurement copyWith({
    String? id,
    bool? chauffage,
    double? humidite,
    double? humiditeSol,
    bool? lampe,
    double? luminosite,
    bool? pompe,
    double? temperature,
    bool? ventilateur,
    DateTime? time,
  }) {
    return Measurement(
      id: id ?? this.id,
      time: time ?? this.time,
      chauffage: chauffage ?? this.chauffage,
      humidite: humidite ?? this.humidite,
      humiditeSol: humiditeSol ?? this.humiditeSol,
      lampe: lampe ?? this.lampe,
      luminosite: luminosite ?? this.luminosite,
      pompe: pompe ?? this.pompe,
      temperature: temperature ?? this.temperature,
      ventilateur: ventilateur ?? this.ventilateur,
    );
  }
}
