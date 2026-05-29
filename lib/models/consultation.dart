// lib/models/consultation.dart
// Représente une consultation médicale (lien entre Patient et Médecin)

class Consultation {
  int? id;
  int patientId;      // Référence vers le patient
  int medecinId;      // Référence vers le médecin
  String date;        // Format : YYYY-MM-DD
  String heure;       // Format : HH:MM
  String motif;       // Raison de la consultation
  String diagnostic;  // Résultat du médecin
  String traitement;  // Médicaments / soins prescrits
  String statut;      // 'planifié', 'en_cours', 'terminé', 'annulé'

  // Ces champs sont remplis par jointure SQL (pas stockés directement)
  String? patientNom;
  String? medecinNom;
  String? medecinSpecialite;

  Consultation({
    this.id,
    required this.patientId,
    required this.medecinId,
    required this.date,
    required this.heure,
    required this.motif,
    this.diagnostic = '',
    this.traitement = '',
    this.statut = 'planifié',
    this.patientNom,
    this.medecinNom,
    this.medecinSpecialite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'medecin_id': medecinId,
      'date': date,
      'heure': heure,
      'motif': motif,
      'diagnostic': diagnostic,
      'traitement': traitement,
      'statut': statut,
    };
  }

  factory Consultation.fromMap(Map<String, dynamic> map) {
    return Consultation(
      id: map['id'],
      patientId: map['patient_id'],
      medecinId: map['medecin_id'],
      date: map['date'],
      heure: map['heure'],
      motif: map['motif'],
      diagnostic: map['diagnostic'] ?? '',
      traitement: map['traitement'] ?? '',
      statut: map['statut'] ?? 'planifié',
      // Ces champs viennent d'une jointure SQL
      patientNom: map['patient_nom'],
      medecinNom: map['medecin_nom'],
      medecinSpecialite: map['medecin_specialite'],
    );
  }
}
