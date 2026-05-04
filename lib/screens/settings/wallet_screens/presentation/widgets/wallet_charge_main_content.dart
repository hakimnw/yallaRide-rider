// // Deprecated: Use WalletScreen.dart for all wallet UI and logic.
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:taxi_booking/screens/settings/wallet_screens/presentation/providers/wallet_provider.dart';
// import 'package:taxi_booking/utils/Extensions/app_common.dart';
// import 'package:taxi_booking/utils/core/constant/app_colors.dart';
// import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
// import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
// import 'package:taxi_booking/utils/core/widget/buttons/app_buttons.dart';
// import 'package:taxi_booking/utils/core/widget/shared/wallet_widget.dart';
// import 'package:url_launcher/url_launcher.dart';

// import '../pages/payment_webview_page.dart';

// class WalletAddChargeMainContent extends StatefulWidget {
//   const WalletAddChargeMainContent({super.key});
//   @override
//   State<WalletAddChargeMainContent> createState() => _WalletAddChargeMainContentState();
// }

// class _WalletAddChargeMainContentState extends State<WalletAddChargeMainContent> with WidgetsBindingObserver {
//   final TextEditingController _amountController = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;
//   bool _checkoutLaunched = false;
//   String? _lastCheckoutUrl;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<WalletProvider>().fetchWallet();
//     });
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // When user returns from external browser, attempt to refresh wallet
//     if (state == AppLifecycleState.resumed && _checkoutLaunched) {
//       _refreshAndClose();
//     }
//   }

//   Future<void> _loadWallet() async {
//     try {
//       await context.read<WalletProvider>().fetchWallet();
//     } catch (_) {}
//   }

//   String? _validateAmount(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'الرجاء إدخال المبلغ';
//     }
//     final amount = double.tryParse(value);
//     if (amount == null || amount <= 0) {
//       return 'الرجاء إدخال مبلغ صحيح';
//     }
//     return null;
//   }

//   Future<void> _chargeWallet() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);
//     try {
//       final amount = double.parse(_amountController.text);
//       final provider = context.read<WalletProvider>();
//       final String? url = await provider.createCheckout(amount: amount, paymentType: 'MADA');
//       if (url != null && url.isNotEmpty) {
//         _lastCheckoutUrl = url;
//         _checkoutLaunched = true;

//         await Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (_) => PaymentWebViewPage(
//               title: 'الدفع',
//               initialUrl: url,
//             ),
//           ),
//         );

//         // Hide reopen button and reset checkout flag once WebView returns
//         if (mounted) {
//           setState(() {
//             _lastCheckoutUrl = null;
//             _checkoutLaunched = false;
//           });
//         }

//         // Regardless of reported status, refresh wallet and close
//         await _refreshAndClose();
//       } else {
//         // If no URL returned, assume server-side handled top-up
//         toast('تم إنشاء عملية الدفع');
//         await _loadWallet();
//         if (mounted) Navigator.pop(context, true);
//       }
//     } catch (e) {
//       toast('حدث خطأ أثناء شحن المحفظة');
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _refreshAndClose() async {
//     setState(() => _isLoading = true);
//     try {
//       final prev = context.read<WalletProvider>().balance ?? 0;
//       await _loadWallet();
//       final current = context.read<WalletProvider>().balance ?? 0;
//       if (current > prev) {
//         toast('تم الشحن بنجاح');
//       } else {
//         toast('تم تحديث الرصيد');
//       }
//       // If balance increased, close with success; otherwise still close to allow parent to re-check
//       if (mounted) Navigator.pop(context, true);
//     } catch (_) {
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const WalletWidget(
//               walletCharged: true,
//               addCharged: true,
//               showButton: false,
//             ),
//             const ResponsiveVerticalSpace(24),
//             Text('المبلغ', style: AppTextStyles.sSemiBold16()),
//             const ResponsiveVerticalSpace(16),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(10),
//                 boxShadow: const [
//                   BoxShadow(
//                     color:AppColors.black,
//                     blurRadius: 4,
//                     offset: Offset(0, 0),
//                     spreadRadius: 0,
//                   ),
//                 ],
//               ),
//               child: TextFormField(
//                 controller: _amountController,
//                 keyboardType: TextInputType.number,
//                 inputFormatters: [
//                   FilteringTextInputFormatter.digitsOnly,
//                 ],
//                 style: TextStyle(
//                   color: AppColors.textColor,
//                   fontSize: 16,
//                   fontFamily: 'Tajawal',
//                   fontWeight: FontWeight.w500,
//                 ),
//                 decoration: InputDecoration(
//                   border: InputBorder.none,
//                   hintText: 'أدخل المبلغ',
//                   hintStyle: TextStyle(
//                     color: AppColors.gray,
//                     fontSize: 16,
//                     fontFamily: 'Tajawal',
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 validator: _validateAmount,
//               ),
//             ),
//             const ResponsiveVerticalSpace(24),
//             const ResponsiveVerticalSpace(24),
//             if (!_checkoutLaunched)
//               AppButtons.primaryButton(
//                 title: _isLoading ? 'جاري الشحن...' : 'شحن المحفظة',
//                 onPressed: _isLoading ? null : _chargeWallet,
//               )
//             else ...[
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: const Color(0x15FF9800),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   'بعد إتمام الدفع سيتم تحديث الرصيد تلقائيًا عند الرجوع. في حال لم يكتمل الدفع يمكنك إعادة فتح صفحة الدفع.',
//                   style: AppTextStyles.sMedium14(color: AppColors.textColor),
//                 ),
//               ),
//               const ResponsiveVerticalSpace(12),
//               if (_lastCheckoutUrl != null)
//                 AppButtons.secondaryButton(
//                   title: 'فتح صفحة الدفع مرة أخرى',
//                   onPressed: () async {
//                     final u = _lastCheckoutUrl;
//                     if (u != null && u.isNotEmpty) {
//                       await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
//                     }
//                   },
//                 ),
//               // Manual refresh no longer needed; wallet refreshes automatically on return
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
