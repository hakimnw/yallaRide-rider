import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_booking/main.dart';
import 'package:taxi_booking/utils/core/constant/app_colors.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_booking/utils/core/widget/buttons/app_buttons.dart';

import '../../../../../utils/core/utils/responsive_vertical_space.dart';

class AccountEmailScreen extends StatefulWidget {
  const AccountEmailScreen({super.key});

  @override
  State<AccountEmailScreen> createState() => _AccountNameScreenState();
}

class _AccountNameScreenState extends State<AccountEmailScreen> {
  final TextEditingController controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load the current email
    controller.text = appStore.userEmail;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    // Basic email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'الرجاء إدخال بريد إلكتروني صحيح';
    }
    return null;
  }

  Future<void> _updateEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final newEmail = controller.text.trim();

      // Update email in appStore
      await appStore.setUserEmail(newEmail);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث البريد الإلكتروني بنجاح'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحديث البريد الإلكتروني'),
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
          const BackAppBar(title: "البريد الالكتروني"),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "تحديث البريد الالكتروني",
                    style: AppTextStyles.sSemiBold16(),
                  ),
                  const ResponsiveVerticalSpace(10),
                  Text(
                    "هذا البريد لتلقي الاشعارات و تسجيل الدخول و استرداد حسابك",
                    style: AppTextStyles.sMedium16(),
                  ),
                  const ResponsiveVerticalSpace(24),
                  AppTextFormField(
                    controller: controller,
                    hint: 'ادخل البريد الالكتروني',
                    hintColor: AppColors.gray,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const ResponsiveVerticalSpace(24),
                  AppButtons.primaryButton(
                    title: _isLoading ? "جاري التحديث..." : "تحديث",
                    onPressed: _isLoading ? null : _updateEmail,
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
