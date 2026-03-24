import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant_prediction.dart';

class PlantPredictionService {
  final CollectionReference _predictionsCollection = FirebaseFirestore.instance
      .collection('plant_predictions');

  // Récupérer les prédictions triées par timestamp et regroupées par image_url
  Future<Map<String, Map<String, dynamic>>> getGroupedPredictions() async {
    try {
      final querySnapshot =
          await _predictionsCollection
              .orderBy('timestamp', descending: true)
              .get();
      Map<String, Map<String, dynamic>> groupedPredictions = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final imageUrl = data['image_url'];
        final timestamp = data['timestamp'] as Timestamp;
        final detectedPlants =
            (data['detected_plants'] as List)
                .map(
                  (plant) =>
                      PlantPrediction.fromMap(plant as Map<String, dynamic>),
                )
                .toList();

        groupedPredictions[imageUrl] = {
          'timestamp': timestamp,
          'detected_plants': detectedPlants,
        };
      }

      return groupedPredictions;
    } catch (e) {
      print('Erreur lors de la récupération des prédictions : $e');
      return {};
    }
  }

  // Supprimer une prédiction (supprime le document entier pour l'instant)
  Future<void> deletePrediction(String imageUrl) async {
    try {
      final querySnapshot =
          await _predictionsCollection
              .where('image_url', isEqualTo: imageUrl)
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        await _predictionsCollection.doc(querySnapshot.docs.first.id).delete();
      }
    } catch (e) {
      print('Erreur lors de la suppression de la prédiction : $e');
    }
  }

  // Mettre à jour l'URL de l'image
  Future<void> updateImageUrl(String imageUrl, String newImageUrl) async {
    try {
      final querySnapshot =
          await _predictionsCollection
              .where('image_url', isEqualTo: imageUrl)
              .limit(1)
              .get();
      if (querySnapshot.docs.isNotEmpty) {
        await _predictionsCollection.doc(querySnapshot.docs.first.id).update({
          'image_url': newImageUrl,
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'URL de l\'image : $e');
    }
  }
}
