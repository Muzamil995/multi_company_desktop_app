// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:multi_company_invoice/models/company_model.dart';
import 'package:multi_company_invoice/models/invoice_model.dart';
import 'package:multi_company_invoice/providers/invoice_provider.dart';
import 'package:multi_company_invoice/providers/product_provider.dart';
import 'package:multi_company_invoice/services/invoice_pdf_service.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import 'widgets/main_layout.dart';

class DashboardScreen extends StatefulWidget {
  final CompanyModel company;

  const DashboardScreen({super.key, required this.company});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Track which invoice is generating PDF
  int? _downloadingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices(widget.company.id!);
      context.read<ProductProvider>().loadProducts(widget.company.id!);
    });
  }

  // ─── PDF DOWNLOAD ─────────────────────────────────────────
  Future<void> _downloadPdf(InvoiceModel invoice) async {
    setState(() => _downloadingId = invoice.id);

    final items =
        await context.read<InvoiceProvider>().getItems(invoice.id!);

    if (!mounted) return;

    await InvoicePdfService.download(
      context,
      invoice,
      items,
      widget.company,
    );

    if (mounted) setState(() => _downloadingId = null);
  }

  // ─── DATE HELPERS (Updated to Count Invoices instead of Amount) ───

  int _todaySalesCount(List<InvoiceModel> invoices) {
    final today = DateTime.now();
    return invoices.where((inv) => _isToday(inv.issueDate, today)).length;
  }

  int _monthlySalesCount(List<InvoiceModel> invoices) {
    final now = DateTime.now();
    return invoices.where((inv) => _isThisMonth(inv.issueDate, now)).length;
  }

  int _yearlySalesCount(List<InvoiceModel> invoices) {
    final now = DateTime.now();
    return invoices.where((inv) => _isThisYear(inv.issueDate, now)).length;
  }

  bool _isToday(String dateStr, DateTime today) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return false;
      return int.parse(parts[0]) == today.day &&
          int.parse(parts[1]) == today.month &&
          int.parse(parts[2]) == today.year;
    } catch (_) {
      return false;
    }
  }

  bool _isThisMonth(String dateStr, DateTime now) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return false;
      return int.parse(parts[1]) == now.month &&
          int.parse(parts[2]) == now.year;
    } catch (_) {
      return false;
    }
  }

  bool _isThisYear(String dateStr, DateTime now) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return false;
      return int.parse(parts[2]) == now.year;
    } catch (_) {
      return false;
    }
  }

  // ─── BUILD ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final invoiceProvider = context.watch<InvoiceProvider>();
    final productProvider = context.watch<ProductProvider>();

    final invoices = invoiceProvider.invoices;
    final products = productProvider.products;
    final recentInvoices = invoices.take(6).toList();

    return MainLayout(
      activeRoute: "dashboard",
      title: "Dashboard",
      company: widget.company,
      child: invoiceProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── STAT CARDS ──
                  Row(
                    children: [
                      // ✅ Today Invoices - Using Count
                      _statCard(
                          "Today Invoices",
                          "${_todaySalesCount(invoices)}",
                          Icons.account_balance_wallet),
                      SizedBox(width: 24.w),
                      
                      // ✅ Monthly Invoices - Using Count
                      _statCard(
                          "Monthly Invoices",
                          "${_monthlySalesCount(invoices)}",
                          Icons.calendar_today),
                      SizedBox(width: 24.w),
                      
                      // ✅ Yearly Invoices - Using Count
                      _statCard(
                          "Yearly Invoices",
                          "${_yearlySalesCount(invoices)}",
                          Icons.assessment_outlined),
                      SizedBox(width: 24.w),
                      
                      // ✅ Total Products
                      _statCard(
                          "Total Products", 
                          "${products.length}",
                          Icons.inventory_2_outlined),
                    ],
                  ),

                  SizedBox(height: 30.h),

                  // ── RECENT INVOICES TABLE ──
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(20.r),
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
                        // Card header
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 20.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Recent Invoices",
                                  style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              TextButton(
                                onPressed: () {},
                                child: Text("View All",
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.sp)),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                            height: 1,
                            color: AppColors.border.withOpacity(0.5)),

                        // Column headers
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 12.h),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: _headerCell("INVOICE ID")),
                              Expanded(
                                  flex: 2, child: _headerCell("DATE")),
                              Expanded(
                                  flex: 3,
                                  child: _headerCell("CUSTOMER")),
                              Expanded(
                                  flex: 2, child: _headerCell("AMOUNT")),
                              Expanded(
                                  flex: 2, child: _headerCell("STATUS")),
                              Expanded(
                                  flex: 1, child: _headerCell("ACTION")),
                            ],
                          ),
                        ),
                        Divider(
                            height: 1,
                            color: AppColors.border.withOpacity(0.3)),

                        // Rows
                        recentInvoices.isEmpty
                            ? Padding(
                                padding: EdgeInsets.all(40.r),
                                child: Center(
                                  child: Text("No invoices yet",
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 14.sp)),
                                ),
                              )
                            : Column(
                                children: recentInvoices
                                    .map((inv) => _buildInvoiceRow(inv))
                                    .toList(),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── STAT CARD ────────────────────────────────────────────
  Widget _statCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10.r,
                offset: Offset(0, 5.h))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Text(value,
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12.r)),
              child: Icon(icon, color: Colors.white, size: 20.sp),
            )
          ],
        ),
      ),
    );
  }

  // ─── HEADER CELL ──────────────────────────────────────────
  Widget _headerCell(String label) => Text(label,
      style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5));

  // ─── INVOICE ROW ──────────────────────────────────────────
  Widget _buildInvoiceRow(InvoiceModel invoice) {
    Color statusColor;
    Color statusBgColor;

    switch (invoice.status) {
      case "Paid":
        statusColor = AppColors.success;
        statusBgColor = AppColors.success.withOpacity(0.1);
        break;
      case "Pending":
        statusColor = AppColors.warning;
        statusBgColor = AppColors.warning.withOpacity(0.1);
        break;
      case "Overdue":
        statusColor = AppColors.error;
        statusBgColor = AppColors.error.withOpacity(0.1);
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusBgColor = AppColors.scaffoldBg;
    }

    final bool isDownloading = _downloadingId == invoice.id;

    return Column(
      children: [
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          child: Row(
            children: [
              // Invoice ID
              Expanded(
                flex: 2,
                child: Text(invoice.invoiceNo,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 13.sp)),
              ),

              // Date
              Expanded(
                flex: 2,
                child: Text(invoice.issueDate,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.sp)),
              ),

              // Customer
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    // CircleAvatar(
                    //   radius: 14.r,
                    //   backgroundColor: AppColors.scaffoldBg,
                    //   child: Text(invoice.customerName[0],
                    //       style: TextStyle(
                    //           fontSize: 12.sp,
                    //           color: AppColors.textPrimary,
                    //           fontWeight: FontWeight.bold)),
                    // ),
                    // SizedBox(width: 10.w),
                    Flexible(
                      child: Text(invoice.customerName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 13.sp)),
                    ),
                  ],
                ),
              ),

              // Amount
              Expanded(
                flex: 2,
                child: Text(
                    "total: ${invoice.total.toStringAsFixed(2)}", 
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14.sp)),
              ),

              // Status badge
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20.r)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor)),
                      SizedBox(width: 6.w),
                      Text(invoice.status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // ── DOWNLOAD ACTION ──────────────────────────
              Expanded(
                flex: 1,
                child: isDownloading
                    ? SizedBox(
                        width: 20.sp,
                        height: 20.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : IconButton(
                        icon: Icon(Icons.download_outlined,
                            size: 18.sp, color: AppColors.primary),
                        onPressed: () => _downloadPdf(invoice),
                        tooltip: "Download PDF",
                        splashRadius: 20,
                      ),
              ),
            ],
          ),
        ),
        Divider(
            height: 1, color: AppColors.border.withOpacity(0.3)),
      ],
    );
  }
}