// lib/screens/hospitalisations/sortie_dialog.dart

import 'package:flutter/material.dart';
import '../../models/hospitalisation.dart';

class SortieDialog extends StatefulWidget {
  final Hospitalisation hospitalisation;
  const SortieDialog({super.key, required this.hospitalisation});

  @override
  State<SortieDialog> createState() => _SortieDialogState();
}

class _SortieDialogState extends State<SortieDialog> {
  final _dateCtrl = TextEditingController();
  final _heureCtrl = TextEditingController();
  final _diagnosticCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl.text = now.toString().substring(0, 10);
    _heureCtrl.text =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _diagnosticCtrl.text = widget.hospitalisation.diagnosticFinal ?? '';
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _heureCtrl.dispose();
    _diagnosticCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    // FIX curly_braces_in_flow_control_structures
    if (p != null) {
      setState(() => _dateCtrl.text = p.toString().substring(0, 10));
    }
  }

  Future<void> _selectTime() async {
    final p =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (p != null) {
      setState(() => _heureCtrl.text =
          '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        const Icon(Icons.logout, color: Color(0xFF00695C)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Sortie — ${widget.hospitalisation.patientNom}',
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: _selectDate,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _dateCtrl,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                  decoration: const InputDecoration(
                    labelText: 'Date de sortie',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectTime,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: _heureCtrl,
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                  decoration: const InputDecoration(
                    labelText: 'Heure de sortie',
                    prefixIcon: Icon(Icons.access_time),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _diagnosticCtrl,
              maxLines: 3,
              validator: (v) =>
                  v!.isEmpty ? 'Veuillez saisir un diagnostic' : null,
              decoration: const InputDecoration(
                labelText: 'Diagnostic final',
                prefixIcon: Icon(Icons.assignment),
                border: OutlineInputBorder(),
              ),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.check, color: Colors.white),
          label: const Text('Valider la sortie',
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00695C)),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'date': _dateCtrl.text,
                'heure': _heureCtrl.text,
                'diagnostic': _diagnosticCtrl.text,
              });
            }
          },
        ),
      ],
    );
  }
}
