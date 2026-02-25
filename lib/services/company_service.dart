 

import 'package:multi_company_invoice/models/company_model.dart';
import 'package:multi_company_invoice/services/database_service.dart';

class CompanyService {
  // INSERT
  static Future<int> addCompany(CompanyModel company) async {
    final db = await DatabaseService.database;
    return await db.insert('companies', company.toMap());
  }

  // GET ALL
  static Future<List<CompanyModel>> getAllCompanies() async {
    final db = await DatabaseService.database;
    final result = await db.query('companies', orderBy: 'created_at DESC');
    return result.map((e) => CompanyModel.fromMap(e)).toList();
  }

  // GET BY ID
  static Future<CompanyModel?> getCompanyById(int id) async {
    final db = await DatabaseService.database;
    final result =
        await db.query('companies', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? CompanyModel.fromMap(result.first) : null;
  }

  // LOGIN (email + pin)
  static Future<CompanyModel?> loginCompany(
      String email, String pin) async {
    final db = await DatabaseService.database;
    final result = await db.query('companies',
        where: 'email = ? AND pin = ?', whereArgs: [email, pin]);
    return result.isNotEmpty ? CompanyModel.fromMap(result.first) : null;
  }

  // UPDATE
  static Future<int> updateCompany(CompanyModel company) async {
    final db = await DatabaseService.database;
    return await db.update('companies', company.toMap(),
        where: 'id = ?', whereArgs: [company.id]);
  }

  // DELETE
  static Future<int> deleteCompany(int id) async {
    final db = await DatabaseService.database;
    return await db.delete('companies', where: 'id = ?', whereArgs: [id]);
  }
}