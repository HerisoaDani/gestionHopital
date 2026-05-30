// lib/screens/medecins/medecins_screen.dart
// Liste et gestion des médecins

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/medecin.dart';
import 'medecin_form_screen.dart';

class MedecinsScreen extends StatefulWidget {
  const MedecinsScreen({super.key});

  @override
  State<MedecinsScreen> createState() => _MedecinsScreenState();
}

class _MedecinsScreenState extends State<MedecinsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Medecin> _medecins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedecins();
  }

  Future<void> _loadMedecins() async {
    setState(() => _isLoading = true);
    final medecins = await _dbHelper.getAllMedecins();
    setState(() {
      _medecins = medecins;
      _isLoading = false;
    });
  }

  Future<void> _deleteMedecin(Medecin medecin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer Dr. ${medecin.prenom} ${medecin.nom} ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _dbHelper.deleteMedecin(medecin.id!);
      _loadMedecins();
    }
  }

  // Couleur selon la spécialité
  Color _getSpecialiteColor(String specialite) {
    final colors = {
      'Cardiologie': Colors.red,
      'Pédiatrie': Colors.orange,
      'Neurologie': Colors.purple,
      'Chirurgie': Colors.teal,
      'Gynécologie': Colors.pink,
      'Orthopédie': Colors.brown,
      'Dermatologie': Colors.lime,
      'Ophtalmologie': Colors.cyan,
    };
    return colors[specialite] ?? const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Médecins',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedecinFormScreen()),
        ).then((_) => _loadMedecins()),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau médecin',
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMedecins,
              child: _medecins.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medical_services_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucun médecin enregistré',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _medecins.length,
                      itemBuilder: (ctx, i) => _buildMedecinCard(_medecins[i]),
                    ),
            ),
    );
  }

  Widget _buildMedecinCard(Medecin medecin) {
    final color = _getSpecialiteColor(medecin.specialite);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        isThreeLine: true,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            'Dr',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        title: Text(
          'Dr. ${medecin.prenom} ${medecin.nom}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                medecin.specialite,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Text('📞 ${medecin.telephone}'),
            Row(
              children: [
                Icon(
                  medecin.disponible ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: medecin.disponible ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  medecin.disponible ? 'Disponible' : 'Indisponible',
                  style: TextStyle(
                    color: medecin.disponible ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (ctx) => [
            const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Modifier')
                  ],
                )),
            const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer')
                  ],
                )),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => MedecinFormScreen(medecin: medecin)),
              ).then((_) => _loadMedecins());
            } else if (value == 'delete') {
              _deleteMedecin(medecin);
            }
          },
        ),
      ),
    );
  }
}
