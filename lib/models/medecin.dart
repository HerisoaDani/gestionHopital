// lib/models/medecin.dart
// Ce fichier définit la structure d'un Médecin

class Medecin {
  int? id;
  String nom;
  String prenom;
  String specialite;  // Ex: 'Cardiologie', 'Pédiatrie', etc.
  String telephone;
  String email;
  bool disponible;    // true = disponible pour consultations

  Medecin({
    this.id,
    required this.nom,
    required this.prenom,
    required this.specialite,
    required this.telephone,
    required this.email,
    this.disponible = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'specialite': specialite,
      'telephone': telephone,
      'email': email,
      'disponible': disponible ? 1 : 0, // SQLite stocke les booléens en 0/1
    };
  }

  factory Medecin.fromMap(Map<String, dynamic> map) {
    return Medecin(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      specialite: map['specialite'],
      telephone: map['telephone'],
      email: map['email'],
      disponible: map['disponible'] == 1,
    );
  }

  @override
  String toString() {
    return 'Medecin{id: $id, nom: $nom, specialite: $specialite}';
  }
}
