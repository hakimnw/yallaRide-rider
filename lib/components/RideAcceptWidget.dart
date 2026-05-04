import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/LoginResponse.dart';
import '../network/RestApis.dart';
import '../screens/AlertScreen.dart';
import '../screens/MainScreen.dart';
import '../screens/settings/wallet_screens/presentation/providers/wallet_provider.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/constant/app_colors.dart';
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
    await rideRequestUpdate(request: req, rideId: widget.rideRequest!.id).then((value) async {
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
    // Determine payment type from ride request or parameter
    String paymentType = cashPayment == true ? CASH : (widget.rideRequest!.paymentType ?? CASH);

    Map req = {
      "id": widget.rideRequest!.id,
      "status": COMPLETED,
      "payment_type": paymentType,
    };

    // Handle payment based on type
    if (paymentType == WALLET) {
      // For wallet payments, we need to process the payment
      req["payment_status"] = "paid";

      // Get the ride amount
      num rideAmount = widget.rideRequest!.totalAmount ?? widget.rideRequest!.subtotal ?? appStore.selectedTripTotalAmount;

      if (rideAmount <= 0) {
        toast("مبلغ الرحلة غير صحيح");
        return;
      }

      // Check wallet balance before proceeding - ENSURE SUFFICIENT FUNDS
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.refresh(); // Ensure we have latest balance

      // Log balance check for debugging
      log('Wallet balance check - Balance: ${walletProvider.balance}, Ride Amount: $rideAmount');

      // CRITICAL: Check if wallet has sufficient balance (>= ride amount)
      if (walletProvider.balance == null) {
        toast("خطأ في تحميل رصيد المحفظة. يرجى المحاولة مرة أخرى");
        return;
      }

      if (walletProvider.balance! < rideAmount) {
        toast(
            "رصيد المحفظة غير كافي لإكمال الرحلة. المطلوب: ${rideAmount.toStringAsFixed(2)} ${appStore.currencyCode}, المتاح: ${walletProvider.balance!.toStringAsFixed(2)} ${appStore.currencyCode}");
        log('Insufficient wallet balance - Required: $rideAmount, Available: ${walletProvider.balance}');
        return;
      }

      // SUCCESS: Wallet has sufficient balance, proceed with payment
      log('Wallet balance sufficient - proceeding with payment');

      appStore.setLoading(true);

      try {
        // First complete the ride
        await rideRequestUpdate(request: req, rideId: widget.rideRequest!.id);

        // Then process wallet payment via savePayment API
        Map paymentReq = {
          "id": widget.rideRequest!.id,
          "rider_id": sharedPref.getInt(USER_ID).toString(),
          "ride_request_id": widget.rideRequest!.id,
          "datetime": DateTime.now().toString(),
          "total_amount": rideAmount.toString(),
          "payment_type": WALLET,
          "txn_id": "",
          "payment_status": "paid",
          "transaction_detail": "Ride completion payment"
        };

        await savePayment(paymentReq);

        // Refresh wallet balance after successful payment
        await walletProvider.refresh();

        appStore.setLoading(false);

        // Show success notification
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
      } catch (error) {
        appStore.setLoading(false);
        log('Error completing ride with wallet payment: $error');

        // Try to refresh wallet balance on error
        try {
          await walletProvider.refresh();
        } catch (e) {
          log('Error refreshing wallet after payment failure: $e');
        }

        toast("فشل في إكمال الرحلة: ${error.toString()}");
      }
    } else {
      // For cash payments, just mark as paid
      req["payment_status"] = "paid";

      appStore.setLoading(true);
      await rideRequestUpdate(request: req, rideId: widget.rideRequest!.id).then((value) async {
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
        toast("فشل في إكمال الرحلة: ${error.toString()}");
        log(error.toString());
      });
    }
  }

  /// Handle driver call with Zego integration
  Future<void> _handleDriverCall() async {
    try {
      if (widget.driverData?.contactNumber == null || widget.driverData!.contactNumber!.isEmpty) {
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
                    color: zegoReady ? AppColors.primary.withAlpha(25) : Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: zegoReady ? AppColors.primary : Colors.orange,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        zegoReady ? Icons.check_circle : Icons.warning,
                        color: zegoReady ? AppColors.primary : Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          zegoReady ? 'Zego متصل - مكالمات فيديو متاحة' : 'Zego غير متصل - سيتم استخدام الهاتف العادي',
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
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop('phone'),
                  icon: Icon(Icons.phone, size: 16),
                  label: Text("اتصال"),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
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
              driverName: "${widget.driverData!.firstName ?? ''} ${widget.driverData!.lastName ?? ''}".trim(),
            );
            break;
          case 'voice':
            callSuccess = await zegoService.initiateVoiceCall(
              driverPhoneNumber: widget.driverData!.contactNumber!,
              context: context,
              driverName: "${widget.driverData!.firstName ?? ''} ${widget.driverData!.lastName ?? ''}".trim(),
            );
            break;
          case 'phone':
            final Uri phoneUri = Uri.parse('tel:${widget.driverData!.contactNumber}');
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
                callType == 'phone' ? 'تم فتح تطبيق الهاتف' : 'تم إرسال دعوة المكالمة',
              ),
              backgroundColor: AppColors.primary,
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
        print("${DateTime.now()}: User not logged into Zego, attempting login...");

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
              userName: appStore.userName.isNotEmpty ? appStore.userName : appStore.firstName,
            );

            if (loginResult) {
              print("${DateTime.now()}: Zego login successful on attempt $attempt");
              break;
            } else {
              print("${DateTime.now()}: Zego login failed on attempt $attempt");
              if (attempt < maxRetries) {
                // Wait before retrying
                await Future.delayed(Duration(milliseconds: 1000 * attempt));
              }
            }
          } catch (e) {
            print("${DateTime.now()}: Zego login error on attempt $attempt: $e");
            if (attempt < maxRetries) {
              await Future.delayed(Duration(milliseconds: 1000 * attempt));
            }
          }
        }

        if (!loginResult) {
          print("${DateTime.now()}: Failed to login to Zego after $maxRetries attempts");
          return false;
        }
      }

      // Step 3: Final verification with timeout
      print("${DateTime.now()}: Performing final Zego connection verification...");

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
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
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
                        color: AppColors.primary,
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
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withAlpha(76)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "سيتم إضافة هذه الرحلة إلى قائمة الرحلات المكتملة\nThis ride will be added to completed rides list",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
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
                backgroundColor: AppColors.primary,
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
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payments,
                  color: AppColors.primary,
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
                        color: AppColors.primary,
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
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withAlpha(76)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.money,
                      color: Colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "تأكد من دفع المبلغ المطلوب للسائق قبل إكمال الرحلة\nMake sure to pay the required amount to the driver before completing",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
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
                backgroundColor: AppColors.primary,
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

  void _showWalletCompleteRideDialog() async {
    // Get ride amount for display
    num rideAmount = widget.rideRequest!.totalAmount ?? widget.rideRequest!.subtotal ?? appStore.selectedTripTotalAmount;

    // Get current wallet balance
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await walletProvider.refresh(); // Ensure latest balance

    num currentBalance = walletProvider.balance ?? 0;
    bool hasSufficientBalance = currentBalance >= rideAmount;

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
                  color: hasSufficientBalance ? Colors.blue.withAlpha(25) : Colors.red.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasSufficientBalance ? Icons.account_balance_wallet : Icons.warning,
                  color: hasSufficientBalance ? Colors.blue : Colors.red,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "إكمال الرحلة - دفع من المحفظة",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasSufficientBalance ? Colors.blue : Colors.red,
                      ),
                    ),
                    Text(
                      "Complete Ride - Wallet Payment",
                      style: TextStyle(
                        fontSize: 12,
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
              // Wallet Balance Display
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: hasSufficientBalance ? AppColors.primary.withAlpha(25) : Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: hasSufficientBalance ? AppColors.primary.withAlpha(76) : Colors.red.withAlpha(76)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "رصيد المحفظة الحالي:",
                          style: TextStyle(
                            fontSize: 14,
                            color: hasSufficientBalance ? AppColors.primary : Colors.red,
                          ),
                        ),
                        Text(
                          "${currentBalance.toStringAsFixed(2)} ${appStore.currencyCode}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: hasSufficientBalance ? AppColors.primary : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "مبلغ الرحلة:",
                          style: TextStyle(
                            fontSize: 14,
                            color: hasSufficientBalance ? Colors.blue : Colors.red,
                          ),
                        ),
                        Text(
                          "${rideAmount.toStringAsFixed(2)} ${appStore.currencyCode}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: hasSufficientBalance ? Colors.blue : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (hasSufficientBalance) ...[
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "الرصيد المتبقي:",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            "${(currentBalance - rideAmount).toStringAsFixed(2)} ${appStore.currencyCode}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 12),
              if (!hasSufficientBalance) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withAlpha(76)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "رصيد المحفظة غير كافي! يرجى شحن المحفظة أولاً.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],
              Text(
                hasSufficientBalance
                    ? "هل أنت متأكد من إكمال الرحلة وخصم المبلغ من المحفظة؟"
                    : "يرجى شحن المحفظة لإكمال الرحلة.",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
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
            if (hasSufficientBalance)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  completeRide(); // Will handle wallet payment automatically
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  "تأكيد وإكمال / Confirm & Complete",
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
              decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(defaultRadius)),
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
                          content: AlertScreen(rideId: widget.rideRequest!.id, regionId: widget.rideRequest!.regionId),
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
                  decoration: BoxDecoration(color: primaryColor, borderRadius: radius()),
                  child: InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ImageIcon(
                          AssetImage(statusTypeIcon(type: widget.rideRequest!.status.validate())),
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(
                          width: 4,
                        ),
                        Text(statusName(status: widget.rideRequest!.status.validate()),
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
                    Text(widget.driverData!.driverService!.name.validate(), style: boldTextStyle()),
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
                            style: boldTextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: widget.rideRequest!.status != IN_PROGRESS && widget.rideRequest!.status != COMPLETED,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(border: Border.all(color: dividerColor), borderRadius: radius(defaultRadius)),
                  child: Text('${language.otp} ${widget.rideRequest!.otp ?? ''}', style: boldTextStyle()),
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
                child: commonCachedNetworkImage(widget.driverData!.profileImage.validate(),
                    fit: BoxFit.cover, height: 40, width: 40),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${widget.driverData!.firstName.validate()} ${widget.driverData!.lastName.validate()}',
                        style: boldTextStyle()),
                    SizedBox(height: 2),
                    Text('${widget.driverData!.email.validate()}', style: secondaryTextStyle()),
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
                  Icon(Icons.near_me, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                      child: Text(widget.rideRequest!.startAddress ?? ''.validate(),
                          style: primaryTextStyle(size: 14), maxLines: 2)),
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
                      child: Text(widget.rideRequest!.endAddress ?? '', style: primaryTextStyle(size: 14), maxLines: 2)),
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
                      borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: primaryColor)),
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
                  colors: [AppColors.primary, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(76),
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
                          color: Colors.white.withAlpha(51),
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
                            Text(
                              widget.rideRequest!.paymentType == WALLET ? "سيتم الخصم من المحفظة" : "الدفع نقدي للسائق",
                              style: TextStyle(
                                color: Colors.white.withAlpha(226),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  AppButtonWidget(
                    width: MediaQuery.of(context).size.width,
                    text: widget.rideRequest!.paymentType == WALLET
                        ? "إكمال الرحلة - دفع من المحفظة"
                        : "إكمال الرحلة / Complete Ride",
                    color: Colors.white,
                    textColor: AppColors.primary,
                    shapeBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      if (widget.rideRequest!.paymentType == WALLET) {
                        _showWalletCompleteRideDialog();
                      } else {
                        _showCompleteRideDialog();
                      }
                    },
                  ),
                ],
              ),
            ),

          // Complete Ride with Payment Button (for non-in-progress rides)
          if (widget.rideRequest!.status != COMPLETED && widget.rideRequest!.status != IN_PROGRESS)
            Container(
              margin: EdgeInsets.only(bottom: 12),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(defaultRadius),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(76),
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
                    if (widget.rideRequest!.paymentType == WALLET) {
                      _showWalletCompleteRideDialog();
                    } else {
                      _showCashPaymentCompleteDialog();
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.rideRequest!.paymentType == WALLET ? Icons.account_balance_wallet : Icons.payments,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          widget.rideRequest!.paymentType == WALLET
                              ? "إكمال الرحلة - دفع من المحفظة"
                              : "إكمال الرحلة - دفع نقدي",
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
          if (widget.rideRequest!.status != IN_PROGRESS ? widget.rideRequest!.status != COMPLETED : false)
            AppButtonWidget(
                width: MediaQuery.of(context).size.width,
                text: language.cancel,
                textColor: primaryColor,
                color: Colors.white,
                shapeBorder: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: primaryColor)),
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
                color: appStore.isDarkMode ? scaffoldColorDark : scaffoldColorLight,
                borderRadius: BorderRadius.circular(defaultRadius)),
            child: Icon(icon, size: 18, color: primaryColor),
          ),
          StreamBuilder<int>(
              stream: chatMessageService.getUnReadCount(
                  senderId: "${sharedPref.getString(UID)}", receiverId: widget.driverData!.uid.toString()),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null && snapshot.data! > 0) {
                  return Positioned(
                      top: -2, right: 0, child: Lottie.asset(messageDetect, width: 18, height: 18, fit: BoxFit.cover));
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

void showOnlyDropLocationsDialog(BuildContext context, List<String> dropLocations) {
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
                      Icon(Icons.location_on, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text((location).validate(),
                              style: primaryTextStyle(size: 14), overflow: TextOverflow.ellipsis, maxLines: 2)),
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
