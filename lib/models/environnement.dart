import 'package:cloud_firestore/cloud_firestore.dart';

class Temperature {
  final double? min;
  final double? max;

  Temperature({this.min, this.max});

  factory Temperature.fromMap(Map<String, dynamic> map) {
    return Temperature(
      min: map['min']?.toDouble(),
      max: map['max']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'min': min, 'max': max};
  }

  Temperature copyWith({double? min, double? max}) {
    return Temperature(min: min ?? this.min, max: max ?? this.max);
  }
}

class HumiditeAir {
  final double? min;
  final double? max;

  HumiditeAir({this.min, this.max});

  factory HumiditeAir.fromMap(Map<String, dynamic> map) {
    return HumiditeAir(
      min: map['min']?.toDouble(),
      max: map['max']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'min': min, 'max': max};
  }

  HumiditeAir copyWith({double? min, double? max}) {
    return HumiditeAir(min: min ?? this.min, max: max ?? this.max);
  }
}

class Humidite {
  final HumiditeAir air;
  final double? sol;

  Humidite({required this.air, this.sol});

  factory Humidite.fromMap(Map<String, dynamic> map) {
    return Humidite(
      air: HumiditeAir.fromMap(map['air'] ?? {}),
      sol: map['sol']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'air': air.toJson(), 'sol': sol};
  }

  Humidite copyWith({HumiditeAir? air, double? sol}) {
    return Humidite(air: air ?? this.air, sol: sol ?? this.sol);
  }
}

class TimeRange {
  final int start;
  final int end;

  TimeRange({required this.start, required this.end});

  factory TimeRange.fromMap(Map<String, dynamic> map) {
    return TimeRange(start: map['start'] ?? 7, end: map['end'] ?? 19);
  }

  Map<String, dynamic> toJson() {
    return {'start': start, 'end': end};
  }

  TimeRange copyWith({int? start, int? end}) {
    return TimeRange(start: start ?? this.start, end: end ?? this.end);
  }
}

class Lumiere {
  static const String pleine = 'Pleine';
  static const String miOmbre = 'Mi-ombre';
  static const String ombre = 'Ombre';
  final int? duree;
  final String? type;
  final TimeRange optimalRange;

  Lumiere({this.duree, this.type, required this.optimalRange});

  factory Lumiere.fromMap(Map<String, dynamic> map) {
    return Lumiere(
      duree: map['duree'],
      type: map['type'],
      optimalRange: TimeRange.fromMap(map['optimalRange'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duree': duree,
      'type': type,
      'optimalRange': optimalRange.toJson(),
    };
  }

  Lumiere copyWith({int? duree, String? type, TimeRange? optimalRange}) {
    return Lumiere(
      duree: duree ?? this.duree,
      type: type ?? this.type,
      optimalRange: optimalRange ?? this.optimalRange,
    );
  }
}

class Environnement {
  final String? id;
  final String plantId;
  final Temperature temperature;
  final Humidite humidite;
  final Lumiere lumiere;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Environnement({
    this.id,
    required this.plantId,
    required this.temperature,
    required this.humidite,
    required this.lumiere,
    this.createdAt,
    this.updatedAt,
  });

  factory Environnement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Environnement(
      id: doc.id,
      plantId: data['plante'] ?? '',
      temperature: Temperature.fromMap(data['temperature'] ?? {}),
      humidite: Humidite.fromMap(data['humidite'] ?? {}),
      lumiere: Lumiere.fromMap(data['lumiere'] ?? {}),
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'plante': plantId,
      'temperature': temperature.toJson(),
      'humidite': humidite.toJson(),
      'lumiere': lumiere.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Environnement copyWith({
    String? id,
    String? plantId,
    Temperature? temperature,
    Humidite? humidite,
    Lumiere? lumiere,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Environnement(
      id: id ?? this.id,
      plantId: plantId ?? this.plantId,
      temperature: temperature ?? this.temperature,
      humidite: humidite ?? this.humidite,
      lumiere: lumiere ?? this.lumiere,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Environnement.fromMap(Map<String, dynamic> map) {
    return Environnement(
      plantId: map['plante'] ?? '',
      temperature: Temperature.fromMap(map['temperature'] ?? {}),
      humidite: Humidite.fromMap(map['humidite'] ?? {}),
      lumiere: Lumiere.fromMap(map['lumiere'] ?? {}),
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plante': plantId,
      'temperature': temperature.toJson(),
      'humidite': humidite.toJson(),
      'lumiere': lumiere.toJson(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
