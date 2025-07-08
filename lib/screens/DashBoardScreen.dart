import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart' as lt;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../components/SearchLocationComponent.dart';
import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/NearByDriverListModel.dart';
import '../network/RestApis.dart';
import '../screens/ReviewScreen.dart';
import '../screens/RidePaymentDetailScreen.dart';
import '../screens/MainScreen.dart';
import '../service/RideService.dart';
import '../service/VersionServices.dart';
import '../utils/constant/app_colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import '../utils/Extensions/context_extension.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/images.dart';
import 'BidingScreen.dart';
import 'LocationPermissionScreen.dart';
import 'NewEstimateRideListWidget.dart';
import 'NotificationScreen.dart';
import 'ScheduleRideListScreen.dart';

class DashBoardScreen extends StatefulWidget {
  @override
  DashBoardScreenState createState() => DashBoardScreenState();
  String? cancelReason;

  DashBoardScreen({this.cancelReason});
}

class DashBoardScreenState extends State<DashBoardScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  RideService rideService = RideService();
  List<Marker> markers = [];
  Set<Polyline> _polyLines = Set<Polyline>();
  List<LatLng> polylineCoordinates = [];
  late PolylinePoints polylinePoints;
  OnRideRequest? servicesListData;
  double cameraZoom = 17.0, cameraTilt = 0;
  double cameraBearing = 30;
  int onTapIndex = 0;
  int selectIndex = 0;
  late StreamSubscription<ServiceStatus> serviceStatusStream;
  LocationPermission? permissionData;
  late BitmapDescriptor driverIcon;
  List<NearByDriverListModel>? nearDriverModel;
  GoogleMapController? mapController;
  PanelController panelController = PanelController();

  // Animation controllers
  late AnimationController _mapElementsAnimationController;
  late Animation<double> _mapElementsFadeAnimation;

  late AnimationController _panelAnimationController;
  late Animation<double> _panelScaleAnimation;

  late AnimationController _quickActionAnimationController;
  late Animation<Offset> _quickActionSlideAnimation;

  late AnimationController _headerAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  bool isMapReady = false;
  bool isFirstLoad = true;
  bool isSearchBarFocused = false;

  List<OnRideRequest> schedule_ride_request = [];

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _mapElementsAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _mapElementsFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _mapElementsAnimationController,
        curve: Curves.easeIn,
      ),
    );

    _panelAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _panelScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _panelAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _quickActionAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _quickActionSlideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _quickActionAnimationController,
        curve: Interval(0.3, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // Start animations
    Future.delayed(Duration(milliseconds: 150), () {
      _mapElementsAnimationController.forward();
      _headerAnimationController.forward();
    });

    Future.delayed(Duration(milliseconds: 600), () {
      _panelAnimationController.forward();
      _quickActionAnimationController.forward();
    });

    locationPermission();
    if (app_update_check != null) {
      VersionService().getVersionData(context, app_update_check);
    }
    if (widget.cancelReason != null) {
      afterBuildCreated(() {
        _triggerCanceledPopup();
      });
    } else {
      getCurrentRequest();
    }
    afterBuildCreated(() {
      init();
    });
  }

  void init() async {
    // Load location from SharedPreferences first for immediate display
    if (sharedPref.getDouble(LATITUDE) != null &&
        sharedPref.getDouble(LONGITUDE) != null) {
      sourceLocation = LatLng(
        sharedPref.getDouble(LATITUDE)!,
        sharedPref.getDouble(LONGITUDE)!,
      );
      setState(() {});
    }

    // Then get current location to update if needed
    getCurrentUserLocation();

    riderIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(
          devicePixelRatio: 2.5,
        ),
        Platform.isIOS ? SourceIOSIcon : SourceIcon);
    driverIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5),
        Platform.isIOS ? DriverIOSIcon : MultipleDriver);
    await getAppSettingsData();

    polylinePoints = PolylinePoints();
  }

  Future<void> getCurrentUserLocation() async {
    if (permissionData != LocationPermission.denied) {
      if (sourceLocation != null) {
        polylineSource =
            LatLng(sourceLocation!.latitude, sourceLocation!.longitude);
        addMarker();
        startLocationTracking();
        await getNearByDriver();
        return;
      }

      try {
        final geoPosition = await Geolocator.getCurrentPosition(
            timeLimit: Duration(seconds: 30),
            desiredAccuracy: LocationAccuracy.high);

        sourceLocation = LatLng(geoPosition.latitude, geoPosition.longitude);

        // Immediately update map camera to user's location
        if (mapController != null) {
          await mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(sourceLocation!, cameraZoom),
          );
        }

        try {
          List<Placemark>? placemarks = await placemarkFromCoordinates(
              geoPosition.latitude, geoPosition.longitude);
          await getNearByDriver();

          //set Country
          sharedPref.setString(COUNTRY,
              placemarks[0].isoCountryCode.validate(value: defaultCountry));

          Placemark place = placemarks[0];
          if (place != null) {
            sourceLocationTitle =
                "${place.name != null ? place.name : place.subThoroughfare}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}, ${place.country}";
            polylineSource =
                LatLng(geoPosition.latitude, geoPosition.longitude);
          }
        } catch (e) {
          print("Error getting placemark: $e");
        }

        addMarker();
        startLocationTracking();

        setState(() {});
      } catch (error) {
        print("Error getting current location: $error");
        launchScreen(navigatorKey.currentState!.overlay!.context,
            LocationPermissionScreen());
      }
    } else {
      launchScreen(navigatorKey.currentState!.overlay!.context,
          LocationPermissionScreen());
    }
  }

  Future<void> getCurrentRequest() async {
    await getCurrentRideRequest().then((value) async {
      servicesListData = value.rideRequest ?? value.onRideRequest;
      print("CHecking140");
      schedule_ride_request = value.schedule_ride_request ?? [];
      print("CHecking142");
      print("CHecking142::${schedule_ride_request.length}");
      if (servicesListData == null && schedule_ride_request.isNotEmpty) {
        schedule_ride_request.map(
          (e) => e.schedule_datetime,
        );

        var d1 = DateTime.parse(
            DateTime.now().toUtc().toString().replaceAll("Z", ""));
        var d2 = DateTime.parse(
            schedule_ride_request.first.schedule_datetime.toString());

        print("CheckBothDate:::D1:::$d1 ===>D2: $d2");
        print("CHecking148");
        print("CHecking148.2");
        if (d1.isAfter(d2)) {
          print("CHecking150::}");
          servicesListData = schedule_ride_request.first;
          print("CHecking161:::${servicesListData!.toJson()}");
        } else {
          scheduleFunction(
              scheduledTime: d2.add(Duration(seconds: 5)),
              function: () => getCurrentRequest());
        }
      }
      if (servicesListData == null) {
        sharedPref.remove(REMAINING_TIME);
        sharedPref.remove(IS_TIME);
        setState(() {});
      }
      print("169");
      if (servicesListData != null) {
        print("171");
        if ((value.ride_has_bids == 1) &&
            (servicesListData!.status == NEW_RIDE_REQUESTED ||
                servicesListData!.status == "bid_rejected")) {
          launchScreen(
            context,
            isNewTask: true,
            Bidingscreen(
              dt: servicesListData!.isSchedule == 1
                  ? servicesListData!.schedule_datetime
                  : servicesListData!.datetime,
              ride_id: servicesListData!.id!,
              source: {},
              endLocation: {},
              multiDropObj: {},
              multiDropLocationNamesObj: {},
            ),
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
          );
        } else if (servicesListData!.status != COMPLETED &&
            servicesListData!.status != CANCELED) {
          int x = 0;
          if (value.rideRequest == null && value.onRideRequest == null) {
            x = servicesListData!.id!;
          } else {
            x = value.rideRequest != null
                ? value.rideRequest!.id!
                : value.onRideRequest!.id!;
          }
          QuerySnapshot<Object?> b =
              await rideService.checkIsRideExist(rideId: x);
          if (b.docs.length > 0) {
            //   Check Condition so screen looping issue not occur
            //   if Ride Not exist in firebase than don't navigate to next screen
            launchScreen(
              getContext,
              NewEstimateRideListWidget(
                dt: servicesListData!.isSchedule == 1
                    ? servicesListData!.schedule_datetime
                    : servicesListData!.datetime,
                sourceLatLog: LatLng(
                    double.parse(servicesListData!.startLatitude!),
                    double.parse(servicesListData!.startLongitude!)),
                destinationLatLog: LatLng(
                    double.parse(servicesListData!.endLatitude!),
                    double.parse(servicesListData!.endLongitude!)),
                sourceTitle: servicesListData!.startAddress!,
                destinationTitle: servicesListData!.endAddress!,
                isCurrentRequest: true,
                servicesId: servicesListData!.serviceId,
                id: servicesListData!.id,
              ),
              pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
            );
          } else {
            if (value.schedule_ride_request != null &&
                value.schedule_ride_request!.isNotEmpty) {
              if (value.schedule_ride_request!.first.id == x) {
                return;
              }
            }
            return toast(rideNotFound);
          }
        } else if (servicesListData!.status == COMPLETED &&
            servicesListData!.isRiderRated == 0) {
          Future.delayed(
            Duration(seconds: 1),
            () {
              launchScreen(
                  getContext,
                  ReviewScreen(
                      rideRequest: servicesListData!, driverData: value.driver),
                  pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
                  isNewTask: true);
            },
          );
        }
      } else if (value.payment != null &&
          value.payment!.paymentStatus != "paid") {
        print("222");
        launchScreen(getContext,
            RidePaymentDetailScreen(rideId: value.payment!.rideRequestId),
            pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
            isNewTask: true);
      }
    }).catchError((error, s) {
      log(error.toString() + "::$s");
      print("CHecking200:::$error ===$s");
    });
  }

  Future<void> locationPermission() async {
    serviceStatusStream =
        Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.disabled) {
        launchScreen(navigatorKey.currentState!.overlay!.context,
            LocationPermissionScreen());
      } else if (status == ServiceStatus.enabled) {
        getCurrentUserLocation();
        if (locationScreenKey.currentContext != null) {
          if (Navigator.canPop(navigatorKey.currentState!.overlay!.context)) {
            Navigator.pop(navigatorKey.currentState!.overlay!.context);
          }
        }
      }
    }, onError: (error) {
      //
    });
  }

  addMarker() {
    // Clear existing user location markers
    markers.removeWhere((marker) => marker.markerId.value == 'Order Detail');

    if (sourceLocation != null) {
      markers.add(
        Marker(
          markerId: MarkerId('Order Detail'),
          position: sourceLocation!,
          draggable: true,
          infoWindow: InfoWindow(title: sourceLocationTitle, snippet: ''),
          icon: riderIcon,
        ),
      );
    }
  }

  Future<void> startLocationTracking() async {
    Map req = {
      "latitude": sourceLocation!.latitude.toString(),
      "longitude": sourceLocation!.longitude.toString(),
    };
    await updateStatus(req).then((value) {}).catchError((error) {
      log(error);
    });
  }

  Future<BitmapDescriptor> getNetworkImageMarker(String imageUrl) async {
    print("OPERATION111");
    final http.Response response = await http.get(Uri.parse(imageUrl));
    final Uint8List bytes = response.bodyBytes;

    // Load the image as a codec (which includes its dimensions)
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    print("OPERATION222");
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    print("OPERATION232");
    final ByteData? byteData =
        await frameInfo.image.toByteData(format: ui.ImageByteFormat.png);
    print("OPERATION232");
    final Uint8List resizedBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<void> getNearByDriver() async {
    await getNearByDriverList(latLng: sourceLocation).then((value) async {
      value.data!.forEach((element) async {
        print("CHECKIMAGE:::${element}");
        try {
          var driverIcon1 =
              await getNetworkImageMarker(element.service_marker.validate());
          markers.add(
            Marker(
              markerId: MarkerId('Driver${element.id}'),
              position: LatLng(double.parse(element.latitude!.toString()),
                  double.parse(element.longitude!.toString())),
              infoWindow: InfoWindow(
                  title: '${element.firstName} ${element.lastName}',
                  snippet: ''),
              icon: driverIcon1,
            ),
          );
          setState(() {});
        } catch (e, s) {
          markers.add(
            Marker(
              markerId: MarkerId('Driver${element.id}'),
              position: LatLng(double.parse(element.latitude!.toString()),
                  double.parse(element.longitude!.toString())),
              infoWindow: InfoWindow(
                  title: '${element.firstName} ${element.lastName}',
                  snippet: ''),
              icon: driverIcon,
            ),
          );
          setState(() {});
        }
      });
    }).catchError((e, s) {
      print("ERROR  FOUND:::$e ++++>$s");
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    LiveStream().on(CHANGE_LANGUAGE, (p0) {
      setState(() {});
    });
    return WillPopScope(
      onWillPop: () async {
        // عند الضغط على زر الرجوع، انتقل إلى HomeScreen (index 0) في MainScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MainScreen(initialIndex: 0),
          ),
          (route) => false,
        );
        return false; // منع السلوك الافتراضي للرجوع
      },
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Map as primary element with loading state
            sourceLocation == null &&
                    (sharedPref.getDouble(LATITUDE) == null ||
                        sharedPref.getDouble(LONGITUDE) == null)
                ? Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'جاري تحديد موقعك...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GoogleMap(
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: sourceLocation ??
                          LatLng(
                            sharedPref.getDouble(LATITUDE) ?? 24.7136,
                            sharedPref.getDouble(LONGITUDE) ?? 46.6753,
                          ),
                      zoom: cameraZoom,
                      bearing: cameraBearing,
                      tilt: cameraTilt,
                    ),
                    markers: markers.map((e) => e).toSet(),
                    polylines: _polyLines,
                    compassEnabled: false,
                    onMapCreated: (GoogleMapController controller) async {
                      mapController = controller;
                      setState(() {
                        isMapReady = true;
                      });

                      // If we have current location, move camera to it
                      if (sourceLocation != null) {
                        await Future.delayed(Duration(milliseconds: 500));
                        await controller.animateCamera(
                          CameraUpdate.newLatLngZoom(
                              sourceLocation!, cameraZoom),
                        );
                      }
                    },
                  ),

            // // Top status bar with user info - Modern design
            // Positioned(
            //   top: 0,
            //   left: 0,
            //   right: 0,
            //   child: FadeTransition(
            //     opacity: _headerFadeAnimation,
            //     child: SlideTransition(
            //       position: _headerSlideAnimation,
            //       child: Container(
            //         padding: EdgeInsets.fromLTRB(
            //             16, context.statusBarHeight + 16, 16, 16),
            //         decoration: BoxDecoration(
            //           gradient: LinearGradient(
            //             begin: Alignment.topCenter,
            //             end: Alignment.bottomCenter,
            //             colors: [
            //               Colors.black.withOpacity(0.6),
            //               Colors.black.withOpacity(0.3),
            //               Colors.transparent,
            //             ],
            //             stops: [0.0, 0.7, 1.0],
            //           ),
            //         ),
            //         child: Row(
            //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //           children: [
            //             // User profile and welcome message
            //             Row(
            //               children: [
            //                 Container(
            //                   height: 48,
            //                   width: 48,
            //                   decoration: BoxDecoration(
            //                     color: Colors.white,
            //                     shape: BoxShape.circle,
            //                     boxShadow: [
            //                       BoxShadow(
            //                         color: Colors.black.withOpacity(0.2),
            //                         blurRadius: 10,
            //                         offset: Offset(0, 4),
            //                       ),
            //                     ],
            //                     border: Border.all(color: Colors.white, width: 2),
            //                   ),
            //                   child: ClipRRect(
            //                     borderRadius: BorderRadius.circular(24),
            //                     child: appStore.userProfile.isNotEmpty
            //                         ? Image.network(
            //                             appStore.userProfile,
            //                             fit: BoxFit.cover,
            //                             errorBuilder:
            //                                 (context, error, stackTrace) {
            //                               return Icon(Icons.person,
            //                                   color: AppColors.primary, size: 30);
            //                             },
            //                           )
            //                         : Image.asset(
            //                             'assets/assets/placeholder.jpg',
            //                             fit: BoxFit.cover,
            //                             errorBuilder:
            //                                 (context, error, stackTrace) {
            //                               return Icon(Icons.person,
            //                                   color: AppColors.primary, size: 30);
            //                             },
            //                           ),
            //                   ),
            //                 ),
            //                 SizedBox(width: 12),
            //                 Column(
            //                   crossAxisAlignment: CrossAxisAlignment.start,
            //                   children: [
            //                     Text(
            //                       "Welcome,",
            //                       style: TextStyle(
            //                         color: Colors.white,
            //                         fontSize: 14,
            //                         fontWeight: FontWeight.w500,
            //                         shadows: [
            //                           Shadow(
            //                             color: Colors.black.withOpacity(0.3),
            //                             blurRadius: 4,
            //                             offset: Offset(0, 2),
            //                           ),
            //                         ],
            //                       ),
            //                     ),
            //                     SizedBox(height: 2),
            //                     Text(
            //                       appStore.firstName.isNotEmpty
            //                           ? appStore.firstName
            //                           : "User",
            //                       style: TextStyle(
            //                         color: Colors.white,
            //                         fontSize: 18,
            //                         fontWeight: FontWeight.bold,
            //                         shadows: [
            //                           Shadow(
            //                             color: Colors.black.withOpacity(0.3),
            //                             blurRadius: 4,
            //                             offset: Offset(0, 2),
            //                           ),
            //                         ],
            //                       ),
            //                       maxLines: 1,
            //                       overflow: TextOverflow.ellipsis,
            //                     ),
            //                   ],
            //                 ),
            //               ],
            //             ),
            //
            //             // Notification button
            //             Container(
            //               height: 48,
            //               width: 48,
            //               decoration: BoxDecoration(
            //                 color: Colors.white.withOpacity(0.2),
            //                 shape: BoxShape.circle,
            //                 border: Border.all(
            //                     color: Colors.white.withOpacity(0.4), width: 1.5),
            //                 boxShadow: [
            //                   BoxShadow(
            //                     color: Colors.black.withOpacity(0.2),
            //                     blurRadius: 8,
            //                     offset: Offset(0, 2),
            //                   ),
            //                 ],
            //               ),
            //               child: Material(
            //                 color: Colors.transparent,
            //                 shape: CircleBorder(),
            //                 child: InkWell(
            //                   borderRadius: BorderRadius.circular(24),
            //                   onTap: () {
            //                     launchScreen(context, NotificationScreen());
            //                   },
            //                   child: Icon(MaterialCommunityIcons.bell_outline,
            //                       color: Colors.white, size: 24),
            //                 ),
            //               ),
            //             ),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            // Location input cards - Modern floating cards
            Positioned(
              top: context.statusBarHeight + 20,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _mapElementsFadeAnimation,
                child: Column(
                  children: [
                    // Current location card
                    Container(
                      margin: EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              builder: (_) => SearchLocationComponent(
                                  title: sourceLocationTitle),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.my_location,
                                      color: AppColors.primary, size: 22),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    sourceLocationTitle != null &&
                                            sourceLocationTitle.isNotEmpty
                                        ? sourceLocationTitle.length > 30
                                            ? '${sourceLocationTitle.substring(0, 30)}...'
                                            : sourceLocationTitle
                                        : language.whatWouldYouLikeToGo,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Destination input card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                              ),
                              builder: (_) => SearchLocationComponent(
                                  title: sourceLocationTitle),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.search,
                                      color: Colors.grey.shade700, size: 22),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    language.enterYourDestination,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
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
              ),
            ),

            // Map control buttons
            Positioned(
              bottom: schedule_ride_request.isNotEmpty ? 90 : 24,
              right: 16,
              child: FadeTransition(
                opacity: _mapElementsFadeAnimation,
                child: Column(
                  children: [
                    // My location button
                    Container(
                      margin: EdgeInsets.only(bottom: 12),
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () async {
                            try {
                              // Get fresh current location
                              final geoPosition =
                                  await Geolocator.getCurrentPosition(
                                timeLimit: Duration(seconds: 10),
                                desiredAccuracy: LocationAccuracy.high,
                              );

                              final currentLocation = LatLng(
                                  geoPosition.latitude, geoPosition.longitude);

                              // Update global sourceLocation
                              sourceLocation = currentLocation;

                              // Save to SharedPreferences
                              sharedPref.setDouble(
                                  LATITUDE, geoPosition.latitude);
                              sharedPref.setDouble(
                                  LONGITUDE, geoPosition.longitude);

                              // Move map camera
                              if (mapController != null) {
                                await mapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      currentLocation, cameraZoom),
                                );
                              }

                              // Update markers
                              addMarker();
                              setState(() {});
                            } catch (error) {
                              print("Error getting current location: $error");
                              // Fallback to existing location if available
                              if (sourceLocation != null &&
                                  mapController != null) {
                                mapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      sourceLocation!, cameraZoom),
                                );
                              }
                            }
                          },
                          child:
                              Icon(Icons.my_location, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom panel for scheduled rides - Modern glass effect card
            if (schedule_ride_request.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: SlideTransition(
                  position: _quickActionSlideAnimation,
                  child: ScaleTransition(
                    scale: _panelScaleAnimation,
                    child: GestureDetector(
                      onTap: () {
                        launchScreen(context, ScheduleRideListScreen());
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              spreadRadius: 1,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.schedule,
                                  color: AppColors.primary, size: 24),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    language.schedule_list_title,
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "${schedule_ride_request.length} ${language.schedule_list_title}",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.arrow_forward,
                                  color: AppColors.primary, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _triggerCanceledPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "${language.rideCanceledByDriver}",
                  maxLines: 2,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.close, size: 20, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${language.cancelledReason}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.cancelReason.validate(),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size(double.infinity, 48),
                ),
                child: Text(
                  "موافق",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          contentPadding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        );
      },
    );
  }

  Future<void> cancelRequest(String reason, {int? ride_id}) async {
    Map req = {
      "id": ride_id,
      "cancel_by": RIDER,
      "status": CANCELED,
      "reason": reason,
    };
    await rideRequestUpdate(request: req, rideId: ride_id).then((value) async {
      getCurrentRequest();
      toast(value.message);
    }).catchError((error) {});
  }

  @override
  void dispose() {
    _mapElementsAnimationController.dispose();
    _panelAnimationController.dispose();
    _quickActionAnimationController.dispose();
    _headerAnimationController.dispose();
    if (serviceStatusStream != null) {
      serviceStatusStream.cancel();
    }
    super.dispose();
  }
}
