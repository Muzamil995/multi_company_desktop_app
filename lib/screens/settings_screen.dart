import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:multi_company_invoice/models/company_model.dart';
import 'package:multi_company_invoice/providers/company_provider.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import 'widgets/main_layout.dart';

class SettingsScreen extends StatefulWidget {
  final CompanyModel company;

  const SettingsScreen({super.key, required this.company});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  String? _logoPath;
  bool isLoading = false;

  late CompanyModel _currentCompany;

  @override
  void initState() {
    super.initState();
    _currentCompany = widget.company;
    _populateFields(_currentCompany);
  }

  void _populateFields(CompanyModel c) {
    nameController.text = c.name;
    emailController.text = c.email;
    phoneController.text = c.phone ?? '';
    addressController.text = c.address ?? '';
    pinController.text = c.pin;
    _logoPath = c.logo;
    headerColor = c.headerColorValue;
    footerColor = c.footerColorValue;
    bodyColor = c.bodyColorValue;
    textColor = c.textColorValue;
  }

  Future<void> _updateCompanySettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final updated = CompanyModel(
      id: _currentCompany.id,
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

    final provider = context.read<CompanyProvider>();
    final success = await provider.updateCompany(updated);

    if (!mounted) return;

    if (success) {
      final freshCompany = provider.companies.firstWhere(
        (c) => c.id == updated.id,
        orElse: () => updated,
      );

      setState(() {
        _currentCompany = freshCompany;
        _populateFields(freshCompany);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? "Company settings updated successfully!"
            : provider.error ?? "Update failed"),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

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
            onColorChanged: (color) {
              onColorChanged(color);
              setState(() {});
            },
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
    context.watch<CompanyProvider>();

    return MainLayout(
      company: _currentCompany,
      activeRoute: "settings",
      title: "Settings",
      child: LayoutBuilder(builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 700;

        return Container(
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
                  _sectionTitle("Company Profile", Icons.domain),
                  SizedBox(height: 8.h),
                  Text(
                      "Update your company's basic information and contact details.",
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13.sp)),
                  SizedBox(height: 24.h),

                  _buildInputRow(
                    isWide,
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
                    isWide,
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

                  _logoPickerPlaceholder(),

                  SizedBox(height: 40.h),
                  const Divider(color: AppColors.border),
                  SizedBox(height: 40.h),

                  _sectionTitle(
                      "Invoice Customization", Icons.color_lens_outlined),
                  SizedBox(height: 8.h),
                  Text(
                      "Modify the brand colors used for generating your PDF invoices.",
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13.sp)),
                  SizedBox(height: 24.h),

                  Wrap(
                    spacing: 20.w,
                    runSpacing: 20.h,
                    children: [
                      _colorPickerBox("Header Color", headerColor,
                          (c) => setState(() => headerColor = c)),
                      _colorPickerBox("Footer Color", footerColor,
                          (c) => setState(() => footerColor = c)),
                      _colorPickerBox("Body Color", bodyColor,
                          (c) => setState(() => bodyColor = c)),
                      _colorPickerBox("Text Color", textColor,
                          (c) => setState(() => textColor = c)),
                    ],
                  ),

                  SizedBox(height: 50.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : _updateCompanySettings,
                        icon: isLoading
                            ? const SizedBox()
                            : Icon(Icons.save,
                                size: 18.sp, color: Colors.white),
                        label: isLoading
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text("Save Changes",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 2,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                          padding: EdgeInsets.symmetric(
                              horizontal: 32.w, vertical: 18.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ================================================================
  // HELPER WIDGETS
  // ================================================================

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r)),
          child: Icon(icon, color: AppColors.primary, size: 20.sp),
        ),
        SizedBox(width: 12.w),
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
        SizedBox(width: 24.w),
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
          style: TextStyle(fontSize: 14.sp, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: "Enter $label",
            hintStyle:
                TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
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

  Widget _logoPickerPlaceholder() {
    final bool hasLogo = _logoPath != null && _logoPath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Company Logo",
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.sp,
                color: AppColors.textPrimary)),
        SizedBox(height: 8.h),
        InkWell(
          onTap: _pickLogo,
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            children: [
              // ── Main container ──
              Container(
                height: 290.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: AppColors.border, style: BorderStyle.solid),
                ),
                child: hasLogo
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.file(
                          File(_logoPath!),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textMuted,
                              size: 32.sp,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              color: AppColors.textSecondary, size: 32.sp),
                          SizedBox(height: 12.h),
                          Text("Click to upload logo",
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp)),
                          SizedBox(height: 4.h),
                          Text("SVG, PNG, JPG or GIF (max. 800x400px)",
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.sp)),
                        ],
                      ),
              ),

              // ── Edit icon overlay (top-right, only when logo is set) ──
              if (hasLogo)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                    child: Icon(Icons.edit_outlined,
                        color: Colors.white, size: 16.sp),
                  ),
                ),
            ],
          ),
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
        width: 150.w,
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