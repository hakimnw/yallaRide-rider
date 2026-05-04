import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_booking/utils/core/constant/app_colors.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_booking/utils/core/widget/buttons/app_buttons.dart';

import '../../../../../main.dart';
import '../../../../../network/RestApis.dart';
import '../../../../../utils/Colors.dart';
import '../../../../../utils/Extensions/ConformationDialog.dart';
import '../../../../../utils/Extensions/app_common.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackAppBar(title: "تسجيل خروج"),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "تسجيل خروج",
                  style: AppTextStyles.sSemiBold16(),
                ),
                const ResponsiveVerticalSpace(10),
                Text(
                  "هل انت متأكد من تسجيل الخروج ",
                  style: AppTextStyles.sMedium16(),
                ),
                const ResponsiveVerticalSpace(24),
                AppButtons.primaryButton(
                  title: "خروج",
                  onPressed: () {
                    showConfirmDialogCustom(
                      context,
                      primaryColor: primaryColor,
                      dialogType: DialogType.CONFIRMATION,
                      title: language.areYouSureYouWantToLogoutThisApp,
                      positiveText: language.yes,
                      negativeText: language.no,
                      onAccept: (context) async {
                        appStore.setLoading(true);
                        await logout().then((value) {
                          appStore.setLoading(false);
                        }).catchError((error) {
                          appStore.setLoading(false);
                          toast(error.toString());
                        });
                      },
                    );
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
