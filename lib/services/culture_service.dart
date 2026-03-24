import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/culture.dart';

class CultureService {
  final String plantId;

  CultureService({required this.plantId});

  // Récupérer toutes les cultures d'une plante
  Future<List<Culture>> getCulturesByPlant() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('cultures')
          .where('plante', isEqualTo: plantId)
          .get();

      return querySnapshot.docs
          .map((doc) => Culture.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cultures: $e');
    }
  }

  // Créer une nouvelle culture
  Future<String> createCulture(Culture culture) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('cultures')
          .add(culture.toFirestore());

      // Lier la culture à la plante
      await FirebaseFirestore.instance
          .collection('plants')
          .doc(plantId)
          .update({
        'cultures': FieldValue.arrayUnion([docRef.id])
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Erreur lors de la création de la culture: $e');
    }
  }

  // Mettre à jour une culture
  Future<void> updateCulture(String cultureId, Culture culture) async {
    await FirebaseFirestore.instance
        .collection('cultures') // ✅ CORRIGÉ
        .doc(cultureId)
        .update(culture.toFirestore());
  }

  // Supprimer une culture
  Future<void> deleteCulture(String cultureId) async {
    try {
      // Supprimer la référence dans la plante
      await FirebaseFirestore.instance
          .collection('plants')
          .doc(plantId)
          .update({
        'cultures': FieldValue.arrayRemove([cultureId])
      });

      // Supprimer la culture
      await FirebaseFirestore.instance
          .collection('cultures')
          .doc(cultureId)
          .delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la culture: $e');
    }
  }

  // Mettre à jour la phase actuelle (version optimisée)
  Future<void> updateCulturePhase(String cultureId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('cultures')
          .doc(cultureId)
          .get();

      if (!doc.exists) return;

      final culture = Culture.fromFirestore(doc);
      final now = DateTime.now();
      final plantedDate = culture.datePlantation is Timestamp
          ? (culture.datePlantation as Timestamp).toDate()
          : culture.datePlantation;

      final elapsedDays = now.difference(plantedDate).inDays;
      int accumulatedDays = 0;
      String newPhase = 'Épuisé';

      // Trouver la phase actuelle
      for (final phase in culture.phases) {
        accumulatedDays += phase.duree;
        if (elapsedDays < accumulatedDays) {
          newPhase = phase.nom;
          break;
        }
      }

      // Mettre à jour seulement si nécessaire
      if (culture.phaseActuelle != newPhase) {
        await doc.reference.update({
          'phaseActuelle': newPhase,
          'updatedAt': FieldValue.serverTimestamp()
        });
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la phase: $e');
    }
  }

  // Méthode batch pour mettre à jour toutes les phases
  Future<void> updateAllPhases() async {
    try {
      final cultures = await getCulturesByPlant();
      await Future.wait(cultures.map((culture) => culture.id != null
          ? updateCulturePhase(culture.id!)
          : Future.value()));
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des phases: $e');
    }
  }
}

Future<void> triggerPhaseRecalculation(String cultureId) async {
  try {
    await FirebaseFirestore.instance
        .collection('cultures')
        .doc(cultureId)
        .update({
      'lastPhaseCheck': FieldValue.serverTimestamp(),
      'needsPhaseUpdate': true
    });
  } catch (e) {
    throw Exception('Trigger failed: $e');
  }
}
