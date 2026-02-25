// lib/features/product/model/product_model.dart

class ProductModel {
  final int? id;
  final int companyId;
  final String name;
  final double price;
  final int stock;
  final String? createdAt;

  ProductModel({
    this.id,
    required this.companyId,
    required this.name,
    required this.price,
    required this.stock,
    this.createdAt,
  });

  bool get inStock => stock > 0;

  // ← Fix: dropdown comparison ka liye
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'name': name,
        'price': price,
        'stock': stock,
      };

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id: map['id'],
        companyId: map['company_id'],
        name: map['name'],
        price: (map['price'] as num).toDouble(),
        stock: map['stock'],
        createdAt: map['created_at'],
      );

  ProductModel copyWith({
    int? id,
    int? companyId,
    String? name,
    double? price,
    int? stock,
  }) =>
      ProductModel(
        id: id ?? this.id,
        companyId: companyId ?? this.companyId,
        name: name ?? this.name,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        createdAt: createdAt,
      );
}