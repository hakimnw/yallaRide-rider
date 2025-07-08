import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:lottie/lottie.dart';

import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/AlertScreen.dart';
import '../screens/ChatScreen.dart';
import '../screens/MainScreen.dart';
import '../service/ChatMessagesService.dart';
import '../service/ZegoService.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'CancelOrderDialog.dart';
import 'RideCompletionNotification.dart';

class RideAcceptWidget extends StatefulWidget {
  final Driver? driverData;
  final OnRideRequest? rideRequest;

  RideAcceptWidget({this.driverData, this.rideRequest});

  @override
  RideAcceptWidgetState createState() => RideAcceptWidgetState();
}

class RideAcceptWidgetState extends State<RideAcceptWidget> {
  UserModel? userData;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    await getUserDetail(userId: widget.rideRequest!.driverId).then((value) {
      sharedPref.remove(IS_TIME);
      appStore.setLoading(false);
      userData = value.data;
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> cancelRequest(String reason) async {
    Map req = {
      "id": widget.rideRequest!.id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: widget.rideRequest!.id)
        .then((value) async {
      toast(value.message);
      chatMessageService.justDeleteChat(
        senderId: sharedPref.getString(UID).validate(),
        receiverId: userData!.uid.validate(),
      );
    }).catchError((error) {
      try {
        chatMessageService.justDeleteChat(
          senderId: sharedPref.getString(UID).validate(),
          receiverId: userData!.uid.validate(),
        );
      } catch (e) {}
      log(error.toString());
    });
  }

  Future<void> completeRide({bool? cashPayment}) async {
    Map req = {
      "id": widget.rideRequest!.id,
      "status": COMPLETED,
    };

    // Add cash payment information if specified
    if (cashPayment == true) {
      req["payment_type"] = "cash";
      req["payment_status"] = "paid";
    }

    appStore.setLoading(true);
    await rideRequestUpdate(request: req, rideId: widget.rideRequest!.id)
        .then((value) async {
      appStore.setLoading(false);

      // Show beautiful completion notification
      showRideCompletionNotification(
        context,
        rideId: widget.rideRequest!.id.toString(),
      );

      // Navigate back to dashboard after a short delay
      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainScreen(initialIndex: 1),
          ),
          (route) => false,
        );
      });
    }).catchError((error) {
      appStore.setLoading(false);
      toast(error.toString());
      log(error.toString());
    });
  }

  /// Handle driver call with Zego integration
  Future<void> _handleDriverCall() async {
    try {
      if (widget.driverData?.contactNumber == null ||
          widget.driverData!.contactNumber!.isEmpty) {
        toast("رقم الهاتف غير متوفر");
        return;
      }

      // Show loading while checking/initializing Zego
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري التحقق من اتصال Zego...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Check and ensure Zego connection
      bool zegoReady = await _ensureZegoConnection();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show call options dialog
      String? callType = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "اختر نوع المكالمة",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("كيف تريد الاتصال بالسائق؟"),
                SizedBox(height: 12),
                // Zego status indicator
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: zegoReady
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: zegoReady ? Colors.green : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        zegoReady ? Icons.check_circle : Icons.warning,
                        color: zegoReady ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          zegoReady
                              ? 'Zego متصل - مكالمات فيديو متاحة'
                              : 'Zego غير متصل - سيتم استخدام الهاتف العادي',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!zegoReady) ...[
                  SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _handleDriverCall(); // Retry
                    },
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('إعادة المحاولة'),
                    style: TextButton.styleFrom(foregroundColor: primaryColor),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text("إلغاء"),
              ),
              if (zegoReady) ...[
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop('voice'),
                  icon: Icon(Icons.phone, size: 16),
                  label: Text("صوت"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop('video'),
                  icon: Icon(Icons.videocam, size: 16),
                  label: Text("فيديو"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: primaryColor),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop('phone'),
                  icon: Icon(Icons.phone, size: 16),
                  label: Text("اتصال"),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ],
          );
        },
      );

      if (callType != null) {
        bool callSuccess = false;

        switch (callType) {
          case 'video':
            callSuccess = await zegoService.initiateVideoCall(
              driverPhoneNumber: widget.driverData!.contactNumber!,
              context: context,
              driverName:
                  "${widget.driverData!.firstName ?? ''} ${widget.driverData!.lastName ?? ''}"
                      .trim(),
            );
            break;
          case 'voice':
            callSuccess = await zegoService.initiateVoiceCall(
              driverPhoneNumber: widget.driverData!.contactNumber!,
              context: context,
              driverName:
                  "${widget.driverData!.firstName ?? ''} ${widget.driverData!.lastName ?? ''}"
                      .trim(),
            );
            break;
          case 'phone':
            final Uri phoneUri =
                Uri.parse('tel:${widget.driverData!.contactNumber}');
            if (await canLaunchUrl(phoneUri)) {
              await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
              callSuccess = true;
            }
            break;
        }

        if (callSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                callType == 'phone'
                    ? 'تم فتح تطبيق الهاتف'
                    : 'تم إرسال دعوة المكالمة',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (error) {
      print('Error in _handleDriverCall: $error');
      toast("حدث خطأ أثناء إجراء المكالمة");
    }
  }

  /// Ensure Zego connection is ready with retry logic
  Future<bool> _ensureZegoConnection() async {
    try {
      print("${DateTime.now()}: Checking Zego connection...");

      // If already connected, return true immediately
      if (zegoService.isInitialized && zegoService.isLoggedIn) {
        print("${DateTime.now()}: Zego already connected and ready");
        return true;
      }

      // Step 1: Check if SDK is initialized
      if (!zegoService.isInitialized) {
        print("${DateTime.now()}: SDK not initialized, initializing...");
        bool initResult = await zegoService.initializeZegoSDK();
        if (!initResult) {
          print("${DateTime.now()}: Failed to initialize SDK");
          return false;
        }

        // Add small delay after initialization
        await Future.delayed(Duration(milliseconds: 500));
      }

      // Step 2: Check if user is logged in
      if (!zegoService.isLoggedIn) {
        print(
            "${DateTime.now()}: User not logged into Zego, attempting login...");

        // Check if app user is authenticated
        if (!appStore.isLoggedIn || appStore.userPhone.isEmpty) {
          print("${DateTime.now()}: App user not authenticated");
          return false;
        }

        // Attempt login with retry logic
        bool loginResult = false;
        int maxRetries = 3;
        int attempt = 0;

        while (!loginResult && attempt < maxRetries) {
          attempt++;
          print("${DateTime.now()}: Zego login attempt $attempt/$maxRetries");

          try {
            loginResult = await zegoService.loginToZego(
              userID: appStore.userPhone,
              userName: appStore.userName.isNotEmpty
                  ? appStore.userName
                  : appStore.firstName,
            );

            if (loginResult) {
              print(
                  "${DateTime.now()}: Zego login successful on attempt $attempt");
              break;
            } else {
              print("${DateTime.now()}: Zego login failed on attempt $attempt");
              if (attempt < maxRetries) {
                // Wait before retrying
                await Future.delayed(Duration(milliseconds: 1000 * attempt));
              }
            }
          } catch (e) {
            print(
                "${DateTime.now()}: Zego login error on attempt $attempt: $e");
            if (attempt < maxRetries) {
              await Future.delayed(Duration(milliseconds: 1000 * attempt));
            }
          }
        }

        if (!loginResult) {
          print(
              "${DateTime.now()}: Failed to login to Zego after $maxRetries attempts");
          return false;
        }
      }

      // Step 3: Final verification with timeout
      print(
          "${DateTime.now()}: Performing final Zego connection verification...");

      // Wait a bit for connection to stabilize
      await Future.delayed(Duration(milliseconds: 500));

      bool isReady = zegoService.isInitialized && zegoService.isLoggedIn;
      print("${DateTime.now()}: Zego connection check result: $isReady");

      return isReady;
    } catch (error) {
      print("${DateTime.now()}: Error ensuring Zego connection: $error");
      return false;
    }
  }

  void _showCompleteRideDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "إكمال الرحلة",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      "Complete Ride",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "هل أنت متأكد من إكمال هذه الرحلة؟",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Are you sure you want to complete this ride?",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.green[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "سيتم إضافة هذه الرحلة إلى قائمة الرحلات المكتملة\nThis ride will be added to completed rides list",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "إلغاء / Cancel",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                completeRide();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                "إكمال / Complete",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCashPaymentCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payments,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "إكمال الرحلة - دفع نقدي",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    /*  Text(
                      "Complete Ride - Cash Payment",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ), */
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "هل تم دفع المبلغ نقدياً للسائق؟",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              /*       Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.money,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "تأكد من دفع المبلغ المطلوب للسائق قبل إكمال الرحلة\nMake sure to pay the required amount to the driver before completing",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
           */
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "إلغاء / Cancel",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                completeRide(cashPayment: true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                "نعم، تم الدفع / Yes, Paid",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              alignment: Alignment.center,
              height: 5,
              width: 70,
              decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(defaultRadius)),
            ),
          ),
          SizedBox(height: 12),
          Align(
            alignment: Alignment.topLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                inkWellWidget(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          contentPadding: EdgeInsets.all(0),
                          content: AlertScreen(
                              rideId: widget.rideRequest!.id,
                              regionId: widget.rideRequest!.regionId),
                        );
                      },
                    );
                  },
                  child: chatCallWidget(Icons.sos),
                ),
                SizedBox(width: 8),
                inkWellWidget(
                  onTap: () => _handleDriverCall(),
                  child: chatCallWidget(Icons.call),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                      color: primaryColor, borderRadius: radius()),
                  child: InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ImageIcon(
                          AssetImage(statusTypeIcon(
                              type: widget.rideRequest!.status.validate())),
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(
                          width: 4,
                        ),
                        Text(
                            statusName(
                                status: widget.rideRequest!.status.validate()),
                            style: boldTextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.driverData!.driverService!.name.validate(),
                        style: boldTextStyle()),
                    SizedBox(height: 2),
                    Observer(
                      builder: (context) => Row(
                        children: [
                          Text("تكلفة الرحلة  ", style: secondaryTextStyle()),
                          Text(
                            appStore.selectedTripTotalAmount > 0
                                ? '${appStore.selectedTripTotalAmount.toStringAsFixed(2)} ${appStore.currencyCode}'
                                : (widget.rideRequest!.subtotal != null
                                    ? '${widget.rideRequest!.subtotal!.toStringAsFixed(2)} ${appStore.currencyCode}'
                                    : (widget.rideRequest!.totalAmount != null
                                        ? '${widget.rideRequest!.totalAmount!.toStringAsFixed(2)} ${appStore.currencyCode}'
                                        : 'غير محدد')),
                            style: boldTextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: widget.rideRequest!.status != IN_PROGRESS &&
                    widget.rideRequest!.status != COMPLETED,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      border: Border.all(color: dividerColor),
                      borderRadius: radius(defaultRadius)),
                  child: Text(
                      '${language.otp} ${widget.rideRequest!.otp ?? ''}',
                      style: boldTextStyle()),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(defaultRadius),
                child: commonCachedNetworkImage(
                    widget.driverData!.profileImage.validate(),
                    fit: BoxFit.cover,
                    height: 40,
                    width: 40),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        '${widget.driverData!.firstName.validate()} ${widget.driverData!.lastName.validate()}',
                        style: boldTextStyle()),
                    SizedBox(height: 2),
                    Text('${widget.driverData!.email.validate()}',
                        style: secondaryTextStyle()),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.near_me, color: Colors.green, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          widget.rideRequest!.startAddress ?? ''.validate(),
                          style: primaryTextStyle(size: 14),
                          maxLines: 2)),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 8),
                  SizedBox(
                    height: 24,
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
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(widget.rideRequest!.endAddress ?? '',
                          style: primaryTextStyle(size: 14), maxLines: 2)),
                ],
              ),
              if (widget.rideRequest!.multiDropLocation?.isNotEmpty == true)
                Row(
                  children: [
                    SizedBox(width: 8),
                    SizedBox(
                      height: 24,
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
              if (widget.rideRequest!.multiDropLocation?.isNotEmpty == true)
                AppButtonWidget(
                  textColor: primaryColor,
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  height: 30,
                  shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(defaultRadius),
                      side: BorderSide(color: primaryColor)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add,
                        color: primaryColor,
                        size: 12,
                      ),
                      Text(
                        language.viewMore,
                        style: primaryTextStyle(size: 14),
                      ),
                    ],
                  ),
                  onTap: () {
                    showOnlyDropLocationsDialog(
                        context,
                        widget.rideRequest!.multiDropLocation!
                            .map(
                              (e) => e.address,
                            )
                            .toList());
                  },
                )
            ],
          ),
          SizedBox(height: 16),
          // Complete ride button when ride is in progress
          if (widget.rideRequest!.status == IN_PROGRESS)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "الرحلة قيد التنفيذ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            /*  Text(
                              "Ride in Progress",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ), */
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  AppButtonWidget(
                    width: MediaQuery.of(context).size.width,
                    text: "إكمال الرحلة / Complete Ride",
                    color: Colors.white,
                    textColor: Colors.green[700],
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      _showCompleteRideDialog();
                    },
                  ),
                ],
              ),
            ),
          if (widget.rideRequest!.status != IN_PROGRESS
              ? widget.rideRequest!.status != COMPLETED
              : false)
            AppButtonWidget(
                width: MediaQuery.of(context).size.width,
                text: language.cancel,
                textColor: primaryColor,
                color: Colors.white,
                shapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    side: BorderSide(color: primaryColor)),
                onTap: () {
                  showModalBottomSheet(
                      context: context,
                      isDismissible: false,
                      isScrollControlled: true,
                      builder: (context) {
                        return CancelOrderDialog(
                          onCancel: (reason) async {
                            Navigator.pop(context);
                            appStore.setLoading(true);
                            sharedPref.remove(REMAINING_TIME);
                            sharedPref.remove(IS_TIME);
                            await cancelRequest(reason);
                            appStore.setLoading(false);
                          },
                        );
                      });
                }),

          // Complete Ride with Cash Payment Button
          if (widget.rideRequest!.status != COMPLETED) SizedBox(height: 12),
          if (widget.rideRequest!.status != COMPLETED)
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[700]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(defaultRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(defaultRadius),
                  onTap: () {
                    _showCashPaymentCompleteDialog();
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "إكمال الرحلة - دفع نقدي",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget chatCallWidget(IconData icon, {bool chat = false}) {
    if (sharedPref.getString(UID) != null && chat == true) {
      return Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                border: Border.all(color: dividerColor),
                color: appStore.isDarkMode
                    ? scaffoldColorDark
                    : scaffoldColorLight,
                borderRadius: BorderRadius.circular(defaultRadius)),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          StreamBuilder<int>(
              stream: chatMessageService.getUnReadCount(
                  senderId: "${sharedPref.getString(UID)}",
                  receiverId: widget.driverData!.uid.toString()),
              builder: (context, snapshot) {
                if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data! > 0) {
                  return Positioned(
                      top: -2,
                      right: 0,
                      child: Lottie.asset(messageDetect,
                          width: 18, height: 18, fit: BoxFit.cover));
                }
                return SizedBox();
              })
        ],
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: dividerColor),
            color: appStore.isDarkMode ? scaffoldColorDark : scaffoldColorLight,
            borderRadius: BorderRadius.circular(defaultRadius)),
        child: Icon(icon, size: 18, color: primaryColor),
      );
    }
  }
}

void showOnlyDropLocationsDialog(
    BuildContext context, List<String> dropLocations) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          language.viewDropLocations,
          style: primaryTextStyle(size: 18, weight: FontWeight.w500),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: dropLocations.map((location) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(location ?? ''.validate(),
                              style: primaryTextStyle(size: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2)),
                    ],
                  ),
                  Divider(
                    height: 10,
                  )
                ],
              );
            }).toList(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              language.close,
              style: primaryTextStyle(),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        ],
      );
    },
  );
}
