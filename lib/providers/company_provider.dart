 

import 'package:flutter/material.dart';
import 'package:multi_company_invoice/models/company_model.dart';
import 'package:multi_company_invoice/services/company_service.dart';

class CompanyProvider extends ChangeNotifier {
  List<CompanyModel> _companies = [];
  bool _isLoading = false;
  String? _error;

  List<CompanyModel> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCompanies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _companies = await CompanyService.getAllCompanies();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCompany(CompanyModel company) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await CompanyService.addCompany(company);
      await loadCompanies();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCompany(CompanyModel company) async {
    try {
      await CompanyService.updateCompany(company);
      await loadCompanies();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCompany(int id) async {
    try {
      await CompanyService.deleteCompany(id);
      await loadCompanies();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<CompanyModel?> loginCompany(String email, String pin) async {
  try {
    return await CompanyService.loginCompany(email, pin);
  } catch (e) {
    _error = e.toString();
    notifyListeners();
    return null;
  }
}

  void clearError() {
    _error = null;
    notifyListeners();
  }
}