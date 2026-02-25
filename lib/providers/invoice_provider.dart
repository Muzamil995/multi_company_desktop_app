 

import 'package:flutter/material.dart';
import 'package:multi_company_invoice/models/invoice_model.dart';
import 'package:multi_company_invoice/services/invoice_service.dart';
 

class InvoiceProvider extends ChangeNotifier {
  List<InvoiceModel> _invoices = [];
  bool _isLoading = false;
  String? _error;
  String _activeFilter = 'All';

  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get activeFilter => _activeFilter;

  Future<void> loadInvoices(int companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      if (_activeFilter == 'All') {
        _invoices = await InvoiceService.getInvoicesByCompany(companyId);
      } else {
        _invoices =
            await InvoiceService.getInvoicesByStatus(companyId, _activeFilter);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> filterByStatus(int companyId, String status) async {
    _activeFilter = status;
    await loadInvoices(companyId);
  }

  Future<void> searchInvoices(int companyId, String query) async {
    try {
      if (query.isEmpty) {
        await loadInvoices(companyId);
      } else {
        _invoices = await InvoiceService.searchInvoices(companyId, query);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addInvoice(
      InvoiceModel invoice, List<InvoiceItemModel> items) async {
    try {
      await InvoiceService.addInvoice(invoice, items);
      await loadInvoices(invoice.companyId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateInvoice(
      InvoiceModel invoice, List<InvoiceItemModel> items) async {
    try {
      await InvoiceService.updateInvoice(invoice, items);
      await loadInvoices(invoice.companyId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteInvoice(int id, int companyId) async {
    try {
      await InvoiceService.deleteInvoice(id);
      await loadInvoices(companyId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String> generateInvoiceNo(int companyId) =>
      InvoiceService.generateInvoiceNo(companyId);

  Future<List<InvoiceItemModel>> getItems(int invoiceId) =>
      InvoiceService.getInvoiceItems(invoiceId);
}