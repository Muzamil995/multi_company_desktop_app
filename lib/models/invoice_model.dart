class InvoiceModel {
  final int? id;
  final int companyId;
  final String invoiceNo;
  final String customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? customerAddress;
  final String issueDate;
  final String dueDate;
  final String status;
  final double discount;
  final double taxRate;
  final String? notes;
  final double total;
  final String currency; // ✅ Added
  final String? createdAt;

  InvoiceModel({
    this.id,
    required this.companyId,
    required this.invoiceNo,
    required this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.customerAddress,
    required this.issueDate,
    required this.dueDate,
    this.status = 'Pending',
    this.discount = 0,
    this.taxRate = 0,
    this.notes,
    required this.total,
    this.currency = 'PKR', // ✅ Added (default PKR)
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'invoice_no': invoiceNo,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'customer_address': customerAddress,
        'issue_date': issueDate,
        'due_date': dueDate,
        'status': status,
        'discount': discount,
        'tax_rate': taxRate,
        'notes': notes,
        'total': total,
        'currency': currency, // ✅ Added
      };

  factory InvoiceModel.fromMap(Map<String, dynamic> map) => InvoiceModel(
        id: map['id'],
        companyId: map['company_id'],
        invoiceNo: map['invoice_no'],
        customerName: map['customer_name'],
        customerEmail: map['customer_email'],
        customerPhone: map['customer_phone'],
        customerAddress: map['customer_address'],
        issueDate: map['issue_date'],
        dueDate: map['due_date'],
        status: map['status'] ?? 'Pending',
        discount: (map['discount'] as num).toDouble(),
        taxRate: (map['tax_rate'] as num).toDouble(),
        notes: map['notes'],
        total: (map['total'] as num).toDouble(),
        currency: map['currency'] ?? 'PKR', // ✅ Added
        createdAt: map['created_at'],
      );
}

// ─────────────────────────────────────────
class InvoiceItemModel {
  final int? id;
  final int? invoiceId;
  final String name;
  final double price;
  final double qty;

  InvoiceItemModel({
    this.id,
    this.invoiceId,
    required this.name,
    required this.price,
    required this.qty,
  });

  double get total => price * qty;

  Map<String, dynamic> toMap() => {
        'id': id,
        'invoice_id': invoiceId,
        'name': name,
        'price': price,
        'qty': qty,
      };

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) =>
      InvoiceItemModel(
        id: map['id'],
        invoiceId: map['invoice_id'],
        name: map['name'],
        price: (map['price'] as num).toDouble(),
        qty: (map['qty'] as num).toDouble(),
      );
}