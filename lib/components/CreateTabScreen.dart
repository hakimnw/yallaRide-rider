import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../main.dart';
import '../../network/RestApis.dart';
import '../../screens/RideDetailScreen.dart';
import '../model/RiderModel.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/constant/app_colors.dart';

class CreateTabScreen extends StatefulWidget {
  final String? status;

  CreateTabScreen({this.status});

  @override
  CreateTabScreenState createState() => CreateTabScreenState();
}

class CreateTabScreenState extends State<CreateTabScreen> {
  ScrollController scrollController = ScrollController();
  int currentPage = 1;
  int totalPage = 1;
  List<RiderModel> riderData = [];
  List<String> riderStatus = [COMPLETED, CANCELED];

  @override
  void initState() {
    super.initState();
    init();
    scrollController.addListener(() {
      try {
        if (scrollController.hasClients &&
            scrollController.position.pixels == scrollController.position.maxScrollExtent &&
            !appStore.isLoading &&
            mounted) {
          if (currentPage < totalPage) {
            appStore.setLoading(true);
            currentPage++;
            getRideList();
            setState(() {});
          }
        }
      } catch (e) {
        log('خطأ في مستمع التمرير: ${e.toString()}');
      }
    });
    afterBuildCreated(() => appStore.setLoading(true));
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  void init() async {
    getRideList();
  }

  getRideList() async {
    try {
      // التأكد من وجود USER_ID
      int? userId = sharedPref.getInt(USER_ID);
      if (userId == null) {
        appStore.setLoading(false);
        log('خطأ: معرف المستخدم غير موجود');
        return;
      }

      await getRiderRequestList(page: currentPage, status: widget.status, riderId: userId).then((value) {
        // التحقق من صحة الاستجابة
        if (value.pagination != null) {
          currentPage = value.pagination!.currentPage ?? 1;
          totalPage = value.pagination!.totalPages ?? 1;
        } else {
          currentPage = 1;
          totalPage = 1;
        }

        if (currentPage == 1) {
          riderData.clear();
        }

        // إضافة البيانات مع التحقق من صحتها
        if (value.data != null && value.data!.isNotEmpty) {
          // فلترة البيانات الصالحة فقط
          List<RiderModel> validData = value.data!.where((item) => item.id != null && item.id! > 0).toList();

          if (validData.isNotEmpty) {
            riderData.addAll(validData);
          }
        }

        appStore.setLoading(false);
        if (mounted) {
          setState(() {});
        }
      }).catchError((error) {
        appStore.setLoading(false);
        log('خطأ في API: ${error.toString()}');
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      appStore.setLoading(false);
      log('خطأ غير متوقع: ${e.toString()}');
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Observer(builder: (context) {
        return RefreshIndicator(
          onRefresh: () async {
            currentPage = 1;
            await getRideList();
          },
          child: Stack(
            children: [
              if (riderData.isNotEmpty)
                AnimationLimiter(
                  child: ListView.builder(
                      itemCount: riderData.length,
                      controller: scrollController,
                      padding: EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
                      itemBuilder: (_, index) {
                        RiderModel data = riderData[index];
                        // التأكد من صحة البيانات قبل العرض
                        if (data.id == null || data.id! <= 0) {
                          return SizedBox.shrink();
                        }
                        return AnimationConfiguration.staggeredList(
                          delay: Duration(milliseconds: 200),
                          position: index,
                          duration: Duration(milliseconds: 300),
                          child: SlideAnimation(
                            child: IntrinsicHeight(child: rideCardWidget(data: data)),
                          ),
                        );
                      }),
                )
              else if (!appStore.isLoading)
                // عرض رسالة عدم وجود بيانات
                SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.status == COMPLETED ? Icons.check_circle_outline : Icons.cancel_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 24),
                          Text(
                            widget.status == COMPLETED
                                ? 'لا توجد رحلات مكتملة'
                                : widget.status == CANCELED
                                    ? 'لا توجد رحلات ملغية'
                                    : 'لا توجد رحلات',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'اسحب للأسفل للتحديث',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // مؤشر التحميل
              if (appStore.isLoading) Center(child: loaderWidget()),
            ],
          ),
        );
      }),
    );
  }

  Widget rideCardWidget({required RiderModel data}) {
    return inkWellWidget(
      onTap: () {
        // منطق التنقل المحسن لجميع حالات الرحلة باستثناء الملغية
        if (data.id != null && data.id! > 0) {
          if (data.status == CANCELED) {
            // عرض رسالة للرحلات الملغية
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'لا يمكن عرض تفاصيل الرحلة الملغية',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: EdgeInsets.all(16),
                ),
              );
            }
          } else {
            // التنقل إلى تفاصيل الرحلة لجميع الحالات الأخرى بما في ذلك المكتملة
            try {
              // إضافة تأثير اهتزاز للتفاعل
              HapticFeedback.lightImpact();

              // عرض مؤشر التحميل لتحسين تجربة المستخدم
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            data.status == COMPLETED
                                ? 'جاري تحميل تفاصيل الرحلة المكتملة...'
                                : 'جاري تحميل تفاصيل الرحلة...',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: data.status == COMPLETED ? AppColors.primary : primaryColor,
                    duration: Duration(milliseconds: 1500),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.all(16),
                  ),
                );
              }

              // التنقل إلى شاشة تفاصيل الرحلة
              launchScreen(context, RideDetailScreen(orderId: data.id!),
                  pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
            } catch (e) {
              log('خطأ في التنقل: ${e.toString()}');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'حدث خطأ أثناء فتح تفاصيل الرحلة',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.all(16),
                  ),
                );
              }
            }
          }
        } else {
          // التعامل مع معرف الرحلة غير الصالح
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.warning_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'معرف الرحلة غير صالح',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.all(16),
              ),
            );
          }
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: EdgeInsets.only(top: 8, bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: data.status == COMPLETED
                ? AppColors.primary.withOpacity(0.4)
                : data.status == CANCELED
                    ? Colors.red.withAlpha(76)
                    : dividerColor,
            width: data.status == COMPLETED || data.status == CANCELED ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(defaultRadius),
          color: data.status == COMPLETED
              ? AppColors.primary.withOpacity(0.08)
              : data.status == CANCELED
                  ? Colors.red.withAlpha(13)
                  : Colors.white,
          boxShadow: [
            BoxShadow(
              color: data.status == COMPLETED
                  ? AppColors.primary.withAlpha(38)
                  : data.status == CANCELED
                      ? Colors.red.withAlpha(25)
                      : Colors.grey.withAlpha(25),
              blurRadius: data.status == COMPLETED ? 12 : 8,
              offset: Offset(0, data.status == COMPLETED ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Row(
                    children: [
                      Icon(Ionicons.calendar, color: textSecondaryColorGlobal, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text('${printDate(data.createdAt.validate())}',
                              style: primaryTextStyle(size: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // مؤشر الحالة المحسن
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: data.status == COMPLETED
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : data.status == CANCELED
                            ? LinearGradient(
                                colors: [Colors.red, Colors.red.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [primaryColor, primaryColor.withAlpha(201)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: (data.status == COMPLETED
                                ? AppColors.primary
                                : data.status == CANCELED
                                    ? Colors.red
                                    : primaryColor)
                            .withAlpha(76),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.status == COMPLETED
                            ? Icons.check_circle
                            : data.status == CANCELED
                                ? Icons.cancel
                                : Icons.info,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        data.status == COMPLETED
                            ? 'مكتملة'
                            : data.status == CANCELED
                                ? 'ملغية'
                                : changeStatusText(data.status.validate()),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 16, thickness: 0.5),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.near_me, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(data.startAddress.validate(), style: primaryTextStyle(size: 14), maxLines: 2)),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      SizedBox(width: 13),
                      SizedBox(
                        height: 34,
                        child: DottedLine(
                          direction: Axis.vertical,
                          lineLength: double.infinity,
                          lineThickness: 1,
                          dashLength: 2,
                          dashColor: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Expanded(child: Text(data.endAddress.validate(), style: primaryTextStyle(size: 14), maxLines: 2)),
                    ],
                  ),
                ],
              ),
            ),
            // إضافة وقت الإكمال للرحلات المكتملة مع تحسينات بصرية
            if (data.status == COMPLETED)
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withAlpha(38),
                      AppColors.primary.withOpacity(0.08),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(25),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(76),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "✅ تم إكمال الرحلة بنجاح",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "اضغط هنا لعرض جميع التفاصيل والفاتورة",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(51),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            // إضافة معلومات إضافية للرحلات الملغية
            if (data.status == CANCELED)
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withAlpha(25),
                      Colors.red.withAlpha(13),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withAlpha(76), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        Icons.cancel,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "❌ تم إلغاء هذه الرحلة",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red[800],
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "لا يمكن عرض تفاصيل الرحلات الملغية",
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.block,
                      color: Colors.red[600],
                      size: 16,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
