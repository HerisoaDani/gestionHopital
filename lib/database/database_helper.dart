// lib/database/database_helper.dart
// CŒUR DE L'APPLICATION : gère toute la base de données SQLite
// C'est ici que toutes les opérations CRUD (Create, Read, Update, Delete) sont définies

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/medecin.dart';
import '../models/consultation.dart';

class DatabaseHelper {
  // Singleton Pattern : une seule instance de la BDD dans toute l'app
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Getter : ouvre la BDD si elle n'est pas encore ouverte
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialise et crée la base de données
  Future<Database> _initDatabase() async {
    // Obtient le chemin vers le dossier de l'app sur l'appareil
    String path = join(await getDatabasesPath(), 'hopital.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables, // Appelé la 1ère fois que l'app est lancée
    );
  }

  // Crée toutes les tables au premier lancement
  Future<void> _createTables(Database db, int version) async {
    // Table des patients
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        date_naissance TEXT NOT NULL,
        sexe TEXT NOT NULL,
        telephone TEXT NOT NULL,
        adresse TEXT NOT NULL,
        groupe_sanguin TEXT NOT NULL
      )
    ''');

    // Table des médecins
    await db.execute('''
      CREATE TABLE medecins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        specialite TEXT NOT NULL,
        telephone TEXT NOT NULL,
        email TEXT NOT NULL,
        disponible INTEGER DEFAULT 1
      )
    ''');

    // Table des consultations
    // patient_id et medecin_id sont des clés étrangères (FOREIGN KEY)
    await db.execute('''
      CREATE TABLE consultations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        medecin_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        heure TEXT NOT NULL,
        motif TEXT NOT NULL,
        diagnostic TEXT DEFAULT '',
        traitement TEXT DEFAULT '',
        statut TEXT DEFAULT 'planifié',
        FOREIGN KEY (patient_id) REFERENCES patients (id),
        FOREIGN KEY (medecin_id) REFERENCES medecins (id)
      )
    ''');

    // Données de démonstration pour tester l'app
    await _insertDemoData(db);
  }

  // Insère des données de test au démarrage
  Future<void> _insertDemoData(Database db) async {
    await db.insert('patients', {
      'nom': 'Rakoto', 'prenom': 'Jean', 'date_naissance': '1985-03-15',
      'sexe': 'M', 'telephone': '034 12 345 67', 'adresse': 'Antananarivo',
      'groupe_sanguin': 'O+'
    });
    await db.insert('patients', {
      'nom': 'Rasoa', 'prenom': 'Marie', 'date_naissance': '1992-07-22',
      'sexe': 'F', 'telephone': '033 98 765 43', 'adresse': 'Fianarantsoa',
      'groupe_sanguin': 'A+'
    });
    await db.insert('medecins', {
      'nom': 'Andriamaro', 'prenom': 'Paul', 'specialite': 'Cardiologie',
      'telephone': '020 22 333 44', 'email': 'p.andriamaro@hopital.mg',
      'disponible': 1
    });
    await db.insert('medecins', {
      'nom': 'Ratsimbazafy', 'prenom': 'Claire', 'specialite': 'Pédiatrie',
      'telephone': '020 22 555 66', 'email': 'c.ratsimbazafy@hopital.mg',
      'disponible': 1
    });
  }

  // ═══════════════════════════════════════════
  //            CRUD - PATIENTS
  // ═══════════════════════════════════════════

  // CREATE : Ajouter un nouveau patient
  Future<int> insertPatient(Patient patient) async {
    final db = await database;
    return await db.insert('patients', patient.toMap());
  }

  // READ : Lire tous les patients
  Future<List<Patient>> getAllPatients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'patients',
      orderBy: 'nom ASC', // Triés par ordre alphabétique
    );
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  // READ : Chercher des patients par nom
  Future<List<Patient>> searchPatients(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'patients',
      where: 'nom LIKE ? OR prenom LIKE ?',
      whereArgs: ['%$query%', '%$query%'], // % = n'importe quels caractères
    );
    return List.generate(maps.length, (i) => Patient.fromMap(maps[i]));
  }

  // UPDATE : Modifier un patient existant
  Future<int> updatePatient(Patient patient) async {
    final db = await database;
    return await db.update(
      'patients',
      patient.toMap(),
      where: 'id = ?',
      whereArgs: [patient.id],
    );
  }

  // DELETE : Supprimer un patient
  Future<int> deletePatient(int id) async {
    final db = await database;
    return await db.delete('patients', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════
  //            CRUD - MÉDECINS
  // ═══════════════════════════════════════════

  Future<int> insertMedecin(Medecin medecin) async {
    final db = await database;
    return await db.insert('medecins', medecin.toMap());
  }

  Future<List<Medecin>> getAllMedecins() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'medecins',
      orderBy: 'specialite ASC',
    );
    return List.generate(maps.length, (i) => Medecin.fromMap(maps[i]));
  }

  Future<int> updateMedecin(Medecin medecin) async {
    final db = await database;
    return await db.update(
      'medecins',
      medecin.toMap(),
      where: 'id = ?',
      whereArgs: [medecin.id],
    );
  }

  Future<int> deleteMedecin(int id) async {
    final db = await database;
    return await db.delete('medecins', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════
  //          CRUD - CONSULTATIONS
  // ═══════════════════════════════════════════

  Future<int> insertConsultation(Consultation consultation) async {
    final db = await database;
    return await db.insert('consultations', consultation.toMap());
  }

  // READ avec jointure SQL : récupère aussi le nom du patient et du médecin
  Future<List<Consultation>> getAllConsultations() async {
    final db = await database;
    // JOIN = combine les données de 3 tables en une seule requête
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        c.*,
        p.nom || ' ' || p.prenom AS patient_nom,
        m.nom || ' ' || m.prenom AS medecin_nom,
        m.specialite AS medecin_specialite
      FROM consultations c
      JOIN patients p ON c.patient_id = p.id
      JOIN medecins m ON c.medecin_id = m.id
      ORDER BY c.date DESC, c.heure DESC
    ''');
    return List.generate(maps.length, (i) => Consultation.fromMap(maps[i]));
  }

  Future<int> updateConsultation(Consultation consultation) async {
    final db = await database;
    return await db.update(
      'consultations',
      consultation.toMap(),
      where: 'id = ?',
      whereArgs: [consultation.id],
    );
  }

  Future<int> deleteConsultation(int id) async {
    final db = await database;
    return await db.delete('consultations', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════
  //          STATISTIQUES (Dashboard)
  // ═══════════════════════════════════════════

  Future<Map<String, int>> getStatistiques() async {
    final db = await database;

    // COUNT(*) = compte le nombre de lignes dans une table
    final patientsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM patients')
    ) ?? 0;

    final medecinsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM medecins')
    ) ?? 0;

    final consultationsCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM consultations')
    ) ?? 0;

    final consultationsAujourdhui = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM consultations WHERE date = ?',
        [DateTime.now().toString().substring(0, 10)],
      )
    ) ?? 0;

    return {
      'patients': patientsCount,
      'medecins': medecinsCount,
      'consultations': consultationsCount,
      'consultationsAujourdhui': consultationsAujourdhui,
    };
  }
}
