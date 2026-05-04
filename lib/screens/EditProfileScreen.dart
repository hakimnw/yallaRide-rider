import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_booking/screens/settings/help/app_bar/search_field.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/utils/core/widget/appbar/home_screen_app_bar.dart';

import '../../main.dart';
import '../../utils/Common.dart';
import '../../utils/Constants.dart';
import '../components/ImageSourceDialog.dart';
import '../languageConfiguration/LanguageDefaultJson.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import 'DashBoardScreen.dart';

class EditProfileScreen extends StatefulWidget {
  final bool? isGoogle;

  EditProfileScreen({this.isGoogle = false});

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> with SingleTickerProviderStateMixin {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  XFile? imageProfile;
  String countryCode = defaultCountryCode;

  TextEditingController emailController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController contactNumberController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  FocusNode emailFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode firstnameFocus = FocusNode();
  FocusNode lastnameFocus = FocusNode();
  FocusNode contactFocus = FocusNode();
  FocusNode addressFocus = FocusNode();

  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style for a more immersive experience
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Define animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    init();
  }

  void init() async {
    appStore.setLoading(true);
    getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
      emailController.text = value.data!.email.validate();
      usernameController.text = value.data!.username.validate();
      firstNameController.text = value.data!.firstName.validate();
      lastNameController.text = value.data!.lastName.validate();
      addressController.text = value.data!.address.validate();
      contactNumberController.text = value.data!.contactNumber.validate();
      if (value.data!.country_code != null) {
        contactNumberController.text = value.data!.country_code.validate() + value.data!.contactNumber.validate();
      }
      if (value.data != null) {
        appStore.setUserEmail(value.data!.email.validate());
        appStore.setUserName(value.data!.username.validate());
        appStore.setFirstName(value.data!.firstName.validate());
        if (sharedPref.getString(LOGIN_TYPE) != LoginTypeGoogle) {
          appStore.setUserProfile(value.data!.profileImage.validate());
        }
      }
      sharedPref.setString(USER_EMAIL, value.data!.email.validate());
      sharedPref.setString(FIRST_NAME, value.data!.firstName.validate());
      sharedPref.setString(LAST_NAME, value.data!.lastName.validate());
      sharedPref.setString(USER_PROFILE_PHOTO, value.data!.profileImage.validate());

      appStore.setLoading(false);
      setState(() {});
    }).catchError((error) {
      log(error.toString());
      appStore.setLoading(false);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget profileImage() {
    if (imageProfile != null) {
      return Hero(
        tag: 'profile_image',
        child: Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(60),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withAlpha(51),
                blurRadius: 10,
                spreadRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Image.file(
              File(imageProfile!.path),
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    } else {
      if (sharedPref.getString(USER_PROFILE_PHOTO) != null && sharedPref.getString(USER_PROFILE_PHOTO)!.isNotEmpty) {
        return Hero(
          tag: 'profile_image',
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withAlpha(51),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: commonCachedNetworkImage(
                sharedPref.getString(USER_PROFILE_PHOTO).validate(),
                fit: BoxFit.cover,
                height: 120,
                width: 120,
              ),
            ),
          ),
        );
      } else {
        return Hero(
          tag: 'profile_image',
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> saveProfile() async {
    hideKeyboard(context);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSaving = true;
      });

      appStore.setLoading(true);
      await updateProfile(
        uid: sharedPref.getString(UID).toString(),
        file: imageProfile != null ? File(imageProfile!.path.validate()) : null,
        contactNumber: widget.isGoogle == true
            ? '$countryCode${contactNumberController.text.trim()}'
            : contactNumberController.text.trim(),
        address: addressController.text.trim(),
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        userEmail: emailController.text.trim(),
      ).then((value) {
        appStore.setLoading(false);
        setState(() {
          _isSaving = false;
        });
        toast(language.profileUpdateMsg);
        if (widget.isGoogle == true) {
          launchScreen(context, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.Slide);
        } else {
          // Navigator.pop(context);
        }
      }).catchError((error) {
        appStore.setLoading(false);
        setState(() {
          _isSaving = false;
        });
        log(error.toString());
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    //primaryColor.withAlpha(13),
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              const HomeScreenAppBar(),
              const ResponsiveVerticalSpace(15),
              const TransformedSearchField(
                hintText: "ابحث عن ما تريد",
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),

                          // Profile Image Section
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              profileImage(),
                              if (sharedPref.getString(LOGIN_TYPE) != LoginTypeGoogle)
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) {
                                        return ImageSourceDialog(
                                          onCamera: () async {
                                            Navigator.pop(context);
                                            imageProfile =
                                                await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 100);
                                            setState(() {});
                                          },
                                          onGallery: () async {
                                            Navigator.pop(context);
                                            imageProfile = await ImagePicker()
                                                .pickImage(source: ImageSource.gallery, imageQuality: 100);
                                            setState(() {});
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: primaryColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(51),
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                )
                            ],
                          ),

                          SizedBox(height: 40),

                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            height: 56,
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (!_isSaving) {
                                  if (sharedPref.getString(USER_EMAIL) == demoEmail) {
                                    toast(language.demoMsg);
                                  } else {
                                    saveProfile();
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: _isSaving
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          "جاري التحديث...",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'تعديل الصوره',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),

                          /*         // Form Fields
                          _buildFormField(
                            controller: emailController,
                            focus: emailFocus,
                            nextFocus: userNameFocus,
                            label: language.email,
                            prefixIcon:
                                Icon(Icons.email_outlined, color: primaryColor),
                            readOnly: true,
                            onTap: () => toast(language.notChangeEmail),
                          ),

                          if (sharedPref.getString(LOGIN_TYPE) != 'mobile' &&
                              sharedPref.getString(LOGIN_TYPE) != null)
                            Column(
                              children: [
                                SizedBox(height: 16),
                                _buildFormField(
                                  controller: usernameController,
                                  focus: userNameFocus,
                                  nextFocus: firstnameFocus,
                                  label: language.userName,
                                  prefixIcon: Icon(Icons.person_outline,
                                      color: primaryColor),
                                  readOnly: true,
                                  onTap: () =>
                                      toast(language.notChangeUsername),
                                ),
                              ],
                            ),

                          SizedBox(height: 16),
                          _buildFormField(
                            controller: firstNameController,
                            focus: firstnameFocus,
                            nextFocus: lastnameFocus,
                            label: language.firstName,
                            prefixIcon:
                                Icon(Icons.badge_outlined, color: primaryColor),
                            textCapitalization: TextCapitalization.words,
                          ),

                          SizedBox(height: 16),
                          _buildFormField(
                            controller: lastNameController,
                            focus: lastnameFocus,
                            nextFocus: contactFocus,
                            label: language.lastName,
                            prefixIcon:
                                Icon(Icons.badge_outlined, color: primaryColor),
                            textCapitalization: TextCapitalization.words,
                          ),

                          SizedBox(height: 16),
                          widget.isGoogle == true
                              ? _buildPhoneField()
                              : _buildFormField(
                                  controller: contactNumberController,
                                  focus: contactFocus,
                                  nextFocus: addressFocus,
                                  label: language.phoneNumber,
                                  prefixIcon: Icon(Icons.phone_outlined,
                                      color: primaryColor),
                                  textInputType: TextInputType.phone,
                                  readOnly: sharedPref.getString(LOGIN_TYPE) ==
                                          LoginTypeGoogle
                                      ? false
                                      : true,
                                  onTap: () {
                                    if (sharedPref.getString(LOGIN_TYPE) !=
                                        LoginTypeGoogle) {
                                      toast(
                                          language.youCannotChangePhoneNumber);
                                    }
                                  },
                                ),

                          SizedBox(height: 16),
                          _buildFormField(
                            controller: addressController,
                            focus: addressFocus,
                            label: language.address,
                            prefixIcon: Icon(Icons.location_on_outlined,
                                color: primaryColor),
                            textInputAction: TextInputAction.newline,
                            textInputType: TextInputType.multiline,
                            maxLines: 3,
                            maxLength: 300,
                          ),

                          SizedBox(height: 40), */
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Observer(
            builder: (_) {
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            },
          ),
        ],
      ),
      /*   bottomNavigationBar: Padding(
        padding: EdgeInsets.all(24),
        child: _buildUpdateButton(),
      ), */
    );
  }

  // Widget _buildFormField({
  //   required TextEditingController controller,
  //   required FocusNode focus,
  //   FocusNode? nextFocus,
  //   required String label,
  //   Widget? prefixIcon,
  //   bool readOnly = false,
  //   Function()? onTap,
  //   TextInputType textInputType = TextInputType.text,
  //   TextInputAction textInputAction = TextInputAction.next,
  //   TextCapitalization textCapitalization = TextCapitalization.none,
  //   int maxLines = 1,
  //   int? maxLength,
  // }) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.grey.withAlpha(25),
  //           blurRadius: 10,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: TextField(
  //       controller: controller,
  //       focusNode: focus,
  //       readOnly: readOnly,
  //       onTap: onTap,
  //       style: TextStyle(fontSize: 16),
  //       keyboardType: textInputType,
  //       textInputAction: textInputAction,
  //       textCapitalization: textCapitalization,
  //       maxLines: maxLines,
  //       maxLength: maxLength,
  //       decoration: InputDecoration(
  //         counterText: '',
  //         contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  //         labelText: label,
  //         labelStyle: TextStyle(color: Colors.grey),
  //         prefixIcon: prefixIcon,
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide: BorderSide.none,
  //         ),
  //         focusedBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide: BorderSide(color: primaryColor, width: 1.0),
  //         ),
  //         enabledBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide: BorderSide(color: Colors.grey.withAlpha(51), width: 1.0),
  //         ),
  //         fillColor: readOnly ? Colors.grey.withAlpha(25) : Colors.white,
  //         filled: true,
  //       ),
  //       onSubmitted: (value) {
  //         if (nextFocus != null) {
  //           FocusScope.of(context).requestFocus(nextFocus);
  //         }
  //       },
  //     ),
  //   );
  // }

  // Widget _buildPhoneField() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.grey.withAlpha(25),
  //           blurRadius: 10,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: TextField(
  //       controller: contactNumberController,
  //       focusNode: contactFocus,
  //       style: TextStyle(fontSize: 16),
  //       keyboardType: TextInputType.phone,
  //       textInputAction: TextInputAction.next,
  //       decoration: InputDecoration(
  //         contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
  //         labelText: language.phoneNumber,
  //         labelStyle: TextStyle(color: Colors.grey),
  //         prefixIcon: Padding(
  //           padding: EdgeInsets.only(left: 8, right: 8),
  //           child: IntrinsicHeight(
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 CountryCodePicker(
  //                   padding: EdgeInsets.zero,
  //                   initialSelection: countryCode,
  //                   showCountryOnly: false,
  //                   dialogSize: Size(MediaQuery.of(context).size.width - 60, MediaQuery.of(context).size.height * 0.6),
  //                   showFlag: true,
  //                   showFlagDialog: true,
  //                   showOnlyCountryWhenClosed: false,
  //                   alignLeft: false,
  //                   textStyle: TextStyle(fontSize: 16, color: Colors.black),
  //                   dialogBackgroundColor: Theme.of(context).cardColor,
  //                   barrierColor: Colors.black12,
  //                   dialogTextStyle: TextStyle(fontSize: 16, color: Colors.black),
  //                   searchDecoration: InputDecoration(
  //                     focusColor: primaryColor,
  //                     enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).dividerColor)),
  //                     focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
  //                   ),
  //                   searchStyle: TextStyle(fontSize: 16, color: Colors.black),
  //                   onInit: (c) {
  //                     countryCode = c!.dialCode!;
  //                   },
  //                   onChanged: (c) {
  //                     countryCode = c.dialCode!;
  //                   },
  //                 ),
  //                 VerticalDivider(color: Colors.grey.withAlpha(127), width: 16),
  //               ],
  //             ),
  //           ),
  //         ),
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide: BorderSide.none,
  //         ),
  //         focusedBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide: BorderSide(color: primaryColor, width: 1.0),
  //         ),
  //         enabledBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(12),
  //           borderSide: BorderSide(color: Colors.grey.withAlpha(51), width: 1.0),
  //         ),
  //         fillColor: Colors.white,
  //         filled: true,
  //       ),
  //       onSubmitted: (value) {
  //         FocusScope.of(context).requestFocus(addressFocus);
  //       },
  //     ),
  //   );
  // }

  // Widget _buildUpdateButton() {
  //   return AnimatedContainer(
  //     duration: Duration(milliseconds: 300),
  //     height: 56,
  //     width: double.infinity,
  //     child: ElevatedButton(
  //       onPressed: () {
  //         if (!_isSaving) {
  //           if (sharedPref.getString(USER_EMAIL) == demoEmail) {
  //             toast(language.demoMsg);
  //           } else {
  //             saveProfile();
  //           }
  //         }
  //       },
  //       style: ElevatedButton.styleFrom(
  //         backgroundColor: primaryColor,
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         elevation: 0,
  //         padding: EdgeInsets.zero,
  //       ),
  //       child: _isSaving
  //           ? Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 SizedBox(
  //                   height: 24,
  //                   width: 24,
  //                   child: CircularProgressIndicator(
  //                     color: Colors.white,
  //                     strokeWidth: 2.5,
  //                   ),
  //                 ),
  //                 SizedBox(width: 12),
  //                 Text(
  //                   "جاري التحديث...",
  //                   style: TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ],
  //             )
  //           : Text(
  //               'تعديل الصوره',
  //               style: TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 16,
  //                 fontWeight: FontWeight.bold,
  //                 letterSpacing: 0.5,
  //               ),
  //             ),
  //     ),
  //   );
  // }
}
