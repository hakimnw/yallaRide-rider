import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../model/AppSettingModel.dart';
import '../network/RestApis.dart';
import '../utils/constant/app_colors.dart';
import '../utils/constant/styles/app_text_style.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  @override
  PrivacyPolicyScreenState createState() => PrivacyPolicyScreenState();
}

class PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool isLoading = true;
  PrivacyPolicyModel? privacyPolicy;

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

    // Fetch privacy policy data
    try {
      privacyPolicy = await getPrivacyPolicyApi();
    } catch (e) {
      print('Error fetching privacy policy: $e');
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
                        : privacyPolicy != null && privacyPolicy!.content != null
                            ? SingleChildScrollView(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (privacyPolicy!.title != null) ...[
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
                                              Icons.shield_outlined,
                                              color: AppColors.primary,
                                              size: 24,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                privacyPolicy!.title!,
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
                                        privacyPolicy!.content!,
                                        textStyle: AppTextStyles.sRegular14(color: AppColors.textColor),
                                      ),
                                    ),
                                    if (privacyPolicy!.updatedAt != null) ...[
                                      SizedBox(height: 16),
                                      Center(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withAlpha(25),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'آخر تحديث: ${privacyPolicy!.updatedAt}',
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
                                      'فشل تحميل سياسة الخصوصية',
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
                'سياسة الخصوصية',
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

  // Widget _buildHeaderCard() {
  //   return Container(
  //     margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
  //     padding: EdgeInsets.all(24),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           AppColors.primary.withAlpha(25),
  //           AppColors.primary.withAlpha(13),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(
  //         color: AppColors.primary.withAlpha(51),
  //         width: 1,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColors.primary.withAlpha(25),
  //           blurRadius: 20,
  //           offset: Offset(0, 8),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       children: [
  //         Container(
  //           padding: EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: AppColors.primary,
  //             shape: BoxShape.circle,
  //             boxShadow: [
  //               BoxShadow(
  //                 color: AppColors.primary.withAlpha(76),
  //                 blurRadius: 12,
  //                 offset: Offset(0, 4),
  //               ),
  //             ],
  //           ),
  //           child: Icon(
  //             MaterialCommunityIcons.shield_check,
  //             color: Colors.white,
  //             size: 28,
  //           ),
  //         ),
  //         SizedBox(height: 16),
  //         Text(
  //           'سياسة الخصوصية – تطبيق YallahRide',
  //           style: TextStyle(
  //             fontSize: 20,
  //             fontWeight: FontWeight.bold,
  //             color: AppColors.textColor,
  //           ),
  //           textAlign: TextAlign.center,
  //           textDirection: TextDirection.rtl,
  //         ),
  //         SizedBox(height: 8),
  //         Container(
  //           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //           decoration: BoxDecoration(
  //             color: AppColors.primary.withAlpha(25),
  //             borderRadius: BorderRadius.circular(20),
  //           ),
  //           child: Text(
  //             'آخر تحديث: 25 يونيو 2025',
  //             style: AppTextStyles.sMedium14(color: AppColors.primary),
  //           ),
  //         ),
  //         SizedBox(height: 16),
  //         Text(
  //           'نحن في YallahRide نحترم خصوصيتك وملتزمون بحماية بياناتك الشخصية. توضح هذه السياسة كيف نجمع، نستخدم، ونشارك معلوماتك عند استخدامك لتطبيقنا.',
  //           style: AppTextStyles.sRegular14(color: AppColors.textColor),
  //           textAlign: TextAlign.center,
  //           textDirection: TextDirection.rtl,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildSectionCard({
  //   required IconData icon,
  //   required String title,
  //   required String content,
  //   required List<String> items,
  // }) {
  //   return Container(
  //     margin: EdgeInsets.fromLTRB(20, 0, 20, 16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.06),
  //           blurRadius: 12,
  //           offset: Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Header
  //         Container(
  //           padding: EdgeInsets.all(20),
  //           decoration: BoxDecoration(
  //             color: AppColors.primary.withAlpha(13),
  //             borderRadius: BorderRadius.only(
  //               topLeft: Radius.circular(16),
  //               topRight: Radius.circular(16),
  //             ),
  //           ),
  //           child: Row(
  //             textDirection: TextDirection.rtl,
  //             children: [
  //               Container(
  //                 padding: EdgeInsets.all(10),
  //                 decoration: BoxDecoration(
  //                   color: AppColors.primary,
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 child: Icon(
  //                   icon,
  //                   color: Colors.white,
  //                   size: 20,
  //                 ),
  //               ),
  //               SizedBox(width: 12),
  //               Expanded(
  //                 child: Text(
  //                   title,
  //                   style: AppTextStyles.sSemiBold16(color: AppColors.textColor),
  //                   textAlign: TextAlign.right,
  //                   textDirection: TextDirection.rtl,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),

  //         // Content
  //         Padding(
  //           padding: EdgeInsets.all(20),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               if (content.isNotEmpty) ...[
  //                 Text(
  //                   content,
  //                   style: AppTextStyles.sRegular14(color: AppColors.textColor),
  //                   textAlign: TextAlign.right,
  //                   textDirection: TextDirection.rtl,
  //                 ),
  //                 if (items.isNotEmpty) SizedBox(height: 16),
  //               ],

  //               // Items
  //               ...items.map((item) => _buildBulletItem(item)).toList(),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildBulletItem(String text) {
  //   return Container(
  //     margin: EdgeInsets.only(bottom: 12),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       textDirection: TextDirection.rtl,
  //       children: [
  //         Container(
  //           margin: EdgeInsets.only(top: 8, left: 12),
  //           width: 6,
  //           height: 6,
  //           decoration: BoxDecoration(
  //             color: AppColors.primary,
  //             shape: BoxShape.circle,
  //           ),
  //         ),
  //         Expanded(
  //           child: Text(
  //             text,
  //             style: AppTextStyles.sRegular14(color: AppColors.textColor),
  //             textAlign: TextAlign.right,
  //             textDirection: TextDirection.rtl,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildContactCard() {
  //   return Container(
  //     margin: EdgeInsets.fromLTRB(20, 8, 20, 0),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //         colors: [
  //           AppColors.primary,
  //           AppColors.darkPrimary,
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(20),
  //       boxShadow: [
  //         BoxShadow(
  //           color: AppColors.primary.withAlpha(76),
  //           blurRadius: 20,
  //           offset: Offset(0, 8),
  //         ),
  //       ],
  //     ),
  //     child: Padding(
  //       padding: EdgeInsets.all(24),
  //       child: Column(
  //         children: [
  //           Row(
  //             textDirection: TextDirection.rtl,
  //             children: [
  //               Container(
  //                 padding: EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white.withAlpha(51),
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //                 child: Icon(
  //                   MaterialCommunityIcons.phone_outline,
  //                   color: Colors.white,
  //                   size: 24,
  //                 ),
  //               ),
  //               SizedBox(width: 16),
  //               Expanded(
  //                 child: Text(
  //                   '6. بيانات الاتصال',
  //                   style: TextStyle(
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.white,
  //                   ),
  //                   textAlign: TextAlign.right,
  //                   textDirection: TextDirection.rtl,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           SizedBox(height: 16),
  //           Text(
  //             'إذا كان لديك أي استفسارات بخصوص سياسة الخصوصية، يمكنك التواصل معنا عبر:',
  //             style: TextStyle(
  //               fontSize: 14,
  //               color: Colors.white.withAlpha(226),
  //             ),
  //             textAlign: TextAlign.center,
  //             textDirection: TextDirection.rtl,
  //           ),
  //           SizedBox(height: 20),

  //           // Contact Items
  //           _buildContactItem(
  //             icon: MaterialCommunityIcons.email_outline,
  //             label: 'البريد الإلكتروني',
  //             value: 'elreefyahmed257@gmail.com',
  //           ),
  //           SizedBox(height: 12),
  //           _buildContactItem(
  //             icon: MaterialCommunityIcons.phone_outline,
  //             label: 'الهاتف',
  //             value: '+201097051812',
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildContactItem({
  //   required IconData icon,
  //   required String label,
  //   required String value,
  // }) {
  //   return Container(
  //     padding: EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white.withAlpha(38),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: Colors.white.withAlpha(51),
  //         width: 1,
  //       ),
  //     ),
  //     child: Row(
  //       textDirection: TextDirection.rtl,
  //       children: [
  //         Icon(
  //           icon,
  //           color: Colors.white,
  //           size: 20,
  //         ),
  //         SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.end,
  //             children: [
  //               Text(
  //                 label,
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   color: Colors.white.withAlpha(201),
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //                 textDirection: TextDirection.rtl,
  //               ),
  //               SizedBox(height: 2),
  //               Text(
  //                 value,
  //                 style: TextStyle(
  //                   fontSize: 14,
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //                 textDirection: TextDirection.ltr,
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
