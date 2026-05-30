// lib/screens/factures/factures_screen.dart

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/facture.dart';
import '../../services/pdf_service.dart';
import 'facture_form_screen.dart';

class FacturesScreen extends StatefulWidget {
  const FacturesScreen({super.key});
  @override
  State<FacturesScreen> createState() => _FacturesScreenState();
}

class _FacturesScreenState extends State<FacturesScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  List<Facture> _factures = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final f = await _db.getAllFactures();
    final s = await _db.getStatistiquesFacturation();
    setState(() {
      _factures = f;
      _stats = s;
      _isLoading = false;
    });
  }

  List<Facture> _filtrer(String statut) => statut == 'tous'
      ? _factures
      : _factures.where((f) => f.statut == statut).toList();

  Color _couleurStatut(String s) {
    switch (s) {
      case 'payee':
        return Colors.green;
      case 'en_attente':
        return Colors.orange;
      case 'annulee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _changerStatut(Facture f) async {
    final choix = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Statut — ${f.numero}'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'en_attente'),
            child: const Text('🕐 En attente'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'payee'),
            child: const Text('✅ Payée'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'annulee'),
            child: const Text('❌ Annulée'),
          ),
        ],
      ),
    );
    if (choix != null) {
      await _db.updateFactureStatut(f.id!, choix);
      _load();
    }
  }

  Future<void> _exporterPdf(Facture f, String action) async {
    try {
      if (action == 'apercu') {
        if (!mounted) return;
        await PdfService.afficherApercu(context, f);
      } else if (action == 'telecharger') {
        final path = await PdfService.telecharger(f);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('PDF sauvegardé : $path'),
              backgroundColor: Colors.green),
        );
      } else if (action == 'partager') {
        await PdfService.partager(f);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur PDF : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Facturation',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006064),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'En attente'),
            Tab(text: 'Payées'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FactureFormScreen()),
        ).then((_) => _load()),
        backgroundColor: const Color(0xFF006064),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle facture',
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _buildListe(_filtrer('tous')),
                      _buildListe(_filtrer('en_attente')),
                      _buildListe(_filtrer('payee')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
              child: _statItem(
            'Encaissé',
            '${(_stats['totalEncaisse'] ?? 0.0).toStringAsFixed(0)} Ar',
            Colors.green,
          )),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          Expanded(
              child: _statItem(
            'En attente',
            '${(_stats['totalAttente'] ?? 0.0).toStringAsFixed(0)} Ar',
            Colors.orange,
          )),
        ],
      ),
    );
  }

  Widget _statItem(String label, String valeur, Color color) => Column(
        children: [
          Text(valeur,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 15)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      );

  Widget _buildListe(List<Facture> liste) {
    if (liste.isEmpty) {
      return const Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey),
          SizedBox(height: 12),
          Text('Aucune facture', style: TextStyle(color: Colors.grey)),
        ],
      ));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: liste.length,
        itemBuilder: (_, i) => _buildCard(liste[i]),
      ),
    );
  }

  Widget _buildCard(Facture f) {
    final color = _couleurStatut(f.statut);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(f.numero,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(f.patientNom ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ])),
            GestureDetector(
              onTap: () => _changerStatut(f),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(Facture.libelleStatut(f.statut),
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_drop_down, size: 16, color: color),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF006064).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(Facture.libelleType(f.type),
                  style: const TextStyle(
                      color: Color(0xFF006064),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Text(f.date,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${f.lignes.length} ligne(s)',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text('${f.total.toStringAsFixed(0)} Ar',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF006064))),
          ]),
          // Actions PDF + modifier
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF006064)),
              tooltip: 'Exporter PDF',
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'apercu',
                    child: Row(children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('Aperçu')
                    ])),
                const PopupMenuItem(
                    value: 'telecharger',
                    child: Row(children: [
                      Icon(Icons.download, size: 18),
                      SizedBox(width: 8),
                      Text('Télécharger')
                    ])),
                const PopupMenuItem(
                    value: 'partager',
                    child: Row(children: [
                      Icon(Icons.share, size: 18),
                      SizedBox(width: 8),
                      Text('Partager')
                    ])),
              ],
              onSelected: (action) => _exporterPdf(f, action),
            ),
            TextButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FactureFormScreen(facture: f)),
              ).then((_) => _load()),
            ),
          ]),
        ]),
      ),
    );
  }
}
