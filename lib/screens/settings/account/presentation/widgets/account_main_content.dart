import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_booking/screens/ChangePasswordScreen.dart';
import 'package:taxi_booking/screens/settings/account/presentation/pages/account_Phone_screen.dart';
import 'package:taxi_booking/screens/settings/account/presentation/pages/account_email_screen.dart';
import 'package:taxi_booking/screens/settings/account/presentation/pages/account_name_screen.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';
import 'package:taxi_booking/utils/core/constant/app_icons.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';

import '../../../../EditProfileScreen.dart';

class AccountMainContent extends StatelessWidget {
  const AccountMainContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        "الحساب",
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
                title: "الاسم",
                leading: SvgPicture.asset(AppIcons.teenyId),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AccountNameScreen()));
                },
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AccountPhoneScreen()));
                },
                title: "رقم الهاتف",
                leading: SvgPicture.asset(AppIcons.phone),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AccountEmailScreen()));
                },
                title: "البريد الالكتروني",
                leading: Icon(
                  Icons.email_outlined,
                  color: Colors.grey,
                  size: 20.r,
                ),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                title: "الرقم السري",
                leading: SvgPicture.asset(AppIcons.lockPassword),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChangePasswordScreen()));
                },
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                title: "تعديل الصوره",
                leading: SvgPicture.asset(AppIcons.user),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => EditProfileScreen()));
                },
              )
            ],
          ))
    ]);
  }
}
