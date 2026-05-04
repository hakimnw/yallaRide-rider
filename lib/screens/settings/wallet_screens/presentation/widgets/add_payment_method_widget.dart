// // Deprecated: Use WalletScreen.dart for all wallet UI and logic.
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:taxi_booking/main.dart';
// import 'package:taxi_booking/network/RestApis.dart';
// import 'package:taxi_booking/screens/settings/wallet_screens/presentation/pages/wallet_charged_screen.dart';
// import 'package:taxi_booking/screens/settings/wallet_screens/presentation/widgets/show_help_expire_date.dart';
// import 'package:taxi_booking/utils/Extensions/app_common.dart';
// import 'package:taxi_booking/utils/core/constant/app_colors.dart';
// import 'package:taxi_booking/utils/core/constant/app_icons.dart';
// import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
// import 'package:taxi_booking/utils/core/utils/responsive_horizontal_space.dart';
// import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
// import 'package:taxi_booking/utils/core/widget/buttons/app_buttons.dart';

// class AddPaymentMethodWidget extends StatefulWidget {
//   const AddPaymentMethodWidget({super.key});

//   @override
//   State<AddPaymentMethodWidget> createState() => _AddPaymentMethodWidgetState();
// }

// class _AddPaymentMethodWidgetState extends State<AddPaymentMethodWidget> {
//   final TextEditingController _cardHolderController = TextEditingController();
//   final TextEditingController _cardNumberController = TextEditingController();
//   final TextEditingController _cvvController = TextEditingController();
//   final TextEditingController _expiryController = TextEditingController();
//   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _cardHolderController.dispose();
//     _cardNumberController.dispose();
//     _cvvController.dispose();
//     _expiryController.dispose();
//     super.dispose();
//   }

//   String? _validateCardHolder(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'الرجاء إدخال اسم حامل البطاقة';
//     }
//     return null;
//   }

//   String? _validateCardNumber(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'الرجاء إدخال رقم البطاقة';
//     }
//     if (value.length != 16) {
//       return 'رقم البطاقة يجب أن يكون 16 رقم';
//     }
//     return null;
//   }

//   String? _validateCVV(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'الرجاء إدخال رقم CVV';
//     }
//     if (value.length != 3) {
//       return 'رقم CVV يجب أن يكون 3 أرقام';
//     }
//     return null;
//   }

//   String? _validateExpiry(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'الرجاء إدخال تاريخ الانتهاء';
//     }
//     // Basic MM/YY validation
//     final parts = value.split('/');
//     if (parts.length != 2) {
//       return 'صيغة غير صحيحة (MM/YY)';
//     }
//     try {
//       final month = int.parse(parts[0]);
//       final year = int.parse(parts[1]);
//       if (month < 1 || month > 12) {
//         return 'شهر غير صحيح';
//       }
//       if (year < DateTime.now().year % 100) {
//         return 'البطاقة منتهية الصلاحية';
//       }
//     } catch (e) {
//       return 'صيغة غير صحيحة (MM/YY)';
//     }
//     return null;
//   }

//   Future<void> _saveCard() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     try {
//       // Prepare card data
//       final Map<String, dynamic> cardData = {
//         'card_holder_name': _cardHolderController.text,
//         'card_number': _cardNumberController.text,
//         'cvv': _cvvController.text,
//         'expiry_date': _expiryController.text,
//         'user_id': appStore.userId,
//       };

//       // Save card using backend card API
//       await savePaymentCard(request: cardData);

//       // Show success message
//       toast('تم حفظ البطاقة بنجاح');

//       // Navigate to wallet charge screen
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => const WalletAddChargeScreen(),
//         ),
//       );
//     } catch (e) {
//       toast('حدث خطأ أثناء حفظ البطاقة');
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hint,
//     Widget? suffixIcon,
//     List<TextInputFormatter>? inputFormatters,
//     TextInputType? keyboardType,
//     String? Function(String?)? validator,
//   }) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0.h),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: const [
//           BoxShadow(
//             color:AppColors.black,
//             blurRadius: 4,
//             offset: Offset(0, 0),
//             spreadRadius: 0,
//           ),
//         ],
//       ),
//       child: TextFormField(
//         controller: controller,
//         style: TextStyle(
//           color: AppColors.textColor,
//           fontSize: 16.spMin,
//           fontFamily: 'Tajawal',
//           fontWeight: FontWeight.w500,
//         ),
//         decoration: InputDecoration(
//           border: InputBorder.none,
//           hintText: hint,
//           hintStyle: TextStyle(
//             color: AppColors.gray,
//             fontSize: 16.spMin,
//             fontFamily: 'Tajawal',
//             fontWeight: FontWeight.w500,
//             letterSpacing: -0.30,
//           ),
//           suffixIcon: suffixIcon,
//           suffixIconConstraints: BoxConstraints(maxHeight: 20.h, maxWidth: 20.w),
//         ),
//         keyboardType: keyboardType,
//         inputFormatters: inputFormatters,
//         validator: validator,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'تفاصيل البطاقه',
//             style: AppTextStyles.sSemiBold16(),
//           ),
//           const ResponsiveVerticalSpace(16),
//           _buildTextField(
//             controller: _cardHolderController,
//             hint: 'اسم حامل البطاقه',
//             validator: _validateCardHolder,
//           ),
//           const ResponsiveVerticalSpace(16),
//           _buildTextField(
//             controller: _cardNumberController,
//             hint: 'رقم البطاقه',
//             keyboardType: TextInputType.number,
//             inputFormatters: [
//               FilteringTextInputFormatter.digitsOnly,
//               LengthLimitingTextInputFormatter(16),
//             ],
//             validator: _validateCardNumber,
//           ),
//           const ResponsiveVerticalSpace(16),
//           Row(
//             children: [
//               Expanded(
//                 child: _buildTextField(
//                   controller: _cvvController,
//                   hint: 'CVV',
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(3),
//                   ],
//                   validator: _validateCVV,
//                   suffixIcon: InkWell(
//                     onTap: () {
//                       showHelpExpireDate(context);
//                     },
//                     child: SvgPicture.asset(
//                       AppIcons.help,
//                       width: 18.w,
//                       height: 18.h,
//                     ),
//                   ),
//                 ),
//               ),
//               const ResponsiveHorizontalSpace(15),
//               Expanded(
//                 child: _buildTextField(
//                   controller: _expiryController,
//                   hint: 'MM/YY',
//                   keyboardType: TextInputType.number,
//                   inputFormatters: [
//                     FilteringTextInputFormatter.digitsOnly,
//                     LengthLimitingTextInputFormatter(4),
//                     _ExpiryDateInputFormatter(),
//                   ],
//                   validator: _validateExpiry,
//                   suffixIcon: InkWell(
//                     onTap: () {
//                       showHelpExpireDate(context);
//                     },
//                     child: SvgPicture.asset(
//                       AppIcons.help,
//                       width: 18.w,
//                       height: 18.h,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const ResponsiveVerticalSpace(24),
//           AppButtons.primaryButton(
//             title: _isLoading ? 'جاري الحفظ...' : 'حفظ',
//             onPressed: _isLoading ? null : _saveCard,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ExpiryDateInputFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
//     final text = newValue.text;

//     if (text.length > 2) {
//       final month = text.substring(0, 2);
//       final year = text.substring(2);
//       return TextEditingValue(
//         text: '$month/$year',
//         selection: TextSelection.collapsed(offset: text.length + 1),
//       );
//     }
//     return newValue;
//   }
// }
