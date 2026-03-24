import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant.dart';

class PlantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Plant>> getPlants() async {
    try {
      final query = await _firestore.collection('plants').get();
      return query.docs.map((doc) => Plant.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to load plants: $e');
    }
  }
}
