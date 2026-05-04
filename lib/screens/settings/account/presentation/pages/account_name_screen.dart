import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_booking/main.dart';
import 'package:taxi_booking/utils/core/constant/app_colors.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/utils/core/widget/app_input_fields/app_text_form_field.dart';
import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';
import 'package:taxi_booking/utils/core/widget/buttons/app_buttons.dart';

class AccountNameScreen extends StatefulWidget {
  const AccountNameScreen({super.key});

  @override
  State<AccountNameScreen> createState() => _AccountNameScreenState();
}

class _AccountNameScreenState extends State<AccountNameScreen> {
  final TextEditingController controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load the current user name into the text field
    controller.text = appStore.userName;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update the name in your app store
      await appStore.setUserName(controller.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث الاسم بنجاح'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context); // Go back after successful update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحديث الاسم'),
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
          const BackAppBar(title: "الاسم"),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "تحديث الاسم",
                    style: AppTextStyles.sSemiBold16(),
                  ),
                  const ResponsiveVerticalSpace(10),
                  Text(
                    "اسمك يجعل من السهل على القبطان التأكد من الشخص الذي سياخذه",
                    style: AppTextStyles.sMedium16(),
                  ),
                  const ResponsiveVerticalSpace(24),
                  AppTextFormField(
                    controller: controller,
                    hint: 'ادخل الاسم كامل',
                    hintColor: AppColors.gray,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال الاسم';
                      }
                      if (value.trim().length < 3) {
                        return 'الاسم يجب أن يكون 3 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const ResponsiveVerticalSpace(24),
                  AppButtons.primaryButton(
                    title: _isLoading ? "جاري التحديث..." : "تحديث",
                    onPressed: _isLoading ? null : _updateName,
                  )
                ],
              ),
            ),
          )
        ],
      ),
      // bottomNavigationBar: const CustomNavigationBar(),
    );
  }
}
