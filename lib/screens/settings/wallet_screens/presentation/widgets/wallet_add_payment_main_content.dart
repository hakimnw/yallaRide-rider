// import 'package:flutter/material.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:taxi_booking/screens/settings/wallet_screens/presentation/providers/wallet_provider.dart';
// import 'package:taxi_booking/screens/settings/wallet_screens/presentation/widgets/add_payment_method_widget.dart';
// import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
// import 'package:taxi_booking/utils/core/widget/shared/wallet_widget.dart';

// class WalletAddPaymentMainContent extends StatefulWidget {
//   const WalletAddPaymentMainContent({super.key});

//   @override
//   State<WalletAddPaymentMainContent> createState() => _WalletAddPaymentMainContentState();
// }

// class _WalletAddPaymentMainContentState extends State<WalletAddPaymentMainContent> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<WalletProvider>().fetchWallet();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Column(children: [
//         const WalletWidget(
//           walletCharged: true,
//         ),
//         const ResponsiveVerticalSpace(24),
//         const AddPaymentMethodWidget()
//       ]),
//     );
//   }
// }
