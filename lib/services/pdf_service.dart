// lib/services/pdf_service.dart
// Génère et partage une facture au format PDF

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../models/facture.dart';

class PdfService {
  // ── Couleurs de l'app dans le PDF ──────────────
  static const _bleu = PdfColor.fromInt(0xFF1565C0);
  static const _gris = PdfColor.fromInt(0xFF757575);
  static const _grisLight = PdfColor.fromInt(0xFFF5F5F5);
  static const _rouge = PdfColor.fromInt(0xFFD32F2F);
  static const _vert = PdfColor.fromInt(0xFF2E7D32);

  /// Génère le PDF et retourne le fichier
  static Future<File> genererPdf(Facture facture) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => _buildHeader(facture),
      footer: (_) => _buildFooter(),
      build: (_) => [
        pw.SizedBox(height: 20),
        _buildInfoPatient(facture),
        pw.SizedBox(height: 20),
        _buildTableauLignes(facture),
        pw.SizedBox(height: 16),
        _buildTotaux(facture),
        pw.SizedBox(height: 24),
        _buildModePaiement(facture),
        if (facture.notes.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _buildNotes(facture),
        ],
        pw.SizedBox(height: 32),
        _buildSignature(),
      ],
    ));

    // Sauvegarde dans le dossier temporaire
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${facture.numero}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── Aperçu dans l'app (Printing) ───────────────
  static Future<void> afficherApercu(
      BuildContext context, Facture facture) async {
    await Printing.layoutPdf(
      onLayout: (_) async => (await genererPdf(facture)).readAsBytes(),
      name: facture.numero,
    );
  }

  // ── Télécharger dans Documents ──────────────────
  static Future<String> telecharger(Facture facture) async {
    final file = await genererPdf(facture);
    Directory saveDir;
    if (Platform.isAndroid) {
      saveDir = Directory('/storage/emulated/0/Download');
      if (!await saveDir.exists()) saveDir = await getTemporaryDirectory();
    } else {
      saveDir = await getApplicationDocumentsDirectory();
    }
    final dest = File('${saveDir.path}/${facture.numero}.pdf');
    await file.copy(dest.path);
    await OpenFilex.open(dest.path);
    return dest.path;
  }

  // ── Partager via WhatsApp, email, etc. ──────────
  static Future<void> partager(Facture facture) async {
    final file = await genererPdf(facture);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Facture ${facture.numero}',
      text: 'Veuillez trouver ci-joint la facture ${facture.numero}.',
    );
  }

  // ════════════════════════════════════════════════
  //              CONSTRUCTION DU PDF
  // ════════════════════════════════════════════════

  static pw.Widget _buildHeader(Facture facture) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _bleu, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('🏥 HÔPITAL CENTRAL',
                style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _bleu)),
            pw.Text('Service de facturation',
                style: pw.TextStyle(fontSize: 11, color: _gris)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('FACTURE',
                style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: _bleu)),
            pw.Text(facture.numero,
                style: pw.TextStyle(fontSize: 13, color: _gris)),
            pw.Text('Date : ${facture.date}',
                style: pw.TextStyle(fontSize: 11, color: _gris)),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoPatient(Facture facture) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _grisLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('PATIENT',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _gris)),
            pw.SizedBox(height: 4),
            pw.Text(facture.patientNom ?? 'N/A',
                style:
                    pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('TYPE DE FACTURE',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _gris)),
            pw.SizedBox(height: 4),
            pw.Text(Facture.libelleType(facture.type),
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: _bleu)),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _buildTableauLignes(Facture facture) {
    final headers = ['Description', 'Qté', 'Prix unit.', 'Montant'];
    final data = facture.lignes
        .map((l) => [
              l.description,
              l.quantite.toString(),
              '${l.prixUnitaire.toStringAsFixed(0)} Ar',
              '${l.montant.toStringAsFixed(0)} Ar',
            ])
        .toList();

    return pw.Table(
      border: pw.TableBorder.all(color: _grisLight),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _bleu),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11)),
                  ))
              .toList(),
        ),
        // Lignes
        ...data.asMap().entries.map((entry) => pw.TableRow(
              decoration: pw.BoxDecoration(
                color: entry.key.isEven ? PdfColors.white : _grisLight,
              ),
              children: entry.value
                  .map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        child: pw.Text(cell,
                            style: const pw.TextStyle(fontSize: 11)),
                      ))
                  .toList(),
            )),
      ],
    );
  }

  static pw.Widget _buildTotaux(Facture facture) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 220,
          child: pw.Column(children: [
            _ligneTotal(
                'Sous-total', '${facture.sousTotal.toStringAsFixed(0)} Ar'),
            if (facture.remise > 0)
              _ligneTotal('Remise (${facture.remise.toStringAsFixed(0)}%)',
                  '- ${facture.montantRemise.toStringAsFixed(0)} Ar',
                  couleur: _rouge),
            pw.Divider(color: _bleu),
            _ligneTotal('TOTAL', '${facture.total.toStringAsFixed(0)} Ar',
                bold: true, couleur: _bleu, fontSize: 14),
          ]),
        ),
      ],
    );
  }

  static pw.Widget _ligneTotal(
    String label,
    String valeur, {
    bool bold = false,
    PdfColor? couleur,
    double fontSize = 11,
  }) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: couleur,
      fontSize: fontSize,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Text(label, style: style), pw.Text(valeur, style: style)],
      ),
    );
  }

  static pw.Widget _buildModePaiement(Facture facture) {
    final icons = {
      'especes': '💵',
      'mobile_money': '📱',
      'carte': '💳',
      'assurance': '🏦',
    };
    final labels = {
      'especes': 'Espèces',
      'mobile_money': 'Mobile Money',
      'carte': 'Carte bancaire',
      'assurance': 'Assurance',
    };
    final statuts = {
      'payee': ('PAYÉE', _vert),
      'en_attente': ('EN ATTENTE', _rouge),
      'annulee': ('ANNULÉE', _gris),
    };
    final (statutLabel, statutColor) = statuts[facture.statut] ?? ('?', _gris);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '${icons[facture.modePaiement] ?? ''} Mode de paiement : ${labels[facture.modePaiement] ?? facture.modePaiement}',
          style: pw.TextStyle(fontSize: 11, color: _gris),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: statutColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(statutLabel,
              style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12)),
        ),
      ],
    );
  }

  static pw.Widget _buildNotes(Facture facture) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grisLight),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child:
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Notes :',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.SizedBox(height: 4),
        pw.Text(facture.notes, style: const pw.TextStyle(fontSize: 11)),
      ]),
    );
  }

  static pw.Widget _buildSignature() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          pw.Text('Signature et cachet',
              style: pw.TextStyle(fontSize: 10, color: _gris)),
          pw.SizedBox(height: 40),
          pw.Container(width: 120, height: 1, color: _gris),
        ]),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _grisLight)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Hôpital Central — Service Facturation',
              style: const pw.TextStyle(fontSize: 9, color: _gris)),
          pw.Text('Document généré automatiquement',
              style: const pw.TextStyle(fontSize: 9, color: _gris)),
        ],
      ),
    );
  }
}
