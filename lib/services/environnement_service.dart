import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/environnement.dart';

class EnvironnementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Environnement?> getEnvironnementForPlant(String plantId) async {
    try {
      final plantDoc = await _firestore.collection('plants').doc(plantId).get();
      final envIds = plantDoc.data()?['environnements'] as List?;

      if (envIds == null || envIds.isEmpty) return null;

      // Prend le premier environnement (vous pourriez aussi les tous charger)
      final envDoc =
          await _firestore.collection('environnements').doc(envIds.first).get();

      return Environnement.fromFirestore(envDoc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'environnement: $e');
    }
  }

  Future<void> addEnvironnement(Environnement environnement) async {
    try {
      await _firestore
          .collection('environnements')
          .add(environnement.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'environnement: $e');
    }
  }

  Future<void> updateEnvironnement(Environnement environnement) async {
    try {
      if (environnement.id == null) {
        throw Exception('ID d\'environnement manquant');
      }
      await _firestore
          .collection('environnements')
          .doc(environnement.id)
          .update(environnement.toFirestore());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'environnement: $e');
    }
  }

  Future<void> deleteEnvironnementForPlant(String plantId) async {
    try {
      await _firestore.collection('plants').doc(plantId).update({
        'environnement': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'environnement: $e');
    }
  }

  Future<void> saveEnvironnementForPlant(
    String plantId,
    Environnement environnement,
  ) async {
    try {
      // Crée un nouveau document dans la collection 'environnements'
      final envDoc = await _firestore.collection('environnements').add({
        ...environnement.toFirestore(),
        'plante': plantId, // Référence à la plante
      });

      // Met à jour la plante avec la référence à l'environnement
      await _firestore.collection('plants').doc(plantId).update({
        'environnements': FieldValue.arrayUnion([envDoc.id]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de l\'environnement: $e');
    }
  }
}
