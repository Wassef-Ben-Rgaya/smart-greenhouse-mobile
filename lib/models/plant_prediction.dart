class PlantPrediction {
  final String plantId;
  final String plantName;
  final List<String> predictedPhases;

  PlantPrediction({
    required this.plantId,
    required this.plantName,
    required this.predictedPhases,
  });

  // Convertir un mappage de detected_plants en objet PlantPrediction
  factory PlantPrediction.fromMap(Map<String, dynamic> data) {
    return PlantPrediction(
      plantId: data['plant_id'],
      plantName: data['plant_name'],
      predictedPhases: List<String>.from(data['predicted_phases']),
    );
  }

  // Convertir en mappage pour Firestore (si nécessaire pour envoi)
  Map<String, dynamic> toMap() {
    return {
      'plant_id': plantId,
      'plant_name': plantName,
      'predicted_phases': predictedPhases,
    };
  }
}
