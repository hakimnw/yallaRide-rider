import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../main.dart';
import '../../service/AuthService1.dart';
import '../../utils/Common.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../../utils/Extensions/app_common.dart';
import '../../utils/constant/app_colors.dart';
import '../../utils/constant/app_image.dart';
import '../../utils/constant/styles/app_text_style.dart';
import '../../utils/constant/styles/input_border_styles.dart';
import '../languageConfiguration/LanguageDefaultJson.dart';
import '../network/RestApis.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/context_extension.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'TermsAndConditionsScreen.dart';

class SignUpScreen extends StatefulWidget {
  final bool socialLogin;
  final String? userName;
  final bool isOtp;
  final String? countryCode;
  final String? privacyPolicyUrl;
  final String? termsConditionUrl;

  SignUpScreen(
      {this.socialLogin = false,
      this.userName,
      this.isOtp = false,
      this.countryCode,
      this.privacyPolicyUrl,
      this.termsConditionUrl});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  AuthServices authService = AuthServices();

  TextEditingController firstController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController userNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController passController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();

  FocusNode firstNameFocus = FocusNode();
  FocusNode lastNameFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode phoneFocus = FocusNode();
  FocusNode passFocus = FocusNode();
  FocusNode confirmPass = FocusNode();

  bool mIsCheck = false;
  bool isAcceptedTc = false;

  String countryCode = defaultCountryCode;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await saveOneSignalPlayerId().then((value) {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> register() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      hideKeyboard(context);
      if (isAcceptedTc) {
        appStore.setLoading(true);
        Map req = {
          'first_name': firstController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'username': widget.socialLogin ? widget.userName : userNameController.text.trim(),
          'email': emailController.text.trim(),
          "user_type": "rider",
          "contact_number": widget.socialLogin ? '${widget.userName}' : '${phoneController.text.trim()}',
          "country_code": widget.socialLogin ? '${widget.countryCode}' : '$countryCode',
          'password': widget.socialLogin ? widget.userName : passController.text.trim(),
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
          if (widget.socialLogin) 'login_type': 'mobile',
        };

        await signUpApi(req).then((value) {
          authService
              .signUpWithEmailPassword(getContext,
                  mobileNumber: widget.socialLogin
                      ? '${widget.countryCode}${widget.userName}'
                      : '$countryCode${phoneController.text.trim()}',
                  email: emailController.text.trim(),
                  fName: firstController.text.trim(),
                  lName: lastNameController.text.trim(),
                  userName: widget.socialLogin ? widget.userName : userNameController.text.trim(),
                  password: widget.socialLogin ? widget.userName : passController.text.trim(),
                  userType: RIDER,
                  isOtpLogin: widget.socialLogin)
              .then((res) async {
            //
          }).catchError((e) {
            appStore.setLoading(false);
            toast('$e');
          });
        }).catchError((error) {
          appStore.setLoading(false);
        });
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.loginFrame),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: context.statusBarHeight + 40),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: ClipRRect(borderRadius: radius(50), child: Image.asset(ic_app_logo, width: 100, height: 100)),
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withAlpha(25),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(language.createAccount,
                            style: AppTextStyles.sSemiBold16(color: AppColors.textColor).copyWith(fontSize: 24)),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                  text: 'Sign up to get started ', style: AppTextStyles.sRegular14(color: AppColors.gray)),
                              TextSpan(text: '🚗', style: AppTextStyles.sSemiBold16().copyWith(fontSize: 20)),
                            ],
                          ),
                        ),
                        SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: firstController,
                                focusNode: firstNameFocus,
                                textInputAction: TextInputAction.next,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: InputDecoration(
                                  labelText: language.firstName,
                                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                                  border: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                                  enabledBorder: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                                  focusedBorder: InputBorders.custom(color: AppColors.primary, borderRadius: 10),
                                  fillColor: AppColors.lightGray.withAlpha(76),
                                  filled: true,
                                ),
                                validator: (s) {
                                  if (s!.trim().isEmpty) return errorThisFieldRequired;
                                  return null;
                                },
                                onFieldSubmitted: (s) => FocusScope.of(context).requestFocus(lastNameFocus),
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: TextFormField(
                                controller: lastNameController,
                                focusNode: lastNameFocus,
                                textInputAction: TextInputAction.next,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                decoration: InputDecoration(
                                  labelText: language.lastName,
                                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                                  border: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                                  enabledBorder: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                                  focusedBorder: InputBorders.custom(color: AppColors.primary, borderRadius: 10),
                                  fillColor: AppColors.lightGray.withAlpha(76),
                                  filled: true,
                                ),
                                validator: (s) {
                                  if (s!.trim().isEmpty) return errorThisFieldRequired;
                                  return null;
                                },
                                onFieldSubmitted: (s) => FocusScope.of(context).requestFocus(userNameFocus),
                              ),
                            ),
                          ],
                        ),
                        if (widget.socialLogin != true) SizedBox(height: 20),
                        if (widget.socialLogin != true)
                          TextFormField(
                            controller: userNameController,
                            focusNode: userNameFocus,
                            textInputAction: TextInputAction.next,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: language.userName,
                              prefixIcon: Icon(Icons.account_circle_outlined, color: AppColors.primary),
                              border: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                              enabledBorder: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                              focusedBorder: InputBorders.custom(color: AppColors.primary, borderRadius: 10),
                              fillColor: AppColors.lightGray.withAlpha(76),
                              filled: true,
                            ),
                            validator: (s) {
                              if (s!.trim().isEmpty) return errorThisFieldRequired;
                              return null;
                            },
                            onFieldSubmitted: (s) => FocusScope.of(context).requestFocus(emailFocus),
                          ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: emailController,
                          focusNode: emailFocus,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          decoration: InputDecoration(
                            labelText: language.email,
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                            border: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                            enabledBorder: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                            focusedBorder: InputBorders.custom(color: AppColors.primary, borderRadius: 10),
                            fillColor: AppColors.lightGray.withAlpha(76),
                            filled: true,
                          ),
                          validator: (s) {
                            if (s!.trim().isEmpty) return errorThisFieldRequired;
                            if (!s.trim().validateEmail()) return errorThisFieldRequired;
                            return null;
                          },
                          onFieldSubmitted: (s) => FocusScope.of(context).requestFocus(phoneFocus),
                        ),
                        if (widget.socialLogin != true) SizedBox(height: 20),
                        if (widget.socialLogin != true)
                          TextFormField(
                            controller: phoneController,
                            focusNode: phoneFocus,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            decoration: InputDecoration(
                              labelText: language.phoneNumber,
                              fillColor: AppColors.lightGray.withAlpha(76),
                              filled: true,
                              border: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                              enabledBorder: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                              focusedBorder: InputBorders.custom(color: AppColors.primary, borderRadius: 10),
                              prefixIcon: IntrinsicHeight(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CountryCodePicker(
                                      padding: EdgeInsets.zero,
                                      initialSelection: countryCode,
                                      showCountryOnly: false,
                                      dialogSize: Size(
                                          MediaQuery.of(context).size.width - 60, MediaQuery.of(context).size.height * 0.6),
                                      showFlag: true,
                                      showFlagDialog: true,
                                      showOnlyCountryWhenClosed: false,
                                      alignLeft: false,
                                      textStyle: AppTextStyles.sRegular14(),
                                      dialogBackgroundColor: Theme.of(context).cardColor,
                                      barrierColor: Colors.black12,
                                      dialogTextStyle: AppTextStyles.sRegular14(),
                                      searchDecoration: InputDecoration(
                                        focusColor: AppColors.primary,
                                        iconColor: Theme.of(context).dividerColor,
                                        enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(color: Theme.of(context).dividerColor)),
                                        focusedBorder:
                                            UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                                      ),
                                      searchStyle: AppTextStyles.sRegular14(),
                                      onInit: (c) {
                                        countryCode = c!.dialCode!;
                                      },
                                      onChanged: (c) {
                                        countryCode = c.dialCode!;
                                      },
                                    ),
                                    VerticalDivider(color: AppColors.gray.withAlpha(127)),
                                  ],
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value!.trim().isEmpty) return errorThisFieldRequired;
                              return null;
                            },
                            onFieldSubmitted: (s) => FocusScope.of(context).requestFocus(passFocus),
                          ),
                        if (widget.socialLogin != true) SizedBox(height: 20),
                        if (widget.socialLogin != true)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: passController,
                                  focusNode: passFocus,
                                  textInputAction: TextInputAction.next,
                                  obscureText: true,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  decoration: InputDecoration(
                                    labelText: language.password,
                                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                                    border: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                                    enabledBorder: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                                    focusedBorder: InputBorders.custom(color: AppColors.primary, borderRadius: 10),
                                    fillColor: AppColors.lightGray.withAlpha(76),
                                    filled: true,
                                  ),
                                  validator: (String? value) {
                                    if (value!.isEmpty) return errorThisFieldRequired;
                                    if (value.length < passwordLengthGlobal) return language.passwordLength;
                                    return null;
                                  },
                                  onFieldSubmitted: (s) => FocusScope.of(context).requestFocus(confirmPass),
                                ),
                              ),
                              if (widget.socialLogin != true) SizedBox(width: 16),
                              if (widget.socialLogin != true)
                                Expanded(
                                  child: TextFormField(
                                    controller: confirmPassController,
                                    focusNode: confirmPass,
                                    textInputAction: TextInputAction.done,
                                    obscureText: true,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    decoration: InputDecoration(
                                      labelText: language.confirmPassword,
                                      prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                                      border: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                                      enabledBorder: InputBorders.custom(color: AppColors.lightGray, borderRadius: 10),
                                      focusedBorder: InputBorders.custom(color: AppColors.primary, borderRadius: 10),
                                      fillColor: AppColors.lightGray.withAlpha(76),
                                      filled: true,
                                    ),
                                    validator: (String? value) {
                                      if (value!.isEmpty) return errorThisFieldRequired;
                                      if (value.length < passwordLengthGlobal) return language.passwordLength;
                                      if (value.trim() != passController.text.trim()) return language.bothPasswordNotMatch;
                                      return null;
                                    },
                                  ),
                                ),
                            ],
                          ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: Checkbox(
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                activeColor: AppColors.primary,
                                value: isAcceptedTc,
                                shape: RoundedRectangleBorder(borderRadius: radius(4)),
                                onChanged: (v) async {
                                  isAcceptedTc = v!;
                                  setState(() {});
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                      text: '${language.iAgreeToThe} ',
                                      style: AppTextStyles.sRegular14(color: AppColors.gray)),
                                  TextSpan(
                                    text: language.termsConditions,
                                    style: AppTextStyles.sSemiBold14(color: AppColors.primary),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchScreen(context, TermsAndConditionsScreen(),
                                            pageRouteAnimation: PageRouteAnimation.Slide);
                                      },
                                  ),
                                  TextSpan(text: ' & ', style: AppTextStyles.sRegular14(color: AppColors.gray)),
                                  TextSpan(
                                    text: language.privacyPolicy,
                                    style: AppTextStyles.sSemiBold14(color: AppColors.primary),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchScreen(context, TermsAndConditionsScreen(),
                                            pageRouteAnimation: PageRouteAnimation.Slide);
                                      },
                                  ),
                                ]),
                                textAlign: TextAlign.left,
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 32),
                        AppButtonWidget(
                          width: MediaQuery.of(context).size.width,
                          text: language.signUp,
                          color: AppColors.primary,
                          textColor: AppColors.white,
                          onTap: () async {
                            register();
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Positioned(
            top: context.statusBarHeight + 4,
            left: 4,
            child: Material(
              color: AppColors.white.withAlpha(226),
              shape: CircleBorder(),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back, color: AppColors.primary),
                ),
              ),
            ),
          ),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          })
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(language.alreadyHaveAnAccount, style: AppTextStyles.sRegular14()),
                SizedBox(width: 8),
                inkWellWidget(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Text(language.logIn, style: AppTextStyles.sSemiBold14(color: AppColors.primary)),
                ),
              ],
            ),
          ),
          SizedBox(height: 16)
        ],
      ),
    );
  }
}
