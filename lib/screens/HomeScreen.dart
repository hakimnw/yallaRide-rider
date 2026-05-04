import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_booking/screens/DashBoardScreen.dart';
import 'package:taxi_booking/screens/MainScreen.dart';

import '../main.dart';
import '../model/LoginResponse.dart';
import '../model/RiderModel.dart';
import '../model/ServiceModel.dart';
import '../network/RestApis.dart';
import '../screens/RideDetailScreen.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/constant/app_colors.dart';
import 'ChatScreen.dart';
import 'NotificationScreen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<ServiceList> serviceList = [];
  List<RiderModel> recentRides = [];
  bool isLoading = false;
  int? selectedServiceId;
  int unreadNotifications = 0;
  int totalRidesCount = 0; // إجمالي عدد الرحلات
  int thisMonthRidesCount = 0; // رحلات هذا الشهر

  // Animation controllers
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  // late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _setupAnimations();
    init();
    _animationController.forward();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatingController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // _floatingAnimation = Tween<double>(
    //   begin: -5.0,
    //   end: 5.0,
    // ).animate(
    //   CurvedAnimation(
    //     parent: _floatingController,
    //     curve: Curves.easeInOut,
    //   ),
    // );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void init() async {
    isLoading = true;
    setState(() {});

    // Load selected service ID from SharedPreferences if it exists
    selectedServiceId = sharedPref.getInt('selectedServiceId');

    await Future.wait([
      _loadServices(),
      _fetchRecentRides(),
      _loadNotificationCount(),
    ]);

    isLoading = false;
    setState(() {});
  }

  Future<void> _loadServices() async {
    try {
      final value = await getServices();
      if (value.data != null && value.data!.isNotEmpty) {
        serviceList = value.data!;
      }
    } catch (error) {
      log(error.toString());
    }
  }

  Future<void> _fetchRecentRides() async {
    try {
      int? userId = sharedPref.getInt(USER_ID);
      if (userId == null) return;

      List<RiderModel> allRides = [];
      int currentPage = 1;
      bool hasMorePages = true;

      // جلب جميع الرحلات من جميع الصفحات
      while (hasMorePages) {
        final pageValue = await getRiderRequestList(page: currentPage, status: COMPLETED, riderId: userId);

        if (pageValue.data != null && pageValue.data!.isNotEmpty) {
          allRides.addAll(pageValue.data!);

          // التحقق من وجود صفحات إضافية
          // إذا كانت الصفحة تحتوي على أقل من العدد المتوقع، فهذا يعني أنها الصفحة الأخيرة
          if (pageValue.data!.length < 10) {
            // افتراض أن كل صفحة تحتوي على 10 عناصر كحد أقصى
            hasMorePages = false;
          } else {
            currentPage++;
          }
        } else {
          hasMorePages = false;
        }

        // حماية من التكرار اللانهائي
        if (currentPage > 50) {
          // حد أقصى 50 صفحة
          hasMorePages = false;
        }
      }

      // حفظ العدد الإجمالي لجميع الرحلات
      totalRidesCount = allRides.length;

      // حساب رحلات الشهر الحالي
      DateTime now = DateTime.now();
      thisMonthRidesCount = allRides.where((ride) {
        if (ride.createdAt != null) {
          try {
            DateTime rideDate = DateTime.parse(ride.createdAt!);
            return rideDate.year == now.year && rideDate.month == now.month;
          } catch (e) {
            return false;
          }
        }
        return false;
      }).length;

      // حفظ آخر 3 رحلات للعرض في قسم الوجهات الأخيرة
      recentRides = allRides.take(3).toList();
    } catch (error) {
      log('Error fetching recent rides: ${error.toString()}');
      totalRidesCount = 0;
      thisMonthRidesCount = 0;
      recentRides = [];
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      // Simulate loading notification count
      // Replace with actual API call
      unreadNotifications = 0; // Example count
    } catch (error) {
      log('Error loading notifications: ${error.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      extendBodyBehindAppBar: true,
      body: isLoading
          ? _buildLoadingState()
          : AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Enhanced Background with gradient
                    //_buildEnhancedBackground(),

                    // Main Content
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: CustomScrollView(
                          physics: BouncingScrollPhysics(),
                          slivers: [
                            // Modern App Bar
                            _buildModernAppBar(),

                            // Quick Stats Cards
                            // _buildQuickStatsSection(),

                            // Search Bar Section
                            _buildSearchSection(),

                            // Service Categories
                            _buildServiceCategoriesSection(),

                            // Promotional Banner

                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(20, 30, 20, 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'العروض الخاصة',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFE8F5E9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.local_offer_rounded,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Enhanced Welcome Message Card
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(20, 0, 20, 30),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(25),
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      'assets/assets/images/home_welcome_message.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // _buildPromotionalBanner(),

                            // Recent Destinations
                            _buildRecentDestinationsSection(),

                            // Quick Actions
                            _buildQuickActionsSection(),

                            // Bottom Spacer
                            SliverToBoxAdapter(child: SizedBox(height: 120)),
                          ],
                        ),
                      ),
                    ),

                    // Floating Action Button
                  ],
                );
              },
            ),
    );
  }

  // Widget _buildEnhancedBackground() {
  //   return Container(
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topCenter,
  //         end: Alignment.bottomCenter,
  //         colors: [
  //           AppColors.primary,
  //           AppColors.primary.withAlpha(201),
  //           Colors.white,
  //         ],
  //         stops: [0.0, 0.3, 0.6],
  //       ),
  //     ),
  //     child: Container(
  //       decoration: BoxDecoration(
  //         image: DecorationImage(
  //           image: AssetImage('assets/assets/images/backgroundFrame.png'),
  //           fit: BoxFit.cover,
  //           opacity: 0.1,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, Colors.white],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'جاري تحميل التطبيق...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            image: DecorationImage(
              image: AssetImage("assets/assets/images/app_bar_background.png"),
              fit: BoxFit.fill,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // User Info
                  Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(51),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            appStore.userProfile,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.white,
                              child: Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 25,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اهلا بك في YallahRide',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${appStore.userName}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w500,
                            ),
                          )

                          /*      Text(
                            'مرحباً بك',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha(226),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${appStore.userName}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                       */
                        ],
                      ),
                    ],
                  ),
/* 

class HomeScreenAppBar extends StatelessWidget {
  const HomeScreenAppBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: 144,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          image: DecorationImage(
            image: AssetImage("assets/assets/images/app_bar_background.png"),
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 21),
          child: Row(
            children: [
              const UserImage(),
              SizedBox(
                width: 9,
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'اهلا بك في YallahRide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'يوسف محمد',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              ),
              /*  const Spacer(),
              GestureDetector(
                onTap: () {
                  //NavigationService.pushNamed(RouterNames.notificationsScreen);
                },
                child: SvgPicture.asset(
                  AppIcons.notification,
                  width: 28,
                  height: 28,
                ),
              ) */
            ],
          ),
        ));
  }
}


 */

                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: unreadNotifications > 0 ? _pulseAnimation.value : 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withAlpha(76),
                              width: 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificationScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(12),
                                child: Stack(
                                  children: [
                                    Icon(
                                      Icons.notifications_outlined,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    if (unreadNotifications > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          constraints: BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '$unreadNotifications',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildQuickStatsSection() {
  //   return SliverToBoxAdapter(
  //     child: Container(
  //       margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
  //       child: Column(
  //         children: [
  //           // الصف الأول - إجمالي الرحلات ورحلات الشهر
  //           Row(
  //             children: [
  //               Expanded(
  //                 child: _buildStatCard(
  //                   'إجمالي رحلاتي',
  //                   isLoading ? '...' : '$totalRidesCount',
  //                   Icons.directions_car_rounded,
  //                   Colors.blue,
  //                 ),
  //               ),
  //               SizedBox(width: 12),
  //               Expanded(
  //                 child: _buildStatCard(
  //                   'رحلات هذا الشهر',
  //                   isLoading ? '...' : '$thisMonthRidesCount',
  //                   Icons.calendar_month_rounded,
  //                   Colors.purple,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           SizedBox(height: 12),
  //           // الصف الثاني - النقاط والمحفظة
  //           /*  Row(
  //             children: [
  //               Expanded(
  //                 child: _buildStatCard(
  //                   'نقاطي',
  //                   '0',
  //                   Icons.stars_rounded,
  //                   Colors.amber,
  //                 ),
  //               ),
  //               SizedBox(width: 12),
  //               Expanded(
  //                 child: _buildStatCard(
  //                   'محفظتي',
  //                   '₹ 0',
  //                   Icons.account_balance_wallet_rounded,
  //                   AppColors.primary,
  //                 ),
  //               ),
  //             ],
  //           ), */
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildStatCard(String title, String value, IconData icon, Color color) {
  //   return Container(
  //     padding: EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withAlpha(13),
  //           blurRadius: 8,
  //           offset: Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         Container(
  //           padding: EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: color.withAlpha(25),
  //             shape: BoxShape.circle,
  //           ),
  //           child: Icon(
  //             icon,
  //             color: color,
  //             size: 20,
  //           ),
  //         ),
  //         SizedBox(height: 8),
  //         Text(
  //           value,
  //           style: TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black87,
  //           ),
  //         ),
  //         SizedBox(height: 2),
  //         Text(
  //           title,
  //           style: TextStyle(
  //             fontSize: 11,
  //             color: Colors.grey[600],
  //             fontWeight: FontWeight.w500,
  //           ),
  //           textAlign: TextAlign.center,
  //           maxLines: 2,
  //           overflow: TextOverflow.ellipsis,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DashboardScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.primary.withAlpha(201)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'إلى أين تريد الذهاب؟',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'ابحث عن وجهتك المفضلة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceCategoriesSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'خدماتنا',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'عرض الكل',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 140,
            child: serviceList.isEmpty
                ? _buildEmptyServicesState()
                : AnimationLimiter(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: serviceList.length,
                      itemBuilder: (context, index) {
                        ServiceList service = serviceList[index];
                        bool isSelected = selectedServiceId == service.id?.toInt();

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: Duration(milliseconds: 600),
                          child: SlideAnimation(
                            horizontalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildEnhancedServiceCard(service, isSelected),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedServiceCard(ServiceList service, bool isSelected) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          selectedServiceId = service.id?.toInt();
          if (service.id != null) {
            sharedPref.setInt('selectedServiceId', service.id!.toInt());
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('تم اختيار ${service.name}'),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(12),
          ),
        );
      },
      child: Container(
        width: 120,
        height: 120,
        //margin: EdgeInsets.only(left: 16),
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: 90,
              width: 90,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                /*  gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primary.withAlpha(201),
                          //AppColors.primary,
                          AppColors.primary.withAlpha(76)
                        ],
                      )
                    : null, */
                // color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                /*     boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withAlpha(76)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: isSelected ? 15 : 10,
                    offset: Offset(0, isSelected ? 8 : 4),
                  ),
                ], */
                border: Border.all(
                  color: !isSelected ? Colors.grey.shade200 : Colors.grey.shade400,
                  width: 1,
                ),
              ),
              child: service.serviceImage != null
                  ? Image.network(
                      height: 70,
                      width: 70,
                      service.serviceImage!,
                      fit: BoxFit.cover,
                      // color: isSelected ? Colors.white : AppColors.primary,
                      /*   errorBuilder: (context, error, stackTrace) =>
                          SvgPicture.asset(
                        'assets/assets/images/hatchback 1.svg',
                        //color: isSelected ? Colors.white : AppColors.primary,
                        width: 70,
                        height: 70,
                      ), */
                    )
                  : SvgPicture.asset(
                      'assets/assets/images/carr1.svg',
                      color: isSelected ? Colors.white : AppColors.primary,
                      width: 70,
                      height: 70,
                    ),
            ),
            SizedBox(height: 12),
            Text(
              service.name ?? 'خدمة',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Container(
                margin: EdgeInsets.only(top: 6),
                height: 3,
                width: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyServicesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.car_rental_outlined,
            size: 40,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 8),
          Text(
            'لا توجد خدمات متاحة',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDestinationsSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'الوجهات الأخيرة',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (recentRides.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MainScreen(
                            initialIndex: 2,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'عرض الكل',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),
          recentRides.isEmpty
              ? _buildEmptyRecentDestinations()
              : Column(
                  children: recentRides.asMap().entries.map((entry) {
                    int index = entry.key;
                    RiderModel ride = entry.value;
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: Duration(milliseconds: 600),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildEnhancedRecentLocationTile(ride),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecentDestinations() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_history,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد رحلات سابقة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ستظهر وجهاتك المفضلة هنا بعد أول رحلة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRecentLocationTile(RiderModel ride) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            if (ride.id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RideDetailScreen(
                    orderId: ride.id!,
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ride Type Row
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRideTypeIcon(ride.serviceId?.toString() ?? ''),
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _getRideTypeName(ride.serviceId?.toString() ?? ''),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    if (ride.createdAt != null)
                      Text(
                        _formatDate(ride.createdAt!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),
                // Locations
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        Container(
                          width: 1,
                          height: 25,
                          color: Colors.grey.shade300,
                        ),
                        Icon(
                          Icons.circle,
                          size: 12,
                          color: Colors.red,
                        ),
                      ],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.startAddress ?? 'نقطة البداية',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 20),
                          Text(
                            ride.endAddress?.split(',').first ?? 'نقطة النهاية',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getRideTypeIcon(String serviceId) {
    switch (serviceId) {
      case '1': // سفر
        return Icons.flight;
      case '2': // سيارة فاخرة
        return Icons.directions_car_filled;
      case '3': // رحلة عادية
        return Icons.local_taxi;
      case '4': // معاقين وكبار السن
        return Icons.accessible;
      default:
        return Icons.local_taxi;
    }
  }

  String _getRideTypeName(String serviceId) {
    switch (serviceId) {
      case '1':
        return 'رحله عاديه';
      case '2':
        return 'سفر';
      case '3':
        return 'رحلة';
      case '4':
        return 'سياره فاخره';
      default:
        return ' للمعاقين وكبار السن';
    }
  }

  Widget _buildQuickActionsSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إجراءات سريعة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    'دعوة الأصدقاء',
                    Icons.person_add_rounded,
                    Colors.purple,
                    () {},
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    'الدعم الفني',
                    Icons.support_agent_rounded,
                    Colors.blue,
                    () {
                      // Create admin user model for support chat
                      UserModel adminSupport = UserModel(
                        id: 0, // Admin ID
                        firstName: "قسم",
                        lastName: "الشكاوى",
                        email: "support@admin.com",
                        profileImage: "", // Add default support avatar if available
                        uid: "admin_support",
                        playerId: "admin_support",
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            userData: adminSupport,
                            ride_id: 0, // General support chat
                            show_history: false,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

/* 
  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 30,
      right: 20,
      child: AnimatedBuilder(
        animation: _floatingAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatingAnimation.value * 0.5),
            child: FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.lightImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SearchLocationComponent(
                    title: sourceLocationTitle,
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              elevation: 8,
              label: Text(
                'احجز رحلة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: Icon(
                Icons.add_location_alt_rounded,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
 */
  // IconData _getLocationIcon(String address) {
  //   String lowerAddress = address.toLowerCase();
  //   if (lowerAddress.contains('منزل') || lowerAddress.contains('بيت') || lowerAddress.contains('home')) {
  //     return Icons.home_rounded;
  //   } else if (lowerAddress.contains('عمل') ||
  //       lowerAddress.contains('شركة') ||
  //       lowerAddress.contains('مكتب') ||
  //       lowerAddress.contains('work')) {
  //     return Icons.work_rounded;
  //   } else if (lowerAddress.contains('مول') || lowerAddress.contains('سوق') || lowerAddress.contains('mall')) {
  //     return Icons.shopping_bag_rounded;
  //   } else if (lowerAddress.contains('مطار') || lowerAddress.contains('airport')) {
  //     return Icons.flight_rounded;
  //   } else if (lowerAddress.contains('مستشفى') || lowerAddress.contains('hospital')) {
  //     return Icons.local_hospital_rounded;
  //   }
  //   return Icons.location_on_rounded;
  // }

  String _formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      DateTime now = DateTime.now();

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return 'اليوم';
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        return 'أمس';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}
