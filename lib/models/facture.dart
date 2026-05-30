// lib/models/facture.dart

class LigneFacture {
  String description;
  int quantite;
  double prixUnitaire;

  LigneFacture({
    required this.description,
    required this.quantite,
    required this.prixUnitaire,
  });

  double get montant => quantite * prixUnitaire;

  Map<String, dynamic> toMap() => {
        'description': description,
        'quantite': quantite,
        'prix_unitaire': prixUnitaire,
      };

  factory LigneFacture.fromMap(Map<String, dynamic> m) => LigneFacture(
        description: m['description'],
        quantite: m['quantite'],
        prixUnitaire: m['prix_unitaire'].toDouble(),
      );
}

class Facture {
  int? id;
  String numero; // Ex: "FACT-2024-001"
  String type; // 'consultation', 'hospitalisation', 'operation'
  int? consultationId;
  int? hospitalisationId;
  int patientId;
  String date; // YYYY-MM-DD
  String statut; // 'en_attente', 'payee', 'annulee'
  String modePaiement; // 'especes', 'mobile_money', 'carte', 'assurance'
  double remise; // Pourcentage de remise (0-100)
  String notes;

  // Champs jointure
  String? patientNom;
  List<LigneFacture> lignes;

  Facture({
    this.id,
    required this.numero,
    required this.type,
    this.consultationId,
    this.hospitalisationId,
    required this.patientId,
    required this.date,
    this.statut = 'en_attente',
    this.modePaiement = 'especes',
    this.remise = 0,
    this.notes = '',
    this.patientNom,
    this.lignes = const [],
  });

  // Calculs
  double get sousTotal => lignes.fold(0, (s, l) => s + l.montant);
  double get montantRemise => sousTotal * remise / 100;
  double get total => sousTotal - montantRemise;

  Map<String, dynamic> toMap() => {
        'id': id,
        'numero': numero,
        'type': type,
        'consultation_id': consultationId,
        'hospitalisation_id': hospitalisationId,
        'patient_id': patientId,
        'date': date,
        'statut': statut,
        'mode_paiement': modePaiement,
        'remise': remise,
        'notes': notes,
      };

  factory Facture.fromMap(Map<String, dynamic> m) => Facture(
        id: m['id'],
        numero: m['numero'],
        type: m['type'],
        consultationId: m['consultation_id'],
        hospitalisationId: m['hospitalisation_id'],
        patientId: m['patient_id'],
        date: m['date'],
        statut: m['statut'] ?? 'en_attente',
        modePaiement: m['mode_paiement'] ?? 'especes',
        remise: (m['remise'] ?? 0).toDouble(),
        notes: m['notes'] ?? '',
        patientNom: m['patient_nom'],
        lignes: [], // chargées séparément
      );

  static String libelleStatut(String s) {
    switch (s) {
      case 'en_attente':
        return 'En attente';
      case 'payee':
        return 'Payée';
      case 'annulee':
        return 'Annulée';
      default:
        return s;
    }
  }

  static String libelleType(String t) {
    switch (t) {
      case 'consultation':
        return 'Consultation';
      case 'hospitalisation':
        return 'Hospitalisation';
      case 'operation':
        return 'Bloc opératoire';
      default:
        return t;
    }
  }
}
