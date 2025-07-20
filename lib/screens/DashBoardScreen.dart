import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert'; // Added for json.decode

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

  // Location state management
  bool isMapReady = false;
  bool isFirstLoad = true;
  bool isSearchBarFocused = false;
  bool isLocationLoading = false;
  String? currentLocationAddress;
  String? selectedDestination;

  List<OnRideRequest> schedule_ride_request = [];

  @override
  void initState() {
    super.initState();

    print("🚀 DashBoardScreen initState started");

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

    // Initialize location services first
    _initializeLocationServices();

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

  // New method to initialize location services with better error handling
  Future<void> _initializeLocationServices() async {
    print("🔧 Initializing location services...");

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print("🔍 Location services enabled: $serviceEnabled");

      if (!serviceEnabled) {
        print("❌ Location services are disabled");
        setState(() {
          currentLocationAddress = "موقعك الحالي";
          sourceLocationTitle = "موقعك الحالي";
        });
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      print("🔐 Current permission status: $permission");

      if (permission == LocationPermission.denied) {
        print("🔐 Requesting location permission...");
        permission = await Geolocator.requestPermission();
        print("🔐 Permission after request: $permission");
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("❌ Location permission denied or denied forever");
        setState(() {
          currentLocationAddress = "موقعك الحالي";
          sourceLocationTitle = "موقعك الحالي";
        });
        return;
      }

      permissionData = permission;
      print("✅ Location services initialized successfully");

      // Start location permission monitoring
      locationPermission();
    } catch (e) {
      print("❌ Error initializing location services: $e");
      setState(() {
        currentLocationAddress = "موقعك الحالي";
        sourceLocationTitle = "موقعك الحالي";
      });
    }
  }

  void init() async {
    print("🚀 Starting init()...");

    // Initialize icons first to avoid late initialization errors
    try {
      print("🎨 Loading icons...");
      // Initialize global riderIcon from main.dart
      riderIcon = await BitmapDescriptor.fromAssetImage(
          ImageConfiguration(
            devicePixelRatio: 2.5,
          ),
          Platform.isIOS ? SourceIOSIcon : SourceIcon);
      driverIcon = await BitmapDescriptor.fromAssetImage(
          ImageConfiguration(devicePixelRatio: 2.5),
          Platform.isIOS ? DriverIOSIcon : MultipleDriver);
      print("✅ Icons loaded successfully");
    } catch (e) {
      print("⚠️ Error loading icons: $e");
      // Use default markers if icons fail to load
      riderIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
      driverIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      print("✅ Using default icons");
    }

    // Load location from SharedPreferences first for immediate display
    print("📱 Checking saved location...");
    double? savedLat = sharedPref.getDouble(LATITUDE);
    double? savedLng = sharedPref.getDouble(LONGITUDE);
    print("  - Saved lat: $savedLat");
    print("  - Saved lng: $savedLng");

    if (savedLat != null && savedLng != null) {
      sourceLocation = LatLng(savedLat, savedLng);
      print(
          "✅ Using saved location: ${sourceLocation!.latitude}, ${sourceLocation!.longitude}");
      setState(() {});
    } else {
      // Set default location if no saved location
      sourceLocation = LatLng(24.7136, 46.6753); // Default to Riyadh
      polylineSource = sourceLocation!;
      print(
          "⚠️ Using default location: ${sourceLocation!.latitude}, ${sourceLocation!.longitude}");
    }

    // Then get current location to update if needed
    print("📍 Getting current user location...");
    await getCurrentUserLocation();

    // إذا كان لدينا إحداثيات، احصل على العنوان تلقائياً
    if (sourceLocation != null) {
      print("🔍 Auto-filling address on screen load...");
      String autoAddress = await _getFullAddressFromCoordinates(
          sourceLocation!.latitude, sourceLocation!.longitude);
      setState(() {
        currentLocationAddress = autoAddress;
        sourceLocationTitle = autoAddress;
      });
      print("✅ Auto-filled address: '$autoAddress'");

      // تحديث الواجهة مرة أخرى للتأكد من العرض
      await Future.delayed(Duration(milliseconds: 100));
      setState(() {});
    }

    print("⚙️ Getting app settings...");
    await getAppSettingsData();

    polylinePoints = PolylinePoints();
    print("✅ init() completed successfully");
    print("📊 Final state:");
    print(
        "  - sourceLocation: ${sourceLocation?.latitude}, ${sourceLocation?.longitude}");
    print("  - currentLocationAddress: '$currentLocationAddress'");
    print("  - sourceLocationTitle: '$sourceLocationTitle'");
  }

  Future<void> getCurrentUserLocation() async {
    print("🔍 Starting getCurrentUserLocation...");
    print("🔐 Current permission: ${permissionData?.toString() ?? 'NULL'}");

    // Check permission first
    if (permissionData == LocationPermission.denied ||
        permissionData == LocationPermission.deniedForever) {
      print("❌ Location permission denied");
      setState(() {
        currentLocationAddress = "موقعك الحالي";
        sourceLocationTitle = "موقعك الحالي";
        isLocationLoading = false;
      });
      return;
    }

    // If we already have a saved location, use it initially
    if (sourceLocation != null) {
      print(
          "📍 Using existing location: ${sourceLocation!.latitude}, ${sourceLocation!.longitude}");
      polylineSource =
          LatLng(sourceLocation!.latitude, sourceLocation!.longitude);
      addMarker();
      startLocationTracking();
      await getNearByDriver();
      return;
    }

    setState(() {
      isLocationLoading = true;
    });

    try {
      print("🔄 Getting current position...");

      // Try different location settings for better compatibility with emulator
      late Position geoPosition;

      try {
        // First try with high accuracy (for real devices)
        geoPosition = await Geolocator.getCurrentPosition(
          timeLimit: Duration(seconds: 15),
          desiredAccuracy: LocationAccuracy.high,
        );
        print("✅ Got high accuracy position");
      } catch (e) {
        print("⚠️ High accuracy failed, trying medium accuracy: $e");
        try {
          // Fallback to medium accuracy (better for emulator)
          geoPosition = await Geolocator.getCurrentPosition(
            timeLimit: Duration(seconds: 10),
            desiredAccuracy: LocationAccuracy.medium,
          );
          print("✅ Got medium accuracy position");
        } catch (e2) {
          print("⚠️ Medium accuracy failed, trying last known position: $e2");
          // Last resort: try to get last known position
          Position? lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            geoPosition = lastPosition;
            print("✅ Got last known position");
          } else {
            // If everything fails, use a default location (e.g., Riyadh)
            print("⚠️ Using default location (Riyadh)");
            geoPosition = Position(
              latitude: 24.7136,
              longitude: 46.6753,
              accuracy: 100.0,
              altitude: 0.0,
              altitudeAccuracy: 0.0,
              heading: 0.0,
              headingAccuracy: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              timestamp: DateTime.now(),
            );
          }
        }
      }

      sourceLocation = LatLng(geoPosition.latitude, geoPosition.longitude);
      print(
          "📍 Final location: ${geoPosition.latitude}, ${geoPosition.longitude}");

      // Save to SharedPreferences for future use
      sharedPref.setDouble(LATITUDE, geoPosition.latitude);
      sharedPref.setDouble(LONGITUDE, geoPosition.longitude);

      // Immediately update map camera to user's location
      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(sourceLocation!, cameraZoom),
        );
        print("🗺️ Map camera updated");
      }

      try {
        print(
            "🔍 Getting address from coordinates: ${geoPosition.latitude}, ${geoPosition.longitude}");

        // استخدام الدالة الجديدة للحصول على العنوان الكامل
        String fullAddress = await _getFullAddressFromCoordinates(
            geoPosition.latitude, geoPosition.longitude);

        await getNearByDriver();

        // حفظ العنوان
        sourceLocationTitle = fullAddress;
        currentLocationAddress = fullAddress;
        polylineSource = LatLng(geoPosition.latitude, geoPosition.longitude);

        print("✅ Location data set successfully");
        print("  - sourceLocationTitle: '$sourceLocationTitle'");
        print("  - currentLocationAddress: '$currentLocationAddress'");

        // تحديث الواجهة فوراً
        setState(() {});
      } catch (e) {
        print("❌ Error getting placemark: $e");
        print("❌ Error stack trace: ${StackTrace.current}");
        currentLocationAddress = "موقعك الحالي";
        sourceLocationTitle = "موقعك الحالي";
        setState(() {});
      }

      addMarker();
      startLocationTracking();

      setState(() {
        isLocationLoading = false;
      });
      print("✅ Location setup completed successfully");
    } catch (error) {
      print("❌ Critical error getting current location: $error");
      setState(() {
        isLocationLoading = false;
        currentLocationAddress = "موقعك الحالي";
        sourceLocationTitle = "موقعك الحالي";
      });

      // Don't show location permission screen, just use default location
      if (sourceLocation == null) {
        sourceLocation = LatLng(24.7136, 46.6753); // Default to Riyadh
        polylineSource = sourceLocation!;
        addMarker();
      }
    }
  }

  // دالة جديدة لتنسيق العنوان بشكل أفضل
  String _formatAddress(Placemark place) {
    List<String> addressParts = [];

    // إضافة اسم الشارع أولاً (الأهم للمستخدم)
    if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
      addressParts.add(place.thoroughfare!);
    }

    // إضافة الحي أو المنطقة
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }

    // إضافة المدينة
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }

    // إضافة المحافظة إذا كانت مختلفة عن المدينة
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty &&
        place.administrativeArea != place.locality) {
      addressParts.add(place.administrativeArea!);
    }

    // إزالة القيم المكررة وتنسيق العنوان
    addressParts = addressParts.toSet().toList();

    // إذا كان العنوان فارغاً، محاولة الحصول على اسم المكان
    if (addressParts.isEmpty) {
      if (place.name != null && place.name!.isNotEmpty) {
        return place.name!;
      }
      return "موقعك الحالي";
    }

    // تحديد طول العنوان المناسب
    String formattedAddress = addressParts.join(', ');

    // إذا كان العنوان طويلاً جداً، اختصره
    if (formattedAddress.length > 50) {
      // استخدام أول عنصرين فقط
      List<String> shortAddress = addressParts.take(2).toList();
      formattedAddress = shortAddress.join(', ');
    }

    return formattedAddress;
  }

  // دالة مساعدة لتنظيف وتحسين العنوان المعروض
  String _cleanAndFormatAddress(String address) {
    if (address.isEmpty) {
      return "موقعك الحالي";
    }

    // إزالة الأرقام والرموز غير المرغوب فيها من بداية العنوان
    String cleaned = address.replaceAll(RegExp(r'^[\d\+\-\,\s]+'), '').trim();

    // إزالة الأرقام والرموز من نهاية العنوان
    cleaned = cleaned.replaceAll(RegExp(r'[\d\+\-\,\s]+$'), '').trim();

    // إزالة الفواصل المزدوجة
    cleaned = cleaned.replaceAll(RegExp(r',\s*,'), ', ');

    // إزالة الفواصل من البداية والنهاية
    cleaned = cleaned.replaceAll(RegExp(r'^,\s*|,\s*$'), '').trim();

    // إذا كان العنوان فارغاً بعد التنظيف
    if (cleaned.isEmpty) {
      return "موقعك الحالي";
    }

    // تحديد الطول المناسب للعرض
    if (cleaned.length > 60) {
      List<String> parts = cleaned.split(', ');
      if (parts.length > 2) {
        return '${parts[0]}, ${parts[1]}';
      } else if (cleaned.length > 60) {
        return '${cleaned.substring(0, 57)}...';
      }
    }

    return cleaned;
  }

  // دالة مساعدة لضمان عرض العنوان بشكل صحيح
  String _getDisplayAddress() {
    print("🔍 DEBUG _getDisplayAddress:");
    print("  - currentLocationAddress: '$currentLocationAddress'");
    print("  - sourceLocationTitle: '$sourceLocationTitle'");
    print(
        "  - sourceLocation: ${sourceLocation?.latitude}, ${sourceLocation?.longitude}");

    String address = "";
    if (currentLocationAddress != null && currentLocationAddress!.isNotEmpty) {
      print("  ✅ Using currentLocationAddress: '$currentLocationAddress'");
      address = currentLocationAddress!;
    } else if (sourceLocationTitle != null && sourceLocationTitle.isNotEmpty) {
      print("  ✅ Using sourceLocationTitle: '$sourceLocationTitle'");
      address = sourceLocationTitle;
    } else {
      print("  ⚠️ Using default: 'موقعك الحالي'");
      address = "موقعك الحالي";
    }

    // Format the address for better display
    return _formatAddressForDisplay(address);
  }

  // Helper function to format address for better display
  String _formatAddressForDisplay(String address) {
    if (address == "موقعك الحالي" || address.isEmpty) {
      return address;
    }

    // If the address is from Google API, it's already well-formatted
    // Just ensure it's not too long for the UI
    if (address.length > 80) {
      // Truncate and add ellipsis if too long
      return address.substring(0, 77) + "...";
    }

    return address;
  }

  // دالة محسنة للحصول على العنوان الكامل مع دعم Google Geocoding API
  // This function now prioritizes Google Geocoding API for better street-level address resolution
  Future<String> _getFullAddressFromCoordinates(double lat, double lng) async {
    print("🔍 Getting full address for: $lat, $lng");

    try {
      // أولاً: محاولة استخدام Google Geocoding API للحصول على عنوان دقيق
      String googleAddress = await _getAddressFromGoogleAPI(lat, lng);
      if (googleAddress.isNotEmpty && googleAddress != "Unknown location") {
        print("✅ Using Google API address: '$googleAddress'");
        return googleAddress;
      }

      // ثانياً: إذا فشل Google API، استخدم placemarkFromCoordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      print("📍 Found ${placemarks.length} placemarks");

      if (placemarks.isEmpty) {
        // إذا لم نجد، نجرب بدون تحديد اللغة
        placemarks = await placemarkFromCoordinates(lat, lng);
        print("📍 Found ${placemarks.length} placemarks without locale");
      }

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        print("🏠 Raw placemark data:");
        print("  - name: '${place.name}'");
        print("  - thoroughfare: '${place.thoroughfare}'");
        print("  - subThoroughfare: '${place.subThoroughfare}'");
        print("  - locality: '${place.locality}'");
        print("  - subLocality: '${place.subLocality}'");
        print("  - administrativeArea: '${place.administrativeArea}'");
        print("  - country: '${place.country}'");
        print("  - postalCode: '${place.postalCode}'");

        // بناء العنوان الكامل
        List<String> addressParts = [];

        // إضافة اسم الشارع
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          addressParts.add(place.thoroughfare!);
        }

        // إضافة الشارع الفرعي
        if (place.subThoroughfare != null &&
            place.subThoroughfare!.isNotEmpty) {
          addressParts.add(place.subThoroughfare!);
        }

        // إضافة اسم المكان
        if (place.name != null &&
            place.name!.isNotEmpty &&
            place.name != place.thoroughfare) {
          addressParts.add(place.name!);
        }

        // إضافة الحي
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }

        // إضافة المدينة
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }

        // إضافة المحافظة
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }

        // إزالة القيم المكررة
        addressParts = addressParts.toSet().toList();

        String fullAddress = addressParts.join(', ');
        print("📍 Full address: '$fullAddress'");

        if (fullAddress.isNotEmpty) {
          return fullAddress;
        } else {
          // إذا كان العنوان فارغاً، نعيد اسم المكان أو المدينة
          if (place.name != null && place.name!.isNotEmpty) {
            return place.name!;
          } else if (place.locality != null && place.locality!.isNotEmpty) {
            return place.locality!;
          } else if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            return place.administrativeArea!;
          }
        }
      }

      print("⚠️ No placemarks found or empty address");
      // استخدام الطريقة البديلة
      return _getAddressFromCoordinates(lat, lng);
    } catch (e) {
      print("❌ Error getting address: $e");
      print("❌ Error stack trace: ${StackTrace.current}");
      // استخدام الطريقة البديلة
      return _getAddressFromCoordinates(lat, lng);
    }
  }

  // دالة بديلة للحصول على العنوان باستخدام Google Geocoding API
  // This function uses Google's Geocoding API to get detailed street-level addresses
  Future<String> _getAddressFromGoogleAPI(double lat, double lng) async {
    print("🔍 Trying Google Geocoding API for: $lat, $lng");

    try {
      // استخدام Google Geocoding API مع المفتاح الصحيح
      String url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$GOOGLE_MAP_API_KEY&language=ar';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          Map<String, dynamic> result = data['results'][0];
          String formattedAddress = result['formatted_address'];
          print("📍 Google API address: '$formattedAddress'");
          return formattedAddress;
        }
      }

      print("⚠️ Google API failed, using fallback");
      return _getAddressFromCoordinates(lat, lng);
    } catch (e) {
      print("❌ Google API error: $e");
      return _getAddressFromCoordinates(lat, lng);
    }
  }

  // دالة بديلة بسيطة للحصول على العنوان
  String _getAddressFromCoordinates(double lat, double lng) {
    print("🔍 Using fallback address method for: $lat, $lng");

    // تحديد المدينة بناءً على الإحداثيات
    String city = "القاهرة";
    String country = "مصر";

    // تحديد المدينة بناءً على الإحداثيات (مثال بسيط)
    if (lat >= 30.0 && lat <= 30.1 && lng >= 31.2 && lng <= 31.3) {
      city = "القاهرة";
    } else if (lat >= 24.6 && lat <= 24.8 && lng >= 46.6 && lng <= 46.8) {
      city = "الرياض";
      country = "السعودية";
    } else if (lat >= 21.4 && lat <= 21.6 && lng >= 39.1 && lng <= 39.3) {
      city = "جدة";
      country = "السعودية";
    }

    // إنشاء عنوان أكثر تفصيلاً
    String streetName = _getStreetNameFromCoordinates(lat, lng);
    String district = _getDistrictFromCoordinates(lat, lng);
    String landmark = _getLandmarkFromCoordinates(lat, lng);

    List<String> addressParts = [];

    if (streetName.isNotEmpty) {
      addressParts.add(streetName);
    }

    if (landmark.isNotEmpty) {
      addressParts.add(landmark);
    }

    if (district.isNotEmpty) {
      addressParts.add(district);
    }

    if (city.isNotEmpty) {
      addressParts.add(city);
    }

    if (country.isNotEmpty) {
      addressParts.add(country);
    }

    String fullAddress = addressParts.join("، ");
    print("📍 Fallback address generated: '$fullAddress'");

    return fullAddress;
  }

  // دالة مساعدة لتحديد اسم الشارع بناءً على الإحداثيات
  String _getStreetNameFromCoordinates(double lat, double lng) {
    // القاهرة - شوارع معروفة
    if (lat >= 29.8 && lat <= 30.2 && lng >= 31.1 && lng <= 31.5) {
      // شارع التحرير
      if (lat >= 30.04 && lat <= 30.06 && lng >= 31.23 && lng <= 31.25) {
        return "شارع التحرير";
      }
      // شارع رمسيس
      else if (lat >= 30.06 && lat <= 30.08 && lng >= 31.24 && lng <= 31.26) {
        return "شارع رمسيس";
      }
      // شارع النيل
      else if (lat >= 30.05 && lat <= 30.07 && lng >= 31.22 && lng <= 31.24) {
        return "شارع النيل";
      }
      // شارع القصر العيني
      else if (lat >= 30.03 && lat <= 30.05 && lng >= 31.22 && lng <= 31.24) {
        return "شارع القصر العيني";
      }
      // شارع الهرم
      else if (lat >= 29.97 && lat <= 29.99 && lng >= 31.13 && lng <= 31.15) {
        return "شارع الهرم";
      }
      // شارع المعادي
      else if (lat >= 29.96 && lat <= 29.98 && lng >= 31.25 && lng <= 31.27) {
        return "شارع المعادي";
      }
      // شارع مصر الجديدة
      else if (lat >= 30.08 && lat <= 30.10 && lng >= 31.33 && lng <= 31.35) {
        return "شارع مصر الجديدة";
      }
      // شارع الزمالك
      else if (lat >= 30.05 && lat <= 30.07 && lng >= 31.22 && lng <= 31.24) {
        return "شارع الزمالك";
      }
      // شارع مدينة نصر
      else if (lat >= 30.05 && lat <= 30.07 && lng >= 31.40 && lng <= 31.42) {
        return "شارع مدينة نصر";
      }
      // شارع المهندسين
      else if (lat >= 30.06 && lat <= 30.08 && lng >= 31.20 && lng <= 31.22) {
        return "شارع المهندسين";
      }
      // شارع المقطم
      else if (lat >= 30.02 && lat <= 30.04 && lng >= 31.35 && lng <= 31.37) {
        return "شارع المقطم";
      }
    }

    // الرياض - شوارع معروفة
    else if (lat >= 24.5 && lat <= 25.0 && lng >= 46.5 && lng <= 47.0) {
      // شارع الملك فهد
      if (lat >= 24.68 && lat <= 24.70 && lng >= 46.62 && lng <= 46.64) {
        return "شارع الملك فهد";
      }
      // شارع العليا
      else if (lat >= 24.69 && lat <= 24.71 && lng >= 46.67 && lng <= 46.69) {
        return "شارع العليا";
      }
      // شارع السليمانية
      else if (lat >= 24.65 && lat <= 24.67 && lng >= 46.71 && lng <= 46.73) {
        return "شارع السليمانية";
      }
      // شارع منفوحة
      else if (lat >= 24.62 && lat <= 24.64 && lng >= 46.75 && lng <= 46.77) {
        return "شارع منفوحة";
      }
    }

    // جدة - شوارع معروفة
    else if (lat >= 21.3 && lat <= 21.7 && lng >= 39.1 && lng <= 39.3) {
      // شارع الكورنيش
      if (lat >= 21.54 && lat <= 21.56 && lng >= 39.15 && lng <= 39.17) {
        return "شارع الكورنيش";
      }
      // شارع الشاطئ
      else if (lat >= 21.52 && lat <= 21.54 && lng >= 39.18 && lng <= 39.20) {
        return "شارع الشاطئ";
      }
      // شارع البلد
      else if (lat >= 21.54 && lat <= 21.56 && lng >= 39.19 && lng <= 39.21) {
        return "شارع البلد";
      }
    }

    return "";
  }

  // دالة مساعدة لتحديد الحي بناءً على الإحداثيات
  String _getDistrictFromCoordinates(double lat, double lng) {
    // القاهرة - أحياء معروفة
    if (lat >= 29.8 && lat <= 30.2 && lng >= 31.1 && lng <= 31.5) {
      // وسط البلد
      if (lat >= 30.04 && lat <= 30.06 && lng >= 31.23 && lng <= 31.25) {
        return "وسط البلد";
      }
      // المعادي
      else if (lat >= 29.96 && lat <= 29.98 && lng >= 31.25 && lng <= 31.27) {
        return "المعادي";
      }
      // مصر الجديدة
      else if (lat >= 30.08 && lat <= 30.10 && lng >= 31.33 && lng <= 31.35) {
        return "مصر الجديدة";
      }
      // الزمالك
      else if (lat >= 30.05 && lat <= 30.07 && lng >= 31.22 && lng <= 31.24) {
        return "الزمالك";
      }
      // مدينة نصر
      else if (lat >= 30.05 && lat <= 30.07 && lng >= 31.40 && lng <= 31.42) {
        return "مدينة نصر";
      }
      // المهندسين
      else if (lat >= 30.06 && lat <= 30.08 && lng >= 31.20 && lng <= 31.22) {
        return "المهندسين";
      }
      // المقطم
      else if (lat >= 30.02 && lat <= 30.04 && lng >= 31.35 && lng <= 31.37) {
        return "المقطم";
      }
    }

    // الرياض - أحياء معروفة
    else if (lat >= 24.5 && lat <= 25.0 && lng >= 46.5 && lng <= 47.0) {
      // النخيل
      if (lat >= 24.68 && lat <= 24.70 && lng >= 46.62 && lng <= 46.64) {
        return "النخيل";
      }
      // العليا
      else if (lat >= 24.69 && lat <= 24.71 && lng >= 46.67 && lng <= 46.69) {
        return "العليا";
      }
      // السليمانية
      else if (lat >= 24.65 && lat <= 24.67 && lng >= 46.71 && lng <= 46.73) {
        return "السليمانية";
      }
      // منفوحة
      else if (lat >= 24.62 && lat <= 24.64 && lng >= 46.75 && lng <= 46.77) {
        return "منفوحة";
      }
    }

    // جدة - أحياء معروفة
    else if (lat >= 21.3 && lat <= 21.7 && lng >= 39.1 && lng <= 39.3) {
      // الكورنيش
      if (lat >= 21.54 && lat <= 21.56 && lng >= 39.15 && lng <= 39.17) {
        return "الكورنيش";
      }
      // الشاطئ
      else if (lat >= 21.52 && lat <= 21.54 && lng >= 39.18 && lng <= 39.20) {
        return "الشاطئ";
      }
      // البلد
      else if (lat >= 21.54 && lat <= 21.56 && lng >= 39.19 && lng <= 39.21) {
        return "البلد";
      }
    }

    return "";
  }

  // دالة مساعدة لتحديد المعالم بناءً على الإحداثيات
  String _getLandmarkFromCoordinates(double lat, double lng) {
    // القاهرة - معالم معروفة
    if (lat >= 29.8 && lat <= 30.2 && lng >= 31.1 && lng <= 31.5) {
      // ميدان التحرير
      if (lat >= 30.04 && lat <= 30.06 && lng >= 31.23 && lng <= 31.25) {
        return "ميدان التحرير";
      }
      // المتحف المصري
      else if (lat >= 30.03 && lat <= 30.05 && lng >= 31.23 && lng <= 31.25) {
        return "المتحف المصري";
      }
      // الأهرامات
      else if (lat >= 29.97 && lat <= 29.99 && lng >= 31.13 && lng <= 31.15) {
        return "الأهرامات";
      }
      // برج القاهرة
      else if (lat >= 30.04 && lat <= 30.06 && lng >= 31.22 && lng <= 31.24) {
        return "برج القاهرة";
      }
      // جامعة القاهرة
      else if (lat >= 30.03 && lat <= 30.05 && lng >= 31.22 && lng <= 31.24) {
        return "جامعة القاهرة";
      }
    }

    // الرياض - معالم معروفة
    else if (lat >= 24.5 && lat <= 25.0 && lng >= 46.5 && lng <= 47.0) {
      // برج المملكة
      if (lat >= 24.71 && lat <= 24.73 && lng >= 46.67 && lng <= 46.69) {
        return "برج المملكة";
      }
      // قصر المصمك
      else if (lat >= 24.63 && lat <= 24.65 && lng >= 46.71 && lng <= 46.73) {
        return "قصر المصمك";
      }
      // جامعة الملك سعود
      else if (lat >= 24.72 && lat <= 24.74 && lng >= 46.62 && lng <= 46.64) {
        return "جامعة الملك سعود";
      }
    }

    // جدة - معالم معروفة
    else if (lat >= 21.3 && lat <= 21.7 && lng >= 39.1 && lng <= 39.3) {
      // نافورة الملك فهد
      if (lat >= 21.54 && lat <= 21.56 && lng >= 39.15 && lng <= 39.17) {
        return "نافورة الملك فهد";
      }
      // برج جدة
      else if (lat >= 21.54 && lat <= 21.56 && lng >= 39.16 && lng <= 39.18) {
        return "برج جدة";
      }
    }

    return "";
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
    // Check if location services are enabled first
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled");
      setState(() {
        currentLocationAddress = "خدمة الموقع غير مفعلة";
        sourceLocationTitle = "خدمة الموقع غير مفعلة";
      });
      launchScreen(navigatorKey.currentState!.overlay!.context,
          LocationPermissionScreen());
      return;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied");
        setState(() {
          currentLocationAddress = "تم رفض أذونات الموقع";
          sourceLocationTitle = "تم رفض أذونات الموقع";
        });
        launchScreen(navigatorKey.currentState!.overlay!.context,
            LocationPermissionScreen());
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied");
      setState(() {
        currentLocationAddress = "أذونات الموقع مرفوضة نهائياً";
        sourceLocationTitle = "أذونات الموقع مرفوضة نهائياً";
      });
      launchScreen(navigatorKey.currentState!.overlay!.context,
          LocationPermissionScreen());
      return;
    }

    // Permission granted, get current location
    permissionData = permission;
    await getCurrentUserLocation();

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
      print("Location service stream error: $error");
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
          icon: riderIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
              icon: driverIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
            ),
          );
          setState(() {});
        }
      });
    }).catchError((e, s) {
      print("ERROR  FOUND:::$e ++++>$s");
    });
  }

  // New method to handle destination selection with automatic current location
  void _handleDestinationSelection() async {
    // Ensure we have current location first
    if (sourceLocation == null) {
      await getCurrentUserLocation();
    }

    // Get the full formatted address for current location
    String currentLocationFullAddress =
        currentLocationAddress ?? sourceLocationTitle ?? "موقعك الحالي";

    // Show destination selection modal
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (_) => SearchLocationComponent(
        title: currentLocationFullAddress,
      ),
    );

    if (result != null) {
      setState(() {
        selectedDestination = result['destination'];
      });

      // Navigate to ride estimation screen with full address
      launchScreen(
        context,
        NewEstimateRideListWidget(
          callFrom: "dashboard_destination_selection",
          sourceLatLog: sourceLocation!,
          destinationLatLog: result['destinationLatLng'],
          sourceTitle: currentLocationFullAddress,
          destinationTitle: result['destination'],
        ),
        pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
      );
    }
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
                          if (isLocationLoading)
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            )
                          else
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                          SizedBox(height: 16),
                          Text(
                            isLocationLoading
                                ? 'جاري تحديد موقعك...'
                                : _getDisplayAddress(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isLocationLoading) ...[
                            SizedBox(height: 8),
                            Text(
                              'قد يستغرق هذا بضع ثوانٍ...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          if (!isLocationLoading) ...[
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () async {
                                print("🔄 Retry button pressed");
                                await _initializeLocationServices();
                                await getCurrentUserLocation();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                'إعادة المحاولة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
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

            // Location input cards - Modern floating cards
            Positioned(
              top: context.statusBarHeight + 20,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _mapElementsFadeAnimation,
                child: Column(
                  children: [
                    // Current location card - Auto-completed
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
                              child: Icon(Icons.location_on,
                                  color: AppColors.primary, size: 22),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'موقع الانطلاق',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    _getDisplayAddress(),
                                    style: TextStyle(
                                      color:
                                          _getDisplayAddress() == "موقعك الحالي"
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade700,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isLocationLoading)
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Destination input card - Interactive
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
                          onTap: _handleDestinationSelection,
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
                                  child: Icon(Icons.search,
                                      color: AppColors.primary, size: 22),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'الوجهة',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        selectedDestination ??
                                            language.enterYourDestination,
                                        style: TextStyle(
                                          color: selectedDestination != null
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade500,
                                          fontSize: 16,
                                          fontWeight:
                                              selectedDestination != null
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
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
                                  child: Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.primary,
                                    size: 16,
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
                              print("🔄 Manual location refresh triggered");
                              setState(() {
                                isLocationLoading = true;
                              });

                              // Clear cached location to force fresh fetch
                              sourceLocation = null;

                              // Try different location settings for better compatibility
                              late Position geoPosition;

                              try {
                                // First try with high accuracy
                                geoPosition =
                                    await Geolocator.getCurrentPosition(
                                  timeLimit: Duration(seconds: 10),
                                  desiredAccuracy: LocationAccuracy.high,
                                );
                                print(
                                    "✅ Manual refresh: Got high accuracy position");
                              } catch (e) {
                                print(
                                    "⚠️ Manual refresh: High accuracy failed, trying medium: $e");
                                try {
                                  // Fallback to medium accuracy
                                  geoPosition =
                                      await Geolocator.getCurrentPosition(
                                    timeLimit: Duration(seconds: 8),
                                    desiredAccuracy: LocationAccuracy.medium,
                                  );
                                  print(
                                      "✅ Manual refresh: Got medium accuracy position");
                                } catch (e2) {
                                  print(
                                      "⚠️ Manual refresh: Medium failed, trying last known: $e2");
                                  // Try last known position
                                  Position? lastPosition =
                                      await Geolocator.getLastKnownPosition();
                                  if (lastPosition != null) {
                                    geoPosition = lastPosition;
                                    print(
                                        "✅ Manual refresh: Got last known position");
                                  } else {
                                    throw Exception("No location available");
                                  }
                                }
                              }

                              final currentLocation = LatLng(
                                  geoPosition.latitude, geoPosition.longitude);
                              print(
                                  "📍 Manual refresh: New location: ${geoPosition.latitude}, ${geoPosition.longitude}");

                              // Update global sourceLocation
                              sourceLocation = currentLocation;

                              // Save to SharedPreferences
                              sharedPref.setDouble(
                                  LATITUDE, geoPosition.latitude);
                              sharedPref.setDouble(
                                  LONGITUDE, geoPosition.longitude);

                              // Get updated address
                              try {
                                print("🔍 Manual refresh: Getting address...");
                                String fullAddress =
                                    await _getFullAddressFromCoordinates(
                                        geoPosition.latitude,
                                        geoPosition.longitude);
                                print(
                                    "📍 Manual refresh: New address: $fullAddress");
                                currentLocationAddress = fullAddress;
                                sourceLocationTitle = fullAddress;
                              } catch (e) {
                                print(
                                    "❌ Manual refresh: Error getting placemark: $e");
                                currentLocationAddress = "موقعك الحالي";
                                sourceLocationTitle = "موقعك الحالي";
                              }

                              // Move map camera
                              if (mapController != null) {
                                await mapController!.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                      currentLocation, cameraZoom),
                                );
                                print("🗺️ Manual refresh: Map camera updated");
                              }

                              // Update markers
                              addMarker();
                              setState(() {
                                isLocationLoading = false;
                              });
                              print("✅ Manual location refresh completed");
                            } catch (error) {
                              print("❌ Manual refresh error: $error");
                              setState(() {
                                isLocationLoading = false;
                              });

                              // Don't show error message, just use default location
                              if (sourceLocation == null) {
                                sourceLocation = LatLng(
                                    24.7136, 46.6753); // Default to Riyadh
                                polylineSource = sourceLocation!;
                                addMarker();
                              }

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
                          child: isLocationLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary),
                                  ),
                                )
                              : Icon(Icons.my_location,
                                  color: AppColors.primary),
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
