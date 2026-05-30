// lib/screens/chambres/chambre_form_screen.dart

import 'package:flutter/material.dart';
import '../../database/database_helper.dart';
import '../../models/chambre.dart';

class ChambreFormScreen extends StatefulWidget {
  final Chambre? chambre;
  const ChambreFormScreen({super.key, this.chambre});

  @override
  State<ChambreFormScreen> createState() => _ChambreFormScreenState();
}

class _ChambreFormScreenState extends State<ChambreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  final _numeroController = TextEditingController();
  final _etageController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'standard';
  int _capacite = 1;
  bool _disponible = true;
  bool _isLoading = false;

  final List<String> _types = ['standard', 'vip', 'urgence', 'reanimation'];

  @override
  void initState() {
    super.initState();
    if (widget.chambre != null) {
      _numeroController.text = widget.chambre!.numero;
      _etageController.text = widget.chambre!.etage;
      _descriptionController.text = widget.chambre!.description;
      _type = widget.chambre!.type;
      _capacite = widget.chambre!.capacite;
      _disponible = widget.chambre!.disponible;
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _etageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final chambre = Chambre(
      id: widget.chambre?.id,
      numero: _numeroController.text.trim(),
      type: _type,
      capacite: _capacite,
      etage: _etageController.text.trim(),
      description: _descriptionController.text.trim(),
      disponible: _disponible,
    );

    try {
      if (widget.chambre == null) {
        await _db.insertChambre(chambre);
      } else {
        await _db.updateChambre(chambre);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Chambre enregistrée !'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text(
            widget.chambre == null ? 'Nouvelle chambre' : 'Modifier chambre',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Identification ──────────────────────
              _card('🏠 Identification', [
                TextFormField(
                  controller: _numeroController,
                  validator: (v) => v!.isEmpty ? 'Numéro requis' : null,
                  decoration:
                      _deco('Numéro de chambre (ex: 101, URG-1)', Icons.tag),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _etageController,
                  validator: (v) => v!.isEmpty ? 'Étage requis' : null,
                  decoration: _deco('Étage (ex: RDC, 1er étage)', Icons.layers),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Type de chambre ──────────────────────
              _card('🏷️ Type de chambre', [
                ..._types.map((type) => RadioListTile<String>(
                      title: Text(Chambre.libelleType(type),
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _couleurType(type))),
                      value: type,
                      groupValue: _type,
                      activeColor: _couleurType(type),
                      onChanged: (v) => setState(() => _type = v!),
                    )),
              ]),
              const SizedBox(height: 16),

              // ── Capacité ────────────────────────────
              _card('🛏️ Capacité en lits', [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 32),
                      color: const Color(0xFF00838F),
                      onPressed: _capacite > 1
                          ? () => setState(() => _capacite--)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Text('$_capacite',
                        style: const TextStyle(
                            fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 32),
                      color: const Color(0xFF00838F),
                      onPressed: _capacite < 20
                          ? () => setState(() => _capacite++)
                          : null,
                    ),
                  ],
                ),
                Center(
                    child: Text(
                  _capacite == 1 ? '1 lit' : '$_capacite lits',
                  style: const TextStyle(color: Colors.grey),
                )),
              ]),
              const SizedBox(height: 16),

              // ── Description + Statut ─────────────────
              _card('📝 Détails', [
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _deco('Description / équipements', Icons.notes),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Chambre disponible',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(_disponible
                      ? 'En service'
                      : 'Hors service (travaux, nettoyage...)'),
                  value: _disponible,
                  onChanged: (v) => setState(() => _disponible = v),
                  activeThumbColor: const Color(0xFF00838F),
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
                    widget.chambre == null
                        ? 'Ajouter la chambre'
                        : 'Enregistrer',
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00838F),
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
        prefixIcon: Icon(icon, color: const Color(0xFF00838F)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00838F), width: 2),
        ),
      );
}
