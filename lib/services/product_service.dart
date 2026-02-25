 
 

import 'package:multi_company_invoice/models/product_model.dart';
import 'package:multi_company_invoice/services/database_service.dart';

class ProductService {
  // INSERT
  static Future<int> addProduct(ProductModel product) async {
    final db = await DatabaseService.database;
    return await db.insert('products', product.toMap());
  }

  // GET ALL BY COMPANY
  static Future<List<ProductModel>> getProductsByCompany(int companyId) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'products',
      where: 'company_id = ?',
      whereArgs: [companyId],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => ProductModel.fromMap(e)).toList();
  }

  // SEARCH
  static Future<List<ProductModel>> searchProducts(
      int companyId, String query) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'products',
      where: 'company_id = ? AND name LIKE ?',
      whereArgs: [companyId, '%$query%'],
    );
    return result.map((e) => ProductModel.fromMap(e)).toList();
  }

  // UPDATE
  static Future<int> updateProduct(ProductModel product) async {
    final db = await DatabaseService.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  // DELETE
  static Future<int> deleteProduct(int id) async {
    final db = await DatabaseService.database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }
}