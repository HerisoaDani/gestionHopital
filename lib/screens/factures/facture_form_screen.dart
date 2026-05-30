// lib/screens/factures/facture_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database_helper.dart';
import '../../models/facture.dart';
import '../../models/patient.dart';

class FactureFormScreen extends StatefulWidget {
  final Facture? facture;
  const FactureFormScreen({super.key, this.facture});
  @override
  State<FactureFormScreen> createState() => _FactureFormScreenState();
}

class _FactureFormScreenState extends State<FactureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  final _notesCtrl = TextEditingController();
  final _remiseCtrl = TextEditingController(text: '0');

  List<Patient> _patients = [];
  Patient? _patient;
  String _type = 'consultation';
  String _modePaiement = 'especes';
  String _statut = 'en_attente';
  List<LigneFacture> _lignes = [];
  bool _isLoading = false;
  bool _loadingData = true;

  final List<String> _types = ['consultation', 'hospitalisation', 'operation'];
  final List<String> _modes = ['especes', 'mobile_money', 'carte', 'assurance'];
  final List<String> _modeLabels = [
    'Espèces',
    'Mobile Money',
    'Carte bancaire',
    'Assurance'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final patients = await _db.getAllPatients();
    setState(() {
      _patients = patients;
      _loadingData = false;
    });
    if (widget.facture != null) {
      final f = widget.facture!;
      _notesCtrl.text = f.notes;
      _remiseCtrl.text = f.remise.toStringAsFixed(0);
      setState(() {
        _type = f.type;
        _modePaiement = f.modePaiement;
        _statut = f.statut;
        _lignes = List.from(f.lignes);
        try {
          _patient = _patients.firstWhere((p) => p.id == f.patientId);
        } catch (_) {}
      });
    }
  }

  double get _sousTotal => _lignes.fold(0, (s, l) => s + l.montant);
  double get _remise => double.tryParse(_remiseCtrl.text) ?? 0;
  double get _total => _sousTotal - (_sousTotal * _remise / 100);

  void _ajouterLigne() {
    showDialog(
      context: context,
      builder: (ctx) => _LigneDialog(),
    ).then((ligne) {
      if (ligne != null) setState(() => _lignes.add(ligne));
    });
  }

  void _supprimerLigne(int index) {
    setState(() => _lignes.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sélectionnez un patient'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (_lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ajoutez au moins une ligne'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final facture = Facture(
      id: widget.facture?.id,
      numero: widget.facture?.numero ?? '',
      type: _type,
      patientId: _patient!.id!,
      date: DateTime.now().toString().substring(0, 10),
      statut: _statut,
      modePaiement: _modePaiement,
      remise: _remise,
      notes: _notesCtrl.text.trim(),
      lignes: _lignes,
    );

    try {
      widget.facture == null
          ? await _db.insertFacture(facture)
          : await _db.updateFacture(facture);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Facture enregistrée !'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _remiseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
            widget.facture == null ? 'Nouvelle facture' : 'Modifier facture',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF006064),
        foregroundColor: Colors.white,
      ),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Patient ─────────────────────────────
                      _card('👤 Patient', [
                        DropdownButtonFormField<Patient>(
                          value: _patient,
                          isExpanded: true,
                          decoration: _deco('Patient', Icons.person),
                          hint: const Text('Sélectionner un patient'),
                          items: _patients
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text('${p.prenom} ${p.nom}',
                                        overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _patient = v),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _type,
                          isExpanded: true,
                          decoration: _deco('Type de facture', Icons.category),
                          items: _types
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(Facture.libelleType(t)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _type = v!),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── Lignes ──────────────────────────────
                      _card('📋 Prestations', [
                        if (_lignes.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text('Aucune ligne — appuyez sur +',
                                  style: TextStyle(color: Colors.grey[400])),
                            ),
                          )
                        else
                          ...List.generate(_lignes.length, (i) {
                            final l = _lignes[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF006064)
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(children: [
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(l.description,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                          '${l.quantite} × ${l.prixUnitaire.toStringAsFixed(0)} Ar',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12)),
                                    ])),
                                Text('${l.montant.toStringAsFixed(0)} Ar',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF006064))),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red, size: 20),
                                  onPressed: () => _supprimerLigne(i),
                                ),
                              ]),
                            );
                          }),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _ajouterLigne,
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter une prestation'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF006064),
                            side: const BorderSide(color: Color(0xFF006064)),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // ── Totaux ──────────────────────────────
                      _card('💰 Totaux', [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sous-total :'),
                              Text('${_sousTotal.toStringAsFixed(0)} Ar',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ]),
                        const SizedBox(height: 8),
                        Row(children: [
                          const Text('Remise : '),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 70,
                            child: TextFormField(
                              controller: _remiseCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: const InputDecoration(
                                suffixText: '%',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ]),
                        const Divider(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('TOTAL :',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              Text('${_total.toStringAsFixed(0)} Ar',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFF006064))),
                            ]),
                      ]),
                      const SizedBox(height: 16),

                      // ── Paiement ────────────────────────────
                      _card('💳 Paiement', [
                        DropdownButtonFormField<String>(
                          value: _modePaiement,
                          isExpanded: true,
                          decoration: _deco('Mode de paiement', Icons.payment),
                          items: List.generate(
                              _modes.length,
                              (i) => DropdownMenuItem(
                                    value: _modes[i],
                                    child: Text(_modeLabels[i]),
                                  )),
                          onChanged: (v) => setState(() => _modePaiement = v!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _statut,
                          isExpanded: true,
                          decoration: _deco('Statut', Icons.info_outline),
                          items: [
                            const DropdownMenuItem(
                                value: 'en_attente', child: Text('En attente')),
                            const DropdownMenuItem(
                                value: 'payee', child: Text('Payée')),
                            const DropdownMenuItem(
                                value: 'annulee', child: Text('Annulée')),
                          ],
                          onChanged: (v) => setState(() => _statut = v!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesCtrl,
                          maxLines: 2,
                          decoration: _deco('Notes (optionnel)', Icons.notes),
                        ),
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
                          widget.facture == null
                              ? 'Créer la facture'
                              : 'Enregistrer',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006064),
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

  InputDecoration _deco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF006064)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF006064), width: 2),
        ),
      );
}

// ── Dialogue d'ajout d'une ligne ────────────────
class _LigneDialog extends StatefulWidget {
  @override
  State<_LigneDialog> createState() => _LigneDialogState();
}

class _LigneDialogState extends State<_LigneDialog> {
  final _descCtrl = TextEditingController();
  final _qteCtrl = TextEditingController(text: '1');
  final _prixCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Prestations prédéfinies (sélection rapide)
  final _suggestions = [
    ('Consultation générale', 5000.0),
    ('Consultation spécialisée', 10000.0),
    ('Nuit d\'hospitalisation', 15000.0),
    ('Intervention chirurgicale', 50000.0),
    ('Analyses biologiques', 8000.0),
    ('Radiographie', 6000.0),
    ('Médicaments', 0.0),
    ('Soins infirmiers', 3000.0),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    _qteCtrl.dispose();
    _prixCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter une prestation'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Suggestions rapides
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _suggestions
                  .map((s) => ActionChip(
                        label: Text(s.$1, style: const TextStyle(fontSize: 11)),
                        onPressed: () => setState(() {
                          _descCtrl.text = s.$1;
                          _prixCtrl.text = s.$2.toStringAsFixed(0);
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              validator: (v) => v!.isEmpty ? 'Requis' : null,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _qteCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      (int.tryParse(v ?? '') ?? 0) < 1 ? 'Min 1' : null,
                  decoration: const InputDecoration(
                      labelText: 'Quantité', border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _prixCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? -1) < 0 ? 'Requis' : null,
                  decoration: const InputDecoration(
                      labelText: 'Prix (Ar)',
                      border: OutlineInputBorder(),
                      suffixText: 'Ar'),
                ),
              ),
            ]),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006064)),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(
                  context,
                  LigneFacture(
                    description: _descCtrl.text.trim(),
                    quantite: int.parse(_qteCtrl.text),
                    prixUnitaire: double.parse(_prixCtrl.text),
                  ));
            }
          },
          child: const Text('Ajouter', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
