// lib/screens/consultations/consultations_screen.dart
// Liste des consultations médicales

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/consultation.dart';
import 'consultation_form_screen.dart';

class ConsultationsScreen extends StatefulWidget {
  const ConsultationsScreen({super.key});

  @override
  State<ConsultationsScreen> createState() => _ConsultationsScreenState();
}

class _ConsultationsScreenState extends State<ConsultationsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Consultation> _consultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    setState(() => _isLoading = true);
    final consultations = await _dbHelper.getAllConsultations();
    setState(() {
      _consultations = consultations;
      _isLoading = false;
    });
  }

  Future<void> _deleteConsultation(Consultation c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la consultation ?'),
        content: Text('Consultation de ${c.patientNom} avec Dr. ${c.medecinNom}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _dbHelper.deleteConsultation(c.id!);
      _loadConsultations();
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'planifié': return Colors.blue;
      case 'en_cours': return Colors.orange;
      case 'terminé': return Colors.green;
      case 'annulé': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'planifié': return Icons.schedule;
      case 'en_cours': return Icons.play_circle;
      case 'terminé': return Icons.check_circle;
      case 'annulé': return Icons.cancel;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Consultations', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConsultationFormScreen()),
        ).then((_) => _loadConsultations()),
        backgroundColor: const Color(0xFFE65100),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle consultation', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConsultations,
              child: _consultations.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_note_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucune consultation enregistrée', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _consultations.length,
                      itemBuilder: (ctx, i) => _buildConsultationCard(_consultations[i]),
                    ),
            ),
    );
  }

  Widget _buildConsultationCard(Consultation c) {
    final statutColor = _getStatutColor(c.statut);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statutColor, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : statut + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStatutIcon(c.statut), size: 14, color: statutColor),
                      const SizedBox(width: 4),
                      Text(c.statut, style: TextStyle(color: statutColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Text(
                  '${c.date} à ${c.heure}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Patient
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Color(0xFF1565C0)),
                const SizedBox(width: 6),
                Text('Patient: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(c.patientNom ?? 'Inconnu',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            // Médecin
            Row(
              children: [
                const Icon(Icons.medical_services, size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                Text('Médecin: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Expanded(
                  child: Text(
                    'Dr. ${c.medecinNom ?? 'Inconnu'} (${c.medecinSpecialite ?? ''})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Motif
            Text('💬 ${c.motif}', style: const TextStyle(color: Colors.black87, fontSize: 13)),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ConsultationFormScreen(consultation: c)),
                  ).then((_) => _loadConsultations()),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                  onPressed: () => _deleteConsultation(c),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
