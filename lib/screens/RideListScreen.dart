import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:taxi_booking/screens/settings/help/app_bar/search_field.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/utils/core/widget/appbar/home_screen_app_bar.dart';

import '../../components/CreateTabScreen.dart';
import '../../utils/Constants.dart';
import '../utils/Colors.dart';

class RideListScreen extends StatefulWidget {
  @override
  RideListScreenState createState() => RideListScreenState();
}

class RideListScreenState extends State<RideListScreen> with TickerProviderStateMixin {
  int currentPage = 1;
  int totalPage = 1;
  List<String> riderStatus = [COMPLETED, CANCELED];

  // Animation Controllers
  late AnimationController _mainAnimationController;
  late AnimationController _tabAnimationController;
  late AnimationController _headerAnimationController;
  late AnimationController _floatingAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _tabSlideAnimation;
  late Animation<double> _headerSlideAnimation;
  late Animation<double> _floatingAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setSystemUIStyle();
    _startAnimations();
    init();
  }

  void _initializeAnimations() {
    // Main animation controller
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Tab animation controller
    _tabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Header animation controller
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Floating animation controller
    _floatingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Define animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _tabSlideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _tabAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _headerSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _floatingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _setSystemUIStyle() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
  }

  void _startAnimations() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _mainAnimationController.forward();
      }
    });

    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        _tabAnimationController.forward();
      }
    });

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _headerAnimationController.forward();
      }
    });

    Future.delayed(Duration(milliseconds: 700), () {
      if (mounted) {
        _floatingAnimationController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _tabAnimationController.dispose();
    _headerAnimationController.dispose();
    _floatingAnimationController.dispose();
    super.dispose();
  }

  void init() async {
    // Initialize any required data
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  String _getStatusText(String status) {
    switch (status) {
      case COMPLETED:
        return 'مكتملة';
      case CANCELED:
        return 'ملغية';
      default:
        return status;
    }
  }

  Widget _buildModernTab() {
    return AnimatedBuilder(
      animation: _tabAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_tabSlideAnimation.value, 0),
          child: Container(
            height: 60,
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: primaryColor.withAlpha(25),
                  blurRadius: 40,
                  offset: Offset(0, 16),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TabBar(
              dividerHeight: 0,
              padding: EdgeInsets.all(6),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    primaryColor.withAlpha(201),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              tabs: riderStatus.asMap().entries.map((entry) {
                // int index = entry.key;
                String status = entry.value;
                return Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        status == COMPLETED ? Icons.check_circle_outline : Icons.cancel_outlined,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _getStatusText(status),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _floatingAnimationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_floatingAnimation.value * 0.1),
                      child: Container(
                        width: 6,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              primaryColor,
                              primaryColor.withAlpha(153),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withAlpha(76),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تاريخ رحلاتك',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'استعرض جميع رحلاتك السابقة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedBuilder(
                  animation: _floatingAnimationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _floatingAnimation.value * 0.1,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor.withAlpha(25),
                              primaryColor.withAlpha(13),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withAlpha(51),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          MaterialCommunityIcons.history,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideListContent() {
    return Expanded(
      child: AnimatedBuilder(
        animation: _mainAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    child: TabBarView(
                      children: riderStatus.map((status) {
                        return Container(
                          padding: EdgeInsets.only(top: 8),
                          child: CreateTabScreen(status: status),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: riderStatus.length,
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: Column(
            children: [
              const HomeScreenAppBar(),
              const ResponsiveVerticalSpace(15),
              const TransformedSearchField(
                hintText: "ابحث عن ما تريد",
              ),
              _buildModernTab(),
              _buildAnimatedHeader(),
              _buildRideListContent(),
            ],
          ),
        ),
      ),
    );
  }
}
