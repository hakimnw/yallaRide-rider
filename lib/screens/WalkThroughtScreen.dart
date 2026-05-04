import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../main.dart';
import '../../utils/Colors.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/app_common.dart';
import '../model/WalkThroughModel.dart';
import 'SignInScreen.dart';

class WalkThroughScreen extends StatefulWidget {
  @override
  WalkThroughScreenState createState() => WalkThroughScreenState();
}

class WalkThroughScreenState extends State<WalkThroughScreen> with TickerProviderStateMixin {
  PageController pageController = PageController();
  int currentPage = 0;

  // Animation controllers
  late AnimationController _imageAnimationController;
  late AnimationController _textAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _imageAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonAnimation;

  // Define page content with custom colors for each page
  List<WalkThroughModel> walkThroughClass = [
    WalkThroughModel(
        name: language.walkthrough_title_1,
        text: language.walkthrough_subtitle_1,
        img: 'assets/assets/images/onboarding1.png'),
    WalkThroughModel(
        name: language.walkthrough_title_2,
        text: language.walkthrough_subtitle_2,
        img: 'assets/assets/images/onboarding2.png'),
    WalkThroughModel(
        name: language.walkthrough_title_3,
        text: language.walkthrough_subtitle_3,
        img: 'assets/assets/images/onboarding3.png')
  ];

  @override
  void initState() {
    super.initState();

    // Set system UI overlay style for a more immersive experience
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    // Initialize animation controllers
    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Define animations
    _imageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _imageAnimationController, curve: Curves.easeOut),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeOut),
    );

    _buttonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeInOut),
    );

    // Start initial animations
    _startAnimations();
  }

  void _startAnimations() {
    _imageAnimationController.forward();
    Future.delayed(Duration(milliseconds: 200), () {
      _textAnimationController.forward();
      Future.delayed(Duration(milliseconds: 200), () {
        _buttonAnimationController.forward();
      });
    });
  }

  void _resetAnimations() {
    _imageAnimationController.reset();
    _textAnimationController.reset();
    _buttonAnimationController.reset();
    _startAnimations();
  }

  @override
  void dispose() {
    _imageAnimationController.dispose();
    _textAnimationController.dispose();
    _buttonAnimationController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background design - subtle gradient
            /*    Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      primaryColor.withAlpha(13),
                    ],
                  ),
                ),
              ),
            ), */

            // Content Column
            Column(
              children: [
                // Top Section with Logo and Skip Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo and App Name
                      /*     Row(
                        children: [
                          Image.asset(
                            'assets/assets/logo.png',
                            height: 40,
                            width: 40,
                          ),
                          SizedBox(width: 8),
                          Text(
                            mAppName,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ), */

                      // Skip button
                      AnimatedBuilder(
                        animation: _buttonAnimationController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _buttonAnimation,
                            child: child,
                          );
                        },
                        child: TextButton(
                          onPressed: () {
                            launchScreen(context, SignInScreen(), isNewTask: true);
                            sharedPref.setBool(IS_FIRST_TIME, false);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: Colors.grey.withAlpha(76),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            language.skip,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page View - taking most of the space
                Expanded(
                  child: PageView.builder(
                    itemCount: walkThroughClass.length,
                    controller: pageController,
                    onPageChanged: (int i) {
                      setState(() {
                        currentPage = i;
                        _resetAnimations();
                      });
                    },
                    itemBuilder: (context, i) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated image
                            AnimatedBuilder(
                              animation: _imageAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _imageAnimation.value,
                                  child: Opacity(
                                    opacity: _imageAnimation.value,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withAlpha(38),
                                      blurRadius: 30,
                                      offset: Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    walkThroughClass[i].img.toString(),
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    width: MediaQuery.of(context).size.width * 0.85,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 40),

                            // Animated text
                            AnimatedBuilder(
                              animation: _textAnimationController,
                              builder: (context, child) {
                                return FadeTransition(
                                  opacity: _textAnimation,
                                  child: SlideTransition(
                                    position: _slideAnimation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Text(
                                    walkThroughClass[i].name!,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      walkThroughClass[i].text.toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                        height: 1.5,
                                        letterSpacing: 0.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Bottom section with indicators and next button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: AnimatedBuilder(
                    animation: _buttonAnimationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _buttonAnimation,
                        child: child,
                      );
                    },
                    child: Column(
                      children: [
                        // Page indicators
                        _buildPageIndicator(),
                        SizedBox(height: 32),

                        // Next/Get Started button - full width modern button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              if (currentPage >= walkThroughClass.length - 1) {
                                launchScreen(context, SignInScreen(), isNewTask: true);
                                sharedPref.setBool(IS_FIRST_TIME, false);
                              } else {
                                pageController.animateToPage(
                                  currentPage + 1,
                                  duration: Duration(milliseconds: 600),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentPage >= walkThroughClass.length - 1 ? "التالي" : "التالي",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  currentPage >= walkThroughClass.length - 1
                                      ? Icons.login_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        walkThroughClass.length,
        (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 5),
          height: 8,
          width: currentPage == index ? 24 : 8,
          decoration: BoxDecoration(
            color: currentPage == index ? primaryColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
