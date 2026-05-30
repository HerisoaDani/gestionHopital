// lib/models/chambre.dart
// Représente une chambre ou salle de l'hôpital
//
// TYPES DE CHAMBRES :
//   'standard'      → Chambre normale (1, 2 ou 3 lits)
//   'vip'           → Chambre privée haut de gamme
//   'urgence'       → Service des urgences
//   'reanimation'   → Soins intensifs / réanimation (USI)
//
// Les blocs opératoires sont dans le modèle Bloc (fichier séparé)
// car leur logique est différente (pas de lits, mais des salles d'opération)

class Chambre {
  int? id;
  String numero; // Ex: "101", "USI-3", "URG-5"
  String type; // 'standard', 'vip', 'urgence', 'reanimation'
  int capacite; // Nombre de lits dans la chambre
  int litsOccupes; // Calculé dynamiquement (mis à jour par les hospitalisations)
  String etage; // Ex: "Rez-de-chaussée", "1er étage"
  String description; // Notes supplémentaires
  bool disponible; // false = chambre hors service (travaux, nettoyage...)

  Chambre({
    this.id,
    required this.numero,
    required this.type,
    required this.capacite,
    this.litsOccupes = 0,
    required this.etage,
    this.description = '',
    this.disponible = true,
  });

  // Calcule si la chambre a encore de la place
  bool get aDePlace => litsOccupes < capacite && disponible;

  // Nombre de lits libres
  int get litsLibres => capacite - litsOccupes;

  // Taux d'occupation en pourcentage
  double get tauxOccupation =>
      capacite > 0 ? (litsOccupes / capacite) * 100 : 0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'type': type,
      'capacite': capacite,
      'lits_occupes': litsOccupes,
      'etage': etage,
      'description': description,
      'disponible': disponible ? 1 : 0,
    };
  }

  factory Chambre.fromMap(Map<String, dynamic> map) {
    return Chambre(
      id: map['id'],
      numero: map['numero'],
      type: map['type'],
      capacite: map['capacite'],
      litsOccupes: map['lits_occupes'] ?? 0,
      etage: map['etage'],
      description: map['description'] ?? '',
      disponible: map['disponible'] == 1,
    );
  }

  // Libellé lisible du type
  static String libelleType(String type) {
    switch (type) {
      case 'standard':
        return 'Chambre Standard';
      case 'vip':
        return 'Chambre VIP';
      case 'urgence':
        return 'Urgences';
      case 'reanimation':
        return 'Réanimation / USI';
      default:
        return type;
    }
  }

  @override
  String toString() => 'Chambre{id: $id, numero: $numero, type: $type}';
}
