import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../constant/app_colors.dart';

class ChooseComplainsTopicsDropDown extends StatelessWidget {
  const ChooseComplainsTopicsDropDown({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        shadows: const [BoxShadow(color: AppColors.black, blurRadius: 4, offset: Offset(0, 0), spreadRadius: 0)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'اختر الموضوع',
            style: TextStyle(
              color: AppColors.gray,
              fontSize: 16,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.30,
            ),
          ),
          Transform.rotate(
            angle: pi / 2,
            child: Icon(Icons.arrow_back_ios, size: 16.r, color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}
