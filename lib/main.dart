// lib/main.dart
// Point d'entrée de l'application Flutter
// C'est le premier fichier qui s'exécute au démarrage

import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() {
  // runApp() lance l'application Flutter
  runApp(const HopitalApp());
}

class HopitalApp extends StatelessWidget {
  const HopitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Hôpital',
      debugShowCheckedModeBanner: false, // Masque le bandeau "DEBUG"

      // Thème global de l'application
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // Bleu médical
          brightness: Brightness.light,
        ),
        useMaterial3: true, // Utilise Material Design 3 (moderne)
        fontFamily: 'Roboto',

        // Style des AppBar
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
        ),

        // Style des boutons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Style des champs de saisie
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // L'écran affiché au lancement = Tableau de bord
      home: const DashboardScreen(),
    );
  }
}
