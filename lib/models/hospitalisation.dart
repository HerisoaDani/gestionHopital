// lib/models/hospitalisation.dart
// Représente l'admission d'un patient dans une chambre ou un bloc
//
// Une hospitalisation = un patient affecté à une chambre pendant une période
// Elle peut aussi être liée à un passage en bloc opératoire.
//
// STATUTS :
//   'en_cours'   → Patient actuellement hospitalisé
//   'sortie'     → Patient sorti (hospitalisation terminée)
//   'transfert'  → Patient transféré dans une autre chambre/hôpital

class Hospitalisation {
  int? id;
  int patientId;
  int chambreId;
  int medecinId; // Médecin responsable
  int? blocId; // null si pas de passage en bloc
  String dateEntree; // Format YYYY-MM-DD
  String heureEntree; // Format HH:MM
  String? dateSortie; // null si encore hospitalisé
  String? heureSortie;
  String motif; // Raison de l'hospitalisation
  String statut; // 'en_cours', 'sortie', 'transfert'
  String notes; // Observations du médecin
  String? diagnosticFinal; // Rempli à la sortie

  // Champs remplis par jointure SQL
  String? patientNom;
  String? medecinNom;
  String? chambreNumero;
  String? chambreType;
  String? blocNumero;

  Hospitalisation({
    this.id,
    required this.patientId,
    required this.chambreId,
    required this.medecinId,
    this.blocId,
    required this.dateEntree,
    required this.heureEntree,
    this.dateSortie,
    this.heureSortie,
    required this.motif,
    this.statut = 'en_cours',
    this.notes = '',
    this.diagnosticFinal,
    this.patientNom,
    this.medecinNom,
    this.chambreNumero,
    this.chambreType,
    this.blocNumero,
  });

  // Calcule le nombre de jours d'hospitalisation
  int get nombreJours {
    final entree = DateTime.tryParse(dateEntree);
    if (entree == null) return 0;
    final sortie = dateSortie != null
        ? DateTime.tryParse(dateSortie!) ?? DateTime.now()
        : DateTime.now();
    return sortie.difference(entree).inDays + 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'chambre_id': chambreId,
      'medecin_id': medecinId,
      'bloc_id': blocId,
      'date_entree': dateEntree,
      'heure_entree': heureEntree,
      'date_sortie': dateSortie,
      'heure_sortie': heureSortie,
      'motif': motif,
      'statut': statut,
      'notes': notes,
      'diagnostic_final': diagnosticFinal,
    };
  }

  factory Hospitalisation.fromMap(Map<String, dynamic> map) {
    return Hospitalisation(
      id: map['id'],
      patientId: map['patient_id'],
      chambreId: map['chambre_id'],
      medecinId: map['medecin_id'],
      blocId: map['bloc_id'],
      dateEntree: map['date_entree'],
      heureEntree: map['heure_entree'],
      dateSortie: map['date_sortie'],
      heureSortie: map['heure_sortie'],
      motif: map['motif'],
      statut: map['statut'] ?? 'en_cours',
      notes: map['notes'] ?? '',
      diagnosticFinal: map['diagnostic_final'],
      // Champs jointure
      patientNom: map['patient_nom'],
      medecinNom: map['medecin_nom'],
      chambreNumero: map['chambre_numero'],
      chambreType: map['chambre_type'],
      blocNumero: map['bloc_numero'],
    );
  }
}
