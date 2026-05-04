// // Deprecated: Use WalletScreen.dart for all wallet UI and logic.
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:taxi_booking/model/PaymentCardModel.dart';
// import 'package:taxi_booking/network/RestApis.dart';
// import 'package:taxi_booking/screens/settings/wallet_screens/presentation/pages/add_paymentCard_screen.dart';
// import 'package:taxi_booking/utils/Extensions/app_common.dart';
// import 'package:taxi_booking/utils/core/constant/app_colors.dart';
// import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
// import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';

// class PaymentCardsWidget extends StatefulWidget {
//   final bool canEdit;
//   final ValueChanged<int?>? onSelectCard;
//   const PaymentCardsWidget({super.key, this.canEdit = false, this.onSelectCard});

//   @override
//   State<PaymentCardsWidget> createState() => _PaymentCardsWidgetState();
// }

// class _PaymentCardsWidgetState extends State<PaymentCardsWidget> {
//   List<PaymentCardModel> _cards = [];
//   int? _selectedCardId;
//   bool _loading = false;

//   @override
//   void initState() {
//     super.initState();
//     _fetchCards();
//   }

//   Future<void> _fetchCards() async {
//     setState(() => _loading = true);
//     try {
//       final cards = await getPaymentCards();
//       setState(() {
//         _cards = cards;
//         if (_cards.isNotEmpty) {
//           _selectedCardId = _cards.first.id;
//           widget.onSelectCard?.call(_selectedCardId);
//         }
//       });
//     } catch (e) {
//       toast('فشل في تحميل البطاقات');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _deleteCard(int cardId) async {
//     try {
//       await deletePaymentCard(cardId: cardId);
//       toast('تم حذف البطاقة');
//       await _fetchCards();
//     } catch (e) {
//       toast('فشل حذف البطاقة');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return Column(
//       children: [
//         if (_cards.isEmpty)
//           Container(
//             width: double.infinity,
//             padding: EdgeInsets.symmetric(vertical: 16.h),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(10),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Color(0x15000000),
//                   blurRadius: 4,
//                   offset: Offset(0, 0),
//                   spreadRadius: 0,
//                 ),
//               ],
//             ),
//             child: Center(child: Text('لا توجد بطاقات محفوظة', style: AppTextStyles.sMedium16(color: AppColors.gray))),
//           )
//         else
//           ListView.separated(
//             padding: EdgeInsets.zero,
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemBuilder: (context, index) {
//               final card = _cards[index];
//               final selected = card.id == _selectedCardId;
//               final last4 = (card.cardNumber ?? '').length >= 4
//                   ? card.cardNumber!.substring(card.cardNumber!.length - 4)
//                   : card.cardNumber ?? '';
//               return InkWell(
//                 onTap: () {
//                   setState(() => _selectedCardId = card.id);
//                   widget.onSelectCard?.call(_selectedCardId);
//                 },
//                 child: Container(
//                   padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(15),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Color(0x15000000),
//                         blurRadius: 4,
//                         spreadRadius: 0,
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     children: [
//                       CircleAvatar(
//                         radius: 8,
//                         backgroundColor: selected ? AppColors.primary : Colors.grey,
//                       ),
//                       SizedBox(width: 10.w),
//                       Image.asset(
//                         "assets/assets/images/visa.png",
//                         width: 64.r,
//                         height: 58.h,
//                       ),
//                       SizedBox(width: 16.w),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               card.cardHolderName ?? 'بطاقة',
//                               style: TextStyle(
//                                 color: AppColors.textColor,
//                                 fontSize: 16.spMin,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                             Text(
//                               '**** **** **** $last4',
//                               style: TextStyle(
//                                 color: AppColors.gray,
//                                 fontSize: 14.spMin,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       if (widget.canEdit)
//                         IconButton(
//                           icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
//                           onPressed: () => _deleteCard(card.id!),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//             separatorBuilder: (context, index) => const ResponsiveVerticalSpace(16),
//             itemCount: _cards.length,
//           ),
//         const ResponsiveVerticalSpace(16),
//         InkWell(
//           onTap: () async {
//             final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPaymentCardScreen()));
//             if (res == true) _fetchCards();
//           },
//           child: Container(
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(10),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Color(0x15000000),
//                   blurRadius: 4,
//                   offset: Offset(0, 0),
//                   spreadRadius: 0,
//                 ),
//               ],
//             ),
//             padding: EdgeInsets.symmetric(vertical: 19.h),
//             child: Center(
//                 child: Text(
//               '+ إضافه بطاقه',
//               style: AppTextStyles.sSemiBold14(color: AppColors.primary),
//             )),
//           ),
//         ),
//       ],
//     );
//   }
// }
