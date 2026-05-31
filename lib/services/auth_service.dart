import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  /// Initialise l'utilisateur admin par défaut s'il n'existe pas
  Future<void> initDefaultUser(Database db) async {
    final existing = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: ['admin'],
    );
    if (existing.isEmpty) {
      await db.insert('users', {
        'username': 'admin',
        'password': 'admin123', // À hasher en production
        'role': 'admin',
        'nom': 'Administrateur',
      });
    }
  }

  Future<User?> login(String username, String password) async {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (result.isNotEmpty) {
      _currentUser = User.fromMap(result.first);
      return _currentUser;
    }
    return null;
  }

  void logout() {
    _currentUser = null;
  }
}
