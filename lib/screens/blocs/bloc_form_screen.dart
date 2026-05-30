// lib/screens/blocs/bloc_form_screen.dart

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/bloc.dart';

class BlocFormScreen extends StatefulWidget {
  final Bloc? bloc;
  const BlocFormScreen({super.key, this.bloc});

  @override
  State<BlocFormScreen> createState() => _BlocFormScreenState();
}

class _BlocFormScreenState extends State<BlocFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  final _numeroCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _etageCtrl = TextEditingController();
  final _equipementsCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String _specialite = 'Chirurgie générale';
  String _statut = 'libre';
  bool _isLoading = false;

  final List<String> _specialites = [
    'Chirurgie générale',
    'Cardiochirurgie',
    'Neurochirurgie',
    'Orthopédie',
    'Urologie',
    'Gynécologie-obstétrique',
    'ORL',
    'Ophtalmologie',
    'Chirurgie plastique',
    'Urgences chirurgicales',
  ];
  final List<String> _statuts = [
    'libre',
    'en_cours',
    'nettoyage',
    'maintenance'
  ];
  final List<String> _statutLabels = [
    'Libre',
    'En cours',
    'Nettoyage',
    'Maintenance'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.bloc != null) {
      _numeroCtrl.text = widget.bloc!.numero;
      _nomCtrl.text = widget.bloc!.nom;
      _etageCtrl.text = widget.bloc!.etage;
      _equipementsCtrl.text = widget.bloc!.equipements;
      _descriptionCtrl.text = widget.bloc!.description;
      _specialite = widget.bloc!.specialite;
      _statut = widget.bloc!.statut;
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _nomCtrl.dispose();
    _etageCtrl.dispose();
    _equipementsCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final bloc = Bloc(
      id: widget.bloc?.id,
      numero: _numeroCtrl.text.trim(),
      nom: _nomCtrl.text.trim(),
      specialite: _specialite,
      statut: _statut,
      etage: _etageCtrl.text.trim(),
      equipements: _equipementsCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
    );

    try {
      widget.bloc == null
          ? await _db.insertBloc(bloc)
          : await _db.updateBloc(bloc);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bloc enregistré !'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
            widget.bloc == null ? 'Nouveau bloc opératoire' : 'Modifier bloc',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF4527A0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _card('🏥 Identification', [
              _field(_numeroCtrl, 'Numéro (ex: BO-1)', Icons.tag,
                  validator: (v) => v!.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              _field(_nomCtrl, 'Nom complet (ex: Bloc Chirurgie Générale)',
                  Icons.label,
                  validator: (v) => v!.isEmpty ? 'Requis' : null),
              const SizedBox(height: 12),
              _field(_etageCtrl, 'Étage / Localisation', Icons.layers,
                  validator: (v) => v!.isEmpty ? 'Requis' : null),
            ]),
            const SizedBox(height: 16),
            _card('🔬 Spécialité', [
              DropdownButtonFormField<String>(
                value: _specialite,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Spécialité chirurgicale',
                  prefixIcon: const Icon(Icons.medical_services,
                      color: Color(0xFF4527A0)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _specialites
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _specialite = v!),
              ),
            ]),
            const SizedBox(height: 16),
            _card('📋 Statut initial', [
              DropdownButtonFormField<String>(
                value: _statut,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Statut du bloc',
                  prefixIcon:
                      const Icon(Icons.info_outline, color: Color(0xFF4527A0)),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: List.generate(
                    _statuts.length,
                    (i) => DropdownMenuItem(
                          value: _statuts[i],
                          child: Text(_statutLabels[i]),
                        )),
                onChanged: (v) => setState(() => _statut = v!),
              ),
            ]),
            const SizedBox(height: 16),
            _card('🔧 Équipements & Notes', [
              _field(_equipementsCtrl, 'Équipements disponibles', Icons.build,
                  maxLines: 2),
              const SizedBox(height: 12),
              _field(_descriptionCtrl, 'Description / notes', Icons.notes,
                  maxLines: 3),
            ]),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, color: Colors.white),
              label: Text(
                  widget.bloc == null ? 'Ajouter le bloc' : 'Enregistrer',
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4527A0),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  Widget _field(TextEditingController c, String label, IconData icon,
          {String? Function(String?)? validator, int maxLines = 1}) =>
      TextFormField(
        controller: c,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF4527A0)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4527A0), width: 2),
          ),
        ),
      );
}
