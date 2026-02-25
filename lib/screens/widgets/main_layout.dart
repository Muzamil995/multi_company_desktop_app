// lib/screens/widgets/main_layout.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:multi_company_invoice/models/company_model.dart';
import '../../core/app_colors.dart';
 import '../dashboard_screen.dart';
import '../invoice_screens/invoice_screen.dart';
import '../products_screen/products_screen.dart';
import '../settings_screen.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String activeRoute;
  final CompanyModel company; // ← pass full model

  const MainLayout({
    super.key,
    required this.child,
    required this.title,
    required this.activeRoute,
    required this.company,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Row(
        children: [
          // ================= SIDEBAR =================
          Container(
            width: 260.w,
            decoration: const BoxDecoration(
              color: AppColors.sidebarBg,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 35.h),
                _logoSection(),
                SizedBox(height: 40.h),
                _sidebarItem(
                  context,
                  Icons.dashboard_rounded,
                  "Dashboard",
                  "dashboard",
                  DashboardScreen(company: company)
                
                ),
                _sidebarItem(
                  context,
                  Icons.inventory_2_outlined,
                  "Products",
                  "products",
                  ProductsScreen(companyId: company.id!,company: company,),
                ),
                _sidebarItem(
                  context,
                  Icons.receipt_long_outlined,
                  "Invoices",
                  "invoices",
                  InvoiceScreen(companyId: company.id!,company: company,),
                ),
                SizedBox(height: 25.h),
                _sidebarItem(
                  context,
                  Icons.settings_outlined,
                  "Settings",
                  "settings",
                  SettingsScreen(company: company),
                ),
              ],
            ),
          ),

          // ================= MAIN AREA =================
          Expanded(
            child: Column(
              children: [
                _topBar(context),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(40.r),
                    child: child,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

 Widget _logoSection() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 28.w),
    child: Row(
      children: [
        Container(
          height: 36.h,
          width: 36.w,
          decoration: BoxDecoration(
            color: AppColors.scaffoldBg,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: company.logo != null && company.logo!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.file(
                    File(company.logo!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.business_rounded,
                      size: 18.sp,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : Icon(
                  Icons.business_rounded,
                  size: 18.sp,
                  color: AppColors.primary,
                ),
        ),
        SizedBox(width: 10.w),
        Flexible(
          child: Text(
            company.name.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _topBar(BuildContext context) {
    return Container(
      height: 70.h,
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      decoration: const BoxDecoration(
        color: AppColors.topBarBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            children: [
             
              
              SizedBox(width: 16.w),
              // Logout
              IconButton(
                icon: Icon(Icons.logout,
                    size: 20.sp, color: AppColors.textSecondary),
                tooltip: "Logout",
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(BuildContext context, IconData icon, String label,
      String routeName, Widget destination) {
    bool isSelected = activeRoute == routeName;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => destination,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(15.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15.r),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  size: 18.sp,
                  color: isSelected ? Colors.white : AppColors.primary,
                ),
              ),
              SizedBox(width: 15.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}