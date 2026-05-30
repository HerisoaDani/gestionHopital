// lib/screens/blocs/blocs_screen.dart
// Liste des blocs opératoires avec leur statut en temps réel

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/bloc.dart';
import 'bloc_form_screen.dart';

class BlocsScreen extends StatefulWidget {
  const BlocsScreen({super.key});

  @override
  State<BlocsScreen> createState() => _BlocsScreenState();
}

class _BlocsScreenState extends State<BlocsScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<Bloc> _blocs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final b = await _db.getAllBlocs();
    setState(() {
      _blocs = b;
      _isLoading = false;
    });
  }

  Color _couleurStatut(String statut) {
    switch (statut) {
      case 'libre':
        return Colors.green;
      case 'en_cours':
        return Colors.orange;
      case 'nettoyage':
        return Colors.blue;
      case 'maintenance':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _iconeStatut(String statut) {
    switch (statut) {
      case 'libre':
        return Icons.check_circle;
      case 'en_cours':
        return Icons.play_circle;
      case 'nettoyage':
        return Icons.cleaning_services;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  // Permet de changer le statut directement depuis la liste
  Future<void> _changerStatut(Bloc bloc) async {
    final statuts = ['libre', 'en_cours', 'nettoyage', 'maintenance'];
    final labels = [
      'Libre',
      'En cours d\'opération',
      'Nettoyage',
      'Maintenance'
    ];

    final choix = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Statut du ${bloc.numero}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
              statuts.length,
              (i) => RadioListTile<String>(
                    title: Text(labels[i]),
                    value: statuts[i],
                    groupValue: bloc.statut,
                    activeColor: _couleurStatut(statuts[i]),
                    onChanged: (v) => Navigator.pop(ctx, v),
                  )),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
        ],
      ),
    );
    if (choix != null && choix != bloc.statut) {
      await _db.updateStatutBloc(bloc.id!, choix);
      _load();
    }
  }

  Future<void> _delete(Bloc bloc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce bloc ?'),
        content: Text('${bloc.numero} — ${bloc.nom}'),
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
      await _db.deleteBloc(bloc.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Blocs Opératoires',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4527A0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BlocFormScreen()),
        ).then((_) => _load()),
        backgroundColor: const Color(0xFF4527A0),
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Nouveau bloc', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blocs.isEmpty
              ? const Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.biotech, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('Aucun bloc opératoire enregistré',
                            style: TextStyle(color: Colors.grey)),
                      ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _blocs.length,
                    itemBuilder: (_, i) => _buildBlocCard(_blocs[i]),
                  ),
                ),
    );
  }

  Widget _buildBlocCard(Bloc bloc) {
    final color = _couleurStatut(bloc.statut);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // En-tête
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4527A0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.biotech, color: Color(0xFF4527A0), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bloc.numero,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(bloc.nom,
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 14)),
                  ]),
            ),
            // Bouton statut cliquable
            GestureDetector(
              onTap: () => _changerStatut(bloc),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_iconeStatut(bloc.statut), size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(Bloc.libelleStatut(bloc.statut),
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, size: 16, color: color),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 10),

          // Infos
          Wrap(spacing: 16, runSpacing: 4, children: [
            _info(Icons.local_hospital, bloc.specialite),
            _info(Icons.layers, bloc.etage),
          ]),

          if (bloc.equipements.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('🔧 ${bloc.equipements}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],

          // Actions
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton.icon(
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Modifier'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BlocFormScreen(bloc: bloc)),
              ).then((_) => _load()),
            ),
            TextButton.icon(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              label:
                  const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onPressed: () => _delete(bloc),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _info(IconData icon, String text) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ]);
}
