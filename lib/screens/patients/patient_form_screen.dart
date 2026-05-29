// lib/screens/patients/patient_form_screen.dart
// Formulaire pour ajouter ou modifier un patient

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/patient.dart';

class PatientFormScreen extends StatefulWidget {
  // Si patient != null, c'est une modification. Sinon c'est un ajout.
  final Patient? patient;

  const PatientFormScreen({super.key, this.patient});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>(); // Clé pour valider le formulaire
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Contrôleurs pour les champs texte
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  String _sexe = 'M';
  String _groupeSanguin = 'A+';
  bool _isLoading = false;

  final List<String> _groupesSanguins = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    // Si on modifie un patient existant, pré-remplir les champs
    if (widget.patient != null) {
      _nomController.text = widget.patient!.nom;
      _prenomController.text = widget.patient!.prenom;
      _dateNaissanceController.text = widget.patient!.dateNaissance;
      _telephoneController.text = widget.patient!.telephone;
      _adresseController.text = widget.patient!.adresse;
      _sexe = widget.patient!.sexe;
      _groupeSanguin = widget.patient!.groupeSanguin;
    }
  }

  @override
  void dispose() {
    // Libérer la mémoire
    _nomController.dispose();
    _prenomController.dispose();
    _dateNaissanceController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  // Ouvre le sélecteur de date
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateNaissanceController.text = picked.toString().substring(0, 10);
    }
  }

  // Sauvegarde le patient (insert ou update)
  Future<void> _savePatient() async {
    // Vérifie que tous les champs requis sont valides
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final patient = Patient(
      id: widget.patient?.id, // null si nouveau patient
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      dateNaissance: _dateNaissanceController.text,
      sexe: _sexe,
      telephone: _telephoneController.text.trim(),
      adresse: _adresseController.text.trim(),
      groupeSanguin: _groupeSanguin,
    );

    try {
      if (widget.patient == null) {
        await _dbHelper.insertPatient(patient);
      } else {
        await _dbHelper.updatePatient(patient);
      }

      if (mounted) {
        Navigator.pop(context); // Retourne à la liste
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.patient == null ? 'Patient ajouté !' : 'Patient modifié !'),
            backgroundColor: Colors.green,
          ),
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
    final isEditing = widget.patient != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Modifier le patient' : 'Nouveau patient',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
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
                title: '👤 Identité',
                children: [
                  _buildTextField(
                    controller: _prenomController,
                    label: 'Prénom',
                    icon: Icons.person,
                    validator: (v) => v!.isEmpty ? 'Le prénom est requis' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nomController,
                    label: 'Nom de famille',
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Le nom est requis' : null,
                  ),
                  const SizedBox(height: 12),
                  // Sélecteur de sexe
                  Row(
                    children: [
                      const Text('Sexe :', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 16),
                      _buildChoiceChip('M', 'Masculin', Icons.male),
                      const SizedBox(width: 8),
                      _buildChoiceChip('F', 'Féminin', Icons.female),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Sélecteur de date de naissance
                  GestureDetector(
                    onTap: _selectDate,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: _dateNaissanceController,
                        label: 'Date de naissance',
                        icon: Icons.calendar_today,
                        validator: (v) => v!.isEmpty ? 'La date est requise' : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: '📞 Contact',
                children: [
                  _buildTextField(
                    controller: _telephoneController,
                    label: 'Téléphone',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Le téléphone est requis' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _adresseController,
                    label: 'Adresse',
                    icon: Icons.location_on,
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'L\'adresse est requise' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCard(
                title: '🩸 Médical',
                children: [
                  const Text('Groupe sanguin :', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _groupesSanguins.map((g) => ChoiceChip(
                      label: Text(g),
                      selected: _groupeSanguin == g,
                      onSelected: (_) => setState(() => _groupeSanguin = g),
                      selectedColor: const Color(0xFF1565C0),
                      labelStyle: TextStyle(
                        color: _groupeSanguin == g ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    )).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Bouton de sauvegarde
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _savePatient,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                label: Text(
                  isEditing ? 'Enregistrer les modifications' : 'Ajouter le patient',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour une section avec titre
  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // Widget pour un champ de saisie
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
      ),
    );
  }

  // Widget pour un chip de sélection sexe
  Widget _buildChoiceChip(String value, String label, IconData icon) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(label)],
      ),
      selected: _sexe == value,
      onSelected: (_) => setState(() => _sexe = value),
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(
        color: _sexe == value ? Colors.white : Colors.black,
      ),
    );
  }
}
