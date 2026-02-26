// lib/screens/invoice_screens/invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:multi_company_invoice/models/company_model.dart';
import 'package:multi_company_invoice/models/invoice_model.dart';
import 'package:multi_company_invoice/providers/invoice_provider.dart';
import 'package:multi_company_invoice/services/invoice_pdf_service.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../widgets/main_layout.dart';
import 'create_invoice_screen.dart';

class InvoiceScreen extends StatefulWidget {
  final int companyId;
  final CompanyModel company;

  const InvoiceScreen({
    super.key,
    required this.companyId,
    required this.company,
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _searchController = TextEditingController();

  // ─── FILTERS LISTS ───
  final List<String> _tabs = ['All', 'Paid', 'Pending', 'Draft', 'Overdue'];
  final List<String> _currencyTabs = ['All', 'USD', 'EUR', 'GBP', 'PKR'];

  // Track active currency filter locally
  String _activeCurrencyFilter = 'All';

  // Track which invoice is currently generating a PDF
  int? _downloadingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices(widget.companyId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── DELETE ────────────────────────────────────────────────
  void _confirmDelete(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text("Delete Invoice",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
        content: Text(
            'Delete invoice "${invoice.invoiceNo}"? This cannot be undone.',
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
              final ok = await context
                  .read<InvoiceProvider>()
                  .deleteInvoice(invoice.id!, widget.companyId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? "Invoice deleted!" : "Delete failed"),
                  backgroundColor: ok ? AppColors.error : AppColors.textMuted,
                ));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── DOWNLOAD PDF ──────────────────────────────────────────
  Future<void> _downloadPdf(InvoiceModel invoice) async {
    setState(() => _downloadingId = invoice.id);

    // Fetch line items for this invoice
    final items = await context.read<InvoiceProvider>().getItems(invoice.id!);

    if (!mounted) return;

    await InvoicePdfService.download(
      context,
      invoice,
      items,
      widget.company,
    );

    if (mounted) setState(() => _downloadingId = null);
  }

  // ─── BUILD ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InvoiceProvider>();

    // Local filtering for Currency
    List<InvoiceModel> filteredInvoices = provider.invoices;
    if (_activeCurrencyFilter != 'All') {
      filteredInvoices = filteredInvoices.where((inv) {
        // Assume invoice has a currency property
        return inv.currency == _activeCurrencyFilter;
      }).toList();
    }

    return MainLayout(
      company: widget.company,
      activeRoute: "invoices",
      title: "Invoices",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADER ACTIONS ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filters Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Filter Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _tabs.map((tab) {
                          final isActive = provider.activeFilter == tab;
                          return Padding(
                            padding: EdgeInsets.only(right: 10.w),
                            child: GestureDetector(
                              onTap: () => context
                                  .read<InvoiceProvider>()
                                  .filterByStatus(widget.companyId, tab),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primary.withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20.r),
                                  border: Border.all(
                                      color: isActive
                                          ? AppColors.primary
                                          : AppColors.border),
                                ),
                                child: Text(tab,
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: isActive
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isActive
                                            ? AppColors.primary
                                            : AppColors.textSecondary)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // ✅ Currency Dropdown Added Here
                    Container(
                      height: 36.h,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBg,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _activeCurrencyFilter,
                          icon: Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary, size: 20.sp),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          dropdownColor: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12.r),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _activeCurrencyFilter = newValue;
                              });
                            }
                          },
                          items: _currencyTabs
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                  value == 'All' ? 'All Currencies' : value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 16.w),

              // Create Invoice Button
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateInvoiceScreen(
                        company: widget.company,
                      ),
                    ),
                  );
                  if (mounted) {
                    context
                        .read<InvoiceProvider>()
                        .loadInvoices(widget.companyId);
                  }
                },
                icon: Icon(Icons.add, size: 18.sp, color: Colors.white),
                label: Text("Create Invoice",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
          ),

          SizedBox(height: 30.h),

          // ── MAIN CARD ──
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 15.r,
                        offset: Offset(0, 5.h))
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header + search
                  Padding(
                    padding: EdgeInsets.all(24.r),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Recent Invoices",
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
                                  color: AppColors.border.withOpacity(0.5))),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (q) => context
                                .read<InvoiceProvider>()
                                .searchInvoices(widget.companyId, q),
                            decoration: InputDecoration(
                              hintText: "Search invoice...",
                              hintStyle: TextStyle(
                                  fontSize: 13.sp, color: AppColors.textMuted),
                              prefixIcon: Icon(Icons.search,
                                  size: 18.sp, color: AppColors.textSecondary),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12.h),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.border.withOpacity(0.5)),

                  // Column headers
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: _headerCell("INVOICE ID")),
                        Expanded(flex: 2, child: _headerCell("DATE")),
                        Expanded(flex: 3, child: _headerCell("CUSTOMER")),
                        Expanded(flex: 2, child: _headerCell("AMOUNT")),
                        Expanded(flex: 2, child: _headerCell("STATUS")),
                        Expanded(flex: 2, child: _headerCell("ACTIONS")),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppColors.border.withOpacity(0.3)),

                  // Body
                  Expanded(
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredInvoices.isEmpty
                            ? _emptyState()
                            : SingleChildScrollView(
                                child: Column(
                                  children: filteredInvoices
                                      .map((inv) => _buildRow(context, inv))
                                      .toList(),
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

  // ─── HEADER CELL ───────────────────────────────────────────
  Widget _headerCell(String label) => Text(label,
      style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 0.5));

  // ─── INVOICE ROW ───────────────────────────────────────────
  Widget _buildRow(BuildContext context, InvoiceModel invoice) {
    Color statusColor;
    Color statusBgColor;

    switch (invoice.status) {
      case 'Paid':
        statusColor = AppColors.success;
        statusBgColor = AppColors.success.withOpacity(0.1);
        break;
      case 'Pending':
        statusColor = AppColors.warning;
        statusBgColor = AppColors.warning.withOpacity(0.1);
        break;
      case 'Overdue':
        statusColor = AppColors.error;
        statusBgColor = AppColors.error.withOpacity(0.1);
        break;
      case 'Draft':
        statusColor = AppColors.textSecondary;
        statusBgColor = AppColors.scaffoldBg;
        break;
      default:
        statusColor = AppColors.primary;
        statusBgColor = AppColors.primary.withOpacity(0.1);
    }

    final isDownloading = _downloadingId == invoice.id;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
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
                        color: AppColors.textSecondary, fontSize: 13.sp)),
              ),

              // Customer
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                   
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
                  '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 14.sp),
                ),
              ),

              // Status badge
              Expanded(
                flex: 2,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
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
                              shape: BoxShape.circle, color: statusColor)),
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

              // ACTIONS
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit — Draft only
                    if (invoice.status == 'Draft')
                      IconButton(
                        icon: Icon(Icons.edit_outlined,
                            size: 18.sp, color: AppColors.textSecondary),
                        onPressed: () async {
                          final items = await context
                              .read<InvoiceProvider>()
                              .getItems(invoice.id!);
                          if (!mounted) return;
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateInvoiceScreen(
                                existingInvoice: invoice,
                                company: widget.company,
                                existingItems: items,
                              ),
                            ),
                          );
                          if (mounted) {
                            context
                                .read<InvoiceProvider>()
                                .loadInvoices(widget.companyId);
                          }
                        },
                        tooltip: "Edit Draft",
                        splashRadius: 20,
                      ),

                    // ── DOWNLOAD PDF ──────────────────────────
                    isDownloading
                        ? SizedBox(
                            width: 18.sp,
                            height: 18.sp,
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

                    // Delete
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 18.sp, color: AppColors.error),
                      onPressed: () => _confirmDelete(invoice),
                      tooltip: "Delete",
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.border.withOpacity(0.3)),
      ],
    );
  }

  // ─── EMPTY STATE ───────────────────────────────────────────
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 55.sp, color: AppColors.textMuted),
          SizedBox(height: 16.h),
          Text("No invoices found",
              style:
                  TextStyle(fontSize: 16.sp, color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          Text("Tap 'Create Invoice' to get started",
              style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
