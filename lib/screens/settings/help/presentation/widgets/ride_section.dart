import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_booking/screens/settings/help/presentation/pages/help_ride_screen.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';
import 'package:taxi_booking/utils/core/constant/app_icons.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';

import '../../../../../utils/constant/app_colors.dart';
import '../../../../PrivacyPolicyScreen.dart';
import '../../../settings_screen/presentation/pages/chat_screen.dart';

class RideSection extends StatelessWidget {
  const RideSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "الرحالات",
        style: AppTextStyles.sSemiBold16(),
      ),
      const ResponsiveVerticalSpace(16),
      Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Color(0x15000000),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              CustomListTitleWidget(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HelpRideScreen()));
                },
                title: "رحله",
                leading: SvgPicture.asset(
                  AppIcons.car,
                  color: AppColors.primary,
                ),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()));
                },
                title: "الامان و الخصوصيه",
                leading: SvgPicture.asset(
                  AppIcons.privacy,
                  color: AppColors.primary,
                ),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                title: "تواصل معانا",
                leading: SvgPicture.asset(
                  AppIcons.chat,
                  color: AppColors.primary,
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChatScreen()));
                },
              )
            ],
          ))
    ]);
  }
}
