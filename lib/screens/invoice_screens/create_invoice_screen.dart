// lib/screens/invoice_screens/create_invoice_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:multi_company_invoice/models/company_model.dart';
import 'package:multi_company_invoice/models/invoice_model.dart';
import 'package:multi_company_invoice/providers/invoice_provider.dart';
import 'package:multi_company_invoice/providers/product_provider.dart';
import 'package:multi_company_invoice/models/product_model.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../widgets/main_layout.dart';

class _InvoiceItemRow {
  ProductModel? selectedProduct;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController qtyController = TextEditingController(text: "1");
  final TextEditingController priceController = TextEditingController();

  double get qty => double.tryParse(qtyController.text) ?? 0;
  double get price => double.tryParse(priceController.text) ?? 0;
  double get total => qty * price;

  _InvoiceItemRow.fromModel(InvoiceItemModel m) {
    nameController.text = m.name;
    qtyController.text = m.qty.toString();
    priceController.text = m.price.toString();
  }

  _InvoiceItemRow();

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    priceController.dispose();
  }
}

class CreateInvoiceScreen extends StatefulWidget {
  final CompanyModel company;
  final InvoiceModel? existingInvoice;
  final List<InvoiceItemModel>? existingItems;

  const CreateInvoiceScreen({
    super.key,
    required this.company,
    this.existingInvoice,
    this.existingItems,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final invoiceNoController = TextEditingController();
  final dateController = TextEditingController();
  final dueDateController = TextEditingController();
  String selectedStatus = 'Pending';
  final List<String> statuses = ['Pending', 'Draft', 'Paid'];

  // ── Currency ──
  String selectedCurrency = 'PKR';
  final List<Map<String, String>> currencies = [
    {'code': 'PKR', 'symbol': '₨', 'label': 'PKR – Pakistani Rupee'},
    {'code': 'USD', 'symbol': '\$', 'label': 'USD – US Dollar'},
    {'code': 'AED', 'symbol': 'د.إ', 'label': 'AED – UAE Dirham'},
    {'code': 'EUR', 'symbol': '€', 'label': 'EUR – Euro'},
    {'code': 'GBP', 'symbol': '£', 'label': 'GBP – British Pound'},
    {'code': 'SAR', 'symbol': '﷼', 'label': 'SAR – Saudi Riyal'},
    {'code': 'INR', 'symbol': '₹', 'label': 'INR – Indian Rupee'},
    {'code': 'CAD', 'symbol': 'CA\$', 'label': 'CAD – Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'label': 'AUD – Australian Dollar'},
  ];

  String get currencySymbol =>
      currencies.firstWhere((c) => c['code'] == selectedCurrency,
          orElse: () => currencies[0])['symbol']!;

  final customerNameController = TextEditingController();
  final customerEmailController = TextEditingController();
  final customerPhoneController = TextEditingController();
  final customerAddressController = TextEditingController();

  final discountController = TextEditingController(text: "0");
  final taxRateController = TextEditingController(text: "0");
  final notesController = TextEditingController();

  List<_InvoiceItemRow> items = [];
  bool isLoading = false;
  bool get isEditMode => widget.existingInvoice != null;

  @override
  void initState() {
    super.initState();
    _init();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts(widget.company.id!);
    });
  }

  Future<void> _init() async {
    if (isEditMode) {
      final inv = widget.existingInvoice!;
      invoiceNoController.text = inv.invoiceNo;
      dateController.text = inv.issueDate;
      dueDateController.text = inv.dueDate;
      selectedStatus = inv.status;
      selectedCurrency = inv.currency; // ✅
      customerNameController.text = inv.customerName;
      customerEmailController.text = inv.customerEmail ?? '';
      customerPhoneController.text = inv.customerPhone ?? '';
      customerAddressController.text = inv.customerAddress ?? '';
      discountController.text = inv.discount.toString();
      taxRateController.text = inv.taxRate.toString();
      notesController.text = inv.notes ?? '';

      if (widget.existingItems != null && widget.existingItems!.isNotEmpty) {
        items = widget.existingItems!
            .map((e) => _InvoiceItemRow.fromModel(e))
            .toList();
      } else {
        items = [_InvoiceItemRow()];
      }
    } else {
      dateController.text = _formatDate(DateTime.now());
      dueDateController.text =
          _formatDate(DateTime.now().add(const Duration(days: 14)));
      items = [_InvoiceItemRow()];

      final no = await context
          .read<InvoiceProvider>()
          .generateInvoiceNo(widget.company.id!);
      if (mounted) setState(() => invoiceNoController.text = no);
    }
    if (mounted) setState(() {});
  }

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = _parseDate(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.cardBg,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
            dialogBackgroundColor: AppColors.cardBg,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => controller.text = _formatDate(picked));
    }
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      return DateTime(
          int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    } catch (_) {
      return null;
    }
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => double.tryParse(discountController.text) ?? 0;
  double get taxAmount =>
      (subtotal - discountAmount) *
      ((double.tryParse(taxRateController.text) ?? 0) / 100);
  double get totalAmount => (subtotal - discountAmount) + taxAmount;

  void _addNewItem() => setState(() => items.add(_InvoiceItemRow()));

  void _removeItem(int index) {
    if (items.length > 1) setState(() => items.removeAt(index));
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (items.isEmpty || items[0].nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please add at least one item"),
          backgroundColor: AppColors.error));
      return;
    }

    for (final item in items) {
      if (item.selectedProduct != null) {
        final available = item.selectedProduct!.stock;
        final requested = item.qty.toInt();
        if (requested > available) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  '"${item.selectedProduct!.name}" has only $available in stock'),
              backgroundColor: AppColors.error));
          return;
        }
      }
    }

    setState(() => isLoading = true);

    final invoice = InvoiceModel(
      id: widget.existingInvoice?.id,
      companyId: widget.company.id!,
      invoiceNo: invoiceNoController.text.trim(),
      customerName: customerNameController.text.trim(),
      customerEmail: customerEmailController.text.trim(),
      customerPhone: customerPhoneController.text.trim(),
      customerAddress: customerAddressController.text.trim(),
      issueDate: dateController.text.trim(),
      dueDate: dueDateController.text.trim(),
      status: selectedStatus,
      discount: discountAmount,
      taxRate: double.tryParse(taxRateController.text) ?? 0,
      notes: notesController.text.trim(),
      total: totalAmount,
      currency: selectedCurrency, // ✅
    );

    final invoiceItems = items
        .where((i) => i.nameController.text.isNotEmpty)
        .map((i) => InvoiceItemModel(
              name: i.nameController.text.trim(),
              price: i.price,
              qty: i.qty,
            ))
        .toList();

    final invoiceProvider = context.read<InvoiceProvider>();
    final productProvider = context.read<ProductProvider>();

    final success = isEditMode
        ? await invoiceProvider.updateInvoice(invoice, invoiceItems)
        : await invoiceProvider.addInvoice(invoice, invoiceItems);

    if (success && !isEditMode) {
      for (final item in items) {
        if (item.selectedProduct != null && item.qty > 0) {
          final updated = item.selectedProduct!.copyWith(
            stock: (item.selectedProduct!.stock - item.qty.toInt())
                .clamp(0, item.selectedProduct!.stock),
          );
          await productProvider.updateProduct(updated);
        }
      }
    }

    if (!mounted) return;
    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEditMode
              ? "Invoice Updated Successfully!"
              : "Invoice Saved Successfully!"),
          backgroundColor: AppColors.success));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(invoiceProvider.error ?? "Save failed"),
          backgroundColor: AppColors.error));
    }
  }

  @override
  void dispose() {
    invoiceNoController.dispose();
    dateController.dispose();
    dueDateController.dispose();
    customerNameController.dispose();
    customerEmailController.dispose();
    customerPhoneController.dispose();
    customerAddressController.dispose();
    discountController.dispose();
    taxRateController.dispose();
    notesController.dispose();
    for (var item in items) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 900;
    double containerWidth = isWide ? 1100.w : double.infinity;

    return MainLayout(
      activeRoute: "invoices",
      company: widget.company,
      title: isEditMode ? "Edit Invoice" : "Create Invoice",
      child: Center(
        child: Container(
          width: containerWidth,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 15.r,
                  offset: Offset(0, 5.h))
            ],
            border: Border.all(color: AppColors.border.withOpacity(0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(40.r),
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back,
                          size: 30.sp,
                        )),
                  ),
                  SizedBox(
                    height: 10.h,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle(isEditMode ? "Edit Invoice" : "New Invoice",
                          Icons.receipt_long_outlined),
                      Row(
                        children: [
                          _currencyDropdown(), // ✅ Currency dropdown
                          SizedBox(width: 12.w),
                          _statusDropdown(),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 30.h),
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildInvoiceDetailsCard()),
                            SizedBox(width: 24.w),
                            Expanded(child: _buildCustomerDetailsCard()),
                          ],
                        )
                      : Column(children: [
                          _buildInvoiceDetailsCard(),
                          SizedBox(height: 24.h),
                          _buildCustomerDetailsCard(),
                        ]),
                  SizedBox(height: 40.h),
                  _sectionTitle("Line Items", Icons.list_alt_outlined),
                  SizedBox(height: 16.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r)),
                    child: Row(children: [
                      Expanded(flex: 4, child: _colHeader("PRODUCT")),
                      Expanded(
                          flex: 2,
                          child: _colHeader(
                              "RATE ($currencySymbol)")), // ✅ dynamic symbol
                      Expanded(flex: 1, child: _colHeader("QTY")),
                      Expanded(flex: 2, child: _colHeader("AMOUNT")),
                      SizedBox(width: 40.w),
                    ]),
                  ),
                  SizedBox(height: 10.h),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) => Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _itemRow(index)),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addNewItem,
                      icon: Icon(Icons.add_circle_outline,
                          color: AppColors.primary, size: 18.sp),
                      label: Text("Add Line Item",
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp)),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  const Divider(color: AppColors.border),
                  SizedBox(height: 20.h),
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildNotesSection()),
                            SizedBox(width: 40.w),
                            Expanded(flex: 2, child: _buildTotalsSection()),
                          ],
                        )
                      : Column(children: [
                          _buildTotalsSection(),
                          SizedBox(height: 40.h),
                          _buildNotesSection(),
                        ]),
                  SizedBox(height: 50.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24.w, vertical: 16.h)),
                        child: Text("Cancel",
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp)),
                      ),
                      SizedBox(width: 16.w),
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : _saveInvoice,
                        icon: isLoading
                            ? const SizedBox()
                            : Icon(Icons.check,
                                size: 18.sp, color: Colors.white),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(
                              horizontal: 32.w, vertical: 16.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        label: isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditMode ? "Update Invoice" : "Save Invoice",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════ CURRENCY DROPDOWN ══════════════

  Widget _currencyDropdown() {
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCurrency,
          icon: Icon(Icons.keyboard_arrow_down,
              color: AppColors.primary, size: 18.sp),
          items: currencies.map((c) {
            return DropdownMenuItem<String>(
              value: c['code'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    c['symbol']!,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    c['code']!,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ],
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) => currencies.map((c) {
            return Center(
              child: Text(
                "${c['symbol']} ${c['code']}",
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => selectedCurrency = v);
          },
        ),
      ),
    );
  }

  // ══════════════ ITEM ROW ══════════════

  Widget _itemRow(int index) {
    final item = items[index];
    final products = context.watch<ProductProvider>().products;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48.h,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ProductModel>(
                    value: item.selectedProduct,
                    isExpanded: true,
                    hint: Text("Select product",
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13.sp)),
                    icon: Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary, size: 18.sp),
                    items: products.map((p) {
                      return DropdownMenuItem<ProductModel>(
                        value: p,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(p.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 13.sp,
                                      color: AppColors.textPrimary)),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: p.inStock
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text("${p.stock} left",
                                  style: TextStyle(
                                      fontSize: 11.sp,
                                      color: p.inStock
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (ProductModel? selected) {
                      if (selected != null) {
                        setState(() {
                          item.selectedProduct = selected;
                          item.nameController.text = selected.name;
                          item.priceController.text = selected.price.toString();
                        });
                      }
                    },
                  ),
                ),
              ),
              if (item.selectedProduct == null)
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: _simpleTextField(
                      "Or type item name", item.nameController),
                ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 2,
          child: _simpleTextField("0.00", item.priceController,
              isNumber: true, onChanged: (_) => setState(() {})),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 1,
          child: _simpleTextField("1", item.qtyController,
              isNumber: true,
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {})),
        ),
        SizedBox(width: 16.w),
        Expanded(
          flex: 2,
          child: Container(
            height: 48.h,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: AppColors.border)),
            child: Text(
              "$currencySymbol${item.total.toStringAsFixed(2)}", // ✅
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                  color: AppColors.textPrimary),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        IconButton(
            icon:
                Icon(Icons.delete_outline, color: AppColors.error, size: 20.sp),
            onPressed: () => _removeItem(index),
            splashRadius: 20),
      ],
    );
  }

  // ══════════════ SECTION BUILDERS ══════════════

  Widget _buildInvoiceDetailsCard() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Invoice Details",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: AppColors.textPrimary)),
        SizedBox(height: 20.h),
        _customTextField("Invoice Number", Icons.tag, invoiceNoController,
            isRequired: true),
        SizedBox(height: 16.h),
        Row(children: [
          Expanded(
            child:
                _dateField("Issue Date", Icons.calendar_today, dateController),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child:
                _dateField("Due Date", Icons.event_outlined, dueDateController),
          ),
        ]),
      ]),
    );
  }

  Widget _dateField(
      String label, IconData icon, TextEditingController controller,
      {bool isRequired = true}) {
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
          readOnly: true,
          onTap: () => _pickDate(controller),
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: "DD/MM/YYYY",
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            prefixIcon: Icon(icon, size: 18.sp, color: AppColors.textSecondary),
            suffixIcon: Icon(Icons.calendar_month_outlined,
                size: 18.sp, color: AppColors.primary),
            filled: true,
            fillColor: Colors.white,
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
          validator: (value) => isRequired && (value == null || value.isEmpty)
              ? "Required"
              : null,
        ),
      ],
    );
  }

  Widget _buildCustomerDetailsCard() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Bill To (Customer)",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: AppColors.textPrimary)),
        SizedBox(height: 20.h),
        Row(children: [
          Expanded(
              child: _customTextField(
                  "Customer Name", Icons.person_outline, customerNameController,
                  isRequired: true)),
          SizedBox(width: 16.w),
          Expanded(
              child: _customTextField("Email Address", Icons.email_outlined,
                  customerEmailController)),
        ]),
        SizedBox(height: 16.h),
        Row(children: [
          Expanded(
              child: _customTextField("Phone Number", Icons.phone_outlined,
                  customerPhoneController)),
          SizedBox(width: 16.w),
          Expanded(
              child: _customTextField("Billing Address",
                  Icons.location_on_outlined, customerAddressController)),
        ]),
      ]),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Notes / Terms",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: AppColors.textPrimary)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: notesController,
          maxLines: 4,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: "Enter payment terms, thank you note, etc.",
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            filled: true,
            fillColor: AppColors.scaffoldBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsSection() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(15.r),
          border: Border.all(color: AppColors.border)),
      child: Column(children: [
        _summaryRow(
            "Subtotal", "$currencySymbol${subtotal.toStringAsFixed(2)}"), // ✅
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Discount ($currencySymbol)", // ✅
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
            SizedBox(
              width: 100.w,
              child: _simpleTextField("", discountController,
                  isNumber: true,
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {})),
            )
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Tax Rate (%)",
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 14.sp)),
            SizedBox(
              width: 100.w,
              child: _simpleTextField("", taxRateController,
                  isNumber: true,
                  textAlign: TextAlign.right,
                  onChanged: (_) => setState(() {})),
            )
          ],
        ),
        SizedBox(height: 16.h),
        const Divider(color: AppColors.border),
        SizedBox(height: 16.h),
        _summaryRow("Total Amount",
            "$currencySymbol${totalAmount.toStringAsFixed(2)}", // ✅
            isTotal: true),
      ]),
    );
  }

  // ══════════════ HELPERS ══════════════

  Widget _colHeader(String label) => Text(label,
      style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary));

  Widget _statusDropdown() {
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          icon: Icon(Icons.keyboard_arrow_down,
              color: AppColors.primary, size: 20.sp),
          items: statuses
              .map((s) => DropdownMenuItem<String>(
                    value: s,
                    child: Text(s,
                        style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => selectedStatus = v);
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22.sp),
          SizedBox(width: 10.w),
          Text(title,
              style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
        ],
      );

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color:
                    isTotal ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: isTotal ? 16.sp : 14.sp,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                color: isTotal ? AppColors.primary : AppColors.textPrimary,
                fontSize: isTotal ? 22.sp : 16.sp,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _simpleTextField(String hint, TextEditingController controller,
      {bool isNumber = false,
      bool isRequired = false,
      TextAlign textAlign = TextAlign.left,
      Function(String)? onChanged}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      textAlign: textAlign,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: AppColors.primary)),
      ),
      validator: (value) =>
          (isRequired && (value == null || value.isEmpty)) ? "*" : null,
    );
  }

  Widget _customTextField(
      String label, IconData icon, TextEditingController controller,
      {bool isRequired = false}) {
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
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: "Enter $label",
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            prefixIcon: Icon(icon, size: 18.sp, color: AppColors.textSecondary),
            filled: true,
            fillColor: Colors.white,
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
                borderSide: const BorderSide(color: AppColors.primary)),
          ),
          validator: (value) => isRequired && (value == null || value.isEmpty)
              ? "Required"
              : null,
        ),
      ],
    );
  }
}
