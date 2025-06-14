import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import 'WalkThroughtScreen.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../languageConfiguration/LanguageDataConstant.dart';
import '../languageConfiguration/ServerLanguageResponse.dart';
import '../main.dart';
import '../network/RestApis.dart';
import '../utils/Common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import 'DashBoardScreen.dart';
import 'EditProfileScreen.dart';
import 'SignInScreen.dart';
import 'MainScreen.dart';

class SplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style for a more immersive experience
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    _checkNotifyPermission();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void init() async {
    List<ConnectivityResult> b = await Connectivity().checkConnectivity();
    if (b.contains(ConnectivityResult.none)) {
      return toast(language.yourInternetIsNotWorking);
    }
    await Future.delayed(Duration(seconds: 2));

    // Debug print to check IS_FIRST_TIME value
    print("IS_FIRST_TIME value: ${sharedPref.getBool(IS_FIRST_TIME)}");

    if (sharedPref.getBool(IS_FIRST_TIME) ?? true) {
      // Force IS_FIRST_TIME to true for testing
      sharedPref.setBool(IS_FIRST_TIME, true);

      await Geolocator.requestPermission().then((value) async {
        launchScreen(context, WalkThroughScreen(),
            pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
        Geolocator.getCurrentPosition().then((value) {
          sharedPref.setDouble(LATITUDE, value.latitude);
          sharedPref.setDouble(LONGITUDE, value.longitude);
        });
      }).catchError((e) {
        launchScreen(context, WalkThroughScreen(),
            pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      });
    } else {
      if (!appStore.isLoggedIn) {
        launchScreen(context, SignInScreen(),
            pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      } else {
        if (sharedPref.getString(CONTACT_NUMBER).validate().isEmptyOrNull) {
          launchScreen(context, EditProfileScreen(isGoogle: true),
              isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        } else {
          getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
            if (value.data != null) {
              appStore.setUserEmail(value.data!.email.validate());
              appStore.setUserName(value.data!.username.validate());
              appStore.setFirstName(value.data!.firstName.validate());
              appStore.setUserProfile(value.data!.profileImage.validate());

              sharedPref.setString(USER_EMAIL, value.data!.email.validate());
              sharedPref.setString(
                  FIRST_NAME, value.data!.firstName.validate());
              sharedPref.setString(LAST_NAME, value.data!.lastName.validate());
              sharedPref.setString(
                  USER_PROFILE_PHOTO, value.data!.profileImage.validate());
            }

            appStore.setLoading(false);
            setState(() {});
          }).catchError((error) {
            log(error.toString());
            appStore.setLoading(false);
          });
          if (await checkPermission()) {
            await Geolocator.requestPermission().then((value) async {
              await Geolocator.getCurrentPosition().then((value) {
                sharedPref.setDouble(LATITUDE, value.latitude);
                sharedPref.setDouble(LONGITUDE, value.longitude);
                launchScreen(context, MainScreen(),
                    pageRouteAnimation: PageRouteAnimation.Slide,
                    isNewTask: true);
              });
            }).catchError((e) {
              launchScreen(context, MainScreen(),
                  pageRouteAnimation: PageRouteAnimation.Slide,
                  isNewTask: true);
            });
          }
        }
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: primaryColor,
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with subtle animation
                      Image.asset(
                        'assets/assets/logo.png',
                        height: 120,
                        width: 120,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _checkNotifyPermission() async {
    String versionNo =
        sharedPref.getString(CURRENT_LAN_VERSION) ?? LanguageVersion;
    await getLanguageList(versionNo).then((value) {
      appStore.setLoading(false);
      app_update_check = value.rider_version;
      if (value.status == true) {
        setValue(CURRENT_LAN_VERSION, value.currentVersionNo.toString());
        if (value.data!.length > 0) {
          defaultServerLanguageData = value.data;
          performLanguageOperation(defaultServerLanguageData);
          setValue(LanguageJsonDataRes, value.toJson());
          bool isSetLanguage =
              sharedPref.getBool(IS_SELECTED_LANGUAGE_CHANGE) ?? false;
          if (!isSetLanguage) {
            for (int i = 0; i < value.data!.length; i++) {
              if (value.data![i].isDefaultLanguage == 1) {
                setValue(SELECTED_LANGUAGE_CODE, value.data![i].languageCode);
                setValue(
                    SELECTED_LANGUAGE_COUNTRY_CODE, value.data![i].countryCode);
                appStore.setLanguage(value.data![i].languageCode!,
                    context: context);
                break;
              }
            }
          }
        } else {
          defaultServerLanguageData = [];
          selectedServerLanguageData = null;
          setValue(LanguageJsonDataRes, "");
        }
      } else {
        String getJsonData = sharedPref.getString(LanguageJsonDataRes) ?? '';

        if (getJsonData.isNotEmpty) {
          ServerLanguageResponse languageSettings =
              ServerLanguageResponse.fromJson(json.decode(getJsonData.trim()));
          if (languageSettings.data!.length > 0) {
            defaultServerLanguageData = languageSettings.data;
            performLanguageOperation(defaultServerLanguageData);
          }
        }
      }
    }).catchError((error) {
      appStore.setLoading(false);
      log(error);
    });
    init();
  }
}
