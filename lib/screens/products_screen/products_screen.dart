// lib/screens/products_screen/products_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:multi_company_invoice/models/company_model.dart';
import 'package:multi_company_invoice/models/product_model.dart';
import 'package:multi_company_invoice/providers/product_provider.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
 
 
import '../widgets/main_layout.dart';
import 'product_dialog.dart';

class ProductsScreen extends StatefulWidget {
  final int companyId; // pass from dashboard/login
  final CompanyModel company;

  const ProductsScreen({super.key, required this.companyId,required this.company,});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(widget.companyId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProductDialog({ProductModel? product}) async {
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductDialog(
        companyId: widget.companyId,
        existingProduct: product,
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              product == null ? "Product Added!" : "Product Updated!"),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text("Delete Product",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16.sp)),
        content: Text(
            "Are you sure you want to delete \"${product.name}\"?",
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r))),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context
                  .read<ProductProvider>()
                  .deleteProduct(product.id!, widget.companyId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? "Product deleted!" : "Delete failed"),
                    backgroundColor:
                        success ? AppColors.error : AppColors.textMuted,
                  ),
                );
              }
            },
            child: const Text("Delete",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return MainLayout(
       company:   widget.company,
      activeRoute: "products",
      title: "Products",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================== HEADER ACTIONS ==================
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // OutlinedButton.icon(
              //   onPressed: () {},
              //   icon: Icon(Icons.file_upload_outlined, size: 18.sp),
              //   label: Text("Import from CSV",
              //       style: TextStyle(fontSize: 14.sp)),
              //   style: OutlinedButton.styleFrom(
              //     foregroundColor: AppColors.primary,
              //     side: const BorderSide(color: AppColors.primary),
              //     padding: EdgeInsets.symmetric(
              //         horizontal: 24.w, vertical: 16.h),
              //     shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(12.r)),
              //   ),
              // ),
              SizedBox(width: 16.w),
              ElevatedButton.icon(
                onPressed: () => _openProductDialog(),
                icon: Icon(Icons.add, size: 18.sp, color: Colors.white),
                label: Text("Add Product",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  padding: EdgeInsets.symmetric(
                      horizontal: 24.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),

          SizedBox(height: 30.h),

          // ================== MAIN CARD ==================
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20.r),
                border:
                    Border.all(color: AppColors.border.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15.r,
                      offset: Offset(0, 5.h))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Header + Search
                  Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("All Products",
                            style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        Container(
                          width: 250.w,
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldBg,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                                color: AppColors.border.withOpacity(0.5)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (q) => context
                                .read<ProductProvider>()
                                .searchProducts(widget.companyId, q),
                            decoration: InputDecoration(
                              hintText: "Search products...",
                              hintStyle: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.textMuted),
                              prefixIcon: Icon(Icons.search,
                                  size: 18.sp,
                                  color: AppColors.textSecondary),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12.h),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                      height: 1,
                      color: AppColors.border.withOpacity(0.5)),

                  // Body
                  Expanded(
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : provider.products.isEmpty
                            ? _emptyState()
                            : SingleChildScrollView(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: DataTable(
                                    headingRowHeight: 50.h,
                                    dataRowMaxHeight: 70.h,
                                    dataRowMinHeight: 70.h,
                                    horizontalMargin: 24.w,
                                    columnSpacing: 24.w,
                                    dividerThickness: 0.5,
                                    headingTextStyle: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                        letterSpacing: 0.5),
                                    columns: const [
                                      DataColumn(label: Text("PRODUCT")),
                                      DataColumn(label: Text("PRICE")),
                                      DataColumn(label: Text("STOCK")),
                                      DataColumn(label: Text("STATUS")),
                                      DataColumn(label: Text("ACTIONS")),
                                    ],
                                    rows: provider.products
                                        .map((p) => _buildProductRow(p))
                                        .toList(),
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildProductRow(ProductModel product) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              Container(
                height: 40.h,
                width: 40.w,
                decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                        color: AppColors.border.withOpacity(0.5))),
                child: Icon(Icons.inventory_2_outlined,
                    size: 20.sp, color: AppColors.primary),
              ),
              SizedBox(width: 16.w),
              Text(product.name,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14.sp)),
            ],
          ),
        ),
        DataCell(Text(
          "total: ${product.price.toStringAsFixed(2)}",
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14.sp),
        )),
        DataCell(Text(
          "${product.stock}",
          style:
              TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
        )),
        DataCell(
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
                color: product.inStock
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 6.w,
                    height: 6.h,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: product.inStock
                            ? AppColors.success
                            : AppColors.error)),
                SizedBox(width: 6.w),
                Text(product.inStock ? "In Stock" : "Out of Stock",
                    style: TextStyle(
                        color: product.inStock
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18.sp, color: AppColors.textSecondary),
                splashRadius: 20,
                onPressed: () => _openProductDialog(product: product),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18.sp, color: AppColors.error),
                splashRadius: 20,
                onPressed: () => _confirmDelete(product),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 55.sp, color: AppColors.textMuted),
          SizedBox(height: 16.h),
          Text("No products found",
              style: TextStyle(
                  fontSize: 16.sp, color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          Text("Tap 'Add Product' to get started",
              style:
                  TextStyle(fontSize: 13.sp, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}