// lib/features/company/model/company_model.dart

import 'dart:ui';

class CompanyModel {
  final int? id;
  final String name;
  final String? logo;
  final String email;
  final String? phone;
  final String? address;
  final String pin;
  final String headerColor;
  final String footerColor;
  final String bodyColor;
  final String textColor;
  final String? createdAt;

  CompanyModel({
    this.id,
    required this.name,
    this.logo,
    required this.email,
    this.phone,
    this.address,
    required this.pin,
    this.headerColor = 'FF4FD1C5',
    this.footerColor = 'FF2D3748',
    this.bodyColor = 'FFFFFFFF',
    this.textColor = 'FF2D3748',
    this.createdAt,
  });

  // Color helpers
  Color get headerColorValue => Color(int.parse('0x$headerColor'));
  Color get footerColorValue => Color(int.parse('0x$footerColor'));
  Color get bodyColorValue => Color(int.parse('0x$bodyColor'));
  Color get textColorValue => Color(int.parse('0x$textColor'));

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'logo': logo,
        'email': email,
        'phone': phone,
        'address': address,
        'pin': pin,
        'header_color': headerColor,
        'footer_color': footerColor,
        'body_color': bodyColor,
        'text_color': textColor,
      };

  factory CompanyModel.fromMap(Map<String, dynamic> map) => CompanyModel(
        id: map['id'],
        name: map['name'],
        logo: map['logo'],
        email: map['email'],
        phone: map['phone'],
        address: map['address'],
        pin: map['pin'],
        headerColor: map['header_color'] ?? 'FF4FD1C5',
        footerColor: map['footer_color'] ?? 'FF2D3748',
        bodyColor: map['body_color'] ?? 'FFFFFFFF',
        textColor: map['text_color'] ?? 'FF2D3748',
        createdAt: map['created_at'],
      );

  // Convert Color → hex string for storage
  static String colorToHex(Color color) =>
      color.value.toRadixString(16).toUpperCase().padLeft(8, '0');
}