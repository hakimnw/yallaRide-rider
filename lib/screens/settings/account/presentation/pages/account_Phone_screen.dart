import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_booking/main.dart';
import 'package:taxi_booking/utils/Constants.dart';
import 'package:taxi_booking/utils/core/constant/app_colors.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/utils/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_booking/utils/core/widget/app_input_fields/my_country_code_picker.dart';
import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_booking/utils/core/widget/buttons/app_buttons.dart';

class AccountPhoneScreen extends StatefulWidget {
  const AccountPhoneScreen({super.key});

  @override
  State<AccountPhoneScreen> createState() => _AccountPhoneScreenState();
}

class _AccountPhoneScreenState extends State<AccountPhoneScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPhone();
  }

  void _loadCurrentPhone() {
    final currentPhone = sharedPref.getString(CONTACT_NUMBER) ?? '';
    if (currentPhone.isNotEmpty) {
      // Split phone number into country code and number if it contains a space
      final parts = currentPhone.split(' ');
      if (parts.length > 1) {
        codeController.text = parts[0];
        phoneController.text = parts[1];
      } else {
        phoneController.text = currentPhone;
        codeController.text = '+966'; // Default to Saudi Arabia
      }
    } else {
      codeController.text = '+966'; // Default to Saudi Arabia
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    codeController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال رقم الهاتف';
    }
    // Remove any spaces or special characters
    final cleanPhone = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Check if it's a valid Saudi phone number (assuming Saudi format)
    if (cleanPhone.length != 9) {
      return 'رقم الهاتف يجب أن يكون 9 أرقام';
    }
    if (!cleanPhone.startsWith('5')) {
      return 'رقم الهاتف يجب أن يبدأ بـ 5';
    }
    return null;
  }

  Future<void> _updatePhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Combine country code and phone number
      final fullPhone = '${codeController.text} ${phoneController.text}';

      // Update phone in appStore and SharedPreferences
      await appStore.setUserPhone(fullPhone);
      await sharedPref.setString(CONTACT_NUMBER, fullPhone);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث رقم الهاتف بنجاح'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحديث رقم الهاتف'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackAppBar(title: "رقم الهاتف"),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "تحديث رقم الهاتف",
                    style: AppTextStyles.sSemiBold16(),
                  ),
                  const ResponsiveVerticalSpace(10),
                  Text(
                    "هذا الرقم لتلقي الالشعارات و تسجيل الدخول و استرداد حسابك",
                    style: AppTextStyles.sMedium16(),
                  ),
                  const ResponsiveVerticalSpace(24),
                  Row(
                    children: [
                      CustomCountryCodePicker(codeController: codeController),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: AppTextFormField(
                          controller: phoneController,
                          hint: 'ادخل رقم الهاتف',
                          hintColor: AppColors.gray,
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                        ),
                      ),
                    ],
                  ),
                  const ResponsiveVerticalSpace(24),
                  AppButtons.primaryButton(
                    title: _isLoading ? "جاري التحديث..." : "تحديث",
                    onPressed: _isLoading ? null : _updatePhone,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
