// // Deprecated: Use WalletScreen.dart for all wallet UI and logic.
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:taxi_booking/utils/core/constant/app_colors.dart';
// import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';
// import 'package:taxi_booking/screens/settings/wallet_screens/presentation/widgets/wallet_charge_main_content.dart';

// class WalletAddChargeScreen extends StatelessWidget {
//   const WalletAddChargeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: AppColors.white,
//         body: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const BackAppBar(title: 'المحفظه'),
//             Expanded(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
//                 child: const WalletAddChargeMainContent(),
//               ),
//             )
//           ],
//         ));
//   }
// }
