// lib/screens/chambres/chambres_screen.dart
// Liste de toutes les chambres avec leur taux d'occupation

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/chambre.dart';
import 'chambre_form_screen.dart';

class ChambresScreen extends StatefulWidget {
  const ChambresScreen({super.key});

  @override
  State<ChambresScreen> createState() => _ChambresScreenState();
}

class _ChambresScreenState extends State<ChambresScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper();
  List<Chambre> _chambres = [];
  bool _isLoading = true;

  // Onglets par type de chambre
  late TabController _tabController;
  final List<String> _types = [
    'tous',
    'standard',
    'vip',
    'urgence',
    'reanimation'
  ];
  final List<String> _tabLabels = [
    'Tous',
    'Standard',
    'VIP',
    'Urgences',
    'Réanimation'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
    _loadChambres();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChambres() async {
    setState(() => _isLoading = true);
    final c = await _db.getAllChambres();
    setState(() {
      _chambres = c;
      _isLoading = false;
    });
  }

  List<Chambre> _filtrer(String type) => type == 'tous'
      ? _chambres
      : _chambres.where((c) => c.type == type).toList();

  Future<void> _delete(Chambre chambre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette chambre ?'),
        content: Text(
            'Chambre ${chambre.numero} — ${Chambre.libelleType(chambre.type)}'),
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
      await _db.deleteChambre(chambre.id!);
      _loadChambres();
    }
  }

  // Couleur selon le type de chambre
  Color _couleurType(String type) {
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

  IconData _iconeType(String type) {
    switch (type) {
      case 'standard':
        return Icons.bed;
      case 'vip':
        return Icons.star;
      case 'urgence':
        return Icons.emergency;
      case 'reanimation':
        return Icons.monitor_heart;
      default:
        return Icons.hotel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Chambres',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChambreFormScreen()),
        ).then((_) => _loadChambres()),
        backgroundColor: const Color(0xFF00838F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle chambre',
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _types.map((type) {
                final liste = _filtrer(type);
                if (liste.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_iconeType(type),
                            size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('Aucune chambre de ce type',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _loadChambres,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: liste.length,
                    itemBuilder: (_, i) => _buildChambreCard(liste[i]),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildChambreCard(Chambre c) {
    final color = _couleurType(c.type);
    final taux = c.tauxOccupation;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : numéro + badge type + statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(_iconeType(c.type), color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chambre ${c.numero}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(Chambre.libelleType(c.type),
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                // Badge disponibilité
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.aDePlace
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c.aDePlace ? '${c.litsLibres} libre(s)' : 'Complet',
                    style: TextStyle(
                      color: c.aDePlace ? Colors.green[700] : Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Infos
            Row(children: [
              const Icon(Icons.layers, size: 15, color: Colors.grey),
              const SizedBox(width: 4),
              Text(c.etage,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.bed, size: 15, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${c.litsOccupes}/${c.capacite} lits',
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
            const SizedBox(height: 10),

            // Barre de progression d'occupation
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: taux / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  taux >= 100
                      ? Colors.red
                      : taux >= 75
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('${taux.toStringAsFixed(0)}% occupé',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),

            if (c.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(c.description,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],

            // Boutons actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ChambreFormScreen(chambre: c)),
                  ).then((_) => _loadChambres()),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Supprimer',
                      style: TextStyle(color: Colors.red)),
                  onPressed: () => _delete(c),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
