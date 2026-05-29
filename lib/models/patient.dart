// lib/models/patient.dart
// Ce fichier définit la structure d'un Patient dans l'application

class Patient {
  int? id;           // Identifiant unique (auto-généré par SQLite)
  String nom;        // Nom de famille
  String prenom;     // Prénom
  String dateNaissance; // Format : YYYY-MM-DD
  String sexe;       // 'M' ou 'F'
  String telephone;
  String adresse;
  String groupeSanguin; // Ex: 'A+', 'B-', 'O+', 'AB+'

  Patient({
    this.id,
    required this.nom,
    required this.prenom,
    required this.dateNaissance,
    required this.sexe,
    required this.telephone,
    required this.adresse,
    required this.groupeSanguin,
  });

  // Convertit un Patient en Map (pour l'enregistrer dans SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'date_naissance': dateNaissance,
      'sexe': sexe,
      'telephone': telephone,
      'adresse': adresse,
      'groupe_sanguin': groupeSanguin,
    };
  }

  // Crée un Patient à partir d'un Map (quand on lit SQLite)
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      dateNaissance: map['date_naissance'],
      sexe: map['sexe'],
      telephone: map['telephone'],
      adresse: map['adresse'],
      groupeSanguin: map['groupe_sanguin'],
    );
  }

  // Utile pour le débogage
  @override
  String toString() {
    return 'Patient{id: $id, nom: $nom, prenom: $prenom}';
  }
}
