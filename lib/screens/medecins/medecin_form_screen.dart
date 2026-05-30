// lib/screens/medecins/medecin_form_screen.dart
// Formulaire pour ajouter ou modifier un médecin

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/medecin.dart';

class MedecinFormScreen extends StatefulWidget {
  final Medecin? medecin;
  const MedecinFormScreen({super.key, this.medecin});

  @override
  State<MedecinFormScreen> createState() => _MedecinFormScreenState();
}

class _MedecinFormScreenState extends State<MedecinFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _specialite = 'Cardiologie';
  bool _disponible = true;
  bool _isLoading = false;

  final List<String> _specialites = [
    'Cardiologie',
    'Pédiatrie',
    'Neurologie',
    'Chirurgie',
    'Gynécologie',
    'Orthopédie',
    'Dermatologie',
    'Ophtalmologie',
    'Médecine générale',
    'Psychiatrie',
    'Radiologie',
    'Anesthésie',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.medecin != null) {
      _nomController.text = widget.medecin!.nom;
      _prenomController.text = widget.medecin!.prenom;
      _telephoneController.text = widget.medecin!.telephone;
      _emailController.text = widget.medecin!.email;
      _specialite = widget.medecin!.specialite;
      _disponible = widget.medecin!.disponible;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveMedecin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final medecin = Medecin(
      id: widget.medecin?.id,
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      specialite: _specialite,
      telephone: _telephoneController.text.trim(),
      email: _emailController.text.trim(),
      disponible: _disponible,
    );

    try {
      if (widget.medecin == null) {
        await _dbHelper.insertMedecin(medecin);
      } else {
        await _dbHelper.updateMedecin(medecin);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médecin enregistré !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          widget.medecin == null ? 'Nouveau médecin' : 'Modifier médecin',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCard(
                title: '👨‍⚕️ Informations',
                children: [
                  _buildTextField(
                    _prenomController,
                    'Prénom',
                    Icons.person,
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _nomController,
                    'Nom',
                    Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  // Dropdown pour la spécialité
                  DropdownButtonFormField<String>(
                    value: _specialite,
                    decoration: InputDecoration(
                      labelText: 'Spécialité',
                      prefixIcon: const Icon(
                        Icons.medical_services,
                        color: Color(0xFF2E7D32),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _specialites
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _specialite = v!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: '📞 Contact',
                children: [
                  _buildTextField(
                    _telephoneController,
                    'Téléphone',
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _emailController,
                    'Email',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v!.isEmpty) return 'Requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: '📋 Statut',
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Disponible pour consultations',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      _disponible
                          ? 'Le médecin accepte des patients'
                          : 'Non disponible',
                    ),
                    value: _disponible,
                    onChanged: (v) => setState(() => _disponible = v),
                    activeThumbColor: const Color(0xFF2E7D32),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveMedecin,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  widget.medecin == null ? 'Ajouter le médecin' : 'Enregistrer',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }
}
