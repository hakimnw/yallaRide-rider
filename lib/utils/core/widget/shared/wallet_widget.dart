import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
// imports removed: wallet_add_paymentMethod_screen.dart, wallet_charged_screen.dart
import 'package:taxi_booking/screens/settings/wallet_screens/presentation/providers/wallet_provider.dart';
import 'package:taxi_booking/utils/core/constant/app_colors.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/widget/buttons/app_buttons.dart';

import '../../../../screens/settings/wallet_screens/presentation/pages/WalletScreen.dart';

class WalletWidget extends StatelessWidget {
  final bool walletCharged, addCharged, showButton;
  const WalletWidget({super.key, this.walletCharged = false, this.addCharged = false, this.showButton = true});

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    return Container(
      width: double.infinity,
      height: 156.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        // color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: AssetImage("assets/assets/images/walletFrame.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (walletCharged || addCharged) ? 'رصيد المحفظه' : 'المحفظه',
            style: AppTextStyles.sMedium16(color: AppColors.white),
          ),
          Text(
            (walletCharged || addCharged)
                ? (walletProvider.isLoading ? 'جاري التحميل...' : walletProvider.formattedBalance)
                : 'لا يوجد محفظه',
            style: AppTextStyles.sMedium16(color: AppColors.white),
          ),
          // if (walletCharged || addCharged) ...[
          //   SizedBox(height: 8),
          //   InkWell(
          //     onTap: () {
          //       Navigator.pushNamed(context, RouterNames.manageCardsScreen);
          //     },
          //     child: Container(
          //       padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //       decoration: BoxDecoration(
          //         color: Colors.white.withAlpha(51),
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       child: Text(
          //         'إدارة البطاقات',
          //         style: AppTextStyles.sSemiBold14(color: AppColors.white),
          //       ),
          //     ),
          //   ),
          // ],
          const Spacer(),
          if (showButton)
            AppButtons.primaryButton(
                onPressed: () {
                  // if (ywalletCharged || addCharged) {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => WalletScreen())); // WalletAddChargeScreen()
                  // } else {
                  //   Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletAddPaymentMethodScreen()));
                  // }
                },
                title: walletCharged
                    ? 'شحن المحفظه'
                    : addCharged
                        ? 'برجاء ادخال القيمه'
                        : "إنشاء محفظه",
                bgColor: AppColors.white.withOpacity(.3)),
        ],
      ),
    );
  }
}
