import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../main.dart';
import '../utils/Constants.dart';
import '../utils/constant/app_colors.dart';

/// Professional ZegoService for managing Zego Cloud SDK
class ZegoService {
  static final ZegoService _instance = ZegoService._internal();
  factory ZegoService() => _instance;
  ZegoService._internal();

  bool _isInitialized = false;
  bool _isLoggedIn = false;
  String? _currentUserID;
  String? _currentUserName;

  static const String _logTag = '[ZegoService]';

  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _isLoggedIn;
  String? get currentUserID => _currentUserID;
  String? get currentUserName => _currentUserName;

  /// Initialize Zego Cloud SDK with professional debugging
  Future<bool> initializeZegoSDK() async {
    try {
      // Debug logs removed for production

      if (_isInitialized) {
        // Debug log removed for production
        return true;
      }

      // Validate credentials
      if (ZEGO_APP_ID <= 0 || ZEGO_APP_SIGN.isEmpty) {
        throw StateError('Invalid Zego credentials. Check ZEGO_APP_ID and ZEGO_APP_SIGN in Constants.dart');
      }

      // Debug log removed for production

      // Initialize call invitation service with real credentials
      try {
        await ZegoUIKitPrebuiltCallInvitationService().init(
          appID: ZEGO_APP_ID,
          appSign: ZEGO_APP_SIGN,
          userID: '', // Will be set during login
          userName: '', // Will be set during login
          plugins: [ZegoUIKitSignalingPlugin()],
        );

        _isInitialized = true;
        // Debug logs removed for production

        return true;
      } catch (zegoError) {
        // Debug log removed for production

        // Check common issues
        if (zegoError.toString().contains('network')) {
          throw StateError('Network error: Check internet connection');
        } else if (zegoError.toString().contains('appID') || zegoError.toString().contains('appSign')) {
          throw StateError('Invalid credentials: Check ZEGO_APP_ID and ZEGO_APP_SIGN');
        } else {
          throw StateError('Zego SDK initialization failed: $zegoError');
        }
      }
    } catch (error, stackTrace) {
      _errorLog('❌ Failed to initialize Zego SDK', error, stackTrace); // Error log kept
      _isInitialized = false;
      return false;
    }
  }

  /// Login user to Zego Cloud with professional debugging
  Future<bool> loginToZego({required String userID, String? userName}) async {
    // final loginStart = DateTime.now();

    try {
      // Debug logs removed for production

      // Validate input
      if (userID.trim().isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      // Check SDK state
      // Debug logs removed for production

      if (!_isInitialized) {
        // Debug log removed for production
        final initResult = await initializeZegoSDK();
        if (!initResult) {
          throw StateError('Failed to initialize SDK before login');
        }
      }

      if (_isLoggedIn && _currentUserID == userID) {
        // Debug logs removed for production
        return true;
      }

      // Logout previous user if different
      if (_isLoggedIn && _currentUserID != userID) {
        // Debug log removed for production
        await logoutFromZego();
      }

      // Sanitize userID (remove special characters)
      final sanitizedUserID = userID.replaceAll(RegExp(r'[^\w\d]'), '');
      final displayName = userName?.isNotEmpty == true ? userName! : 'Rider_$sanitizedUserID';

      // Debug logs removed for production

      if (sanitizedUserID.isEmpty) {
        throw ArgumentError('Sanitized user ID cannot be empty');
      }

      // Debug log removed for production

      // Re-initialize with user credentials
      try {
        await ZegoUIKitPrebuiltCallInvitationService().init(
          appID: ZEGO_APP_ID,
          appSign: ZEGO_APP_SIGN,
          userID: sanitizedUserID,
          userName: displayName,
          plugins: [ZegoUIKitSignalingPlugin()],
        );

        // Update state
        _isLoggedIn = true;
        _currentUserID = sanitizedUserID;
        _currentUserName = displayName;

        // final loginEnd = DateTime.now();
        // final duration = loginEnd.difference(loginStart);

        // Debug logs removed for production

        return true;
      } catch (zegoError) {
        // Debug log removed for production

        // Handle specific error types
        if (zegoError.toString().contains('network')) {
          throw StateError('Network error: Check internet connection');
        } else if (zegoError.toString().contains('token') || zegoError.toString().contains('sign')) {
          throw StateError('Authentication error: Invalid credentials');
        } else if (zegoError.toString().contains('userID')) {
          throw StateError('Invalid user ID: $sanitizedUserID');
        } else {
          throw StateError('Zego login failed: $zegoError');
        }
      }
    } catch (error, stackTrace) {
      // final loginEnd = DateTime.now();
      // final duration = loginEnd.difference(loginStart);

      // Debug logs removed for production

      _errorLog('Zego login failed', error, stackTrace); // Error log kept

      // Reset state on failure
      _isLoggedIn = false;
      _currentUserID = null;
      _currentUserName = null;

      return false;
    }
  }

  /// Automatically login if user is authenticated in the app
  Future<bool> autoLoginIfAuthenticated() async {
    try {
      // Debug log removed for production

      if (!appStore.isLoggedIn) {
        // Debug log removed for production
        return false;
      }

      final userPhone = appStore.userPhone;
      final userName = appStore.userName.isNotEmpty ? appStore.userName : appStore.firstName;

      if (userPhone.isEmpty) {
        // Debug log removed for production
        return false;
      }

      return await loginToZego(userID: userPhone, userName: userName);
    } catch (error, stackTrace) {
      _errorLog('❌ Auto-login failed', error, stackTrace); // Error log kept
      return false;
    }
  }

  /// Logout user from Zego Cloud
  Future<bool> logoutFromZego() async {
    try {
      // Debug log removed for production

      if (!_isLoggedIn) {
        // Debug log removed for production
        return true;
      }

      // Uninitialize the service
      ZegoUIKitPrebuiltCallInvitationService().uninit();

      _isLoggedIn = false;
      _currentUserID = null;
      _currentUserName = null;

      // Debug log removed for production
      return true;
    } catch (error, stackTrace) {
      _errorLog('❌ Failed to logout from Zego', error, stackTrace); // Error log kept
      return false;
    }
  }

  /// Initiate a video call to a driver
  Future<bool> initiateVideoCall({
    required String driverPhoneNumber,
    required BuildContext context,
    String? driverName,
  }) async {
    return await _initiateCall(
      targetPhoneNumber: driverPhoneNumber,
      context: context,
      targetName: driverName,
      isVideoCall: true,
    );
  }

  /// Initiate a voice call to a driver
  Future<bool> initiateVoiceCall({
    required String driverPhoneNumber,
    required BuildContext context,
    String? driverName,
  }) async {
    return await _initiateCall(
      targetPhoneNumber: driverPhoneNumber,
      context: context,
      targetName: driverName,
      isVideoCall: false,
    );
  }

  /// Professional call initiation with comprehensive debugging
  Future<bool> _initiateCall({
    required String targetPhoneNumber,
    required BuildContext context,
    String? targetName,
    required bool isVideoCall,
  }) async {
    // final startTime = DateTime.now();
    final callId = '${DateTime.now().millisecondsSinceEpoch}';

    try {
      // final callType = isVideoCall ? 'VIDEO' : 'VOICE';

      // Debug logs removed for production

      if (!_isInitialized) {
        final initResult = await initializeZegoSDK();
        if (!initResult) throw StateError('Failed to initialize Zego SDK');
      }

      if (!_isLoggedIn) {
        final loginResult = await autoLoginIfAuthenticated();
        if (!loginResult) {
          throw StateError('User must be logged in to make calls');
        }
      }

      // Sanitize and prepare target user data
      final targetUserID = targetPhoneNumber.replaceAll(RegExp(r'[^\w\d]'), '');
      final displayTargetName = targetName?.isNotEmpty == true ? targetName! : 'Driver_$targetUserID';

      // Debug logs removed for production

      // Validate target user ID
      if (targetUserID.isEmpty) {
        throw ArgumentError('Target user ID cannot be empty after sanitization');
      }

      if (targetUserID == _currentUserID) {
        throw ArgumentError('Cannot call yourself');
      }

      // Create invitees list
      final invitees = [
        ZegoCallUser(targetUserID, displayTargetName),
      ];

      // Debug logs removed for production

      // Debug log removed for production

      // Send call invitation with error handling
      try {
        ZegoUIKitPrebuiltCallInvitationService().send(
          invitees: invitees,
          isVideoCall: isVideoCall,
        );

        // final endTime = DateTime.now();
        // final duration = endTime.difference(startTime);

        // Debug logs removed for production

        // Show success feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ تم إرسال دعوة المكالمة بنجاح إلى $displayTargetName'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'عرض التفاصيل',
                textColor: Colors.white,
                onPressed: () {
                  // Debug log removed for production
                },
              ),
            ),
          );
        }

        return true;
      } catch (zegoError) {
        // Debug log removed for production
        throw zegoError;
      }
    } catch (error, stackTrace) {
      // final endTime = DateTime.now();
      // final duration = endTime.difference(startTime);

      // Debug logs removed for production

      _errorLog('Call initiation failed [ID: $callId]', error, stackTrace); // Error log kept

      if (context.mounted) {
        String userFriendlyMessage = 'فشل في إجراء المكالمة';

        if (error.toString().contains('not logged in')) {
          userFriendlyMessage = 'يجب تسجيل الدخول أولاً';
        } else if (error.toString().contains('not initialized')) {
          userFriendlyMessage = 'خطأ في تهيئة الخدمة';
        } else if (error.toString().contains('network')) {
          userFriendlyMessage = 'تحقق من اتصال الإنترنت';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $userFriendlyMessage'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'محاولة مرة أخرى',
              textColor: Colors.white,
              onPressed: () {
                // Debug log removed for production
              },
            ),
          ),
        );
      }
      return false;
    }
  }

  /// Get call invitation received notification widget
  Widget getCallInvitationWidget({required Widget child}) {
    // According to Zego documentation, we don't need to wrap the widget here
    // The ZegoUIKitPrebuiltCallInvitationService handles call invitations automatically
    // after proper initialization in main.dart
    return child;
  }

  /// Debug logging helper
  // void _debugLog(String message) {
  //   // Debug log removed for production
  // }

  /// Error logging helper
  void _errorLog(String message, Object error, StackTrace? stackTrace) {
    dev.log(message, name: _logTag, error: error, stackTrace: stackTrace);
  }

  /// Debug helper: Get current service status
  Map<String, dynamic> getDebugStatus() {
    return {
      'isInitialized': _isInitialized,
      'isLoggedIn': _isLoggedIn,
      'currentUserID': _currentUserID,
      'currentUserName': _currentUserName,
      'appUserLoggedIn': appStore.isLoggedIn,
      'appUserPhone': appStore.userPhone,
      'appUserName': appStore.userName,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
