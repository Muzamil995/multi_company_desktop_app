import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:multi_company_invoice/models/company_model.dart';
import 'package:multi_company_invoice/providers/company_provider.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
 
import 'company_login_screen.dart';
import 'add_company_screen.dart';

class CompanyListScreen extends StatefulWidget {
  const CompanyListScreen({super.key});

  @override
  State<CompanyListScreen> createState() => _CompanyListScreenState();
}

class _CompanyListScreenState extends State<CompanyListScreen> {
  @override
  void initState() {
    super.initState();
    // Load companies when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().loadCompanies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompanyProvider>();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Center(
        child: SizedBox(
          width: 1100.w,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 60.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Select Company",
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Choose a company to continue",
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddCompanyScreen(),
                          ),
                        );
                        // Reload after returning from AddCompanyScreen
                        if (mounted) {
                          context.read<CompanyProvider>().loadCompanies();
                        }
                      },
                      icon: Icon(Icons.add, size: 18.sp, color: Colors.white),
                      label: Text(
                        "Add Company",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 2,
                        shadowColor: AppColors.primary.withOpacity(0.4),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40.h),

                // ================= BODY =================
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.error != null
                          ? Center(
                              child: Text(provider.error!,
                                  style: TextStyle(color: AppColors.error)))
                          : provider.companies.isEmpty
                              ? _emptyState()
                              : GridView.builder(
                                  itemCount: provider.companies.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 25.h,
                                    crossAxisSpacing: 25.w,
                                    childAspectRatio: 1.2,
                                  ),
                                  itemBuilder: (context, index) {
                                    final company = provider.companies[index];
                                    return _companyCard(company);
                                  },
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _companyCard(CompanyModel company) {
    return InkWell(
      borderRadius: BorderRadius.circular(18.r),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CompanyLoginScreen(
              companyName: company.name,
              companyEmail: company.email,
              companyLogo: company.logo,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15.r,
              offset: Offset(0, 5.h),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LOGO
            // LOGO
Container(
  height: 60.h,
  width: 60.w,
  decoration: BoxDecoration(
    color: AppColors.scaffoldBg,
    borderRadius: BorderRadius.circular(14.r),
  ),
  child: company.logo != null && company.logo!.isNotEmpty
      ? ClipRRect(
          borderRadius: BorderRadius.circular(14.r),
          child: Image.file(
            File(company.logo!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image_outlined,
              color: AppColors.textMuted,
              size: 24.sp,
            ),
          ),
        )
      : Icon(
          Icons.business_rounded,
          color: AppColors.primary,
          size: 28.sp,
        ),
),

            SizedBox(height: 20.h),

            // NAME
            Text(
              company.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 8.h),

            // EMAIL
            Text(
              company.email,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.textSecondary,
              ),
            ),

            const Spacer(),

            // CONTINUE BUTTON
            Container(
              height: 40.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Text(
                  "Continue",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined,
              size: 60.sp, color: AppColors.textMuted),
          SizedBox(height: 16.h),
          Text("No companies added yet",
              style: TextStyle(
                  fontSize: 16.sp, color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          Text("Tap 'Add Company' to get started",
              style: TextStyle(
                  fontSize: 13.sp, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}