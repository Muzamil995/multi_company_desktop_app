// lib/screens/company/add_company_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:multi_company_invoice/models/company_model.dart';
import 'package:multi_company_invoice/providers/company_provider.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';

class AddCompanyScreen extends StatefulWidget {
  const AddCompanyScreen({super.key});

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final pinController = TextEditingController();

  Color headerColor = const Color(0xFF4FD1C5);
  Color footerColor = const Color(0xFF2D3748);
  Color bodyColor = const Color(0xFFFFFFFF);
  Color textColor = const Color(0xFF2D3748);

  String? _logoPath; // actual file path after picking

  // ── Logo Picker ──
  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _logoPath = result.files.single.path!;
      });
    }
  }

  void _removeLogo() {
    setState(() => _logoPath = null);
  }

  // ── Color Picker ──
  void _pickColor(
      String title, Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pick $title Color',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
          ),
        ),
        actions: [
          TextButton(
            child:
                const Text('Done', style: TextStyle(color: AppColors.primary)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    final company = CompanyModel(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      address: addressController.text.trim(),
      pin: pinController.text.trim(),
      logo: _logoPath,
      headerColor: CompanyModel.colorToHex(headerColor),
      footerColor: CompanyModel.colorToHex(footerColor),
      bodyColor: CompanyModel.colorToHex(bodyColor),
      textColor: CompanyModel.colorToHex(textColor),
    );

    final success = await context.read<CompanyProvider>().addCompany(company);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Company saved successfully!'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      final error = context.read<CompanyProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error ?? 'Something went wrong'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<CompanyProvider>().isLoading;
    bool isWideScreen = MediaQuery.of(context).size.width > 800;
    double containerWidth = isWideScreen ? 1100.w : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Add New Company",
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp)),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: containerWidth,
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15.r,
                  offset: Offset(0, 5.h))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: EdgeInsets.all(40.r),
                children: [
                  _sectionTitle("Company Details", Icons.business),
                  SizedBox(height: 24.h),
                  _buildInputRow(
                    isWideScreen,
                    _customTextField("Company Name", Icons.badge_outlined,
                        nameController,
                        isRequired: true),
                    _customTextField("Email Address", Icons.email_outlined,
                        emailController,
                        isRequired: true,
                        keyboardType: TextInputType.emailAddress),
                  ),
                  SizedBox(height: 20.h),
                  _buildInputRow(
                    isWideScreen,
                    _customTextField("Phone Number", Icons.phone_outlined,
                        phoneController,
                        keyboardType: TextInputType.phone),
                    _customTextField(
                        "Security PIN", Icons.lock_outline, pinController,
                        isRequired: true,
                        isPassword: true,
                        keyboardType: TextInputType.number),
                  ),
                  SizedBox(height: 20.h),
                  _customTextField("Physical Address",
                      Icons.location_on_outlined, addressController,
                      maxLines: 2),
                  SizedBox(height: 20.h),

                  // ── Logo Upload Section ──
                  _buildLogoSection(),

                  SizedBox(height: 40.h),
                  const Divider(color: AppColors.border),
                  SizedBox(height: 40.h),
                  _sectionTitle(
                      "Invoice Theme Colors", Icons.palette_outlined),
                  SizedBox(height: 8.h),
                  Text(
                      "Select colors that match the company's branding for generating professional invoices.",
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13.sp)),
                  SizedBox(height: 24.h),
                  isWideScreen
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _colorPickers(),
                        )
                      : Wrap(
                          spacing: 20.w,
                          runSpacing: 20.h,
                          children: _colorPickers(),
                        ),
                  SizedBox(height: 50.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 16.h),
                        ),
                        child: Text("Cancel",
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp)),
                      ),
                      SizedBox(width: 16.w),
                      ElevatedButton(
                        onPressed: isLoading ? null : _saveCompany,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 2,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                          padding: EdgeInsets.symmetric(
                              horizontal: 32.w, vertical: 16.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text("Save Company",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp)),
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

  // ══════════════ LOGO SECTION ══════════════

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Company Logo",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                color: AppColors.textPrimary)),
        SizedBox(height: 8.h),

        // If logo selected → show preview, else show upload zone
        _logoPath != null ? _logoPreview() : _logoUploadZone(),
      ],
    );
  }

  // ── Upload Zone (no logo selected) ──
  Widget _logoUploadZone() {
  return InkWell(
    onTap: _pickLogo,
    borderRadius: BorderRadius.circular(12.r),
    child: Container(
      height: 150.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.4),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 120.h),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.primary,
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Click to upload logo",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "PNG, JPG, JPEG supported",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  // ── Logo Preview (logo selected) ──
  Widget _logoPreview() {
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.success.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          // Logo image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12.r),
              bottomLeft: Radius.circular(12.r),
            ),
            child: Image.file(
              File(_logoPath!),
              height: 120.h,
              width: 160.w,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120.h,
                width: 160.w,
                color: AppColors.border,
                child: Icon(Icons.broken_image_outlined,
                    color: AppColors.textMuted, size: 30.sp),
              ),
            ),
          ),
          SizedBox(width: 20.w),

          // File info
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.success, size: 16.sp),
                    SizedBox(width: 6.w),
                    Text("Logo uploaded",
                        style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp)),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  _logoPath!.split('/').last, // filename only
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12.sp),
                ),
              ],
            ),
          ),

          // Actions
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _pickLogo,
                icon: Icon(Icons.edit_outlined,
                    color: AppColors.primary, size: 20.sp),
                tooltip: "Change logo",
              ),
              IconButton(
                onPressed: _removeLogo,
                icon: Icon(Icons.delete_outline,
                    color: AppColors.error, size: 20.sp),
                tooltip: "Remove logo",
              ),
            ],
          ),
          SizedBox(width: 8.w),
        ],
      ),
    );
  }

  // ══════════════ HELPERS ══════════════

  List<Widget> _colorPickers() => [
        _colorPickerBox("Header Color", headerColor,
            (c) => setState(() => headerColor = c)),
        _colorPickerBox("Footer Color", footerColor,
            (c) => setState(() => footerColor = c)),
        _colorPickerBox(
            "Body Color", bodyColor, (c) => setState(() => bodyColor = c)),
        _colorPickerBox(
            "Text Color", textColor, (c) => setState(() => textColor = c)),
      ];

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
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
  }

  Widget _buildInputRow(bool isWideScreen, Widget left, Widget right) {
    if (isWideScreen) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: left),
        SizedBox(width: 20.w),
        Expanded(child: right),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      left,
      SizedBox(height: 20.h),
      right,
    ]);
  }

  Widget _customTextField(
      String label, IconData icon, TextEditingController controller,
      {bool isRequired = false,
      bool isPassword = false,
      TextInputType? keyboardType,
      int maxLines = 1}) {
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
          obscureText: isPassword,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: "Enter $label",
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            prefixIcon:
                Icon(icon, size: 18.sp, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.scaffoldBg,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.error)),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return "$label is required";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _colorPickerBox(
      String title, Color color, Function(Color) onColorChanged) {
    return InkWell(
      onTap: () => _pickColor(title, color, onColorChanged),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 160.w,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: AppColors.scaffoldBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              height: 40.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h))
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                    color: AppColors.textPrimary)),
            SizedBox(height: 4.h),
            Text(
                "#${color.value.toRadixString(16).toUpperCase().substring(2)}",
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }
}