 Application de Gestion Hospitalière — Flutter + SQLite

Un projet académique sur la gestion d'un hopital

---

# Structure du projet

```
hopital_app/
├── lib/
│   ├── main.dart                          ← Point d'entrée de l'app
│   ├── models/
│   │   ├── patient.dart                   ← Modèle Patient
│   │   ├── medecin.dart                   ← Modèle Médecin
│   │   └── consultation.dart              ← Modèle Consultation
│   ├── database/
│   │   └── database_helper.dart           ← Toute la logique SQLite (CRUD)
│   └── screens/
│       ├── dashboard/
│       │   └── dashboard_screen.dart      ← Tableau de bord (accueil)
│       ├── patients/
│       │   ├── patients_screen.dart       ← Liste des patients
│       │   └── patient_form_screen.dart   ← Formulaire ajout/modification
│       ├── medecins/
│       │   ├── medecins_screen.dart       ← Liste des médecins
│       │   └── medecin_form_screen.dart   ← Formulaire ajout/modification
│       └── consultations/
│           ├── consultations_screen.dart  ← Liste des consultations
│           └── consultation_form_screen.dart ← Formulaire consultation
├── pubspec.yaml                           ← Dépendances du projet
└── README.md
```

---

# Installation et lancement

1. Installer Flutter : https://docs.flutter.dev/get-started/install
2. Installer VS Code
3. Avoir un émulateur Android ou un appareil physique

### Étapes

```bash
# 1. Aller dans le dossier du projet
cd hopital_app

# 2. Télécharger les dépendances
flutter pub get

# 3. Lancer l'application
flutter run
```

---

##  Fonctionnalités

### Patients
- Lister tous les patients
-  Rechercher un patient par nom/prénom
-  Ajouter un nouveau patient (nom, prénom, date de naissance, sexe, téléphone, adresse, groupe sanguin)
-  Modifier les informations d'un patient
-  Supprimer un patient

### Médecins
-  Lister tous les médecins avec leur spécialité
-  Ajouter un médecin
-  Modifier / Supprimer
-  Statut disponible/indisponible

### Consultations
-  Créer une consultation (associer un patient + un médecin)
-  Saisir : date, heure, motif, diagnostic, traitement
-  Statuts : planifié / en cours / terminé / annulé
-  Modifier et supprimer des consultations

### Dashboard
-  Nombre total de patients, médecins, consultations
-  Consultations du jour

---

# Concepts Flutter utilisés

| Concept | Fichier d'exemple |
|---|---|
| `StatefulWidget` | Tous les écrans |
| `Form` + `TextFormField` | `patient_form_screen.dart` |
| `FutureBuilder` / `setState` | `patients_screen.dart` |
| `Navigator.push` | Navigation entre écrans |
| `DropdownButtonFormField` | `consultation_form_screen.dart` |
| `showDialog` | Confirmation de suppression |
| `SnackBar` | Messages de retour |

# Concepts SQLite utilisés

| Concept | Où dans le code |
|---|---|
| Créer des tables (`CREATE TABLE`) | `_createTables()` |
| Insérer (`INSERT`) | `insertPatient()` etc. |
| Lire (`SELECT`) | `getAllPatients()` etc. |
| Modifier (`UPDATE`) | `updatePatient()` etc. |
| Supprimer (`DELETE`) | `deletePatient()` etc. |
| Jointure (`JOIN`) | `getAllConsultations()` |
| Recherche (`LIKE`) | `searchPatients()` |
| Agrégat (`COUNT`) | `getStatistiques()` |

---

# Dépendances (pubspec.yaml)

```yaml
sqflite: ^2.3.0    # Base de données SQLite pour Flutter
path: ^1.8.3        # Gestion des chemins de fichiers
intl: ^0.18.1       # Formatage des dates

```

---

# Perspectives

- Ajouter un module **Chambre / Hospitalisation** : feature/chambre-hospitalisation
- Ajouter des **ordonnances** en PDF : feature/export-PDF
- Synchroniser avec un **serveur distant** (API REST) : feature/serveur-distant
- Ajouter une **authentification** (médecin, secrétaire, admin) : feature/authentification
- Ajouter des **graphiques** de statistiques : feature/dashboard
