import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_booking/screens/settings/help/presentation/help_screen.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/pages/chat_screen.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/pages/language_screen.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/pages/who_are_we_screen.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';
import 'package:taxi_booking/utils/core/constant/app_icons.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';

import '../../../../../utils/constant/app_colors.dart';
import '../../../../PrivacyPolicyScreen.dart';
import '../../../../TermsAndConditionsScreen.dart';

class MoreInfoSection extends StatelessWidget {
  const MoreInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("مزيد من المعلومات و الدعم", style: AppTextStyles.sSemiBold16()),
        const ResponsiveVerticalSpace(16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: AppColors.black, blurRadius: 4, offset: Offset(0, 0), spreadRadius: 0)],
          ),
          child: Column(
            children: [
              CustomListTitleWidget(
                title: "من نحن",
                leading: SvgPicture.asset(AppIcons.info, color: AppColors.primary),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WhoAreWeScreen()));
                },
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "تغيير اللغه",
                leading: SvgPicture.asset(AppIcons.language, color: AppColors.primary),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LanguageScreen()));
                },
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "تواصل معانا",
                leading: SvgPicture.asset(AppIcons.chat, color: AppColors.primary),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChatScreen()));
                },
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "المساعده",
                leading: SvgPicture.asset(AppIcons.help, color: AppColors.primary),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HelpMainScreen()));
                },
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "سياسه الخصوصيه",
                leading: SvgPicture.asset(AppIcons.privacy, color: AppColors.primary),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => PrivacyPolicyScreen()));
                },
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "شروط الاستخدام",
                leading: SvgPicture.asset(AppIcons.privacy, color: AppColors.primary),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => TermsAndConditionsScreen()));
                },
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ],
    );
  }

  Widget customDivider() => const Divider(indent: 16, endIndent: 16, height: 1);
}
