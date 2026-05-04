import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_booking/screens/settings/help/presentation/widgets/help_ride_item.dart';
import 'package:taxi_booking/utils/core/constant/app_colors.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';

class HelpRideScreen extends StatelessWidget {
  const HelpRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackAppBar(title: "المساعده"),
          Expanded(
            child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                itemBuilder: (context, index) => const HelpRideItem(),
                separatorBuilder: (context, index) => const ResponsiveVerticalSpace(16),
                itemCount: 4),
          ),
        ],
      ),
      //bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}
