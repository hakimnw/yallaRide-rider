import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/pages/chat_screen.dart' show ChatScreen;
import 'package:taxi_booking/utils/core/app_routes/navigation_service.dart';
import 'package:taxi_booking/utils/core/app_routes/router_names.dart';
import 'package:taxi_booking/utils/core/constant/app_icons.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/screens/settings/help/domain/entity/help_page_entity.dart';
import 'package:taxi_booking/screens/settings/settings_screen/presentation/widgets/list_title_widget.dart';

import '../../../../../utils/constant/app_colors.dart';

class PaymentSection extends StatelessWidget {
  const PaymentSection({super.key});
  final String content = '''نحن نعتذر بصدق عن الإزعاج.
في بعض الأحيان يتعين على الكباتن التعامل مع عوامل خارجة عن سيطرتهم مثل حركة المرور أو أعمال الطرق أو التحويلات.

إذا شعرت أن الكابتن كان غير مسؤول وتسبب في زيادة رسوم رحلتك، فيرجى الإبلاغ عن المشكلة أدناه.

يرجى التواصل معنا خلال 7 أيام من وقوع الحادث، وإلا فلن نتمكن من مراجعة الأسعار''';
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("الدفع", style: AppTextStyles.sSemiBold16()),
        const ResponsiveVerticalSpace(16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [BoxShadow(color: AppColors.black, blurRadius: 4, offset: Offset(0, 0), spreadRadius: 0)],
          ),
          child: Column(
            children: [
              CustomListTitleWidget(
                title: "مشكله في إنشاء محفظه",
                leading: SvgPicture.asset(
                  AppIcons.wallet,
                  colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                ),
                onTap: () {
                  NavigationService.pushNamed(
                    RouterNames.helperContactMessageScreen,
                    arguments: HelpPageEntity(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChatScreen()));
                      },
                      title: 'مشكله في إنشاء المحفظه',
                      content: content,
                    ),
                  );
                },
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "مشكله في شحن المحفظه",
                leading: SvgPicture.asset(
                  AppIcons.wallet,
                  colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                ),
                onTap: () {
                  NavigationService.pushNamed(
                    RouterNames.helperContactMessageScreen,
                    arguments: HelpPageEntity(
                      onTap: () {
                        NavigationService.pushNamed(RouterNames.chatScreen);
                      },
                      title: 'مشكله في شحن المحفظه',
                      content: content,
                    ),
                  );
                },
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "مشكله في إضافه بطاقه",
                onTap: () {
                  NavigationService.pushNamed(
                    RouterNames.helperContactMessageScreen,
                    arguments: HelpPageEntity(
                      onTap: () {
                        NavigationService.pushNamed(RouterNames.chatScreen);
                      },
                      title: 'مشكله في إضافه بطاقه',
                      content: content,
                    ),
                  );
                },
                leading: SvgPicture.asset(
                  AppIcons.visaCard,
                  colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                ),
              ),
              customDivider(),
              CustomListTitleWidget(
                title: "تواصل معانا",
                leading: SvgPicture.asset(
                  AppIcons.chat,
                  colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                ),
                onTap: () {
                  NavigationService.pushNamed(RouterNames.chatScreen);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget customDivider() => const Divider(indent: 16, endIndent: 16, height: 1);
}
