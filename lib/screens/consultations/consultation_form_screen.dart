// lib/screens/consultations/consultation_form_screen.dart
// Formulaire pour créer ou modifier une consultation

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/consultation.dart';
import '../../models/patient.dart';
import '../../models/medecin.dart';

class ConsultationFormScreen extends StatefulWidget {
  final Consultation? consultation;
  const ConsultationFormScreen({super.key, this.consultation});

  @override
  State<ConsultationFormScreen> createState() => _ConsultationFormScreenState();
}

class _ConsultationFormScreenState extends State<ConsultationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final _motifController = TextEditingController();
  final _diagnosticController = TextEditingController();
  final _traitementController = TextEditingController();
  final _dateController = TextEditingController();
  final _heureController = TextEditingController();

  List<Patient> _patients = [];
  List<Medecin> _medecins = [];
  Patient? _selectedPatient;
  Medecin? _selectedMedecin;
  String _statut = 'planifié';
  bool _isLoading = false;
  bool _loadingData = true;

  final List<String> _statuts = ['planifié', 'en_cours', 'terminé', 'annulé'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final patients = await _dbHelper.getAllPatients();
    final medecins = await _dbHelper.getAllMedecins();

    setState(() {
      _patients = patients;
      _medecins = medecins;
      _loadingData = false;
    });

    // Si on modifie une consultation existante
    if (widget.consultation != null) {
      final c = widget.consultation!;
      _motifController.text = c.motif;
      _diagnosticController.text = c.diagnostic;
      _traitementController.text = c.traitement;
      _dateController.text = c.date;
      _heureController.text = c.heure;
      _statut = c.statut;

      // Sélectionner le patient et le médecin correspondants
      try {
        _selectedPatient = _patients.firstWhere((p) => p.id == c.patientId);
        _selectedMedecin = _medecins.firstWhere((m) => m.id == c.medecinId);
      } catch (_) {}
      setState(() {});
    } else {
      // Valeurs par défaut pour une nouvelle consultation
      final now = DateTime.now();
      _dateController.text = now.toString().substring(0, 10);
      _heureController.text =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _dateController.text = picked.toString().substring(0, 10);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      _heureController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _saveConsultation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner un patient'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedMedecin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner un médecin'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final consultation = Consultation(
      id: widget.consultation?.id,
      patientId: _selectedPatient!.id!,
      medecinId: _selectedMedecin!.id!,
      date: _dateController.text,
      heure: _heureController.text,
      motif: _motifController.text.trim(),
      diagnostic: _diagnosticController.text.trim(),
      traitement: _traitementController.text.trim(),
      statut: _statut,
    );

    try {
      if (widget.consultation == null) {
        await _dbHelper.insertConsultation(consultation);
      } else {
        await _dbHelper.updateConsultation(consultation);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Consultation enregistrée !'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _motifController.dispose();
    _diagnosticController.dispose();
    _traitementController.dispose();
    _dateController.dispose();
    _heureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          widget.consultation == null
              ? 'Nouvelle consultation'
              : 'Modifier consultation',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE65100),
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
                    _buildCard(
                      title: '👥 Participants',
                      children: [
                        // Dropdown patient
                        DropdownButtonFormField<Patient>(
                          value: _selectedPatient,
                          isExpanded:
                              true, // ← empêche le débordement horizontal
                          decoration: InputDecoration(
                            labelText: 'Patient',
                            prefixIcon: const Icon(Icons.person,
                                color: Color(0xFF1565C0)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          hint: const Text('Sélectionner un patient'),
                          items: _patients
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(
                                      '${p.prenom} ${p.nom}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (p) =>
                              setState(() => _selectedPatient = p),
                        ),
                        const SizedBox(height: 12),
                        // Dropdown médecin
                        DropdownButtonFormField<Medecin>(
                          value: _selectedMedecin,
                          isExpanded:
                              true, // ← empêche le débordement horizontal
                          decoration: InputDecoration(
                            labelText: 'Médecin',
                            prefixIcon: const Icon(Icons.medical_services,
                                color: Color(0xFF2E7D32)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
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
                          onChanged: (m) =>
                              setState(() => _selectedMedecin = m),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: '📅 Date et Heure',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: _selectDate,
                                child: AbsorbPointer(
                                  child: TextFormField(
                                    controller: _dateController,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requis' : null,
                                    decoration: InputDecoration(
                                      labelText: 'Date',
                                      prefixIcon: const Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFFE65100)),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
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
                                    controller: _heureController,
                                    validator: (v) =>
                                        v!.isEmpty ? 'Requis' : null,
                                    decoration: InputDecoration(
                                      labelText: 'Heure',
                                      prefixIcon: const Icon(Icons.access_time,
                                          color: Color(0xFFE65100)),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Statut
                        DropdownButtonFormField<String>(
                          value: _statut,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Statut',
                            prefixIcon: const Icon(Icons.info_outline,
                                color: Color(0xFFE65100)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _statuts
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _statut = v!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      title: '📋 Informations médicales',
                      children: [
                        TextFormField(
                          controller: _motifController,
                          maxLines: 2,
                          validator: (v) =>
                              v!.isEmpty ? 'Le motif est requis' : null,
                          decoration: InputDecoration(
                            labelText: 'Motif de consultation',
                            prefixIcon: const Icon(Icons.chat_bubble_outline,
                                color: Color(0xFFE65100)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _diagnosticController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Diagnostic (optionnel)',
                            prefixIcon: const Icon(Icons.assignment,
                                color: Color(0xFFE65100)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _traitementController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Traitement prescrit (optionnel)',
                            prefixIcon: const Icon(Icons.medication,
                                color: Color(0xFFE65100)),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveConsultation,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save, color: Colors.white),
                      label: Text(
                        widget.consultation == null
                            ? 'Enregistrer la consultation'
                            : 'Modifier',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE65100),
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

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
