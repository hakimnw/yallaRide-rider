import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_booking/screens/MainScreen.dart';

import '../../components/OTPDialog.dart';
import '../../main.dart';
import '../../network/RestApis.dart';
import '../../screens/ForgotPasswordScreen.dart';
import '../../service/AuthService1.dart';
import '../../utils/constant/app_colors.dart';
import '../../utils/constant/app_image.dart';
import '../../utils/constant/styles/app_text_style.dart';
import '../../utils/constant/styles/input_border_styles.dart';
import '../../utils/Common.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../../utils/Extensions/app_common.dart';
import '../../utils/Extensions/app_textfield.dart';
import '../model/LoginResponse.dart';
import '../service/AuthService.dart';
import '../utils/Extensions/context_extension.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'DashBoardScreen.dart';
import 'SignUpScreen.dart';
import 'TermsConditionScreen.dart';
import 'PrivacyPolicyScreen.dart';

class SignInScreen extends StatefulWidget {
  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> signUpFormKey = GlobalKey<FormState>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  UserModel userModel = UserModel();

  AuthServices authService = AuthServices();
  GoogleAuthServices googleAuthService = GoogleAuthServices();

  // Login controllers
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  // Sign Up controllers
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController signUpEmailController = TextEditingController();
  TextEditingController signUpPhoneController = TextEditingController();
  TextEditingController signUpPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController userNameController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode passFocus = FocusNode();

  bool mIsRemember = false;
  bool isAcceptTermsNPrivacy = false;
  bool isLogin = true; // To control which tab is active

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {
        isLogin = _tabController.index == 0;
      });
    });
    init();
  }

  void init() async {
    await saveOneSignalPlayerId().then((value) {});
    mIsRemember = sharedPref.getBool(REMEMBER_ME) ?? false;
    if (mIsRemember) {
      emailController.text = sharedPref.getString(USER_EMAIL).validate();
      passController.text = sharedPref.getString(USER_PASSWORD).validate();
      setState(() {});
    }
  }

  Future<void> logIn() async {
    hideKeyboard(context);
    if (loginFormKey.currentState!.validate()) {
      loginFormKey.currentState!.save();
      if (isAcceptTermsNPrivacy) {
        appStore.setLoading(true);

        Map req = {
          'email': emailController.text.trim(),
          'password': passController.text.trim(),
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
          'user_type': RIDER,
        };
        log(req);
        await logInApi(req).then((value) {
          userModel = value.data!;
          auth
              .signInWithEmailAndPassword(
                  email: emailController.text, password: passController.text)
              .then((value) async {
            sharedPref.setString(UID, value.user!.uid);
            updateProfileUid();
            await checkPermission().then((value) async {
              await Geolocator.getCurrentPosition().then((value) {
                sharedPref.setDouble(LATITUDE, value.latitude);
                sharedPref.setDouble(LONGITUDE, value.longitude);
              });
            });
            appStore.setLoading(false);
            launchScreen(context, MainScreen(),
                isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
          }).catchError((e) {
            appStore.setLoading(false);
            if (e.toString().contains('user-not-found') ||
                e.toString().contains('invalid')) {
              authService.signUpWithEmailPassword(
                context,
                mobileNumber: userModel.contactNumber,
                email: userModel.email,
                fName: userModel.firstName,
                lName: userModel.lastName,
                userName: userModel.username,
                password: passController.text,
                userType: RIDER,
              );
            } else {
              launchScreen(context, MainScreen(),
                  isNewTask: true,
                  pageRouteAnimation: PageRouteAnimation.Slide);
            }
            log(e.toString());
          });
        }).catchError((error) {
          appStore.isLoading = false;
          toast(error.toString());
        });
      } else {
        toast(language.pleaseAcceptTermsOfServicePrivacyPolicy);
      }
    }
  }

  Future<void> register() async {
    hideKeyboard(context);
    if (signUpFormKey.currentState!.validate()) {
      signUpFormKey.currentState!.save();
      if (isAcceptTermsNPrivacy) {
        appStore.setLoading(true);
        Map req = {
          'first_name': firstNameController.text.trim(),
          'last_name': "",
          'username': userNameController.text.trim(),
          'email': signUpEmailController.text.trim(),
          "user_type": "rider",
          "contact_number": signUpPhoneController.text.trim(),
          "country_code": '+1', // You might need to add country code picker
          'password': signUpPasswordController.text.trim(),
          "player_id": sharedPref.getString(PLAYER_ID).validate(),
        };

        await signUpApi(req).then((value) {
          authService
              .signUpWithEmailPassword(
            context,
            mobileNumber: signUpPhoneController.text.trim(),
            email: signUpEmailController.text.trim(),
            fName: firstNameController.text.trim(),
            lName: lastNameController.text.trim(),
            userName: userNameController.text.trim(),
            password: signUpPasswordController.text.trim(),
            userType: RIDER,
          )
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

  void googleSignIn() async {
    hideKeyboard(context);
    appStore.setLoading(true);

    await googleAuthService.signInWithGoogle(context).then((value) async {
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  appleLoginApi() async {
    hideKeyboard(context);
    appStore.setLoading(true);
    await appleLogIn().then((value) {
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Custom App Bar with background image
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  image: DecorationImage(
                    //assets\assets\images\loginFrame.png
                    image: AssetImage(
                        "assets/assets/images/app_bar_background.png"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                  // Commenting out the app logo
                  child: ClipRRect(
                      borderRadius: radius(50),
                      child: SvgPicture.asset(
                        ic_app_logo,
                        width: 100,
                        height: 100,
                        color: AppColors.white,
                      )),
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: Offset(0, -40),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab bar for Login/Signup
                        Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
                          child: TabBar(
                            controller: _tabController,
                            labelColor: AppColors.primary,
                            unselectedLabelColor: AppColors.gray,
                            indicatorColor: AppColors.primary,
                            indicatorSize: TabBarIndicatorSize.label,
                            tabs: [
                              Tab(text: language.logIn),
                              Tab(text: language.signUp),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Login Tab
                              SingleChildScrollView(
                                padding: EdgeInsets.all(16),
                                child: loginForm(),
                              ),
                              // Signup Tab
                              SingleChildScrollView(
                                padding: EdgeInsets.all(16),
                                child: signUpForm(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

  Widget loginForm() {
    return Form(
      key: loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: emailController,
            focusNode: emailFocus,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: language.email,
              labelStyle: TextStyle(color: AppColors.primary),
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
              border: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              enabledBorder: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              focusedBorder: InputBorders.custom(
                  color: AppColors.primary, borderRadius: 10),
              fillColor: AppColors.lightGray.withOpacity(0.3),
              //filled: true,
            ),
            validator: (s) {
              if (s!.trim().isEmpty) return language.thisFieldRequired;
              if (!s.trim().validateEmail()) return language.thisFieldRequired;
              return null;
            },
            onFieldSubmitted: (s) =>
                FocusScope.of(context).requestFocus(passFocus),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: passController,
            focusNode: passFocus,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.done,
            obscureText: true,
            decoration: InputDecoration(
              labelText: language.password,
              labelStyle: TextStyle(color: AppColors.primary),
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
              border: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              enabledBorder: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              focusedBorder: InputBorders.custom(
                  color: AppColors.primary, borderRadius: 10),
              fillColor: AppColors.lightGray.withOpacity(0.3),
              //filled: true,
            ),
            validator: (s) {
              if (s!.trim().isEmpty) return language.thisFieldRequired;
              return null;
            },
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 18.0,
                    width: 18.0,
                    child: Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: AppColors.primary,
                      value: mIsRemember,
                      shape: RoundedRectangleBorder(borderRadius: radius(4)),
                      onChanged: (v) async {
                        mIsRemember = v!;
                        if (!mIsRemember) {
                          sharedPref.remove(REMEMBER_ME);
                        } else {
                          await sharedPref.setBool(REMEMBER_ME, mIsRemember);
                          await sharedPref.setString(
                              USER_EMAIL, emailController.text);
                          await sharedPref.setString(
                              USER_PASSWORD, passController.text);
                        }

                        setState(() {});
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  inkWellWidget(
                    onTap: () async {
                      mIsRemember = !mIsRemember;
                      setState(() {});
                    },
                    child: Text(language.rememberMe,
                        style: AppTextStyles.sRegular14()),
                  ),
                ],
              ),
              /*   inkWellWidget(
                onTap: () {
                  launchScreen(context, ForgotPasswordScreen(),
                      pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                },
                child: Text(language.forgotPassword,
                    style: AppTextStyles.sMedium14()),
              ), */
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
                  value: isAcceptTermsNPrivacy,
                  shape: RoundedRectangleBorder(borderRadius: radius(4)),
                  onChanged: (v) async {
                    isAcceptTermsNPrivacy = v!;
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: language.iAgreeToThe + " ",
                          style: AppTextStyles.sRegular14()
                              .copyWith(fontSize: 12)),
                      TextSpan(
                        text: language.termsConditions.splitBefore(' &'),
                        style:
                            AppTextStyles.sSemiBold14(color: AppColors.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (appStore.termsCondition != null &&
                                appStore.termsCondition!.isNotEmpty) {
                              launchScreen(
                                  context,
                                  TermsConditionScreen(
                                      title: language.termsConditions,
                                      subtitle: appStore.termsCondition),
                                  pageRouteAnimation: PageRouteAnimation.Slide);
                            } else {
                              toast(language.txtURLEmpty);
                            }
                          },
                      ),
                      TextSpan(
                          text: ' & ',
                          style: AppTextStyles.sRegular14()
                              .copyWith(fontSize: 12)),
                      TextSpan(
                        text: language.privacyPolicy,
                        style:
                            AppTextStyles.sSemiBold14(color: AppColors.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launchScreen(context, PrivacyPolicyScreen(),
                                pageRouteAnimation: PageRouteAnimation.Slide);
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
              )
            ],
          ),
          SizedBox(height: 30),
          AppButtonWidget(
            width: MediaQuery.of(context).size.width,
            text: language.logIn,
            color: AppColors.primary,
            textColor: AppColors.white,
            onTap: () async {
              logIn();
            },
          ),
        ],
      ),
    );
  }

  Widget signUpForm() {
    return Form(
      key: signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: firstNameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: language.firstName,
                    labelStyle: TextStyle(color: AppColors.primary),
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppColors.primary),
                    border: InputBorders.custom(
                        color: AppColors.lightGray, borderRadius: 10),
                    enabledBorder: InputBorders.custom(
                        color: AppColors.lightGray, borderRadius: 10),
                    focusedBorder: InputBorders.custom(
                        color: AppColors.primary, borderRadius: 10),
                    fillColor: AppColors.lightGray.withOpacity(0.3),
                    //filled: true,
                  ),
                  validator: (s) {
                    if (s!.trim().isEmpty) return language.thisFieldRequired;
                    return null;
                  },
                ),
              ),
              /*        SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: lastNameController,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: language.lastName,
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppColors.primary),
                    border: InputBorders.custom(
                        color: AppColors.lightGray, borderRadius: 10),
                    enabledBorder: InputBorders.custom(
                        color: AppColors.lightGray, borderRadius: 10),
                    focusedBorder: InputBorders.custom(
                        color: AppColors.primary, borderRadius: 10),
                    fillColor: AppColors.lightGray.withOpacity(0.3),
                    filled: true,
                  ),
                  validator: (s) {
                    if (s!.trim().isEmpty) return language.thisFieldRequired;
                    return null;
                  },
                ),
              ),
        */
            ],
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: userNameController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: language.userName,
              labelStyle: TextStyle(color: AppColors.primary),
              prefixIcon:
                  Icon(Icons.account_circle_outlined, color: AppColors.primary),
              border: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              enabledBorder: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              focusedBorder: InputBorders.custom(
                  color: AppColors.primary, borderRadius: 10),
              fillColor: AppColors.lightGray.withOpacity(0.3),
              //filled: true,
            ),
            validator: (s) {
              if (s!.trim().isEmpty) return language.thisFieldRequired;
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: signUpEmailController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: language.email,
              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
              labelStyle: TextStyle(color: AppColors.primary),
              border: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              enabledBorder: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              focusedBorder: InputBorders.custom(
                  color: AppColors.primary, borderRadius: 10),
              fillColor: AppColors.lightGray.withOpacity(0.3),
              //filled: true,
            ),
            validator: (s) {
              if (s!.trim().isEmpty) return language.thisFieldRequired;
              if (!s.trim().validateEmail()) return language.thisFieldRequired;
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: signUpPhoneController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: language.phoneNumber,
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
              labelStyle: TextStyle(color: AppColors.primary),
              border: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              enabledBorder: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              focusedBorder: InputBorders.custom(
                  color: AppColors.primary, borderRadius: 10),
              fillColor: AppColors.lightGray.withOpacity(0.3),
              //filled: true,
            ),
            validator: (s) {
              if (s!.trim().isEmpty) return language.thisFieldRequired;
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: signUpPasswordController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.next,
            obscureText: true,
            decoration: InputDecoration(
              labelText: language.password,
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
              labelStyle: TextStyle(color: AppColors.primary),
              border: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              enabledBorder: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              focusedBorder: InputBorders.custom(
                  color: AppColors.primary, borderRadius: 10),
              fillColor: AppColors.lightGray.withOpacity(0.3),
              //filled: true,
            ),
            validator: (String? value) {
              if (value!.isEmpty) return errorThisFieldRequired;
              if (value.length < passwordLengthGlobal)
                return language.passwordLength;
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: confirmPasswordController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.done,
            obscureText: true,
            decoration: InputDecoration(
              labelText: language.confirmPassword,
              labelStyle: TextStyle(color: AppColors.primary),
              prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
              border: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              enabledBorder: InputBorders.custom(
                  color: AppColors.lightGray, borderRadius: 10),
              focusedBorder: InputBorders.custom(
                  color: AppColors.primary, borderRadius: 10),
              fillColor: AppColors.lightGray.withOpacity(0.3),
              //filled: true,
            ),
            validator: (String? value) {
              if (value!.isEmpty) return errorThisFieldRequired;
              if (value.length < passwordLengthGlobal)
                return language.passwordLength;
              if (value.trim() != signUpPasswordController.text.trim())
                return language.bothPasswordNotMatch;
              return null;
            },
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
                  value: isAcceptTermsNPrivacy,
                  shape: RoundedRectangleBorder(borderRadius: radius(4)),
                  onChanged: (v) async {
                    isAcceptTermsNPrivacy = v!;
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: language.iAgreeToThe + " ",
                          style: AppTextStyles.sRegular14()
                              .copyWith(fontSize: 12)),
                      TextSpan(
                        text: language.termsConditions.splitBefore(' &'),
                        style:
                            AppTextStyles.sSemiBold14(color: AppColors.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            if (appStore.termsCondition != null &&
                                appStore.termsCondition!.isNotEmpty) {
                              launchScreen(
                                  context,
                                  TermsConditionScreen(
                                      title: language.termsConditions,
                                      subtitle: appStore.termsCondition),
                                  pageRouteAnimation: PageRouteAnimation.Slide);
                            } else {
                              toast(language.txtURLEmpty);
                            }
                          },
                      ),
                      TextSpan(
                          text: ' & ',
                          style: AppTextStyles.sRegular14()
                              .copyWith(fontSize: 12)),
                      TextSpan(
                        text: language.privacyPolicy,
                        style:
                            AppTextStyles.sSemiBold14(color: AppColors.primary),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            launchScreen(context, PrivacyPolicyScreen(),
                                pageRouteAnimation: PageRouteAnimation.Slide);
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.left,
                ),
              )
            ],
          ),
          SizedBox(height: 30),
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
    );
  }

  Widget socialLoginWidget() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(child: Divider(color: AppColors.lightGray)),
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16),
                child: Text(language.orLogInWith,
                    style: AppTextStyles.sRegular14()),
              ),
              Expanded(child: Divider(color: AppColors.lightGray)),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            inkWellWidget(
              onTap: () async {
                googleSignIn();
              },
              child: socialWidgetComponent(img: ic_google),
            ),
            SizedBox(width: 12),
            inkWellWidget(
              onTap: () async {
                showDialog(
                  context: context,
                  builder: (_) {
                    return AlertDialog(
                      contentPadding: EdgeInsets.all(16),
                      content: OTPDialog(),
                    );
                  },
                );
                appStore.setLoading(false);
              },
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightGray),
                    borderRadius: radius(defaultRadius)),
                child: Image.asset(ic_mobile,
                    fit: BoxFit.cover, height: 30, width: 30),
              ),
            ),
            if (Platform.isIOS) SizedBox(width: 12),
            if (Platform.isIOS)
              inkWellWidget(
                onTap: () async {
                  appleLoginApi();
                },
                child: socialWidgetComponent(img: ic_apple),
              ),
          ],
        ),
      ],
    );
  }

  Widget socialWidgetComponent({required String img}) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.lightGray),
          borderRadius: radius(defaultRadius)),
      child: Image.asset(img, fit: BoxFit.cover, height: 30, width: 30),
    );
  }
}
