// lib/screens/patients/patients_screen.dart
// Liste de tous les patients avec recherche

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/patient.dart';
import 'patient_form_screen.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Patient> _patients = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() => _isLoading = true);
    final patients = await _dbHelper.getAllPatients();
    setState(() {
      _patients = patients;
      _isLoading = false;
    });
  }

  // Recherche de patients en temps réel
  Future<void> _searchPatients(String query) async {
    if (query.isEmpty) {
      _loadPatients();
      return;
    }
    final results = await _dbHelper.searchPatients(query);
    setState(() => _patients = results);
  }

  // Confirme et supprime un patient
  Future<void> _deletePatient(Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Supprimer ${patient.prenom} ${patient.nom} ?\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deletePatient(patient.id!);
      _loadPatients();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Patient supprimé'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Patients',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      // Bouton flottant pour ajouter un patient
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PatientFormScreen()),
        ).then((_) => _loadPatients()),
        backgroundColor: const Color(0xFF1565C0),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau patient',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _searchPatients,
              decoration: InputDecoration(
                hintText: 'Rechercher un patient...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadPatients();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Compteur de patients
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_patients.length} patient(s)',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Liste des patients
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _patients.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Aucun patient trouvé',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPatients,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _patients.length,
                          itemBuilder: (ctx, i) =>
                              _buildPatientCard(_patients[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Carte affichant un patient
  Widget _buildPatientCard(Patient patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        isThreeLine: true,
        leading: CircleAvatar(
          backgroundColor: patient.sexe == 'M'
              ? const Color(0xFF1565C0).withValues(alpha: 0.1)
              : Colors.pink.withValues(alpha: 0.1),
          child: Text(
            patient.prenom[0].toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color:
                  patient.sexe == 'M' ? const Color(0xFF1565C0) : Colors.pink,
            ),
          ),
        ),
        title: Text(
          '${patient.prenom} ${patient.nom}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📞 ${patient.telephone}'),
            Text('🩸 Groupe: ${patient.groupeSanguin}'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (ctx) => [
            const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Modifier')
                  ],
                )),
            const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer')
                  ],
                )),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PatientFormScreen(patient: patient)),
              ).then((_) => _loadPatients());
            } else if (value == 'delete') {
              _deletePatient(patient);
            }
          },
        ),
      ),
    );
  }
}
