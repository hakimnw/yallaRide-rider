import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_booking/utils/core/constant/app_colors.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/utils/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_booking/utils/core/widget/buttons/app_buttons.dart';

class AccountPasswordScreen extends StatefulWidget {
  const AccountPasswordScreen({super.key});

  @override
  State<AccountPasswordScreen> createState() => _AccountPasswordScreenState();
}

class _AccountPasswordScreenState extends State<AccountPasswordScreen> {
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackAppBar(title: "الرقم السري"),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "تحديث الرقم السري",
                  style: AppTextStyles.sSemiBold16(),
                ),
                const ResponsiveVerticalSpace(10),
                Text(
                  "هذا النص هو مثال لنص يمكن أن يستبدل في نفس المساحة، لقد تم توليد هذا النص من مولد النص ",
                  style: AppTextStyles.sMedium16(),
                ),
                const ResponsiveVerticalSpace(24),
                AppTextFormField(
                  controller: oldPasswordController,
                  hint: 'ادخل الرقم السري القديم ',
                  hintColor: AppColors.gray,
                ),
                const ResponsiveVerticalSpace(16),
                AppTextFormField(
                  controller: newPasswordController,
                  hint: 'ادخل الرقم السري الجديد ',
                  hintColor: AppColors.gray,
                ),
                const ResponsiveVerticalSpace(24),
                AppButtons.primaryButton(
                  title: "تحديث",
                  onPressed: () {},
                )
              ],
            ),
          )
        ],
      ),
      //bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}
