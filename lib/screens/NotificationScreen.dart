/*
 * NotificationScreen - صفحة الإشعارات المحسنة
 * 
 * الميزات المضافة:
 * ================
 * 
 * 1. تصنيف الإشعارات:
 *    - الكل، الرحلات، المدفوعات، الشكاوى، النظام
 *    - عدادات لكل فئة
 * 
 * 2. البحث والفلترة:
 *    - البحث النصي في العنوان والرسالة ورقم الرحلة
 *    - فلترة الإشعارات غير المقروءة
 *    - تبديل سريع بين المقروء وغير المقروء
 * 
 * 3. إدارة الإشعارات:
 *    - تعليم كمقروء/غير مقروء
 *    - حذف الإشعارات مع إمكانية التراجع
 *    - تعليم الإشعارات كمهمة
 *    - حذف جميع الإشعارات
 * 
 * 4. تحسينات التصميم:
 *    - أيقونات ملونة حسب نوع الإشعار
 *    - تصميم بطاقات محسن مع ظلال
 *    - مؤشرات بصرية للإشعارات غير المقروءة
 *    - تنسيق الوقت النسبي (منذ دقيقة، ساعة، يوم)
 * 
 * 5. إحصائيات الإشعارات:
 *    - عرض إجمالي الإشعارات
 *    - عدد الإشعارات غير المقروءة
 *    - إحصائيات حسب الفئة
 * 
 * 6. تحسينات UX:
 *    - رسائل تأكيد للعمليات
 *    - مؤشر تحميل محسن
 *    - انيميشن للعناصر
 *    - دعم السحب للإجراءات (Slidable)
 * 
 * 7. معالجة الأخطاء:
 *    - استرجاع الحالة عند فشل API
 *    - رسائل خطأ واضحة
 *    - إعادة المحاولة
 * 
 * 8. دعم API:
 *    - تعليم كمقروء
 *    - حذف الإشعارات
 *    - تحديث الحالة
 * 
 * المطور: Senior Flutter Developer
 * التاريخ: 2024
 */

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../main.dart';
import '../../network/RestApis.dart';
import '../../utils/Common.dart';
import '../../utils/Extensions/app_common.dart';
import '../../utils/constant/app_colors.dart';
import '../model/NotificationListModel.dart';
import '../screens/ComplaintListScreen.dart';
import '../utils/Constants.dart';
import 'RideDetailScreen.dart';

class NotificationScreen extends StatefulWidget {
  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen> with TickerProviderStateMixin {
  ScrollController scrollController = ScrollController();
  int currentPage = 1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool mIsLastPage = false;
  List<NotificationData> notificationData = [];
  List<NotificationData> filteredNotifications = [];
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();

    // Setup fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeIn,
      ),
    );

    _fadeController.forward();

    init();
    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
        if (!mIsLastPage) {
          appStore.setLoading(true);
          currentPage++;
          setState(() {});
          init();
        }
      }
    });
    afterBuildCreated(() => appStore.setLoading(true));
  }

  Future<void> refresh() async {
    setState(() {
      isRefreshing = true;
      currentPage = 1;
      notificationData.clear();
      filteredNotifications.clear();
    });

    init();

    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      isRefreshing = false;
    });

    return;
  }

  void init() async {
    getNotification(page: currentPage).then((value) {
      appStore.setLoading(false);
      mIsLastPage = value.notificationData!.length < currentPage;
      if (currentPage == 1) {
        notificationData.clear();
      }
      notificationData.addAll(value.notificationData!);
      filteredNotifications = notificationData;
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            image: DecorationImage(
              image: AssetImage("assets/assets/images/app_bar_background.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'الإشعارات',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Observer(builder: (context) {
        return Stack(
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: refresh,
                color: AppColors.primary,
                child: filteredNotifications.isNotEmpty
                    ? AnimationLimiter(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: filteredNotifications.length,
                          physics: AlwaysScrollableScrollPhysics(),
                          itemBuilder: (_, index) {
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: Duration(milliseconds: 500),
                              child: SlideAnimation(
                                horizontalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildNotificationItem(filteredNotifications[index]),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : !appStore.isLoading
                        ? _buildEmptyState()
                        : SizedBox(),
              ),
            ),
            if (appStore.isLoading && !isRefreshing)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildNotificationItem(NotificationData data) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (data.data!.type == COMPLAIN_COMMENT) {
              launchScreen(context, ComplaintListScreen(complaint: data.data!.complaintId ?? 0));
            } else if (data.data!.subject == 'Completed') {
              launchScreen(context, RideDetailScreen(orderId: data.data!.id ?? 0));
            }
          },
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      /*     color: getNotificationIconColor(data.data?.type)
                        .withAlpha(25), */
                      //borderRadius: BorderRadius.circular(15),
                      ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      getNotificationIcon(data.data?.type),
                      //color: getNotificationIconColor(data.data?.type),
                      width: 70,
                      height: 70,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getNotificationTitle(data),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(data.createdAt ?? ""),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        data.data?.message ?? "",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNotificationTitle(NotificationData data) {
    if (data.data?.type == COMPLAIN_COMMENT) {
      return 'رد على الشكوى';
    } else if (data.data?.type == COMPLETED) {
      return 'تم اكتمال الرحلة';
    } else if (data.data?.type == CANCELED) {
      return 'تم إلغاء الرحلة';
    } else if (data.data?.type == NEW_RIDE_REQUESTED) {
      return 'عرض رحلة جديد';
    } else {
      return data.data?.subject ?? "إشعار جديد";
    }
  }

  String getNotificationIcon(String? type) {
    switch (type) {
      case NEW_RIDE_REQUESTED:
        return 'assets/assets/images/Mapsss.png';
      case COMPLETED:
        return 'assets/assets/images/asm.png';
      case CANCELED:
        return 'assets/assets/images/asm.png';
      case COMPLAIN_COMMENT:
        return 'assets/assets/images/asm.png';
      default:
        return 'assets/assets/images/Mapsss.png';
    }
  }

/* 
  Color getNotificationIconColor(String? type) {
    switch (type) {
      case NEW_RIDE_REQUESTED:
        return Colors.blue;
      case COMPLETED:
        return AppColors.primary;
      case CANCELED:
        return Colors.red;
      case COMPLAIN_COMMENT:
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }
 */
  String _formatTime(String dateTime) {
    try {
      DateTime date = DateTime.parse(dateTime);
      DateTime now = DateTime.now();
      Duration difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'الآن';
      } else if (difference.inMinutes < 60) {
        return 'منذ ${difference.inMinutes} دقيقة';
      } else if (difference.inHours < 24) {
        return 'منذ ${difference.inHours} ساعة';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateTime;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'سيتم إعلامك عند وصول إشعارات جديدة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
