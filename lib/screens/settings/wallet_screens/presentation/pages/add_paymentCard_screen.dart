// // Deprecated: Use WalletScreen.dart for all wallet UI and logic.
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:taxi_booking/utils/core/constant/app_colors.dart';
// import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';
// import 'package:taxi_booking/screens/settings/wallet_screens/presentation/widgets/add_payment_method_widget.dart';

// class AddPaymentCardScreen extends StatelessWidget {
//   const AddPaymentCardScreen({super.key});

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
//                 child: const AddPaymentMethodWidget(),
//               ),
//             )
//           ],
//         ));
//   }
// }
