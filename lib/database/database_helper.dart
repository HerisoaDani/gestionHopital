// lib/database/database_helper.dart
// CŒUR DE L'APPLICATION : gère toute la base de données SQLite
// C'est ici que toutes les opérations CRUD (Create, Read, Update, Delete) sont définies

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/patient.dart';
import '../models/medecin.dart';
import '../models/consultation.dart';
import '../models/chambre.dart';
import '../models/bloc.dart';
import '../models/hospitalisation.dart';

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
      version: 2, // ← version 2 pour les nouvelles tables
      onCreate: _createTables,
      onUpgrade: _onUpgrade, // ← migration si l'app était déjà installée
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
    await _createNouvellesTables(db);
    await _insertDemoDataHospitalisation(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createNouvellesTables(db);
      await _insertDemoDataHospitalisation(db);
    }
  }

  // Crée uniquement les nouvelles tables (pour migration ou création initiale)
  Future<void> _createNouvellesTables(Database db) async {
    // Table des chambres
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chambres (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        capacite INTEGER NOT NULL DEFAULT 1,
        lits_occupes INTEGER NOT NULL DEFAULT 0,
        etage TEXT NOT NULL,
        description TEXT DEFAULT '',
        disponible INTEGER DEFAULT 1
      )
    ''');

    // Table des blocs opératoires
    await db.execute('''
      CREATE TABLE IF NOT EXISTS blocs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero TEXT NOT NULL UNIQUE,
        nom TEXT NOT NULL,
        specialite TEXT NOT NULL,
        statut TEXT DEFAULT 'libre',
        etage TEXT NOT NULL,
        equipements TEXT DEFAULT '',
        description TEXT DEFAULT ''
      )
    ''');

    // Table des hospitalisations
    // Lien entre : patient + chambre + médecin (+ bloc optionnel)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS hospitalisations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        chambre_id INTEGER NOT NULL,
        medecin_id INTEGER NOT NULL,
        bloc_id INTEGER,
        date_entree TEXT NOT NULL,
        heure_entree TEXT NOT NULL,
        date_sortie TEXT,
        heure_sortie TEXT,
        motif TEXT NOT NULL,
        statut TEXT DEFAULT 'en_cours',
        notes TEXT DEFAULT '',
        diagnostic_final TEXT,
        FOREIGN KEY (patient_id)  REFERENCES patients (id),
        FOREIGN KEY (chambre_id)  REFERENCES chambres (id),
        FOREIGN KEY (medecin_id)  REFERENCES medecins (id),
        FOREIGN KEY (bloc_id)     REFERENCES blocs (id)
      )
    ''');
  }

  // Insère des données de test (chambres et blocs)
  Future<void> _insertDemoDataHospitalisation(Database db) async {
    // Chambres standard
    await db.insert('chambres', {
      'numero': '101',
      'type': 'standard',
      'capacite': 3,
      'lits_occupes': 0,
      'etage': '1er étage',
      'description': 'Chambre standard 3 lits',
      'disponible': 1
    });
    await db.insert('chambres', {
      'numero': '102',
      'type': 'standard',
      'capacite': 2,
      'lits_occupes': 0,
      'etage': '1er étage',
      'description': 'Chambre standard 2 lits',
      'disponible': 1
    });
    await db.insert('chambres', {
      'numero': '201',
      'type': 'vip',
      'capacite': 1,
      'lits_occupes': 0,
      'etage': '2e étage',
      'description': 'Suite privée',
      'disponible': 1
    });
    // Urgences
    await db.insert('chambres', {
      'numero': 'URG-1',
      'type': 'urgence',
      'capacite': 4,
      'lits_occupes': 0,
      'etage': 'RDC',
      'description': 'Salle des urgences principale',
      'disponible': 1
    });
    await db.insert('chambres', {
      'numero': 'URG-2',
      'type': 'urgence',
      'capacite': 2,
      'lits_occupes': 0,
      'etage': 'RDC',
      'description': 'Box urgences pédiatriques',
      'disponible': 1
    });
    // Réanimation
    await db.insert('chambres', {
      'numero': 'REA-1',
      'type': 'reanimation',
      'capacite': 6,
      'lits_occupes': 0,
      'etage': 'RDC',
      'description': 'Unité de soins intensifs',
      'disponible': 1
    });

    // Blocs opératoires
    await db.insert('blocs', {
      'numero': 'BO-1',
      'nom': 'Bloc Chirurgie Générale',
      'specialite': 'Chirurgie générale',
      'statut': 'libre',
      'etage': 'Sous-sol',
      'equipements': 'Table op., Anesthésie, Bistouri électrique',
      'description': 'Bloc principal polyvalent'
    });
    await db.insert('blocs', {
      'numero': 'BO-2',
      'nom': 'Bloc Cardiochirurgie',
      'specialite': 'Cardiochirurgie',
      'statut': 'libre',
      'etage': 'Sous-sol',
      'equipements': 'CEC, Défibrillateur, Monitoring avancé',
      'description': 'Chirurgie cardiaque et vasculaire'
    });
    await db.insert('blocs', {
      'numero': 'BO-3',
      'nom': 'Bloc Orthopédie',
      'specialite': 'Orthopédie',
      'statut': 'libre',
      'etage': 'Sous-sol',
      'equipements': 'Amplificateur de brillance, Traction',
      'description': 'Chirurgie osseuse et articulaire'
    });
  }

  // ═══════════════════════════════════════════
  //            CRUD - CHAMBRES
  // ═══════════════════════════════════════════

  Future<int> insertChambre(Chambre chambre) async {
    final db = await database;
    return await db.insert('chambres', chambre.toMap());
  }

  Future<List<Chambre>> getAllChambres() async {
    final db = await database;
    // Recalcule lits_occupes depuis les hospitalisations en cours
    final maps = await db.rawQuery('''
      SELECT c.*,
        (SELECT COUNT(*) FROM hospitalisations h
         WHERE h.chambre_id = c.id AND h.statut = 'en_cours') AS lits_occupes
      FROM chambres c
      ORDER BY c.type ASC, c.numero ASC
    ''');
    return maps.map((m) => Chambre.fromMap(Map.of(m))).toList();
  }

  Future<List<Chambre>> getChambresDisponibles() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT c.*,
        (SELECT COUNT(*) FROM hospitalisations h
         WHERE h.chambre_id = c.id AND h.statut = 'en_cours') AS lits_occupes
      FROM chambres c
      WHERE c.disponible = 1
      ORDER BY c.type ASC, c.numero ASC
    ''');
    // Filtrer celles qui ont encore de la place
    return maps
        .map((m) => Chambre.fromMap(Map.of(m)))
        .where((c) => c.aDePlace)
        .toList();
  }

  Future<int> updateChambre(Chambre chambre) async {
    final db = await database;
    return await db.update('chambres', chambre.toMap(),
        where: 'id = ?', whereArgs: [chambre.id]);
  }

  Future<int> deleteChambre(int id) async {
    final db = await database;
    return await db.delete('chambres', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════
  //            CRUD - BLOCS
  // ═══════════════════════════════════════════

  Future<int> insertBloc(Bloc bloc) async {
    final db = await database;
    return await db.insert('blocs', bloc.toMap());
  }

  Future<List<Bloc>> getAllBlocs() async {
    final db = await database;
    final maps = await db.query('blocs', orderBy: 'numero ASC');
    return maps.map((m) => Bloc.fromMap(m)).toList();
  }

  Future<int> updateBloc(Bloc bloc) async {
    final db = await database;
    return await db
        .update('blocs', bloc.toMap(), where: 'id = ?', whereArgs: [bloc.id]);
  }

  Future<int> updateStatutBloc(int id, String statut) async {
    final db = await database;
    return await db.update('blocs', {'statut': statut},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBloc(int id) async {
    final db = await database;
    return await db.delete('blocs', where: 'id = ?', whereArgs: [id]);
  }

  // ═══════════════════════════════════════════
  //         CRUD - HOSPITALISATIONS
  // ═══════════════════════════════════════════

  Future<int> insertHospitalisation(Hospitalisation h) async {
    final db = await database;
    return await db.insert('hospitalisations', h.toMap());
  }

  // Lecture avec jointure : récupère les noms patient, médecin, chambre, bloc
  Future<List<Hospitalisation>> getAllHospitalisations() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT
        h.*,
        p.nom || ' ' || p.prenom           AS patient_nom,
        m.nom || ' ' || m.prenom           AS medecin_nom,
        c.numero                           AS chambre_numero,
        c.type                             AS chambre_type,
        b.numero                           AS bloc_numero
      FROM hospitalisations h
      JOIN patients  p ON h.patient_id = p.id
      JOIN medecins  m ON h.medecin_id  = m.id
      JOIN chambres  c ON h.chambre_id  = c.id
      LEFT JOIN blocs b ON h.bloc_id    = b.id
      ORDER BY
        CASE h.statut WHEN 'en_cours' THEN 0 ELSE 1 END,
        h.date_entree DESC
    ''');
    return maps.map((m) => Hospitalisation.fromMap(Map.of(m))).toList();
  }

  // Hospitalisations en cours uniquement
  Future<List<Hospitalisation>> getHospitalisationsEnCours() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT
        h.*,
        p.nom || ' ' || p.prenom AS patient_nom,
        m.nom || ' ' || m.prenom AS medecin_nom,
        c.numero                 AS chambre_numero,
        c.type                   AS chambre_type,
        b.numero                 AS bloc_numero
      FROM hospitalisations h
      JOIN patients p ON h.patient_id = p.id
      JOIN medecins m ON h.medecin_id  = m.id
      JOIN chambres c ON h.chambre_id  = c.id
      LEFT JOIN blocs b ON h.bloc_id   = b.id
      WHERE h.statut = 'en_cours'
      ORDER BY h.date_entree DESC
    ''');
    return maps.map((m) => Hospitalisation.fromMap(Map.of(m))).toList();
  }

  Future<int> updateHospitalisation(Hospitalisation h) async {
    final db = await database;
    return await db.update('hospitalisations', h.toMap(),
        where: 'id = ?', whereArgs: [h.id]);
  }

  // Enregistre la sortie d'un patient
  Future<int> enregistrerSortie(int id, String dateSortie, String heureSortie,
      String diagnosticFinal) async {
    final db = await database;
    return await db.update(
      'hospitalisations',
      {
        'statut': 'sortie',
        'date_sortie': dateSortie,
        'heure_sortie': heureSortie,
        'diagnostic_final': diagnosticFinal,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteHospitalisation(int id) async {
    final db = await database;
    return await db
        .delete('hospitalisations', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _insertDemoData(Database db) async {
    await db.insert('patients', {
      'nom': 'Rakoto',
      'prenom': 'Jean',
      'date_naissance': '1985-03-15',
      'sexe': 'M',
      'telephone': '034 12 345 67',
      'adresse': 'Antananarivo',
      'groupe_sanguin': 'O+'
    });
    await db.insert('patients', {
      'nom': 'Rasoa',
      'prenom': 'Marie',
      'date_naissance': '1992-07-22',
      'sexe': 'F',
      'telephone': '033 98 765 43',
      'adresse': 'Fianarantsoa',
      'groupe_sanguin': 'A+'
    });
    await db.insert('medecins', {
      'nom': 'Andriamaro',
      'prenom': 'Paul',
      'specialite': 'Cardiologie',
      'telephone': '020 22 333 44',
      'email': 'p.andriamaro@hopital.mg',
      'disponible': 1
    });
    await db.insert('medecins', {
      'nom': 'Ratsimbazafy',
      'prenom': 'Claire',
      'specialite': 'Pédiatrie',
      'telephone': '020 22 555 66',
      'email': 'c.ratsimbazafy@hopital.mg',
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
            await db.rawQuery('SELECT COUNT(*) FROM patients')) ??
        0;

    final medecinsCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM medecins')) ??
        0;

    final consultationsCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM consultations')) ??
        0;

    final consultationsAujourdhui = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM consultations WHERE date = ?',
          [DateTime.now().toString().substring(0, 10)],
        )) ??
        0;

    final hospitalisationsEnCours = Sqflite.firstIntValue(await db.rawQuery(
            "SELECT COUNT(*) FROM hospitalisations WHERE statut = 'en_cours'")) ??
        0;

    final chambresTotal = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM chambres')) ??
        0;

    final blocsTotal = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM blocs')) ??
        0;

    return {
      'patients': patientsCount,
      'medecins': medecinsCount,
      'consultations': consultationsCount,
      'consultationsAujourdhui': consultationsAujourdhui,
      'hospitalisationsEnCours': hospitalisationsEnCours,
      'chambres': chambresTotal,
      'blocs': blocsTotal,
    };
  }
}
