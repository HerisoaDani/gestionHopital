// lib/screens/dashboard/dashboard_screen.dart
// Page d'accueil : affiche un résumé de l'hôpital

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../patients/patients_screen.dart';
import '../medecins/medecins_screen.dart';
import '../consultations/consultations_screen.dart';
import '../chambres/chambres_screen.dart';
import '../blocs/blocs_screen.dart';
import '../hospitalisations/hospitalisations_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // Charge les statistiques depuis la base de données
  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _dbHelper.getStatistiques();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text(
          '🏥 Hôpital Central',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          // Bouton pour rafraîchir les statistiques
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre de bienvenue
                    const Text(
                      'Tableau de bord',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aujourd\'hui : ${_getDateAujourdhui()}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    // Cartes de statistiques — 2 colonnes adaptatives
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                'Patients',
                                _stats['patients'] ?? 0,
                                Icons.people,
                                const Color(0xFF1565C0))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildStatCard(
                                'Médecins',
                                _stats['medecins'] ?? 0,
                                Icons.medical_services,
                                const Color(0xFF2E7D32))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                'Consultations',
                                _stats['consultations'] ?? 0,
                                Icons.calendar_today,
                                const Color(0xFFE65100))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildStatCard(
                                'Aujourd\'hui',
                                _stats['consultationsAujourdhui'] ?? 0,
                                Icons.today,
                                const Color(0xFF6A1B9A))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                'Hospitalisés',
                                _stats['hospitalisationsEnCours'] ?? 0,
                                Icons.hotel,
                                const Color(0xFF00695C))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildStatCard(
                                'Chambres',
                                _stats['chambres'] ?? 0,
                                Icons.bed,
                                const Color(0xFF00838F))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard(
                                'Blocs opér.',
                                _stats['blocs'] ?? 0,
                                Icons.biotech,
                                const Color(0xFF4527A0))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildStatCard(
                                'Médecins',
                                _stats['medecins'] ?? 0,
                                Icons.medical_services,
                                const Color(0xFF2E7D32))),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Section Accès rapide
                    const Text(
                      'Accès rapide',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Boutons de navigation
                    _buildMenuButton(
                      context,
                      icon: Icons.person_add,
                      label: 'Gérer les Patients',
                      description:
                          'Ajouter, modifier ou supprimer des patients',
                      color: const Color(0xFF1565C0),
                      onTap: () => _navigateTo(context, const PatientsScreen()),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context,
                      icon: Icons.add_card,
                      label: 'Gérer les Médecins',
                      description: 'Gérer le personnel médical',
                      color: const Color(0xFF2E7D32),
                      onTap: () => _navigateTo(context, const MedecinsScreen()),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context,
                      icon: Icons.event_note,
                      label: 'Consultations',
                      description: 'Planifier et suivre les consultations',
                      color: const Color(0xFFE65100),
                      onTap: () =>
                          _navigateTo(context, const ConsultationsScreen()),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context,
                      icon: Icons.hotel,
                      label: 'Hospitalisations',
                      description:
                          'Admettre et suivre les patients hospitalisés',
                      color: const Color(0xFF00695C),
                      onTap: () =>
                          _navigateTo(context, const HospitalisationsScreen()),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context,
                      icon: Icons.bed,
                      label: 'Chambres',
                      description: 'Gérer les chambres et leur occupation',
                      color: const Color(0xFF00838F),
                      onTap: () => _navigateTo(context, const ChambresScreen()),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuButton(
                      context,
                      icon: Icons.biotech,
                      label: 'Blocs Opératoires',
                      description: 'Gérer les salles d\'opération',
                      color: const Color(0xFF4527A0),
                      onTap: () => _navigateTo(context, const BlocsScreen()),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Widget pour une carte statistique
  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour un bouton de menu
  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => _loadStats()); // Rafraîchit les stats au retour
  }

  String _getDateAujourdhui() {
    final now = DateTime.now();
    final mois = [
      '',
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${now.day} ${mois[now.month]} ${now.year}';
  }
}
