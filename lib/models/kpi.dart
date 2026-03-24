import 'package:flutter/foundation.dart';

class DailyTotals {
  final double dailyPumpSeconds;
  final double dailyFanSeconds;
  final double dailyHeaterSeconds;
  final double dailyLampSeconds;
  final double dailySunlightSeconds;
  final double dailyLowLightSeconds;

  DailyTotals({
    required this.dailyPumpSeconds,
    required this.dailyFanSeconds,
    required this.dailyHeaterSeconds,
    required this.dailyLampSeconds,
    required this.dailySunlightSeconds,
    required this.dailyLowLightSeconds,
  });

  factory DailyTotals.fromJson(Map<String, dynamic> json) {
    return DailyTotals(
      dailyPumpSeconds: (json['dailyPumpSeconds'] ?? 0).toDouble(),
      dailyFanSeconds: (json['dailyFanSeconds'] ?? 0).toDouble(),
      dailyHeaterSeconds: (json['dailyHeaterSeconds'] ?? 0).toDouble(),
      dailyLampSeconds: (json['dailyLampSeconds'] ?? 0).toDouble(),
      dailySunlightSeconds: (json['dailySunlightSeconds'] ?? 0).toDouble(),
      dailyLowLightSeconds: (json['dailyLowLightSeconds'] ?? 0).toDouble(),
    );
  }
}

class KPI {
  final double avgTemperature;
  final double avgHumidity;
  final double soilHumidity;
  final double avgLuminosity;
  final double sunlightDuration;
  final String? lastUpdate;
  final double ventilationDuration;
  final double heatingDuration;
  final double energyConsumption;
  final double avgWateringInterval;
  final int manualInterventionCount;
  final double lightEfficiency;
  final double totalWaterVolume;
  final String? updatedAt;
  final double pumpDuration;
  final double lampDuration;
  final double lowLightDuration;
  final DailyTotals? dailyTotals;
  final String? date;

  KPI({
    required this.avgTemperature,
    required this.avgHumidity,
    required this.soilHumidity,
    required this.avgLuminosity,
    required this.sunlightDuration,
    this.lastUpdate,
    required this.ventilationDuration,
    required this.heatingDuration,
    required this.energyConsumption,
    required this.avgWateringInterval,
    required this.manualInterventionCount,
    required this.lightEfficiency,
    required this.totalWaterVolume,
    this.updatedAt,
    required this.pumpDuration,
    required this.lampDuration,
    required this.lowLightDuration,
    this.dailyTotals,
    this.date,
  });

  factory KPI.fromJson(Map<String, dynamic> json, {String? date}) {
    debugPrint('KPI.fromJson input: $json');
    return KPI(
      avgTemperature: (json['avgTemperature'] as num?)?.toDouble() ?? 0.0,
      avgHumidity: (json['avgHumidity'] as num?)?.toDouble() ?? 0.0,
      soilHumidity: (json['soilHumidity'] as num?)?.toDouble() ?? 0.0,
      avgLuminosity: (json['avgLuminosity'] as num?)?.toDouble() ?? 0.0,
      sunlightDuration: (json['sunlightDuration'] as num?)?.toDouble() ?? 0.0,
      lastUpdate: json['lastUpdate']?.toString(),
      ventilationDuration:
          (json['ventilationDuration'] as num?)?.toDouble() ?? 0.0,
      heatingDuration: (json['heatingDuration'] as num?)?.toDouble() ?? 0.0,
      energyConsumption: (json['energyConsumption'] as num?)?.toDouble() ?? 0.0,
      avgWateringInterval:
          (json['avgWateringInterval'] as num?)?.toDouble() ?? 0.0,
      manualInterventionCount:
          (json['manualInterventionCount'] as num?)?.toInt() ?? 0,
      lightEfficiency: (json['lightEfficiency'] as num?)?.toDouble() ?? 0.0,
      totalWaterVolume: (json['totalWaterVolume'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updatedAt']?.toString(),
      pumpDuration: (json['pumpDuration'] as num?)?.toDouble() ?? 0.0,
      lampDuration: (json['lampDuration'] as num?)?.toDouble() ?? 0.0,
      lowLightDuration: (json['lowLightDuration'] as num?)?.toDouble() ?? 0.0,
      dailyTotals:
          json['dailyTotals'] != null
              ? DailyTotals.fromJson(json['dailyTotals'])
              : null,
      date: date,
    );
  }
}
