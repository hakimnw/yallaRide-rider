// // Deprecated: Use WalletScreen.dart for all wallet UI and logic.
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:taxi_booking/utils/core/app_routes/navigation_service.dart';
// import 'package:taxi_booking/utils/core/app_routes/router_names.dart';
// import 'package:taxi_booking/utils/core/constant/app_icons.dart';
// import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
// import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
// import 'package:taxi_booking/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';

// class PaymentMethodMainContent extends StatelessWidget {
//   const PaymentMethodMainContent({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'اضف طريقه دفع',
//             style: AppTextStyles.sSemiBold16(),
//           ),
//           CustomListTitleWidget(
//             onTap: () {
//               NavigationService.pushNamed(RouterNames.addPaymentMethodScreen);
//             },
//             title: "بطاقه إطمان",
//             leading: SvgPicture.asset(AppIcons.visaCard),
//           ),
//           CustomListTitleWidget(
//             onTap: () {
//               NavigationService.pushNamed(RouterNames.addPaymentMethodScreen);
//             },
//             title: "باي بل",
//             leading: SvgPicture.asset(AppIcons.phPaypalLogo),
//           ),
//           const ResponsiveVerticalSpace(20),
//         ],
//       ),
//     );
//   }
// }
