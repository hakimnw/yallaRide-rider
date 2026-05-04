import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/widgets/settings_screen_main_content.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/utils/core/widget/appbar/home_screen_app_bar.dart';

import 'settings/help/app_bar/search_field.dart';

class SettingsScreenNew extends StatelessWidget {
  const SettingsScreenNew({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeScreenAppBar(),
              const ResponsiveVerticalSpace(15),
              const TransformedSearchField(
                hintText: "ابحث عن ما تريد",
              ),
              const ResponsiveVerticalSpace(15),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const SettingsScreenMainContent(),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
