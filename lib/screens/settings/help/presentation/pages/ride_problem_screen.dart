import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_booking/screens/settings/help/presentation/widgets/ride_problems_widget.dart';
import 'package:taxi_booking/utils/core/constant/app_colors.dart';
import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';

class RideProblemScreen extends StatelessWidget {
  const RideProblemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackAppBar(title: "المساعده"),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: const RideProblemsWidget(),
            ),
          )
        ],
      ),
      // bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}
