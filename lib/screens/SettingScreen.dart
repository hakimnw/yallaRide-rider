import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:taxi_booking/screens/NotificationScreen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxi_booking/utils/core/widget/appbar/home_screen_app_bar.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/screens/settings/help/app_bar/search_field.dart';

import '../main.dart';
import '../model/SettingModel.dart';
import '../model/DriverRatting.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/ConformationDialog.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import 'AboutScreen.dart';
import 'ChangePasswordScreen.dart';
import 'DeleteAccountScreen.dart';
import 'EditProfileScreen.dart';
import 'LanguageScreen.dart';
import 'SignInScreen.dart';
import 'TermsConditionScreen.dart';
import 'PrivacyPolicyScreen.dart';
import 'ComplaintScreen.dart';
import '../components/ModernAppBar.dart';
import '../model/RiderModel.dart';
import 'dart:developer';
import 'WalletScreen.dart';

class SettingScreen extends StatefulWidget {
  @override
  SettingScreenState createState() => SettingScreenState();
}

class SettingScreenState extends State<SettingScreen>
    with TickerProviderStateMixin {
  SettingModel settingModel = SettingModel();
  String? privacyPolicy;
  String? termsCondition;

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  // Track which setting is being pressed
  int? _pressedSetting;
  bool _isDarkMode = false;
  bool _isPremiumUser = false; // This would come from your app state
  int totalRidesCount = 0;
  int thisMonthRidesCount = 0;
  num totalSavings = 0;
  bool isLoading = false;
  double averageRating = 0.0;
  num walletBalance = 0;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _animationController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);

    _isDarkMode = appStore.isDarkMode;
    fetchRideStatistics();

    init();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void init() async {
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> fetchRideStatistics() async {
    try {
      setState(() => isLoading = true);
      int? userId = sharedPref.getInt(USER_ID);
      if (userId == null) return;

      List<RiderModel> allRides = [];
      int currentPage = 1;
      bool hasMorePages = true;

      // Fetch wallet info
      try {
        final walletInfo = await getWalletData();
        if (walletInfo.walletData != null) {
          walletBalance = walletInfo.walletData!.totalAmount ?? 0;
        }
      } catch (e) {
        log('Error fetching wallet data: ${e.toString()}');
      }

      while (hasMorePages) {
        final pageValue = await getRiderRequestList(
            page: currentPage, status: COMPLETED, riderId: userId);

        if (pageValue.data != null && pageValue.data!.isNotEmpty) {
          allRides.addAll(pageValue.data!);

          if (pageValue.data!.length < 10) {
            hasMorePages = false;
          } else {
            currentPage++;
          }
        } else {
          hasMorePages = false;
        }

        if (currentPage > 50) hasMorePages = false;
      }

      // Calculate total rides
      totalRidesCount = allRides.length;

      // Calculate this month's rides
      DateTime now = DateTime.now();
      thisMonthRidesCount = allRides.where((ride) {
        if (ride.createdAt != null) {
          try {
            DateTime rideDate = DateTime.parse(ride.createdAt ?? '');
            return rideDate.year == now.year && rideDate.month == now.month;
          } catch (e) {
            return false;
          }
        }
        return false;
      }).length;

      // Calculate total savings
      totalSavings =
          allRides.fold(0, (sum, ride) => sum + (ride.couponDiscount ?? 0));

      // Calculate average rating
      try {
        double totalRating = 0;
        int ratedRidesCount = 0;

        for (var ride in allRides) {
          if (ride.id != null) {
            final rideDetailData = await rideDetail(orderId: ride.id);
            if (rideDetailData.driverRatting?.rating != null) {
              totalRating += rideDetailData.driverRatting!.rating!.toDouble();
              ratedRidesCount++;
            }
          }
        }

        if (ratedRidesCount > 0) {
          averageRating = totalRating / ratedRidesCount;
        }
      } catch (e) {
        log('Error calculating average rating: ${e.toString()}');
      }

      setState(() => isLoading = false);
    } catch (error) {
      log('Error fetching ride statistics: ${error.toString()}');
      setState(() {
        isLoading = false;
        totalRidesCount = 0;
        thisMonthRidesCount = 0;
        totalSavings = 0;
        averageRating = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _isDarkMode
                    ? [Color(0xFF1E1E1E), Color(0xFF121212)]
                    : [Colors.white, Colors.grey.shade100],
              ),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    const HomeScreenAppBar(),
                    const ResponsiveVerticalSpace(15),
                    const TransformedSearchField(
                      hintText: "ابحث عن ما تريد",
                    ),
                    SizedBox(height: 16),
                    _buildEnhancedProfileCard(),
                    SizedBox(height: 16),
                    _buildQuickStatsSection(),
                    SizedBox(height: 24),
                    AnimationLimiter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle("💰 المحفظة ",
                              color: Colors.green),
                          _buildWalletSection(),
                          SizedBox(height: 24),
                          _buildSectionTitle("👤 الحساب والملف الشخصي"),
                          _buildAccountSection(),
                          SizedBox(height: 24),
                          _buildSectionTitle("⚙️ تفضيلات التطبيق"),
                          _buildPreferencesSection(),
                          _buildRideSection(),
                          SizedBox(height: 24),
                          _buildSectionTitle("📋 القانونية والدعم"),
                          _buildLegalSection(),
                          SizedBox(height: 24),
                          _buildSectionTitle("⚠️ إجراءات الحساب",
                              isDanger: true),
                          _buildDangerSection(),
                          SizedBox(height: 20),
                          //_buildAppInfo(),
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
    );
  }

  Widget _buildEnhancedProfileCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isPremiumUser
              ? [Color(0xFFFFD700), Color(0xFFDAA520)]
              : [Color(0xFF0C9869), Color(0xFF1E7145)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color:
                (_isPremiumUser ? Colors.amber : primaryColor).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        /*  launchScreen(context, EditProfileScreen(),
                            pageRouteAnimation: PageRouteAnimation.Slide); */
                      },
                      child: Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.8)
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(35),
                              child: Container(
                                width: 65,
                                height: 65,
                                child:
                                    sharedPref.getString(USER_PROFILE_PHOTO) !=
                                                null &&
                                            sharedPref
                                                .getString(USER_PROFILE_PHOTO)!
                                                .isNotEmpty
                                        ? commonCachedNetworkImage(
                                            sharedPref
                                                .getString(USER_PROFILE_PHOTO)!,
                                            fit: BoxFit.cover,
                                            height: 65,
                                            width: 65,
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.grey.shade300,
                                                  Colors.grey.shade400
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              MaterialCommunityIcons.account,
                                              color: Colors.grey.shade700,
                                              size: 32,
                                            ),
                                          ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue, Colors.blue.shade700],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                MaterialCommunityIcons.camera,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  appStore.userName.isEmpty
                                      ? (appStore.firstName.isNotEmpty)
                                          ? "${appStore.firstName} ${sharedPref.getString(LAST_NAME) ?? ''}"
                                              .trim()
                                          : (sharedPref.getString(FIRST_NAME) !=
                                                      null &&
                                                  sharedPref
                                                      .getString(FIRST_NAME)!
                                                      .isNotEmpty)
                                              ? "${sharedPref.getString(FIRST_NAME) ?? ''} ${sharedPref.getString(LAST_NAME) ?? ''}"
                                                  .trim()
                                              : language.guest
                                      : appStore.userName,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            appStore.userEmail.isEmpty
                                ? (sharedPref.getString(USER_EMAIL) != null &&
                                        sharedPref
                                            .getString(USER_EMAIL)!
                                            .isNotEmpty)
                                    ? sharedPref.getString(USER_EMAIL)!
                                    : language.guest
                                : appStore.userEmail,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              _buildQuickActionButton(
                                icon: Icons.star,
                                label: isLoading
                                    ? "..."
                                    : averageRating > 0
                                        ? averageRating.toStringAsFixed(1)
                                        : "لا يوجد",
                                onTap: () {},
                              ),
                              SizedBox(width: 12),
                              _buildQuickActionButton(
                                icon: Icons.drive_eta,
                                label: isLoading
                                    ? "..."
                                    : totalRidesCount.toString(),
                                onTap: () {},
                              ),
                              SizedBox(width: 12),
                              _buildQuickActionButton(
                                icon: Icons.wallet,
                                label: isLoading
                                    ? "..."
                                    : "\$${walletBalance.toStringAsFixed(2)}",
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
              child: _buildStatCard(
                  "إجمالي الرحلات",
                  isLoading ? "..." : totalRidesCount.toString(),
                  Icons.directions_car,
                  Colors.blue)),
          SizedBox(width: 12),
          Expanded(
              child: _buildStatCard(
                  "هذا الشهر",
                  isLoading ? "..." : thisMonthRidesCount.toString(),
                  Icons.calendar_month,
                  Colors.green)),
          SizedBox(width: 12),
          Expanded(
              child: _buildStatCard(
                  "موفر",
                  isLoading ? "..." : "\$${totalSavings.toStringAsFixed(2)}",
                  Icons.savings,
                  Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Column(
      children: [
        _buildModernSettingItem(
          icon: MaterialCommunityIcons.wallet,
          title: "محفظتي",
          subtitle: isLoading
              ? "جاري التحميل..."
              : "الرصيد: \$${walletBalance.toStringAsFixed(2)}",
          color: Colors.green,
          onTap: () {
            launchScreen(context, WalletScreen(),
                pageRouteAnimation: PageRouteAnimation.Slide);
          },
          index: 0,
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      children: [
        AnimationConfiguration.staggeredList(
          position: 3,
          duration: Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildModernSettingItem(
                icon: MaterialCommunityIcons.account_edit,
                title: "تحديث ملفك",
                subtitle: "تحديث معلوماتك الشخصية",
                onTap: () {
                  launchScreen(context, EditProfileScreen(),
                      pageRouteAnimation: PageRouteAnimation.Slide);
                },
                index: 3,
              ),
            ),
          ),
        ),
        AnimationConfiguration.staggeredList(
          position: 4,
          duration: Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildModernSettingItem(
                icon: MaterialCommunityIcons.lock_outline,
                title: language.changePassword,
                subtitle: "تحديث كلمة مرور الحساب",
                onTap: () {
                  launchScreen(context, ChangePasswordScreen(),
                      pageRouteAnimation: PageRouteAnimation.Slide);
                },
                index: 4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      children: [
        AnimationConfiguration.staggeredList(
          position: 6,
          duration: Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildModernSettingItem(
                icon: MaterialCommunityIcons.translate,
                title: "اللغة",
                subtitle: "اختر لغتك المفضلة",
                onTap: () {
                  launchScreen(context, LanguageScreen(),
                      pageRouteAnimation: PageRouteAnimation.Slide);
                },
                index: 6,
              ),
            ),
          ),
        ),
        _buildModernSettingItem(
          icon: MaterialCommunityIcons.bell_outline,
          title: "الإشعارات",
          subtitle: "تخصيص تفضيلات الإشعارات",
          color: Colors.orange,
          onTap: () {
            launchScreen(context, NotificationScreen(),
                pageRouteAnimation: PageRouteAnimation.Slide);
          },
          index: 7,
        ),
      ],
    );
  }

  Widget _buildRideSection() {
    return Column(
      children: [
        _buildModernSettingItem(
          icon: MaterialCommunityIcons.credit_card,
          title: "طرق الدفع",
          subtitle: "إدارة البطاقات، المحافظ الرقمية",
          color: Colors.green,
          onTap: () {},
          index: 11,
        ),
      ],
    );
  }

  Widget _buildLegalSection() {
    return Column(
      children: [
        AnimationConfiguration.staggeredList(
          position: 13,
          duration: Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildModernSettingItem(
                icon: MaterialCommunityIcons.message_alert_outline,
                title: "تواصل معنا للشكاوي",
                subtitle: "الإبلاغ عن المشاكل والشكاوى",
                onTap: () {
                  final defaultDriverRatting = DriverRatting(
                    rating: 0,
                    comment: '',
                  );
                  launchScreen(
                      context,
                      ComplaintScreen(
                        driverRatting: defaultDriverRatting,
                        riderModel: null,
                      ),
                      pageRouteAnimation: PageRouteAnimation.Slide);
                },
                index: 13,
              ),
            ),
          ),
        ),
        if (appStore.mHelpAndSupport != null)
          _buildModernSettingItem(
            icon: MaterialCommunityIcons.help_circle_outline,
            title: language.helpSupport,
            subtitle: "الحصول على المساعدة والدعم",
            onTap: () {
              if (appStore.mHelpAndSupport != null) {
                launchUrl(Uri.parse(appStore.mHelpAndSupport!));
              } else {
                toast(language.txtURLEmpty);
              }
            },
            index: 14,
          ),
        _buildModernSettingItem(
          icon: MaterialCommunityIcons.shield_check_outline,
          title: language.privacyPolicy,
          subtitle: "اقرأ سياسة الخصوصية الخاصة بنا",
          onTap: () {
            launchScreen(context, PrivacyPolicyScreen(),
                pageRouteAnimation: PageRouteAnimation.Slide);
          },
          index: 15,
        ),
        if (appStore.termsCondition == null)
          _buildModernSettingItem(
            icon: MaterialCommunityIcons.file_document_outline,
            title: language.termsConditions,
            subtitle: "الشروط والأحكام",
            onTap: () {
              if (appStore.termsCondition == null) {
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
            index: 16,
          ),
        _buildModernSettingItem(
          icon: MaterialCommunityIcons.information_outline,
          title: "  الدعم الفني   ",
          subtitle: "  الدعم الفني للمستخدمين  ",
          onTap: () {
            launchScreen(
                context, AboutScreen(settingModel: appStore.settingModel),
                pageRouteAnimation: PageRouteAnimation.Slide);
          },
          index: 17,
        ),
      ],
    );
  }

  Widget _buildDangerSection() {
    return Column(
      children: [
        AnimationConfiguration.staggeredList(
          position: 18,
          duration: Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildModernSettingItem(
                icon: MaterialCommunityIcons.logout,
                title: language.logOut,
                subtitle: "تسجيل الخروج من حسابك",
                color: Colors.orange[700],
                onTap: () {
                  _showLogoutConfirmation();
                },
                index: 18,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        AnimationConfiguration.staggeredList(
          position: 19,
          duration: Duration(milliseconds: 375),
          child: SlideAnimation(
            verticalOffset: 50.0,
            child: FadeInAnimation(
              child: _buildModernSettingItem(
                icon: MaterialCommunityIcons.delete_outline,
                title: language.deleteAccount,
                subtitle: "حذف حسابك نهائياً",
                color: Colors.red,
                onTap: () {
                  launchScreen(context, DeleteAccountScreen(),
                      pageRouteAnimation: PageRouteAnimation.Slide);
                },
                index: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title,
      {bool isDanger = false, Color? color}) {
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 15, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              color: isDanger ? Colors.red[700] : color ?? primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isDanger ? Colors.red[700] : color ?? primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildModernSettingItem({
    required IconData icon,
    required String title,
    required Function() onTap,
    required int index,
    String? subtitle,
    Color? color,
    Widget? trailing,
  }) {
    bool isPressed = _pressedSetting == index;
    final itemColor = color ?? primaryColor;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _isDarkMode ? Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPressed
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(_isDarkMode ? 0.2 : 0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onTapDown: (_) {
            setState(() {
              _pressedSetting = index;
            });
          },
          onTapUp: (_) {
            Future.delayed(Duration(milliseconds: 100), () {
              if (mounted) {
                setState(() {
                  _pressedSetting = null;
                });
              }
            });
          },
          onTapCancel: () {
            setState(() {
              _pressedSetting = null;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: itemColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: itemColor,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color:
                              _isDarkMode ? Colors.white : Colors.grey.shade800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        MaterialCommunityIcons.chevron_right,
                        size: 16,
                        color: itemColor.withOpacity(0.7),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() async {
    await showConfirmDialogCustom(
      context,
      primaryColor: primaryColor,
      dialogType: DialogType.CONFIRMATION,
      title: language.areYouSureYouWantToLogoutThisApp,
      positiveText: language.yes,
      negativeText: language.no,
      onAccept: (context) async {
        appStore.setLoading(true);
        await logout().then((value) {
          appStore.setLoading(false);
        }).catchError((error) {
          appStore.setLoading(false);
          toast(error.toString());
        });
      },
    );
  }

  // Helper methods
  int _getUserLevel() {
    return 5;
  }

  String _getUserWalletBalance() {
    return "45.50";
  }
}
