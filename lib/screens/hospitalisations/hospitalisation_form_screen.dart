// lib/screens/hospitalisations/hospitalisation_form_screen.dart

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/hospitalisation.dart';
import '../../models/patient.dart';
import '../../models/medecin.dart';
import '../../models/chambre.dart';
import '../../models/bloc.dart';

class HospitalisationFormScreen extends StatefulWidget {
  final Hospitalisation? hospitalisation;
  const HospitalisationFormScreen({super.key, this.hospitalisation});

  @override
  State<HospitalisationFormScreen> createState() =>
      _HospitalisationFormScreenState();
}

class _HospitalisationFormScreenState extends State<HospitalisationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  final _motifCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dateEntreeCtrl = TextEditingController();
  final _heureEntreeCtrl = TextEditingController();

  List<Patient> _patients = [];
  List<Medecin> _medecins = [];
  List<Chambre> _chambres = [];
  List<Bloc> _blocs = [];

  Patient? _patient;
  Medecin? _medecin;
  Chambre? _chambre;
  Bloc? _bloc;

  String _statut = 'en_cours';
  bool _loading = false;
  bool _loadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final patients = await _db.getAllPatients();
    final medecins = await _db.getAllMedecins();
    final blocs = await _db.getAllBlocs();
    List<Chambre> chambres;

    if (widget.hospitalisation != null) {
      // Mode édition : on charge toutes les chambres
      chambres = await _db.getAllChambres();
    } else {
      // Mode création : seulement les chambres avec de la place
      chambres = await _db.getChambresDisponibles();
    }

    final now = DateTime.now();

    setState(() {
      _patients = patients;
      _medecins = medecins;
      _chambres = chambres;
      _blocs = blocs;
      _loadingData = false;

      _dateEntreeCtrl.text = now.toString().substring(0, 10);
      _heureEntreeCtrl.text =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });

    // Pré-remplissage si modification
    if (widget.hospitalisation != null) {
      final h = widget.hospitalisation!;
      _motifCtrl.text = h.motif;
      _notesCtrl.text = h.notes;
      _dateEntreeCtrl.text = h.dateEntree;
      _heureEntreeCtrl.text = h.heureEntree;

      setState(() {
        _statut = h.statut;
        try {
          _patient = _patients.firstWhere((p) => p.id == h.patientId);
        } catch (_) {}
        try {
          _medecin = _medecins.firstWhere((m) => m.id == h.medecinId);
        } catch (_) {}
        try {
          _chambre = _chambres.firstWhere((c) => c.id == h.chambreId);
        } catch (_) {}
        if (h.blocId != null) {
          try {
            _bloc = _blocs.firstWhere((b) => b.id == h.blocId);
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (p != null) {
      setState(() => _dateEntreeCtrl.text = p.toString().substring(0, 10));
    }
  }

  Future<void> _selectTime() async {
    final p =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (p != null) {
      setState(() => _heureEntreeCtrl.text =
          '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patient == null) {
      _snack('Sélectionnez un patient', Colors.orange);
      return;
    }
    if (_medecin == null) {
      _snack('Sélectionnez un médecin', Colors.orange);
      return;
    }
    if (_chambre == null) {
      _snack('Sélectionnez une chambre', Colors.orange);
      return;
    }

    setState(() => _loading = true);

    final h = Hospitalisation(
      id: widget.hospitalisation?.id,
      patientId: _patient!.id!,
      medecinId: _medecin!.id!,
      chambreId: _chambre!.id!,
      blocId: _bloc?.id,
      dateEntree: _dateEntreeCtrl.text,
      heureEntree: _heureEntreeCtrl.text,
      motif: _motifCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      statut: _statut,
    );

    try {
      widget.hospitalisation == null
          ? await _db.insertHospitalisation(h)
          : await _db.updateHospitalisation(h);
      if (mounted) {
        Navigator.pop(context);
        _snack('Hospitalisation enregistrée !', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('Erreur : $e', Colors.red);
      }
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Color _couleurChambre(String type) {
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

  @override
  void dispose() {
    _motifCtrl.dispose();
    _notesCtrl.dispose();
    _dateEntreeCtrl.dispose();
    _heureEntreeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          widget.hospitalisation == null
              ? 'Admettre un patient'
              : 'Modifier admission',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00695C),
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
                    // ── Participants ────────────────────────
                    _card('👥 Participants', [
                      DropdownButtonFormField<Patient>(
                        // FIX: value → initialValue n'existe pas sur Dropdown,
                        //      mais value est correct ici (c'est le selected item)
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
                      DropdownButtonFormField<Medecin>(
                        value: _medecin,
                        isExpanded: true,
                        decoration: _deco(
                            'Médecin responsable', Icons.medical_services),
                        hint: const Text('Sélectionner un médecin'),
                        items: _medecins
                            .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    'Dr. ${m.prenom} ${m.nom} — ${m.specialite}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _medecin = v),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // ── Chambre ─────────────────────────────
                    _card('🏠 Affectation en chambre', [
                      if (_chambres.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // FIX: withOpacity → withValues
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Aucune chambre disponible actuellement.',
                                style: TextStyle(color: Colors.orange),
                              ),
                            ),
                          ]),
                        )
                      else
                        DropdownButtonFormField<Chambre>(
                          value: _chambre,
                          isExpanded: true,
                          decoration: _deco('Chambre', Icons.bed),
                          hint: const Text('Sélectionner une chambre'),
                          items: _chambres.map((c) {
                            final color = _couleurChambre(c.type);
                            return DropdownMenuItem(
                              value: c,
                              child: Row(children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${c.numero} — ${Chambre.libelleType(c.type)} (${c.litsLibres} libre(s))',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _chambre = v),
                        ),
                    ]),
                    const SizedBox(height: 16),

                    // ── Bloc (optionnel) ────────────────────
                    _card('🔬 Bloc opératoire (optionnel)', [
                      const Text(
                        'Uniquement si le patient nécessite une intervention chirurgicale.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Bloc?>(
                        value: _bloc,
                        isExpanded: true,
                        decoration: _deco('Bloc opératoire', Icons.biotech),
                        items: [
                          const DropdownMenuItem<Bloc?>(
                              value: null, child: Text('Aucun bloc')),
                          ..._blocs.map((b) => DropdownMenuItem<Bloc?>(
                                value: b,
                                child: Text('${b.numero} — ${b.nom}',
                                    overflow: TextOverflow.ellipsis),
                              )),
                        ],
                        onChanged: (v) => setState(() => _bloc = v),
                      ),
                    ]),
                    const SizedBox(height: 16),

                    // ── Date / heure ────────────────────────
                    _card("📅 Date d'entrée", [
                      Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _dateEntreeCtrl,
                                validator: (v) => v!.isEmpty ? 'Requis' : null,
                                decoration: _deco('Date', Icons.calendar_today),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectTime,
                            child: AbsorbPointer(
                              child: TextFormField(
                                controller: _heureEntreeCtrl,
                                validator: (v) => v!.isEmpty ? 'Requis' : null,
                                decoration: _deco('Heure', Icons.access_time),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ]),
                    const SizedBox(height: 16),

                    // ── Motif & Notes ───────────────────────
                    _card('📋 Informations médicales', [
                      TextFormField(
                        controller: _motifCtrl,
                        maxLines: 2,
                        validator: (v) => v!.isEmpty ? 'Motif requis' : null,
                        decoration: _deco("Motif d'hospitalisation",
                            Icons.chat_bubble_outline),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        decoration: _deco(
                            'Notes / observations (optionnel)', Icons.notes),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _loading ? null : _save,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        widget.hospitalisation == null
                            ? 'Admettre le patient'
                            : 'Enregistrer',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00695C),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // FIX: withOpacity → withValues
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
          ],
        ),
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
        prefixIcon: Icon(icon, color: const Color(0xFF00695C)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00695C), width: 2),
        ),
      );
}
