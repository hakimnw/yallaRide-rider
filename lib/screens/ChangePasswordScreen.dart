import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../network/RestApis.dart';
import '../../utils/constant/app_colors.dart';
import '../../utils/constant/styles/app_text_style.dart';
import '../../utils/constant/styles/input_border_styles.dart';
import '../../utils/Common.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../../utils/Extensions/app_common.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  ChangePasswordScreenState createState() => ChangePasswordScreenState();
}

class ChangePasswordScreenState extends State<ChangePasswordScreen> with SingleTickerProviderStateMixin {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController oldPassController = TextEditingController();
  TextEditingController newPassController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();

  FocusNode oldPassFocus = FocusNode();
  FocusNode newPassFocus = FocusNode();
  FocusNode confirmPassFocus = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    init();

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    _animationController.forward();
  }

  void init() async {
    //
  }

  @override
  void dispose() {
    _animationController.dispose();
    oldPassController.dispose();
    newPassController.dispose();
    confirmPassController.dispose();
    oldPassFocus.dispose();
    newPassFocus.dispose();
    confirmPassFocus.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (formKey.currentState!.validate()) {
      Map req = {
        'old_password': oldPassController.text.trim(),
        'new_password': newPassController.text.trim(),
      };
      appStore.setLoading(true);

      await sharedPref.setString(USER_PASSWORD, newPassController.text.trim());

      await changePassword(req).then((value) {
        toast(value.message.toString());
        appStore.setLoading(false);

        // Add haptic feedback on success
        HapticFeedback.mediumImpact();

        Navigator.pop(context);
      }).catchError((error) {
        appStore.setLoading(false);

        // Add haptic feedback on error
        HapticFeedback.vibrate();

        toast(error.toString());
      });
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              image: DecorationImage(
                image: AssetImage('assets/assets/images/backgroundFrame.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(language.changePassword, style: AppTextStyles.sSemiBold16(color: AppColors.white)),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Curved background
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: EdgeInsets.only(top: 30, left: 20, right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withAlpha(25),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lock_outline,
                                color: AppColors.primary,
                                size: 40,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),

                          Text(
                            language.changePassword,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.sSemiBold16(),
                          ),

                          SizedBox(height: 8),

                          Text(
                            "يرجى إدخال كلمة المرور الحالية وكلمة المرور الجديدة لتغيير كلمة المرور",
                            style: AppTextStyles.sRegular14(color: AppColors.gray),
                          ),

                          SizedBox(height: 30),

                          // Old Password Field
                          TextFormField(
                            controller: oldPassController,
                            focusNode: oldPassFocus,
                            obscureText: _obscureOldPassword,
                            style: AppTextStyles.sRegular14(),
                            decoration: InputDecoration(
                              labelText: language.oldPassword,
                              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.gray,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureOldPassword = !_obscureOldPassword;
                                  });
                                },
                              ),
                              border: InputBorders.custom(
                                color: AppColors.lightGray,
                                borderRadius: 10,
                              ),
                              enabledBorder: InputBorders.custom(
                                color: AppColors.lightGray,
                                borderRadius: 10,
                              ),
                              focusedBorder: InputBorders.custom(
                                color: AppColors.primary,
                                borderRadius: 10,
                              ),
                              fillColor: AppColors.lightGray.withAlpha(76),
                              filled: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return language.thisFieldRequired;
                              return null;
                            },
                            onFieldSubmitted: (s) => FocusScope.of(context).requestFocus(newPassFocus),
                          ),

                          SizedBox(height: 20),

                          // New Password Field
                          TextFormField(
                            controller: newPassController,
                            focusNode: newPassFocus,
                            obscureText: _obscureNewPassword,
                            style: AppTextStyles.sRegular14(),
                            decoration: InputDecoration(
                              labelText: language.newPassword,
                              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.gray,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                              border: InputBorders.custom(
                                color: AppColors.lightGray,
                                borderRadius: 10,
                              ),
                              enabledBorder: InputBorders.custom(
                                color: AppColors.lightGray,
                                borderRadius: 10,
                              ),
                              focusedBorder: InputBorders.custom(
                                color: AppColors.primary,
                                borderRadius: 10,
                              ),
                              fillColor: AppColors.lightGray.withAlpha(76),
                              filled: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return language.thisFieldRequired;
                              if (value.length < passwordLengthGlobal) return language.passwordLength;
                              return null;
                            },
                            onFieldSubmitted: (s) => FocusScope.of(context).requestFocus(confirmPassFocus),
                          ),

                          SizedBox(height: 20),

                          // Confirm Password Field
                          TextFormField(
                            controller: confirmPassController,
                            focusNode: confirmPassFocus,
                            obscureText: _obscureConfirmPassword,
                            style: AppTextStyles.sRegular14(),
                            decoration: InputDecoration(
                              labelText: language.confirmPassword,
                              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppColors.gray,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: InputBorders.custom(
                                color: AppColors.lightGray,
                                borderRadius: 10,
                              ),
                              enabledBorder: InputBorders.custom(
                                color: AppColors.lightGray,
                                borderRadius: 10,
                              ),
                              focusedBorder: InputBorders.custom(
                                color: AppColors.primary,
                                borderRadius: 10,
                              ),
                              fillColor: AppColors.lightGray.withAlpha(76),
                              filled: true,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return language.thisFieldRequired;
                              if (val != newPassController.text) return language.passwordDoesNotMatch;
                              return null;
                            },
                          ),

                          SizedBox(height: 40),

                          AppButtonWidget(
                            text: "تحديث كلمة المرور",
                            textColor: AppColors.white,
                            color: AppColors.primary,
                            width: MediaQuery.of(context).size.width,
                            onTap: () {
                              if (sharedPref.getString(USER_EMAIL) == demoEmail) {
                                toast(language.demoMsg);
                              } else {
                                submit();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Observer(
            builder: (context) {
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            },
          ),
        ],
      ),
    );
  }
}
