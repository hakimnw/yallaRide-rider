import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/pages/logout_screen.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';

import '../../../../../utils/constant/app_colors.dart';
import '../../../account/presentation/pages/account_screen.dart';

class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("الحساب", style: AppTextStyles.sSemiBold16()),
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
                title: "إداره الحساب",
                leading: SvgPicture.asset("assets/assets/icons/account_icon.svg"),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountScreen()));
                  // NavigationService.pushNamed(RouterNames.accountScreen);
                },
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              // CustomListTitleWidget(
              //   onTap: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletAddPaymentMethodScreen()));
              //     // NavigationService.pushNamed(
              //     //     RouterNames.addPaymentMethodScreen);
              //   },
              //   title: "البطاقات البنكيه",
              //   leading: SvgPicture.asset(color: AppColors.primary, "assets/assets/icons/payment.svg"),
              // ),
              // const Divider(
              //   indent: 16,
              //   endIndent: 16,
              //   height: 1,
              // ),
              CustomListTitleWidget(
                onTap: () {
                  // Navigator.of(context).pushNamed(RouterNames.addAddress);
                },
                title: "االعنواين المحفوظه",
                leading: SvgPicture.asset("assets/assets/images/basil_location-outline.svg"),
              ),
              const Divider(
                indent: 16,
                endIndent: 16,
                height: 1,
              ),
              CustomListTitleWidget(
                title: "تسجيل خروج",
                leading: SvgPicture.asset(
                  "assets/assets/icons/Logout.svg",
                  color: AppColors.primary,
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const LogoutScreen()));
                },
              )
            ],
          ))
    ]);
  }
}
