import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:multi_company_invoice/providers/company_provider.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../dashboard_screen.dart';

class CompanyLoginScreen extends StatefulWidget {
  final String companyName;
  final String companyEmail;
  final String? companyLogo;

  const CompanyLoginScreen({
    super.key,
    required this.companyName,
    required this.companyEmail,
    this.companyLogo,
  });

  @override
  State<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<CompanyLoginScreen> {
  final pinController = TextEditingController();
  bool isPinVisible = false;
  bool isLoading = false;

// lib/screens/company/company_login_screen.dart
// _handleLogin() mein yeh change karo:

  void _handleLogin() async {
    if (pinController.text.isEmpty) {}

    setState(() => isLoading = true);

    final company = await context
        .read<CompanyProvider>()
        .loginCompany(widget.companyEmail, pinController.text.trim());

    if (!mounted) return;
    setState(() => isLoading = false);

    if (company != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            company: company, // ← full CompanyModel pass karo
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Incorrect PIN. Please try again."),
            backgroundColor: AppColors.error),
      );
      pinController.clear();
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Row(
        children: [
          // ================= LEFT SIDE (PIN FORM) =================
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Positioned(
                  top: 40.h,
                  left: 40.w,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios,
                        color: AppColors.textPrimary, size: 20.sp),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Center(
                  child: SizedBox(
                    width: 380.w,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Info Card
                        Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10.r,
                                    offset: Offset(0, 4.h))
                              ]),
                          child: Row(
                            children: [
                              Container(
                                height: 50.h,
                                width: 50.w,
                                decoration: BoxDecoration(
                                  color: AppColors.scaffoldBg,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: widget.companyLogo != null &&
        widget.companyLogo!.isNotEmpty
    ? ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Image.file(
          File(widget.companyLogo!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(
            Icons.broken_image_outlined,
            color: AppColors.textMuted,
            size: 22.sp,
          ),
        ),
      )
    : Icon(
        Icons.business_rounded,
        color: AppColors.primary,
        size: 24.sp,
      ),),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.companyName,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                          color: AppColors.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      widget.companyEmail,
                                      style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 13.sp),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),

                        SizedBox(height: 40.h),

                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Enter your security PIN to access the dashboard",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        SizedBox(height: 35.h),

                        _pinInputField(),

                        SizedBox(height: 30.h),

                        SizedBox(
                          width: double.infinity,
                          height: 50.h,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 2,
                              shadowColor: AppColors.primary.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            onPressed: isLoading ? null : _handleLogin,
                            child: isLoading
                                ? SizedBox(
                                    width: 20.w,
                                    height: 20.h,
                                    child: const CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : Text(
                                    "Unlock Dashboard",
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
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
          ),

          // ================= RIGHT SIDE =================
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF05CD99), Color(0xFF3E8EED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      height: 300.h,
                      width: 300.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -80,
                    left: -80,
                    child: Container(
                      height: 250.h,
                      width: 250.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flash_on_rounded,
                            color: Colors.white, size: 60.sp),
                        SizedBox(height: 15.h),
                        Text(
                          "chakra",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _pinInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Security PIN",
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
              color: AppColors.textPrimary),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: pinController,
          obscureText: !isPinVisible,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: TextStyle(
              fontSize: 18.sp, letterSpacing: 8, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: "",
            hintText: "••••",
            hintStyle: const TextStyle(letterSpacing: 8),
            prefixIcon: Icon(Icons.lock_outline,
                size: 20.sp, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                isPinVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20.sp,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => isPinVisible = !isPinVisible),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
