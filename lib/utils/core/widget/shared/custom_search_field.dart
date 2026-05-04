import 'package:flutter/material.dart';

import '../../../constant/app_colors.dart';

class CustomSearchField extends StatelessWidget {
  const CustomSearchField({super.key, required this.hintText, this.haveIcon = true, this.margin, this.padding});

  final String hintText;
  final bool haveIcon;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      margin: margin ?? EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: AppColors.black, blurRadius: 4, offset: Offset(0, 0), spreadRadius: 0)],
      ),
      child: TextField(
        onTap: null,
        decoration: InputDecoration(
          prefixIcon: haveIcon ? const Icon(Icons.search, color: AppColors.gray) : null,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.gray,
            fontSize: 16,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w400,
            letterSpacing: -0.30,
          ),
        ),
      ),
    );
  }
}
