import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_booking/utils/Extensions/dataTypeExtensions.dart';
import 'package:taxi_booking/utils/images.dart';

import '../main.dart';
import '../network/RestApis.dart';
import '../service/RideService.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import 'CancelOrderDialog.dart';
import 'DriverAcceptanceNotification.dart';
import 'DriverSelectionScreen.dart';

class BookingWidget extends StatefulWidget {
  final bool isLast;
  final int? id;
  final String? dt;

  BookingWidget({required this.id, this.isLast = false, this.dt});

  @override
  BookingWidgetState createState() => BookingWidgetState();
}

class BookingWidgetState extends State<BookingWidget> with TickerProviderStateMixin {
  RideService rideService = RideService();
  final int timerMaxSeconds = appStore.rideMinutes != null ? int.parse(appStore.rideMinutes!) * 60 : 5 * 60;

  int currentSeconds = 0;
  int count = 0;
  Timer? timer;
  Timer? statusCheckTimer;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? d2;
  int duration = 0;
  bool _isCheckingStatus = false;
  bool called = false;

  String get timerText =>
      '${((duration - currentSeconds) ~/ 60).toString().padLeft(2, '0')}: ${((duration - currentSeconds) % 60).toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();

    init();

    // Start checking ride status immediately
    Future.delayed(Duration(milliseconds: 1000), () {
      if (mounted) {
        _startStatusChecking();
      }
    });
  }

  void init() async {
    print(REMAINING_TIME);
    print(IS_TIME);
    if (sharedPref.getString(IS_TIME) == null) {
      duration = timerMaxSeconds;
      startTimeout();
      sharedPref.setString(IS_TIME, DateTime.now().add(Duration(seconds: timerMaxSeconds)).toString());
      sharedPref.setString(REMAINING_TIME, timerMaxSeconds.toString());
    } else {
      duration = DateTime.parse(sharedPref.getString(IS_TIME)!).difference(DateTime.now()).inSeconds;
      if (duration > 0) {
        startTimeout();
      } else {
        sharedPref.remove(IS_TIME);
        duration = timerMaxSeconds;
        setState(() {});
        startTimeout();
      }
    }
  }

  // Check ride status periodically to detect driver acceptance
  void _startStatusChecking() {
    if (_isCheckingStatus) return;
    _isCheckingStatus = true;

    // Check every 1 second for faster response
    statusCheckTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        final currentRequest = await getCurrentRideRequest();
        final rideRequest = currentRequest.rideRequest ?? currentRequest.onRideRequest;

        if (rideRequest != null) {
          // Check for any acceptance status
          bool isAccepted = rideRequest.status == ACCEPTED ||
              rideRequest.status == BID_ACCEPTED ||
              rideRequest.status == ARRIVING ||
              rideRequest.status == ARRIVED ||
              rideRequest.status == IN_PROGRESS;

          if (isAccepted) {
            // Driver accepted the ride!
            timer.cancel();
            _isCheckingStatus = false;

            // Add a small delay to ensure UI is ready
            Future.delayed(Duration(milliseconds: 500), () {
              _showDriverAcceptedMessage();
            });
            return;
          }

          // Also check if ride was cancelled
          if (rideRequest.status == CANCELED) {
            timer.cancel();
            _isCheckingStatus = false;
            if (mounted) {
              toast("تم إلغاء الطلب / Request was cancelled");
              Navigator.of(context).pop();
            }
            return;
          }
        }
      } catch (e) {
        print('Error checking ride status: $e');
        // Continue checking even if there's an error
      }
    });
  }

  void _showDriverAcceptedMessage() async {
    if (!mounted) return;

    // Stop all timers immediately
    statusCheckTimer?.cancel();
    timer?.cancel();

    // Clear timing preferences
    sharedPref.remove(REMAINING_TIME);
    sharedPref.remove(IS_TIME);

    try {
      // Get driver information for the notification
      final currentRequest = await getCurrentRideRequest();
      final rideRequest = currentRequest.rideRequest ?? currentRequest.onRideRequest;

      String? driverName;

      if (rideRequest?.driverId != null) {
        try {
          final driverData = await getUserDetail(userId: rideRequest!.driverId);
          if (driverData.data != null) {
            final firstName = driverData.data!.firstName?.trim() ?? '';
            final lastName = driverData.data!.lastName?.trim() ?? '';
            if (firstName.isNotEmpty || lastName.isNotEmpty) {
              driverName = "$firstName $lastName".trim();
            }
          }
        } catch (e) {
          print('Error getting driver info: $e');
        }
      }

      // Show the beautiful notification
      showDriverAcceptanceNotification(
        context,
        driverName: driverName,
        duration: Duration(seconds: 3),
      );

      // Navigate to driver selection screen after 2 seconds
      Future.delayed(Duration(seconds: 2), () {
        if (mounted && rideRequest != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DriverSelectionScreen(
                rideRequestId: widget.id!,
                sourceTitle: rideRequest.startAddress ?? '',
                destinationTitle: rideRequest.endAddress ?? '',
                sourceLatLog: LatLng(
                  double.parse(rideRequest.startLatitude ?? '0'),
                  double.parse(rideRequest.startLongitude ?? '0'),
                ),
                destinationLatLog: LatLng(
                  double.parse(rideRequest.endLatitude ?? '0'),
                  double.parse(rideRequest.endLongitude ?? '0'),
                ),
                dt: rideRequest.datetime,
              ),
            ),
          );
        }
      });
    } catch (e) {
      print('Error showing driver acceptance: $e');
      // Fallback: just navigate to driver selection
      Future.delayed(Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => DriverSelectionScreen(
                rideRequestId: widget.id!,
                sourceTitle: 'موقع الانطلاق',
                destinationTitle: 'الوجهة',
                sourceLatLog: LatLng(0, 0),
                destinationLatLog: LatLng(0, 0),
                dt: widget.dt,
              ),
            ),
          );
        }
      });
    }
  }

  startTimeout() {
    if (called == true) return;
    called = true;
    if (widget.dt != null) {
      DateTime? d1 = DateTime.tryParse(widget.dt.validate());
      if (d1 != null) {
        setState(
          () {
            d2 = d1.add(Duration(seconds: timerMaxSeconds));
          },
        );
        print("CheckDateTimedafjfkljf:::${d2}");
        return;
      }
    }
    return;
    // var duration2 = Duration(seconds: 1);
    // timer = Timer.periodic(duration2, (timer) {
    //   setState(
    //     () {
    //       currentSeconds = timer.tick;
    //       count++;
    //       if (count >= 60) {
    //         int data = int.parse(sharedPref.getString(REMAINING_TIME)!);
    //         data = data - count;
    //         Map req = {
    //           'max_time_for_find_driver_for_ride_request': data,
    //         };
    //         rideRequestUpdate(request: req, rideId: widget.id).then((value) {
    //           //
    //         }).catchError((error) {
    //           log(error.toString());
    //         });
    //         sharedPref.setString(REMAINING_TIME, data.toString());
    //         count = 0;
    //       }
    //       if (timer.tick >= duration) {
    //         timer.cancel();
    //         Map req = {
    //           'status': CANCELED,
    //           'cancel_by': AUTO,
    //           "reason": "Ride is auto cancelled",
    //         };
    //         appStore.setLoading(true);
    //         rideRequestUpdate(request: req, rideId: widget.id).then((value) async {
    //           appStore.setLoading(false);
    //           toast(language.noNearByDriverFound);
    //           sharedPref.remove(REMAINING_TIME);
    //           sharedPref.remove(IS_TIME);
    //         }).catchError((error) {
    //           appStore.setLoading(false);
    //           log(error.toString());
    //         });
    //       }
    //     },
    //   );
    // });
  }

  Future<void> cancelRequest(String? reason) async {
    Map req = {
      "id": widget.id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: widget.id).then((value) async {
      toast(value.message);
    }).catchError((error) {
      log(error.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    // Stop all timers and animations
    statusCheckTimer?.cancel();
    timer?.cancel();

    // Clear status checking flag
    _isCheckingStatus = false;

    // Clear any remaining preferences if needed
    if (sharedPref.containsKey(IS_TIME)) {
      sharedPref.remove(IS_TIME);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Stack(
        children: [
          // Main booking content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(language.lookingForNearbyDrivers, style: boldTextStyle()),
                  if (d2 != null)
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: primaryColor, borderRadius: radius(8)),
                        child: StreamBuilder(
                          stream: Stream.periodic(Duration(seconds: 1)),
                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                            if (d2 != null &&
                                d2!
                                    .difference(DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", "")))
                                    .isNegative) {
                              Map req = {
                                'status': CANCELED,
                                'cancel_by': AUTO,
                                "reason": "Ride is auto cancelled",
                              };
                              d2 = null;
                              print("AutoCancelFunctionCall:::::");
                              appStore.setLoading(true);
                              rideRequestUpdate(request: req, rideId: widget.id).then((value) async {
                                appStore.setLoading(false);
                                toast(language.noNearByDriverFound);
                                sharedPref.remove(REMAINING_TIME);
                                sharedPref.remove(IS_TIME);
                              }).catchError((error) {
                                appStore.setLoading(false);
                                log(error.toString());
                              });
                            }
                            if (d2 != null &&
                                d2!
                                    .difference(DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", "")))
                                    .isNegative) return Text("--:--", style: boldTextStyle(color: Colors.white));
                            if (d2 == null) return Text("--:--", style: boldTextStyle(color: Colors.white));
                            return Text(
                                (d2!
                                                .difference(
                                                    DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", "")))
                                                .inSeconds /
                                            60)
                                        .toInt()
                                        .toString()
                                        .padLeft(2, "0") +
                                    ":" +
                                    (d2!
                                                .difference(
                                                    DateTime.parse(DateTime.now().toUtc().toString().replaceAll("Z", "")))
                                                .inSeconds %
                                            60)
                                        .toString()
                                        .padLeft(2, "0")
                                        .toString(),
                                style: boldTextStyle(color: Colors.white));
                          },
                        ))
                ],
              ),
              SizedBox(height: 8),
              Lottie.asset(bookingAnim, height: 100, width: MediaQuery.of(context).size.width, fit: BoxFit.contain),
              SizedBox(height: 20),
              Text(language.weAreLookingForNearDriversAcceptsYourRide,
                  style: primaryTextStyle(), textAlign: TextAlign.center),
              SizedBox(height: 16),
              AppButtonWidget(
                width: MediaQuery.of(context).size.width,
                text: language.cancel,
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
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
