// // Deprecated: Use WalletScreen.dart for all wallet UI and logic.
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:taxi_booking/utils/core/constant/app_colors.dart';
// import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
// import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
// import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';
// import 'package:taxi_booking/screens/settings/wallet_screens/presentation/widgets/payment_cards_widget.dart';

// class AddPaymentMethodScreen extends StatelessWidget {
//   const AddPaymentMethodScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: AppColors.white,
//         body: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const BackAppBar(title: 'البطاقات البنكيه'),
//             Expanded(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'البطاقات المحفوظه',
//                         style: AppTextStyles.sSemiBold16(),
//                       ),
//                       const ResponsiveVerticalSpace(20),
//                       const PaymentCardsWidget(
//                         canEdit: true,
//                       ),
//                       const ResponsiveVerticalSpace(20),
//                     ],
//                   ),
//                 ),
//               ),
//             )
//           ],
//         ));
//   }
// }
