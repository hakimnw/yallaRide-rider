import 'dart:convert';
import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';

import '../languageConfiguration/ServerLanguageResponse.dart';
import '../main.dart';
import '../model/AppSettingModel.dart';
import '../model/BidListingModel.dart';
import '../model/ChangePasswordResponseModel.dart';
import '../model/ComplaintCommentModel.dart';
import '../model/ContactNumberListModel.dart';
import '../model/CouponListModel.dart';
import '../model/CurrentRequestModel.dart';
import '../model/EstimatePriceModel.dart';
import '../model/LDBaseResponse.dart';
import '../model/LoginResponse.dart';
import '../model/ModelGetLocationPlaceId.dart';
import '../model/NearByDriverModel.dart';
import '../model/NotificationListModel.dart';
import '../model/PaymentCardModel.dart';
import '../model/PaymentListModel.dart';
import '../model/PlaceSearchAutoCompleteModel.dart';
import '../model/RideDetailModel.dart';
import '../model/RiderListModel.dart';
import '../model/ServiceModel.dart';
import '../model/UserDetailModel.dart';
import '../model/WalletInfoModel.dart';
import '../model/WalletListModel.dart';
import '../model/WithDrawListModel.dart';
import '../screens/SignInScreen.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import 'NetworkUtils.dart';

Future<LoginResponse> signUpApi(Map request) async {
  Response response = await buildHttpResponse('register', request: request, method: HttpMethod.POST);

  if (!(response.statusCode >= 200 && response.statusCode <= 206)) {
    if (response.body.isJson()) {
      var json = jsonDecode(response.body);

      if (json.containsKey('code') && json['code'].toString().contains('invalid_username')) {
        throw 'invalid_username';
      }
    }
  }

  return await handleResponse(response).then((json) async {
    var loginResponse = LoginResponse.fromJson(json);

    if (loginResponse.data!.loginType == 'mobile') {
      await sharedPref.setString(TOKEN, loginResponse.data!.apiToken.validate());
      await sharedPref.setString(USER_TYPE, loginResponse.data!.userType.validate());
      await sharedPref.setString(FIRST_NAME, loginResponse.data!.firstName.validate());
      await sharedPref.setString(LAST_NAME, loginResponse.data!.lastName.validate());
      await sharedPref.setString(CONTACT_NUMBER, loginResponse.data!.contactNumber.validate());
      await sharedPref.setString(USER_EMAIL, loginResponse.data!.email.validate());
      await sharedPref.setString(USER_NAME, loginResponse.data!.username.validate());
      await sharedPref.setString(ADDRESS, loginResponse.data!.address.validate());
      await sharedPref.setInt(USER_ID, loginResponse.data!.id!);
      await sharedPref.setString(USER_PROFILE_PHOTO, loginResponse.data!.profileImage.validate());
      await sharedPref.setString(GENDER, loginResponse.data!.gender.validate());
      await sharedPref.setString(LOGIN_TYPE, loginResponse.data!.loginType.validate());
      await appStore.setLoggedIn(true);
      await appStore.setUserEmail(loginResponse.data!.email.validate());
      await sharedPref.setString(UID, loginResponse.data!.uid.validate());
      await appStore.setUserProfile(loginResponse.data!.profileImage.validate());

      // Initialize Zego Cloud after successful signup
      if (loginResponse.data!.contactNumber.validate().isNotEmpty) {
        try {
          print("${DateTime.now()}: User signed up successfully, initializing Zego Cloud...");

          // Ensure SDK is initialized
          if (!zegoService.isInitialized) {
            await zegoService.initializeZegoSDK();
          }

          // Auto-login to Zego Cloud after successful signup
          final zegoLoginSuccess = await zegoService.loginToZego(
            userID: loginResponse.data!.contactNumber.validate(),
            userName: loginResponse.data!.firstName.validate().isNotEmpty
                ? loginResponse.data!.firstName.validate()
                : loginResponse.data!.username.validate(),
          );

          if (zegoLoginSuccess) {
            print("${DateTime.now()}: Zego login successful after signup");
          } else {
            print("${DateTime.now()}: Zego login failed after signup");
          }
        } catch (e) {
          print("${DateTime.now()}: Error during Zego initialization: $e");
        }
      }
    }

    return loginResponse;
    // ignore: body_might_complete_normally_catch_error
  }).catchError((e) {
    toast(e.toString());
  });
}

Future<LoginResponse> logInApi(Map request, {bool isSocialLogin = false}) async {
  Response response =
      await buildHttpResponse(isSocialLogin ? 'social-login' : 'login', request: request, method: HttpMethod.POST);

  if (!(response.statusCode >= 200 && response.statusCode <= 206)) {
    if (response.body.isJson()) {
      var json = jsonDecode(response.body);

      if (json.containsKey('code') && json['code'].toString().contains('invalid_username')) {
        throw 'invalid_username';
      }
    }
  }

  return await handleResponse(response).then((json) async {
    var loginResponse = LoginResponse.fromJson(json);
    if (loginResponse.data != null) {
      await sharedPref.setString(TOKEN, loginResponse.data!.apiToken.validate());
      await sharedPref.setString(USER_TYPE, loginResponse.data!.userType.validate());
      await sharedPref.setString(FIRST_NAME, loginResponse.data!.firstName.validate());
      await sharedPref.setString(LAST_NAME, loginResponse.data!.lastName.validate());
      await sharedPref.setString(CONTACT_NUMBER, loginResponse.data!.contactNumber.validate());
      await sharedPref.setString(USER_EMAIL, loginResponse.data!.email.validate());
      await sharedPref.setString(USER_NAME, loginResponse.data!.username.validate());
      await sharedPref.setString(ADDRESS, loginResponse.data!.address.validate());
      await sharedPref.setInt(USER_ID, loginResponse.data!.id ?? 0);
      await sharedPref.setString(USER_PROFILE_PHOTO, loginResponse.data!.profileImage.validate());
      await sharedPref.setString(GENDER, loginResponse.data!.gender.validate());
      await sharedPref.setString(LOGIN_TYPE, loginResponse.data!.loginType.validate());
      await appStore.setLoggedIn(true);
      await appStore.setUserEmail(loginResponse.data!.email.validate());
      await appStore.setUserName(loginResponse.data!.username.validate());
      await appStore.setFirstName(loginResponse.data!.firstName.validate());
      if (loginResponse.data!.uid != null) await sharedPref.setString(UID, loginResponse.data!.uid.validate());
      await appStore.setUserProfile(loginResponse.data!.profileImage.validate());

      // تسجيل رقم الهاتف في OneSignal كـ External User ID
      try {
        await setPhoneAsExternalUserId();
      } catch (e) {
        print("Error setting phone as External User ID: $e");
      }

      // Initialize Zego Cloud after successful login
      if (loginResponse.data!.contactNumber.validate().isNotEmpty) {
        try {
          print("${DateTime.now()}: User logged in successfully, initializing Zego Cloud...");

          // Ensure SDK is initialized
          if (!zegoService.isInitialized) {
            await zegoService.initializeZegoSDK();
          }

          // Auto-login to Zego Cloud after successful app login
          final zegoLoginSuccess = await zegoService.loginToZego(
            userID: loginResponse.data!.contactNumber.validate(),
            userName: loginResponse.data!.firstName.validate().isNotEmpty
                ? loginResponse.data!.firstName.validate()
                : loginResponse.data!.username.validate(),
          );

          if (zegoLoginSuccess) {
            print("${DateTime.now()}: Zego login successful after app login");
          } else {
            print("${DateTime.now()}: Zego login failed after app login");
          }
        } catch (e) {
          print("${DateTime.now()}: Error during Zego initialization: $e");
        }
      }
    }

    return loginResponse;
  }).catchError((e) {
    log('${e.toString()}');
    throw e.toString();
  });
}

Future<MultipartRequest> getMultiPartRequest(String endPoint, {String? baseUrl}) async {
  String url = '${baseUrl ?? buildBaseUrl(endPoint).toString()}';
  log(url);
  return MultipartRequest('POST', Uri.parse(url));
}

Future sendMultiPartRequest(MultipartRequest multiPartRequest,
    {Function(dynamic)? onSuccess, Function(dynamic)? onError}) async {
  multiPartRequest.headers.addAll(buildHeaderTokens());

  await multiPartRequest.send().then((res) {
    res.stream.bytesToString().then(
      (value) {
        onSuccess?.call(jsonDecode(value));
      },
    );
  }).catchError((error) {
    onError?.call(error.toString());
  });
}

/// Profile Update
Future updateProfile(
    {String? uid,
    String? firstName,
    String? lastName,
    String? userEmail,
    String? address,
    String? contactNumber,
    String? gender,
    File? file}) async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  multiPartRequest.fields['id'] = sharedPref.getInt(USER_ID).toString();
  multiPartRequest.fields['username'] = sharedPref.getString(USER_NAME).validate();
  multiPartRequest.fields['email'] = userEmail ?? appStore.userEmail;
  multiPartRequest.fields['first_name'] = firstName.validate();
  multiPartRequest.fields['last_name'] = lastName.validate();
  multiPartRequest.fields['contact_number'] = contactNumber.validate();
  multiPartRequest.fields['address'] = address.validate();
  multiPartRequest.fields['gender'] = gender.validate();
  multiPartRequest.fields['uid'] = uid.validate();
  multiPartRequest.fields['player_id'] = sharedPref.getString(PLAYER_ID).toString();

  if (file != null) multiPartRequest.files.add(await MultipartFile.fromPath('profile_image', file.path));

  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    if (data != null) {
      LoginResponse res = LoginResponse.fromJson(data);

      await sharedPref.setString(FIRST_NAME, res.data!.firstName.validate());
      await sharedPref.setString(LAST_NAME, res.data!.lastName.validate());
      await sharedPref.setString(USER_PROFILE_PHOTO, res.data!.profileImage.validate());
      await sharedPref.setString(USER_NAME, res.data!.username.validate());
      await sharedPref.setString(USER_ADDRESS, res.data!.address.validate());
      await sharedPref.setString(CONTACT_NUMBER, res.data!.contactNumber.validate());
      await sharedPref.setString(GENDER, res.data!.gender.validate());
      if (res.data != null) {
        await appStore.setUserEmail(res.data!.email.validate());
        await appStore.setUserProfile(res.data!.profileImage.validate());
      }
    }
  }, onError: (error) {
    toast(error.toString());
  });
}

Future<void> logout({bool isDelete = false}) async {
  if (!isDelete) {
    await logoutApi().then((value) async {
      logOutSuccess();
    }).catchError((e) {
      throw e.toString();
    });
  } else {
    logOutSuccess();
  }
}

Future<ChangePasswordResponseModel> changePassword(Map req) async {
  return ChangePasswordResponseModel.fromJson(
      await handleResponse(await buildHttpResponse('change-password', request: req, method: HttpMethod.POST)));
}

Future<ChangePasswordResponseModel> forgotPassword(Map req) async {
  return ChangePasswordResponseModel.fromJson(
      await handleResponse(await buildHttpResponse('forget-password', request: req, method: HttpMethod.POST)));
}

Future<ServiceModel> getServices() async {
  return ServiceModel.fromJson(await handleResponse(await buildHttpResponse('service-list', method: HttpMethod.GET)));
}

Future<LoginResponse> getUserDetail({int? userId}) async {
  return LoginResponse.fromJson(
      await handleResponse(await buildHttpResponse('user-detail?id=$userId', method: HttpMethod.GET)));
}

Future<WalletListModel> getWalletList({required int page}) async {
  return WalletListModel.fromJson(
      await handleResponse(await buildHttpResponse('wallet-list?page=$page', method: HttpMethod.GET)));
}

Future<PaymentListModel> getPaymentList() async {
  return PaymentListModel.fromJson(
      await handleResponse(await buildHttpResponse('payment-gateway-list?status=1', method: HttpMethod.GET)));
}

Future<LDBaseResponse> saveWallet(Map request) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('save-wallet', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> saveSOS(Map request) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('save-sos', method: HttpMethod.POST, request: request)));
}

Future<ContactNumberListModel> getSosList({int? regionId}) async {
  return ContactNumberListModel.fromJson(await handleResponse(
      await buildHttpResponse(regionId != null ? 'sos-list?region_id=$regionId' : 'sos-list', method: HttpMethod.GET)));
}

Future<ContactNumberListModel> deleteSosList({int? id}) async {
  return ContactNumberListModel.fromJson(
      await handleResponse(await buildHttpResponse('sos-delete/$id', method: HttpMethod.POST)));
}

Future<EstimatePriceModel> estimatePriceList(Map request) async {
  // DEBUG: Log price calculation request
  print('=== PRICE ESTIMATION DEBUG START ===');
  print('Estimate price request: ${jsonEncode(request)}');
  print('Request contains:');
  request.forEach((key, value) {
    print('  $key: $value');
  });

  try {
    final response = await buildHttpResponse('estimate-price-time', method: HttpMethod.POST, request: request);

    print('Price estimation API response status: ${response.statusCode}');
    print('Price estimation API response body: ${response.body}');

    final result = EstimatePriceModel.fromJson(await handleResponse(response));

    if (result.data != null && result.data!.isNotEmpty) {
      print('Price estimation successful! Services found: ${result.data!.length}');
      for (int i = 0; i < result.data!.length; i++) {
        final service = result.data![i];
        print('Service $i: ${service.name}');
        print('  - Total Amount: ${service.totalAmount}');
        print('  - Subtotal: ${service.subtotal}');
        print('  - Base Fare: ${service.baseFare}');
        print('  - Distance Price: ${service.distancePrice}');
        print('  - Time Price: ${service.timePrice}');
        print('  - Discount: ${service.discountAmount}');
      }
    } else {
      print('❌ No services returned in price estimation');
    }

    print('=== PRICE ESTIMATION DEBUG END ===');
    return result;
  } catch (e) {
    print('❌ Error in price estimation: $e');
    print('=== PRICE ESTIMATION DEBUG END ===');
    rethrow;
  }
}

Future<CouponListModel> getCouponList({required int page}) async {
  return CouponListModel.fromJson(
      await handleResponse(await buildHttpResponse('coupon-list?page=$page', method: HttpMethod.GET)));
}

Future<LDBaseResponse> savePayment(Map request) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('save-payment', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> saveRideRequest(Map request) async {
  // DEBUG: Log ride request saving
  print('=== RIDE REQUEST SAVE DEBUG START ===');
  print('Save ride request payload: ${jsonEncode(request)}');
  print('Request contains:');
  request.forEach((key, value) {
    print('  $key: $value');
  });

  // Check if price information is missing
  bool hasPriceInfo = request.containsKey('total_amount') ||
      request.containsKey('subtotal') ||
      request.containsKey('base_fare') ||
      request.containsKey('estimated_price');

  if (!hasPriceInfo) {
    print('⚠️  WARNING: NO PRICE INFORMATION FOUND IN RIDE REQUEST!');
    print('⚠️  This might be why drivers see zero price!');
    print('⚠️  Missing keys: total_amount, subtotal, base_fare, estimated_price');
  } else {
    print('✅ Price information found in request');
    print('💰 Price details being sent to driver:');
    if (request.containsKey('total_amount')) print('  - Total Amount: ${request['total_amount']}');
    if (request.containsKey('subtotal')) print('  - Subtotal: ${request['subtotal']}');
    if (request.containsKey('base_fare')) print('  - Base Fare: ${request['base_fare']}');
    if (request.containsKey('distance_price')) print('  - Distance Price: ${request['distance_price']}');
    if (request.containsKey('time_price')) print('  - Time Price: ${request['time_price']}');
    if (request.containsKey('minimum_fare')) print('  - Minimum Fare: ${request['minimum_fare']}');
  }

  try {
    final response = await buildHttpResponse('save-riderequest', method: HttpMethod.POST, request: request);

    print('Save ride request API response status: ${response.statusCode}');
    print('Save ride request API response body: ${response.body}');

    final result = LDBaseResponse.fromJson(await handleResponse(response));

    if (result.rideRequestId != null) {
      print('✅ Ride request saved successfully with ID: ${result.rideRequestId}');
      print('🎯 SUCCESS: Driver should now see the trip with proper pricing!');
      print('🔔 Next step: Check driver app for ride notification with price');
    } else {
      print('❌ Ride request save failed - no ride ID returned');
      print('❌ FAILURE: Driver will not receive ride request');
    }

    print('=== RIDE REQUEST SAVE DEBUG END ===');
    return result;
  } catch (e) {
    print('❌ Error saving ride request: $e');
    print('=== RIDE REQUEST SAVE DEBUG END ===');
    rethrow;
  }
}

Future<BidListingModel> getBidListing(Map request) async {
  return BidListingModel.fromJson(
      await handleResponse(await buildHttpResponse('get-bidding-riderequest', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> responseBidListing(Map request) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('riderequest-bid-respond', method: HttpMethod.POST, request: request)));
}

Future<AppSettingModel> getAppSetting() async {
  return AppSettingModel.fromJson(await handleResponse(await buildHttpResponse('admin-dashboard', method: HttpMethod.GET)));
}

Future<CurrentRequestModel> getCurrentRideRequest() async {
  return CurrentRequestModel.fromJson(
      await handleResponse(await buildHttpResponse('current-riderequest', method: HttpMethod.GET)));
}

Future<LDBaseResponse> rideRequestUpdate({required Map request, int? rideId}) async {
  return LDBaseResponse.fromJson(await handleResponse(
      await buildHttpResponse('riderequest-update/$rideId', method: HttpMethod.POST, request: request)));
}

Future<ServerLanguageResponse> getLanguageList(versionNo) async {
  return ServerLanguageResponse.fromJson(
      await handleResponse(await buildHttpResponse('language-table-list?version_no=$versionNo', method: HttpMethod.GET))
          .then((value) => value));
}

Future<LDBaseResponse> ratingReview({required Map request}) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('save-ride-rating', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> adminNotify({required Map request}) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('admin-sos-notify', method: HttpMethod.POST, request: request)));
}

Future<RiderListModel> getRiderRequestList({int? page, String? status, LatLng? sourceLatLog, int? riderId}) async {
  if (sourceLatLog != null) {
    return RiderListModel.fromJson(await handleResponse(
        await buildHttpResponse('riderequest-list?page=$page&rider_id=$riderId', method: HttpMethod.GET)));
  } else {
    return RiderListModel.fromJson(await handleResponse(await buildHttpResponse(
        status != null
            ? 'riderequest-list?page=$page&status=$status&rider_id=$riderId'
            : 'riderequest-list?page=$page&rider_id=$riderId',
        method: HttpMethod.GET)));
  }
}

Future<LDBaseResponse> saveComplain({required Map request}) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('save-complaint', method: HttpMethod.POST, request: request)));
}

Future<RideDetailModel> rideDetail({required int? orderId}) async {
  return RideDetailModel.fromJson(
      await handleResponse(await buildHttpResponse('riderequest-detail?id=$orderId', method: HttpMethod.GET)));
}

/// Get Notification List
Future<NotificationListModel> getNotification({required int page}) async {
  return NotificationListModel.fromJson(await handleResponse(
      await buildHttpResponse('notification-list?page=$page&limit=$PER_PAGE', method: HttpMethod.POST)));
}

Future<ModelSearchPlaceRes> searchAddressRequest({String? search}) async {
  return ModelSearchPlaceRes.fromJson(await handleResponse(await buildHttpResponse(
      'https://places.googleapis.com/v1/places:autocomplete',
      header_extra: {'X-Goog-Api-Key': '$GOOGLE_MAP_API_KEY'},
      request: {"input": search},
      method: HttpMethod.POST)));
}

Future<GooglePlacesApiResponse> searchAddressRequestPlaceId({String? placeId}) async {
  return GooglePlacesApiResponse.fromJson(await handleResponse(await buildHttpResponse(
      'https://places.googleapis.com/v1/places/$placeId?fields=id,displayName,location&key=$GOOGLE_MAP_API_KEY',
      header_extra: {},
      method: HttpMethod.GET)));
}

Future<LoginResponse> updateStatus(Map request) async {
  return LoginResponse.fromJson(
      await handleResponse(await buildHttpResponse('update-user-status', method: HttpMethod.POST, request: request)));
}

Future<LDBaseResponse> deleteUser() async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('delete-user-account', method: HttpMethod.POST)));
}

/// Profile Update
Future updateProfileUid() async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  multiPartRequest.fields['id'] = sharedPref.getInt(USER_ID).toString();
  multiPartRequest.fields['username'] = sharedPref.getString(USER_NAME).validate();
  multiPartRequest.fields['email'] = sharedPref.getString(USER_EMAIL).validate();
  multiPartRequest.fields['uid'] = sharedPref.getString(UID).toString();

  log('multipart request:${multiPartRequest.fields}');
  log(sharedPref.getString(UID).toString());

  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    if (data != null) {
      //
    }
  }, onError: (error) {
    toast(error.toString());
  });
}

Future<LDBaseResponse> complaintComment({required Map request}) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('save-complaintcomment', method: HttpMethod.POST, request: request)));
}

Future<ComplaintCommentModel> complaintList({required int complaintId, required int currentPage}) async {
  return ComplaintCommentModel.fromJson(await handleResponse(
      await buildHttpResponse('complaintcomment-list?complaint_id=$complaintId&page=$currentPage', method: HttpMethod.GET)));
}

Future<LDBaseResponse> logoutApi() async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('logout?clear=player_id', method: HttpMethod.GET)));
}

Future<UserDetailModel> getDriverDetail({int? userId}) async {
  return UserDetailModel.fromJson(
      await handleResponse(await buildHttpResponse('user-detail?id=$userId', method: HttpMethod.GET)));
}

logOutSuccess() async {
  sharedPref.remove(FIRST_NAME);
  sharedPref.remove(LAST_NAME);
  sharedPref.remove(USER_PROFILE_PHOTO);
  sharedPref.remove(USER_NAME);
  sharedPref.remove(USER_ADDRESS);
  sharedPref.remove(CONTACT_NUMBER);
  sharedPref.remove(GENDER);
  sharedPref.remove(UID);
  sharedPref.remove(TOKEN);
  sharedPref.remove(USER_TYPE);
  sharedPref.remove(ADDRESS);
  sharedPref.remove(USER_ID);
  sharedPref.remove(COUNTRY);
  appStore.setLoggedIn(false);
  if (!(sharedPref.getBool(REMEMBER_ME) ?? false) ||
      sharedPref.getString(LOGIN_TYPE) == LoginTypeGoogle ||
      sharedPref.getString(LOGIN_TYPE) == 'mobile') {
    sharedPref.remove(USER_EMAIL);
    sharedPref.remove(USER_PASSWORD);
    sharedPref.remove(REMEMBER_ME);
  }
  sharedPref.remove(LOGIN_TYPE);
  launchScreen(getContext, SignInScreen(), isNewTask: true);
}

Future<NearByDriverModel> getNearByDriverList({LatLng? latLng}) async {
  return NearByDriverModel.fromJson(await handleResponse(await buildHttpResponse(
      'near-by-driver?latitude=${latLng!.latitude}&longitude=${latLng.longitude}',
      method: HttpMethod.GET)));
}

Future<WalletInfoModel> getWalletData() async {
  return WalletInfoModel.fromJson(await handleResponse(await buildHttpResponse('wallet-detail', method: HttpMethod.GET)));
}

/// Save Payment Card
Future<LDBaseResponse> savePaymentCard({required Map request}) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('save-payment-card', method: HttpMethod.POST, request: request)));
}

/// Get Payment Cards List
Future<List<PaymentCardModel>> getPaymentCards() async {
  final response = await handleResponse(await buildHttpResponse('payment-cards-list', method: HttpMethod.GET));

  List<PaymentCardModel> cardsList = [];
  if (response['data'] != null) {
    (response['data'] as List).forEach((v) {
      cardsList.add(PaymentCardModel.fromJson(v));
    });
  }
  return cardsList;
}

/// Delete Payment Card
Future<LDBaseResponse> deletePaymentCard({required int cardId}) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('delete-payment-card/$cardId', method: HttpMethod.POST)));
}

/// Update Payment Card
Future<LDBaseResponse> updatePaymentCard({required Map request, required int cardId}) async {
  return LDBaseResponse.fromJson(await handleResponse(
      await buildHttpResponse('update-payment-card/$cardId', method: HttpMethod.POST, request: request)));
}

/// Add Money to Wallet using Card
Future<LDBaseResponse> addMoneyToWallet({required Map request}) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('add-wallet-money', method: HttpMethod.POST, request: request)));
}

/// Create checkout session for wallet top-up and return the `data` payload
Future<Map<String, dynamic>> createCheckoutPayment({
  required double amount,
  String paymentType = 'MADA',
}) async {
  print('Creating checkout payment - Amount: $amount, Type: $paymentType');

  final resp = await handleResponse(
    await buildHttpResponse(
      'payments/create-checkout',
      method: HttpMethod.POST,
      request: {
        'amount': amount,
        'payment_type': paymentType,
      },
    ),
  );

  print('Raw API response: $resp');

  // Ensure we return a Map<String, dynamic>
  if (resp is Map<String, dynamic>) {
    // If response has 'data' field and it's a map, return it
    final data = resp['data'];
    if (data is Map<String, dynamic>) {
      print('Returning data field: $data');
      return data;
    }
    // If no data field or it's not a map, return the whole response
    print('Returning full response: $resp');
    return resp;
  }

  // If response is not a map, wrap it
  print('Response is not a map, wrapping: $resp');
  return {'raw': resp};
}

Future<WithDrawListModel> getWithDrawList({int? page}) async {
  return WithDrawListModel.fromJson(
      await handleResponse(await buildHttpResponse('withdrawrequest-list?page=$page', method: HttpMethod.GET)));
}

Future<LDBaseResponse> saveWithDrawRequest(Map request) async {
  return LDBaseResponse.fromJson(
      await handleResponse(await buildHttpResponse('save-withdrawrequest', method: HttpMethod.POST, request: request)));
}

/// Update Bank Info
Future updateBankDetail(
    {String? bankName,
    String? bankCode,
    String? accountName,
    String? accountNumber,
    String? routing,
    String? iban,
    String? swift}) async {
  MultipartRequest multiPartRequest = await getMultiPartRequest('update-profile');
  multiPartRequest.fields['email'] = sharedPref.getString(USER_EMAIL).validate();
  multiPartRequest.fields['contact_number'] = sharedPref.getString(CONTACT_NUMBER).validate();
  multiPartRequest.fields['username'] = sharedPref.getString(USER_NAME).validate();
  multiPartRequest.fields['user_bank_account[bank_name]'] = bankName.validate();
  multiPartRequest.fields['user_bank_account[bank_code]'] = bankCode.validate();
  multiPartRequest.fields['user_bank_account[account_holder_name]'] = accountName.validate();
  multiPartRequest.fields['user_bank_account[account_number]'] = accountNumber.validate();
  // This field missing in Bank Detail: Routing Number, Bank IBAN, Bank Swift
  multiPartRequest.fields['user_bank_account[routing_number]'] = routing.validate();
  multiPartRequest.fields['user_bank_account[bank_iban]'] = iban.validate();
  multiPartRequest.fields['user_bank_account[bank_swift]'] = swift.validate();

  log('Request:${multiPartRequest.fields}');

  await sendMultiPartRequest(multiPartRequest, onSuccess: (data) async {
    log('data:$data');
    if (data != null) {
      //
    }
  }, onError: (error) {
    toast(error.toString());
  });
}

Future<PrivacyPolicyModel> getPrivacyPolicyApi() async {
  Response response = await buildHttpResponse('privacy-policy', method: HttpMethod.GET);
  var jsonResponse = await handleResponse(response);
  return PrivacyPolicyModel.fromJson(jsonResponse['data']);
}

Future<PrivacyPolicyModel> getTermsAndConditionsApi() async {
  Response response = await buildHttpResponse('terms-and-conditions', method: HttpMethod.GET);
  var jsonResponse = await handleResponse(response);
  return PrivacyPolicyModel.fromJson(jsonResponse['data']);
}
