 

import 'package:multi_company_invoice/models/invoice_model.dart';
import 'package:multi_company_invoice/services/database_service.dart';

class InvoiceService {
  // ── INSERT invoice + items (transaction) ──
  static Future<int> addInvoice(
      InvoiceModel invoice, List<InvoiceItemModel> items) async {
    final db = await DatabaseService.database;

    return await db.transaction((txn) async {
      final invoiceId = await txn.insert('invoices', invoice.toMap());

      for (final item in items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'name': item.name,
          'price': item.price,
          'qty': item.qty,
        });
      }

      return invoiceId;
    });
  }

  // ── GET ALL by company ──
  static Future<List<InvoiceModel>> getInvoicesByCompany(
      int companyId) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'invoices',
      where: 'company_id = ?',
      whereArgs: [companyId],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => InvoiceModel.fromMap(e)).toList();
  }

  // ── GET by status ──
  static Future<List<InvoiceModel>> getInvoicesByStatus(
      int companyId, String status) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'invoices',
      where: 'company_id = ? AND status = ?',
      whereArgs: [companyId, status],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => InvoiceModel.fromMap(e)).toList();
  }

  // ── SEARCH ──
  static Future<List<InvoiceModel>> searchInvoices(
      int companyId, String query) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'invoices',
      where:
          'company_id = ? AND (customer_name LIKE ? OR invoice_no LIKE ?)',
      whereArgs: [companyId, '%$query%', '%$query%'],
    );
    return result.map((e) => InvoiceModel.fromMap(e)).toList();
  }

  // ── GET ITEMS for an invoice ──
  static Future<List<InvoiceItemModel>> getInvoiceItems(
      int invoiceId) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
    );
    return result.map((e) => InvoiceItemModel.fromMap(e)).toList();
  }

  // ── UPDATE invoice + replace items ──
  static Future<void> updateInvoice(
      InvoiceModel invoice, List<InvoiceItemModel> items) async {
    final db = await DatabaseService.database;

    await db.transaction((txn) async {
      await txn.update(
        'invoices',
        invoice.toMap(),
        where: 'id = ?',
        whereArgs: [invoice.id],
      );

      // Delete old items and re-insert
      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoice.id],
      );

      for (final item in items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoice.id,
          'name': item.name,
          'price': item.price,
          'qty': item.qty,
        });
      }
    });
  }

  // ── UPDATE status only ──
  static Future<void> updateStatus(int invoiceId, String status) async {
    final db = await DatabaseService.database;
    await db.update(
      'invoices',
      {'status': status},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  // ── DELETE ──
  static Future<int> deleteInvoice(int id) async {
    final db = await DatabaseService.database;
    return await db
        .delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  // ── AUTO invoice number ──
  static Future<String> generateInvoiceNo(int companyId) async {
    final db = await DatabaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices WHERE company_id = ?',
      [companyId],
    );
    final count = (result.first['count'] as int) + 1;
    return 'INV-${DateTime.now().year}-${count.toString().padLeft(3, '0')}';
  }
}