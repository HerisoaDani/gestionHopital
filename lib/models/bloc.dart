// lib/models/bloc.dart
// Représente un bloc opératoire de l'hôpital
//
// Un bloc opératoire est une SALLE D'OPÉRATION (pas un lit).
// Il est réservé pour des interventions chirurgicales planifiées.
//
// STATUTS D'UN BLOC :
//   'libre'         → Disponible pour une intervention
//   'en_cours'      → Une opération est en cours
//   'nettoyage'     → Désinfection après opération (indisponible temporairement)
//   'maintenance'   → En réparation / révision technique

class Bloc {
  int? id;
  String numero; // Ex: "BO-1", "BO-2" si non calculable, on met en string
  String nom; // Ex: "Bloc Chirurgie Générale"
  String specialite; // Ex: "Chirurgie générale", "Cardiochirurgie"
  String statut; // 'libre', 'en_cours', 'nettoyage', 'maintenance'
  String etage;
  String equipements; // Liste des équipements disponibles
  String description;

  // Champs remplis par jointure (pas en BDD)
  String? prochainPatientNom;
  String? prochaineMedecinNom;

  Bloc({
    this.id,
    required this.numero,
    required this.nom,
    required this.specialite,
    this.statut = 'libre',
    required this.etage,
    this.equipements = '',
    this.description = '',
    this.prochainPatientNom,
    this.prochaineMedecinNom,
  });

  bool get estDisponible => statut == 'libre';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'nom': nom,
      'specialite': specialite,
      'statut': statut,
      'etage': etage,
      'equipements': equipements,
      'description': description,
    };
  }

  factory Bloc.fromMap(Map<String, dynamic> map) {
    return Bloc(
      id: map['id'],
      numero: map['numero'],
      nom: map['nom'],
      specialite: map['specialite'],
      statut: map['statut'] ?? 'libre',
      etage: map['etage'],
      equipements: map['equipements'] ?? '',
      description: map['description'] ?? '',
    );
  }

  static String libelleStatut(String statut) {
    switch (statut) {
      case 'libre':
        return 'Libre';
      case 'en_cours':
        return 'En cours';
      case 'nettoyage':
        return 'Nettoyage';
      case 'maintenance':
        return 'Maintenance';
      default:
        return statut;
    }
  }

  @override
  String toString() => 'Bloc{id: $id, numero: $numero, nom: $nom}';
}
