// lib/screens/products_screen/product_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:multi_company_invoice/models/product_model.dart';
import 'package:multi_company_invoice/providers/product_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/app_colors.dart';
 

class ProductDialog extends StatefulWidget {
  final int companyId;
  final ProductModel? existingProduct; // null = add mode

  const ProductDialog({
    super.key,
    required this.companyId,
    this.existingProduct,
  });

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  bool get isEditMode => widget.existingProduct != null;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      nameController.text = widget.existingProduct!.name;
      priceController.text = widget.existingProduct!.price.toString();
      stockController.text = widget.existingProduct!.stock.toString();
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    final product = ProductModel(
      id: widget.existingProduct?.id,
      companyId: widget.companyId,
      name: nameController.text.trim(),
      price: double.tryParse(priceController.text.trim()) ?? 0,
      stock: int.tryParse(stockController.text.trim()) ?? 0,
    );

    final provider = context.read<ProductProvider>();
    final success = isEditMode
        ? await provider.updateProduct(product)
        : await provider.addProduct(product);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (success) {
      Navigator.pop(context, true); // true = success signal
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? "Operation failed"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      backgroundColor: AppColors.cardBg,
      child: Container(
        width: 450.w,
        padding: EdgeInsets.all(32.r),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? "Edit Product" : "Add New Product",
                    style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        color: AppColors.textSecondary, size: 20.sp),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 20,
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 30),

              _customTextField("Product Name", Icons.inventory_2_outlined,
                  nameController,
                  isRequired: true),
              SizedBox(height: 20.h),

              Row(
                children: [
                  Expanded(
                      child: _customTextField(
                          "Price", Icons.attach_money, priceController,
                          isRequired: true, isNumber: true)),
                  SizedBox(width: 20.w),
                  Expanded(
                      child: _customTextField("Stock Quantity",
                          Icons.layers_outlined, stockController,
                          isRequired: true, isNumber: true)),
                ],
              ),
              SizedBox(height: 30.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel",
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp)),
                  ),
                  SizedBox(width: 16.w),
                  ElevatedButton(
                    onPressed: isLoading ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                          horizontal: 24.w, vertical: 16.h),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            isEditMode ? "Update Product" : "Save Product",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp),
                          ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _customTextField(
      String label, IconData icon, TextEditingController controller,
      {bool isRequired = false, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                  color: AppColors.textPrimary)),
          if (isRequired)
            Text(" *",
                style: TextStyle(color: AppColors.error, fontSize: 13.sp)),
        ]),
        SizedBox(height: 8.h),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: "Enter $label",
            hintStyle:
                TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            prefixIcon:
                Icon(icon, size: 18.sp, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.scaffoldBg,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return "Required";
            }
            return null;
          },
        ),
      ],
    );
  }
}