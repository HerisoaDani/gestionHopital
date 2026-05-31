class User {
  final int? id;
  final String username;
  final String password;
  final String role;
  final String nom;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.nom,
  });

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'],
        username: map['username'],
        password: map['password'],
        role: map['role'],
        nom: map['nom'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password': password,
        'role': role,
        'nom': nom,
      };
}
