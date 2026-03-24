import 'package:cloud_firestore/cloud_firestore.dart';

class Plant {
  final String? id;
  final String nom;
  final String nomScientifique;
  final String zone;
  final List<String> cultures;
  final List<String> environnements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Plant({
    this.id,
    required this.nom,
    this.nomScientifique = '',
    this.zone = 'Zone A',
    this.cultures = const [],
    this.environnements = const [],
    this.createdAt,
    this.updatedAt,
  });

  // Convertir un document Firestore en objet Plant
  factory Plant.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Plant(
      id: doc.id,
      nom: data['nom'] ?? '',
      nomScientifique: data['nomScientifique'] ?? '',
      zone: data['zone'] ?? 'Zone A',
      cultures: List<String>.from(data['cultures'] ?? []),
      environnements: List<String>.from(data['environnements'] ?? []),
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  // Convertir l'objet Plant en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'nomScientifique': nomScientifique,
      'zone': zone,
      'cultures': cultures,
      'environnements': environnements,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copier avec de nouvelles valeurs
  Plant copyWith({
    String? id,
    String? nom,
    String? nomScientifique,
    String? zone,
    List<String>? cultures,
    List<String>? environnements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plant(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      nomScientifique: nomScientifique ?? this.nomScientifique,
      zone: zone ?? this.zone,
      cultures: cultures ?? this.cultures,
      environnements: environnements ?? this.environnements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
