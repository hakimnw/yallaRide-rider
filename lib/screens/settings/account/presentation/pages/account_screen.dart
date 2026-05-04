import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_booking/screens/settings/account/presentation/widgets/account_main_content.dart';
import 'package:taxi_booking/utils/core/constant/app_colors.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/utils/core/widget/appbar/home_screen_app_bar.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeScreenAppBar(),
          const ResponsiveVerticalSpace(5),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: const AccountMainContent(),
            ),
          )
        ],
      ),
      // bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}
