// lib/models/phase.dart
class Phase {
  final String nom;
  final int duree;

  const Phase({
    required this.nom,
    required this.duree,
  });

  factory Phase.fromMap(Map<String, dynamic> map) {
    return Phase(
      nom: map['nom'] as String? ?? '',
      duree: map['duree'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'duree': duree,
    };
  }
}
