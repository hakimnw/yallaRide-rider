import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../model/AppSettingModel.dart';
import '../network/RestApis.dart';
import '../utils/constant/app_colors.dart';
import '../utils/constant/styles/app_text_style.dart';

class TermsAndConditionsScreen extends StatefulWidget {
  @override
  TermsAndConditionsScreenState createState() => TermsAndConditionsScreenState();
}

class TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool isLoading = true;
  PrivacyPolicyModel? termsAndConditions;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    // Fetch terms and conditions data
    try {
      termsAndConditions = await getTermsAndConditionsApi();
    } catch (e) {
      print('Error fetching terms and conditions: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Modern App Bar with gradient background
          _buildModernAppBar(),

          // Content
          Expanded(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        : termsAndConditions != null && termsAndConditions!.content != null
                            ? SingleChildScrollView(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (termsAndConditions!.title != null) ...[
                                      Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(25),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: AppColors.primary.withAlpha(51),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.description_outlined,
                                              color: AppColors.primary,
                                              size: 24,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                termsAndConditions!.title!,
                                                style: AppTextStyles.sSemiBold16(color: AppColors.primary),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                    ],
                                    Container(
                                      padding: EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(13),
                                            blurRadius: 10,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: HtmlWidget(
                                        termsAndConditions!.content!,
                                        textStyle: AppTextStyles.sRegular14(color: AppColors.textColor),
                                      ),
                                    ),
                                    if (termsAndConditions!.updatedAt != null) ...[
                                      SizedBox(height: 16),
                                      Center(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withAlpha(25),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'آخر تحديث: ${termsAndConditions!.updatedAt}',
                                            style: TextStyle(fontSize: 12, color: AppColors.primary),
                                          ),
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 20),
                                  ],
                                ),
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: AppColors.textColor.withAlpha(76),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'فشل تحميل الشروط والأحكام',
                                      style: AppTextStyles.sMedium16(color: AppColors.textColor),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'يرجى المحاولة مرة أخرى',
                                      style: AppTextStyles.sRegular14(
                                        color: AppColors.textColor.withAlpha(153),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.darkPrimary,
          ],
        ),
        image: DecorationImage(
          image: AssetImage("assets/assets/images/app_bar_background.png"),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Text(
                'الشروط والأحكام',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha(76),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
