 

import 'package:flutter/material.dart';
import 'package:multi_company_invoice/models/product_model.dart';
import 'package:multi_company_invoice/services/product_service.dart';
 

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts(int companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await ProductService.getProductsByCompany(companyId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(int companyId, String query) async {
    try {
      if (query.isEmpty) {
        await loadProducts(companyId);
      } else {
        _products = await ProductService.searchProducts(companyId, query);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addProduct(ProductModel product) async {
    try {
      await ProductService.addProduct(product);
      await loadProducts(product.companyId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      await ProductService.updateProduct(product);
      await loadProducts(product.companyId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(int id, int companyId) async {
    try {
      await ProductService.deleteProduct(id);
      await loadProducts(companyId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}