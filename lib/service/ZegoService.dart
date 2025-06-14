import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import '../main.dart';
import '../utils/Constants.dart';

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
      _debugLog('🚀 Starting Zego Cloud SDK initialization...');
      _debugLog('📋 App ID: $ZEGO_APP_ID');
      _debugLog('📋 App Sign: ${ZEGO_APP_SIGN.substring(0, 10)}...');
      _debugLog('📋 Scenario: $ZEGO_SCENARIO');

      if (_isInitialized) {
        _debugLog('✅ SDK already initialized, skipping...');
        return true;
      }

      // Validate credentials
      if (ZEGO_APP_ID <= 0 || ZEGO_APP_SIGN.isEmpty) {
        throw StateError(
            'Invalid Zego credentials. Check ZEGO_APP_ID and ZEGO_APP_SIGN in Constants.dart');
      }

      _debugLog(
          '⚙️ Initializing Zego UIKit Prebuilt Call Invitation Service...');

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
        _debugLog('✅ Zego Cloud SDK initialization completed successfully!');
        _debugLog('🔧 SDK State: Initialized and ready for user login');

        return true;
      } catch (zegoError) {
        _debugLog('❌ Zego SDK initialization failed: $zegoError');

        // Check common issues
        if (zegoError.toString().contains('network')) {
          throw StateError('Network error: Check internet connection');
        } else if (zegoError.toString().contains('appID') ||
            zegoError.toString().contains('appSign')) {
          throw StateError(
              'Invalid credentials: Check ZEGO_APP_ID and ZEGO_APP_SIGN');
        } else {
          throw StateError('Zego SDK initialization failed: $zegoError');
        }
      }
    } catch (error, stackTrace) {
      _errorLog('❌ Failed to initialize Zego SDK', error, stackTrace);
      _isInitialized = false;
      return false;
    }
  }

  /// Login user to Zego Cloud with professional debugging
  Future<bool> loginToZego({required String userID, String? userName}) async {
    final loginStart = DateTime.now();

    try {
      _debugLog('🔐 STARTING ZEGO USER LOGIN');
      _debugLog('═══════════════════════════════════════════════');
      _debugLog('📋 Login Details:');
      _debugLog('   👤 User ID: $userID');
      _debugLog('   📝 User Name: ${userName ?? 'Not provided'}');
      _debugLog('   🕐 Login Time: ${loginStart.toIso8601String()}');

      // Validate input
      if (userID.trim().isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      // Check SDK state
      _debugLog('🔍 Pre-login checks:');
      _debugLog('   ✓ SDK Initialized: $_isInitialized');
      _debugLog('   ✓ Currently Logged In: $_isLoggedIn');
      _debugLog('   ✓ Current User: $_currentUserID');

      if (!_isInitialized) {
        _debugLog('⚙️ SDK not initialized, initializing now...');
        final initResult = await initializeZegoSDK();
        if (!initResult) {
          throw StateError('Failed to initialize SDK before login');
        }
      }

      if (_isLoggedIn && _currentUserID == userID) {
        _debugLog('✅ User already logged in with same ID, skipping...');
        final duration = DateTime.now().difference(loginStart);
        _debugLog('⏱️ Login check completed in: ${duration.inMilliseconds}ms');
        return true;
      }

      // Logout previous user if different
      if (_isLoggedIn && _currentUserID != userID) {
        _debugLog('🔄 Different user detected, logging out previous user...');
        await logoutFromZego();
      }

      // Sanitize userID (remove special characters)
      final sanitizedUserID = userID.replaceAll(RegExp(r'[^\w\d]'), '');
      final displayName =
          userName?.isNotEmpty == true ? userName! : 'Rider_$sanitizedUserID';

      _debugLog('🔧 User data processing:');
      _debugLog('   📱 Original ID: $userID');
      _debugLog('   🆔 Sanitized ID: $sanitizedUserID');
      _debugLog('   👤 Display Name: $displayName');
      _debugLog('   🏢 App ID: $ZEGO_APP_ID');

      if (sanitizedUserID.isEmpty) {
        throw ArgumentError('Sanitized user ID cannot be empty');
      }

      _debugLog('🚀 Re-initializing Zego service with user credentials...');

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

        final loginEnd = DateTime.now();
        final duration = loginEnd.difference(loginStart);

        _debugLog('✅ ZEGO USER LOGIN COMPLETED SUCCESSFULLY!');
        _debugLog('   ⏱️ Total Login Time: ${duration.inMilliseconds}ms');
        _debugLog('   🆔 Logged in as: $sanitizedUserID');
        _debugLog('   👤 Display Name: $displayName');
        _debugLog('   🌐 Zego Status: Connected & Ready');
        _debugLog('═══════════════════════════════════════════════');

        return true;
      } catch (zegoError) {
        _debugLog('❌ Zego login failed: $zegoError');

        // Handle specific error types
        if (zegoError.toString().contains('network')) {
          throw StateError('Network error: Check internet connection');
        } else if (zegoError.toString().contains('token') ||
            zegoError.toString().contains('sign')) {
          throw StateError('Authentication error: Invalid credentials');
        } else if (zegoError.toString().contains('userID')) {
          throw StateError('Invalid user ID: $sanitizedUserID');
        } else {
          throw StateError('Zego login failed: $zegoError');
        }
      }
    } catch (error, stackTrace) {
      final loginEnd = DateTime.now();
      final duration = loginEnd.difference(loginStart);

      _debugLog('❌ ZEGO LOGIN FAILED');
      _debugLog('   ⏱️ Failed after: ${duration.inMilliseconds}ms');
      _debugLog('   🚨 Error: $error');
      _debugLog('═══════════════════════════════════════════════');

      _errorLog('Zego login failed', error, stackTrace);

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
      _debugLog('🤖 Checking for auto-login...');

      if (!appStore.isLoggedIn) {
        _debugLog('❌ User not authenticated in app');
        return false;
      }

      final userPhone = appStore.userPhone;
      final userName =
          appStore.userName.isNotEmpty ? appStore.userName : appStore.firstName;

      if (userPhone.isEmpty) {
        _debugLog('❌ User phone number not available');
        return false;
      }

      return await loginToZego(userID: userPhone, userName: userName);
    } catch (error, stackTrace) {
      _errorLog('❌ Auto-login failed', error, stackTrace);
      return false;
    }
  }

  /// Logout user from Zego Cloud
  Future<bool> logoutFromZego() async {
    try {
      _debugLog('🚪 Starting Zego user logout...');

      if (!_isLoggedIn) {
        _debugLog('✅ User already logged out');
        return true;
      }

      // Uninitialize the service
      ZegoUIKitPrebuiltCallInvitationService().uninit();

      _isLoggedIn = false;
      _currentUserID = null;
      _currentUserName = null;

      _debugLog('✅ Zego user logout completed successfully!');
      return true;
    } catch (error, stackTrace) {
      _errorLog('❌ Failed to logout from Zego', error, stackTrace);
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
    final startTime = DateTime.now();
    final callId = '${DateTime.now().millisecondsSinceEpoch}';

    try {
      final callType = isVideoCall ? 'VIDEO' : 'VOICE';

      _debugLog('═══════════════════════════════════════════════');
      _debugLog('📞 INITIATING $callType CALL [ID: $callId]');
      _debugLog('═══════════════════════════════════════════════');

      _debugLog('🎯 Target Details:');
      _debugLog('   📱 Phone: $targetPhoneNumber');
      _debugLog('   👤 Name: ${targetName ?? 'Unknown'}');
      _debugLog('   🕐 Time: ${startTime.toIso8601String()}');

      // Pre-flight checks
      _debugLog('🔍 Pre-flight checks:');
      _debugLog('   ✓ SDK Initialized: $_isInitialized');
      _debugLog('   ✓ User Logged In: $_isLoggedIn');
      _debugLog('   ✓ Current User ID: $_currentUserID');
      _debugLog('   ✓ Current User Name: $_currentUserName');
      _debugLog('   ✓ App Store Logged In: ${appStore.isLoggedIn}');
      _debugLog('   ✓ App User Phone: ${appStore.userPhone}');

      if (!_isInitialized) {
        _debugLog('❌ SDK not initialized, attempting to initialize...');
        final initResult = await initializeZegoSDK();
        if (!initResult) {
          throw StateError('Failed to initialize Zego SDK');
        }
      }

      if (!_isLoggedIn) {
        _debugLog('❌ User not logged in to Zego, attempting auto-login...');
        final loginResult = await autoLoginIfAuthenticated();
        if (!loginResult) {
          throw StateError('User must be logged in to make calls');
        }
      }

      // Sanitize and prepare target user data
      final targetUserID = targetPhoneNumber.replaceAll(RegExp(r'[^\w\d]'), '');
      final displayTargetName =
          targetName?.isNotEmpty == true ? targetName! : 'Driver_$targetUserID';

      _debugLog('🔧 Processing target data:');
      _debugLog('   📱 Original Phone: $targetPhoneNumber');
      _debugLog('   🆔 Sanitized ID: $targetUserID');
      _debugLog('   👤 Display Name: $displayTargetName');

      // Validate target user ID
      if (targetUserID.isEmpty) {
        throw ArgumentError(
            'Target user ID cannot be empty after sanitization');
      }

      if (targetUserID == _currentUserID) {
        throw ArgumentError('Cannot call yourself');
      }

      // Create invitees list
      final invitees = [
        ZegoCallUser(targetUserID, displayTargetName),
      ];

      _debugLog('📋 Call invitation details:');
      _debugLog(
          '   👥 Invitees: ${invitees.map((e) => '${e.name}(${e.id})').join(', ')}');
      _debugLog('   🎥 Video Call: $isVideoCall');
      _debugLog('   📞 Call Type: $callType');
      _debugLog('   🏢 App ID: $ZEGO_APP_ID');
      _debugLog('   🔑 App Sign: ${ZEGO_APP_SIGN.substring(0, 10)}...');

      _debugLog('🚀 Sending call invitation via Zego Cloud...');

      // Send call invitation with error handling
      try {
        ZegoUIKitPrebuiltCallInvitationService().send(
          invitees: invitees,
          isVideoCall: isVideoCall,
        );

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime);

        _debugLog('✅ CALL INVITATION SENT SUCCESSFULLY!');
        _debugLog('   ⏱️ Processing Time: ${duration.inMilliseconds}ms');
        _debugLog('   🎯 Target: $displayTargetName ($targetUserID)');
        _debugLog('   📞 Type: $callType');
        _debugLog('   🆔 Call ID: $callId');
        _debugLog('   🌐 Zego Connection: Active');
        _debugLog('═══════════════════════════════════════════════');

        // Show success feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('✅ تم إرسال دعوة المكالمة بنجاح إلى $displayTargetName'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: 'عرض التفاصيل',
                textColor: Colors.white,
                onPressed: () {
                  _debugLog('User viewed call details for Call ID: $callId');
                },
              ),
            ),
          );
        }

        return true;
      } catch (zegoError) {
        _debugLog('❌ Zego send call failed: $zegoError');
        throw zegoError;
      }
    } catch (error, stackTrace) {
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      _debugLog('❌ CALL INITIATION FAILED [ID: $callId]');
      _debugLog('   ⏱️ Failed after: ${duration.inMilliseconds}ms');
      _debugLog('   🚨 Error Type: ${error.runtimeType}');
      _debugLog('   💬 Error Message: $error');
      _debugLog('   📍 Stack Trace: Available in logs');
      _debugLog('═══════════════════════════════════════════════');

      _errorLog('Call initiation failed [ID: $callId]', error, stackTrace);

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
                _debugLog('User requested retry for Call ID: $callId');
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
  void _debugLog(String message) {
    dev.log(message, name: _logTag);
  }

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
