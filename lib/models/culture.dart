import 'package:cloud_firestore/cloud_firestore.dart';

class Phase {
  final String nom;
  final int duree; // en jours

  Phase({required this.nom, required this.duree});

  Map<String, dynamic> toMap() {
    return {'nom': nom, 'duree': duree};
  }

  factory Phase.fromMap(Map<String, dynamic> map) {
    return Phase(nom: map['nom'] ?? '', duree: map['duree'] ?? 0);
  }
}

class Culture {
  final String? id;
  final String planteId;
  final DateTime datePlantation;
  final List<Phase> phases;
  final String phaseActuelle;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Culture({
    this.id,
    required this.planteId,
    required this.datePlantation,
    required this.phases,
    required this.phaseActuelle,
    this.createdAt,
    this.updatedAt,
  });

  factory Culture.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Gestion des dates
    DateTime? parseFirestoreDate(dynamic date) {
      if (date == null) return null;
      if (date is Timestamp) return date.toDate();
      if (date is DateTime) return date;
      return null;
    }

    return Culture(
      id: doc.id,
      planteId: data['plante'] ?? '',
      datePlantation: (data['datePlantation'] as Timestamp).toDate(),
      phases: (data['phases'] as List<dynamic>?)
              ?.map((phase) => Phase.fromMap(phase))
              .toList() ??
          [],
      phaseActuelle: data['phaseActuelle'] ?? '',
      createdAt: parseFirestoreDate(data['createdAt']),
      updatedAt: parseFirestoreDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'plante': planteId,
      'datePlantation': datePlantation,
      'phases': phases.map((phase) => phase.toMap()).toList(),
      'phaseActuelle': phaseActuelle,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Culture copyWith({
    String? id,
    String? planteId,
    DateTime? datePlantation,
    List<Phase>? phases,
    String? phaseActuelle,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Culture(
      id: id ?? this.id,
      planteId: planteId ?? this.planteId,
      datePlantation: datePlantation ?? this.datePlantation,
      phases: phases ?? this.phases,
      phaseActuelle: phaseActuelle ?? this.phaseActuelle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
