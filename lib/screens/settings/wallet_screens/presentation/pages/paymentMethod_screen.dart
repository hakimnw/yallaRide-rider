// // Deprecated: Use WalletScreen.dart for all wallet UI and logic.
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:taxi_booking/utils/core/constant/app_colors.dart';
// import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';
// import 'package:taxi_booking/screens/settings/wallet_screens/presentation/widgets/payment_method_main_content.dart';

// class PaymentMethodScreen extends StatelessWidget {
//   const PaymentMethodScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: AppColors.white,
//         body: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const BackAppBar(title: 'طرق الدفع'),
//             Expanded(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
//                 child: const PaymentMethodMainContent(),
//               ),
//             )
//           ],
//         ));
//   }
// }
