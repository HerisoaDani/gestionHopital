// lib/screens/hospitalisations/hospitalisations_screen.dart
// Liste des hospitalisations (en cours + historique)

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/hospitalisation.dart';
import '../../models/chambre.dart';
import 'hospitalisation_form_screen.dart';
import 'sortie_dialog.dart';

class HospitalisationsScreen extends StatefulWidget {
  const HospitalisationsScreen({super.key});

  @override
  State<HospitalisationsScreen> createState() => _HospitalisationsScreenState();
}

class _HospitalisationsScreenState extends State<HospitalisationsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  List<Hospitalisation> _toutes = [];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final h = await _db.getAllHospitalisations();
    setState(() {
      _toutes = h;
      _isLoading = false;
    });
  }

  List<Hospitalisation> get _enCours =>
      _toutes.where((h) => h.statut == 'en_cours').toList();
  List<Hospitalisation> get _historique =>
      _toutes.where((h) => h.statut != 'en_cours').toList();

  Color _couleurChambre(String? type) {
    switch (type) {
      case 'standard':
        return const Color(0xFF1565C0);
      case 'vip':
        return const Color(0xFF6A1B9A);
      case 'urgence':
        return const Color(0xFFE65100);
      case 'reanimation':
        return const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  Future<void> _enregistrerSortie(Hospitalisation h) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => SortieDialog(hospitalisation: h),
    );
    if (result != null) {
      await _db.enregistrerSortie(
          h.id!, result['date']!, result['heure']!, result['diagnostic']!);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Sortie enregistrée !'),
              backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _delete(Hospitalisation h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette hospitalisation ?'),
        content: Text('Patient : ${h.patientNom}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteHospitalisation(h.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Hospitalisations',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'En cours (${_enCours.length})'),
            Tab(text: 'Historique (${_historique.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HospitalisationFormScreen()),
        ).then((_) => _load()),
        backgroundColor: const Color(0xFF00695C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Admettre un patient',
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListe(_enCours, enCours: true),
                _buildListe(_historique, enCours: false),
              ],
            ),
    );
  }

  Widget _buildListe(List<Hospitalisation> liste, {required bool enCours}) {
    if (liste.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(enCours ? Icons.hotel : Icons.history,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            enCours ? 'Aucun patient hospitalisé' : 'Aucun historique',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: liste.length,
        itemBuilder: (_, i) => _buildCard(liste[i], enCours: enCours),
      ),
    );
  }

  Widget _buildCard(Hospitalisation h, {required bool enCours}) {
    final chambreColor = _couleurChambre(h.chambreType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: chambreColor, width: 5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // En-tête patient
          Row(children: [
            CircleAvatar(
              backgroundColor: chambreColor.withValues(alpha: 0.15),
              child: Text(
                (h.patientNom ?? '?')[0].toUpperCase(),
                style:
                    TextStyle(color: chambreColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.patientNom ?? 'Inconnu',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Dr. ${h.medecinNom ?? ''}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ]),
            ),
            // Badge chambre
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: chambreColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(children: [
                Text('Chambre',
                    style: TextStyle(color: chambreColor, fontSize: 10)),
                Text(h.chambreNumero ?? '?',
                    style: TextStyle(
                        color: chambreColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ]),
            ),
          ]),
          const SizedBox(height: 10),

          // Chambre type + étiquette
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: chambreColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                Chambre.libelleType(h.chambreType ?? 'standard'),
                style: TextStyle(
                    color: chambreColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
            if (h.blocNumero != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF4527A0).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Bloc: ${h.blocNumero}',
                    style: const TextStyle(
                        color: Color(0xFF4527A0),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ]),
          const SizedBox(height: 8),

          // Dates
          Row(children: [
            const Icon(Icons.login, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Entrée: ${h.dateEntree} à ${h.heureEntree}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          if (h.dateSortie != null)
            Row(children: [
              const Icon(Icons.logout, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Sortie: ${h.dateSortie} à ${h.heureSortie}',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ]),

          // Durée
          Row(children: [
            const Icon(Icons.timelapse, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${h.nombreJours} jour(s)',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const SizedBox(height: 4),
          Text('💬 ${h.motif}', style: const TextStyle(fontSize: 13)),

          // Actions
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (enCours)
              TextButton.icon(
                icon: const Icon(Icons.logout,
                    size: 16, color: Color(0xFF00695C)),
                label: const Text('Sortie',
                    style: TextStyle(color: Color(0xFF00695C))),
                onPressed: () => _enregistrerSortie(h),
              ),
            TextButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        HospitalisationFormScreen(hospitalisation: h)),
              ).then((_) => _load()),
            ),
            TextButton.icon(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              label:
                  const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () => _delete(h),
            ),
          ]),
        ]),
      ),
    );
  }
}
