import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../constant/app_colors.dart';

abstract class AppButtons {
  static Widget primaryButton({
    String title = "",
    void Function()? onPressed,
    Color bgColor = AppColors.primary,
    EdgeInsetsGeometry? padding,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          padding: padding ?? EdgeInsets.symmetric(horizontal: 19.w, vertical: 14.h),
        ),
        child: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.spMin, color: AppColors.white),
        ),
      ),
    );
  }

  static Widget secondaryButton({
    String title = "",
    void Function()? onPressed,
    Color bgColor = AppColors.white,
    EdgeInsetsGeometry? padding,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shadowColor: AppColors.primary,
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: const Color(0xfff1f1f1), width: 1.w),
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: padding ?? EdgeInsets.symmetric(horizontal: 19.w, vertical: 14.h),
        ),
        child: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.spMin, color: AppColors.primary),
        ),
      ),
    );
  }
}
