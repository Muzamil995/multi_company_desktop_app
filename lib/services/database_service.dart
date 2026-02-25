// lib/core/database/database_service.dart

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;

  static Future<void> init() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'multi_company_invoice.db');
    
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
      ),
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    
    // ================= COMPANIES =================
    await db.execute('''
      CREATE TABLE companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        logo TEXT,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        address TEXT,
        pin TEXT NOT NULL,
        header_color TEXT,
        footer_color TEXT,
        body_color TEXT,
        text_color TEXT,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // ================= PRODUCTS =================
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
      )
    ''');
// ================= INVOICES =================
await db.execute('''
  CREATE TABLE invoices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    company_id INTEGER NOT NULL,
    invoice_no TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT,
    customer_phone TEXT,
    customer_address TEXT,
    issue_date TEXT NOT NULL,
    due_date TEXT NOT NULL,
    status TEXT DEFAULT 'Pending',
    discount REAL DEFAULT 0,
    tax_rate REAL DEFAULT 0,
    notes TEXT,
    total REAL NOT NULL DEFAULT 0,
    currency TEXT DEFAULT 'PKR',  -- ✅ Added
    created_at TEXT DEFAULT (datetime('now')),
    FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE
  )
''');

// ================= INVOICE ITEMS =================
await db.execute('''
  CREATE TABLE invoice_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    invoice_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    price REAL NOT NULL DEFAULT 0,
    qty REAL NOT NULL DEFAULT 1,
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE
  )
''');
  }
}