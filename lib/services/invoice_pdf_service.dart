// lib/core/invoice_pdf_service.dart
//
// Usage:
//   await InvoicePdfService.download(context, invoice, items, company);
//
// pubspec.yaml:
//   pdf: ^3.10.8
//   printing: ^5.12.0

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:multi_company_invoice/models/company_model.dart';
import 'package:multi_company_invoice/models/invoice_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoicePdfService {
  // ─────────────────────────────────────────────────────────
  // PUBLIC ENTRY POINT
  // ─────────────────────────────────────────────────────────
  static Future<void> download(
    BuildContext context,
    InvoiceModel invoice,
    List<InvoiceItemModel> items,
    CompanyModel company,
  ) async {
    try {
      final Uint8List pdf = await _buildPdf(invoice, items, company);
      final fileName =
          '${invoice.invoiceNo.replaceAll(RegExp(r'[#/\\]'), '')}.pdf';
      await Printing.layoutPdf(
        onLayout: (_) async => pdf,
        name: fileName,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────
  // BUILD PDF
  // ─────────────────────────────────────────────────────────
  static Future<Uint8List> _buildPdf(
    InvoiceModel invoice,
    List<InvoiceItemModel> items,
    CompanyModel company,
  ) async {
    // Company brand colors from stored hex
    final PdfColor headerBg = _hex(company.headerColor, PdfColors.teal);
    final PdfColor footerBg = _hex(company.footerColor, const PdfColor.fromInt(0xFF2D3748));
    final PdfColor bodyBg   = _hex(company.bodyColor,   PdfColors.white);
    final PdfColor textClr  = _hex(company.textColor,   const PdfColor.fromInt(0xFF2D3748));

    final PdfColor headerFg   = _isLight(headerBg) ? PdfColors.grey800 : PdfColors.white;
    final PdfColor footerFg   = _isLight(footerBg) ? PdfColors.grey600 : const PdfColor.fromInt(0xFFA0AEC0);
    final PdfColor accentLight = PdfColor(headerBg.red, headerBg.green, headerBg.blue, 0.10);
    final PdfColor statusClr  = _statusColor(invoice.status);

    // Optional logo
    pw.MemoryImage? logoImg;
    if (company.logo != null && company.logo!.isNotEmpty) {
      try {
        logoImg = pw.MemoryImage(await File(company.logo!).readAsBytes());
      } catch (_) {}
    }

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) => [
          _header(company, invoice, headerBg, headerFg, logoImg),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _billTo(invoice, textClr, statusClr),
                pw.SizedBox(height: 28),
                _itemsTable(items, headerBg, headerFg, bodyBg, textClr, accentLight, invoice.currency),
                pw.SizedBox(height: 20),
                _totals(invoice, headerBg, textClr, invoice.currency),
                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  _notes(invoice.notes!, textClr),
                ],
              ],
            ),
          ),
        ],
        footer: (pw.Context ctx) => _footer(company, invoice, footerBg, footerFg),
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  // ─────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────
  static pw.Widget _header(
    CompanyModel c,
    InvoiceModel inv,
    PdfColor bg,
    PdfColor fg,
    pw.MemoryImage? logo,
  ) {
    return pw.Container(
      color: bg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Company info + optional logo
          pw.Row(
            children: [
              if (logo != null) ...[
                pw.Container(
                  height: 48,
                  width: 48,
                  decoration: pw.BoxDecoration(
                    color: PdfColor(1, 1, 1, 0.15),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 14),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(c.name.toUpperCase(),
                      style: pw.TextStyle(
                          color: fg,
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2)),
                  pw.SizedBox(height: 3),
                  pw.Text(c.email,
                      style: pw.TextStyle(
                          color: PdfColor(fg.red, fg.green, fg.blue, 0.7),
                          fontSize: 10)),
                  if (c.phone != null && c.phone!.isNotEmpty)
                    pw.Text(c.phone!,
                        style: pw.TextStyle(
                            color: PdfColor(fg.red, fg.green, fg.blue, 0.7),
                            fontSize: 10)),
                  if (c.address != null && c.address!.isNotEmpty)
                    pw.Text(c.address!,
                        style: pw.TextStyle(
                            color: PdfColor(fg.red, fg.green, fg.blue, 0.7),
                            fontSize: 10)),
                ],
              ),
            ],
          ),

          // Invoice badge
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('INVOICE',
                  style: pw.TextStyle(
                      color: fg,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 3)),
              pw.SizedBox(height: 4),
              pw.Text(inv.invoiceNo,
                  style: pw.TextStyle(
                      color: PdfColor(fg.red, fg.green, fg.blue, 0.75),
                      fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BILL TO + META
  // ─────────────────────────────────────────────────────────
  static pw.Widget _billTo(
    InvoiceModel inv,
    PdfColor textClr,
    PdfColor statusClr,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BILL TO',
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey500,
                      letterSpacing: 1.5)),
              pw.SizedBox(height: 6),
              pw.Text(inv.customerName,
                  style: pw.TextStyle(
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                      color: textClr)),
              if (inv.customerEmail != null && inv.customerEmail!.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(inv.customerEmail!,
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
              ],
              if (inv.customerAddress != null &&
                  inv.customerAddress!.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(inv.customerAddress!,
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
              ],
            ],
          ),
        ),

        // Right meta column
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _metaRow('Issue Date:', inv.issueDate, textClr),
            pw.SizedBox(height: 5),
            _metaRow('Due Date:', inv.dueDate ?? '—', textClr),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Status:',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey600)),
                pw.SizedBox(width: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColor(statusClr.red, statusClr.green,
                        statusClr.blue, 0.12),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Text(inv.status,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: statusClr)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _metaRow(String label, String value, PdfColor textClr) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 10, color: PdfColors.grey600)),
        pw.SizedBox(width: 8),
        pw.Text(value,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: textClr)),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // ITEMS TABLE
  // ─────────────────────────────────────────────────────────
  static pw.Widget _itemsTable(
    List<InvoiceItemModel> items,
    PdfColor headerBg,
    PdfColor headerFg,
    PdfColor bodyBg,
    PdfColor textClr,
    PdfColor accentLight,
    String currency,
  ) {
    return pw.Column(
      children: [
        // Header row
        pw.Container(
          color: headerBg,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: pw.Row(
            children: [
              pw.Expanded(flex: 4, child: _th('DESCRIPTION', headerFg)),
              pw.Expanded(
                  flex: 1,
                  child: _th('QTY', headerFg,
                      align: pw.TextAlign.center)),
              pw.Expanded(
                  flex: 2,
                  child: _th('RATE', headerFg,
                      align: pw.TextAlign.right)),
              pw.Expanded(
                  flex: 2,
                  child: _th('AMOUNT', headerFg,
                      align: pw.TextAlign.right)),
            ],
          ),
        ),

        // Data rows
        ...items.asMap().entries.map((e) {
          final item = e.value;
          final rowBg = e.key % 2 == 0 ? accentLight : bodyBg;
          final amount = item.qty * item.price;

          return pw.Container(
            color: rowBg,
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: pw.Row(
              children: [
                pw.Expanded(
                    flex: 4,
                    child: pw.Text(item.name,
                        style:
                            pw.TextStyle(fontSize: 10, color: textClr))),
                pw.Expanded(
                    flex: 1,
                    child: pw.Text('${item.qty}',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey600))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                        '$currency${item.price.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey600))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('$currency${amount.toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: textClr))),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _th(String text, PdfColor fg,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Text(text,
        textAlign: align,
        style: pw.TextStyle(
            color: fg,
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5));
  }

  // ─────────────────────────────────────────────────────────
  // TOTALS
  // ─────────────────────────────────────────────────────────
  static pw.Widget _totals(
    InvoiceModel inv,
    PdfColor accentColor,
    PdfColor textClr,
    String currency,
  ) {
    // inv.discount and inv.taxRate are stored as flat amounts
    final double discountAmt = inv.discount;
    final double taxAmt      = inv.taxRate;
    final double subtotal    = inv.total - taxAmt + discountAmt;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 220,
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _tRow('Subtotal', '$currency${subtotal.toStringAsFixed(2)}', textClr),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              _tRow('Discount', '-$currency${discountAmt.toStringAsFixed(2)}', textClr),
              pw.Divider(color: PdfColors.grey300, thickness: 0.5),
              _tRow('Tax', '+$currency${taxAmt.toStringAsFixed(2)}', textClr),
              pw.Divider(color: accentColor, thickness: 1),
              _tRow('TOTAL', '$currency${inv.total.toStringAsFixed(2)}',
                  accentColor,
                  isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _tRow(String label, String value, PdfColor color,
      {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: isTotal ? 12 : 10,
                  fontWeight: isTotal
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  color: isTotal ? color : PdfColors.grey600)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: isTotal ? 14 : 10,
                  fontWeight: pw.FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // NOTES
  // ─────────────────────────────────────────────────────────
  static pw.Widget _notes(String notes, PdfColor textClr) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Notes & Terms',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: textClr)),
          pw.SizedBox(height: 5),
          pw.Text(notes,
              style: const pw.TextStyle(
                  fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────────────────────
  static pw.Widget _footer(
    CompanyModel c,
    InvoiceModel inv,
    PdfColor bg,
    PdfColor fg,
  ) {
    return pw.Container(
      color: bg,
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Thank you for your business — ${c.name}',
              style: pw.TextStyle(color: fg, fontSize: 9)),
          pw.Text(inv.invoiceNo,
              style: pw.TextStyle(color: fg, fontSize: 9)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────

  /// "FF4FD1C5" or "#4FD1C5" → PdfColor
  static PdfColor _hex(String? hex, PdfColor fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final clean = hex.replaceAll('#', '');
      final val = int.parse(
          clean.length == 6 ? 'FF$clean' : clean,
          radix: 16);
      return PdfColor.fromInt(val);
    } catch (_) {
      return fallback;
    }
  }

  /// True when colour is light → needs dark text
  static bool _isLight(PdfColor c) =>
      (c.red * 299 + c.green * 587 + c.blue * 114) / 1000 > 0.6;

  static PdfColor _statusColor(String status) {
    switch (status) {
      case 'Paid':    return const PdfColor.fromInt(0xFF38A169);
      case 'Pending': return const PdfColor.fromInt(0xFFDD6B20);
      case 'Overdue': return const PdfColor.fromInt(0xFFE53E3E);
      default:        return PdfColors.grey600;
    }
  }
}