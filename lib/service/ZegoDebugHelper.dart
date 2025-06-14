import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import '../main.dart';
import '../utils/Constants.dart';
import 'ZegoService.dart';

/// Professional debugging helper for Zego Cloud integration
class ZegoDebugHelper {
  static const String _logTag = '[ZegoDebugHelper]';

  /// Test Zego service configuration and connection
  static Future<void> runDiagnostics() async {
    _log('🔧 RUNNING ZEGO DIAGNOSTICS');
    _log('═══════════════════════════════════════════════');

    // Test 1: Configuration Check
    _log('📋 Configuration Check:');
    _log('   🏢 App ID: $ZEGO_APP_ID');
    _log('   🔑 App Sign Length: ${ZEGO_APP_SIGN.length} chars');
    _log('   🔒 Callback Secret Length: ${ZEGO_CALLBACK_SECRET.length} chars');
    _log('   📱 Scenario: $ZEGO_SCENARIO');

    // Test 2: Service State
    final zegoService = ZegoService();
    final status = zegoService.getDebugStatus();

    _log('🔍 Service Status:');
    status.forEach((key, value) {
      _log('   ✓ $key: $value');
    });

    // Test 3: App Store State
    _log('📱 App Store Status:');
    _log('   ✓ Logged In: ${appStore.isLoggedIn}');
    _log('   ✓ User Phone: ${appStore.userPhone}');
    _log('   ✓ User Name: ${appStore.userName}');
    _log('   ✓ First Name: ${appStore.firstName}');

    // Test 4: Initialization Test
    try {
      _log('🚀 Testing SDK Initialization...');
      final initResult = await zegoService.initializeZegoSDK();
      _log('   ✅ Initialization: ${initResult ? "SUCCESS" : "FAILED"}');
    } catch (e) {
      _log('   ❌ Initialization Failed: $e');
    }

    // Test 5: Login Test (if user is authenticated)
    if (appStore.isLoggedIn && appStore.userPhone.isNotEmpty) {
      try {
        _log('🔐 Testing User Login...');
        final loginResult = await zegoService.loginToZego(
          userID: appStore.userPhone,
          userName: appStore.userName.isNotEmpty
              ? appStore.userName
              : appStore.firstName,
        );
        _log('   ✅ Login: ${loginResult ? "SUCCESS" : "FAILED"}');
      } catch (e) {
        _log('   ❌ Login Failed: $e');
      }
    } else {
      _log('⚠️ Skipping login test - user not authenticated in app');
    }

    _log('═══════════════════════════════════════════════');
    _log('✅ DIAGNOSTICS COMPLETED');
  }

  /// Test call to a specific number (for debugging)
  static Future<void> testCall({
    required BuildContext context,
    required String targetPhone,
    String? targetName,
    bool isVideoCall = true,
  }) async {
    _log('📞 TESTING CALL FUNCTIONALITY');
    _log('═══════════════════════════════════════════════');
    _log('🎯 Target: $targetPhone (${targetName ?? "Unknown"})');
    _log('📞 Type: ${isVideoCall ? "VIDEO" : "VOICE"}');

    final zegoService = ZegoService();

    try {
      bool result;
      if (isVideoCall) {
        result = await zegoService.initiateVideoCall(
          driverPhoneNumber: targetPhone,
          context: context,
          driverName: targetName,
        );
      } else {
        result = await zegoService.initiateVoiceCall(
          driverPhoneNumber: targetPhone,
          context: context,
          driverName: targetName,
        );
      }

      _log('📞 Call Result: ${result ? "SUCCESS" : "FAILED"}');
    } catch (e) {
      _log('❌ Call Test Failed: $e');
    }

    _log('═══════════════════════════════════════════════');
  }

  /// Generate test report for troubleshooting
  static Map<String, dynamic> generateReport() {
    final zegoService = ZegoService();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'configuration': {
        'appId': ZEGO_APP_ID,
        'appSignLength': ZEGO_APP_SIGN.length,
        'callbackSecretLength': ZEGO_CALLBACK_SECRET.length,
        'scenario': ZEGO_SCENARIO,
      },
      'zegoService': zegoService.getDebugStatus(),
      'appStore': {
        'isLoggedIn': appStore.isLoggedIn,
        'userPhone': appStore.userPhone,
        'userName': appStore.userName,
        'firstName': appStore.firstName,
      },
      'platform': {
        'isAndroid': Theme.of(navigatorKey.currentContext!).platform ==
            TargetPlatform.android,
        'isIOS': Theme.of(navigatorKey.currentContext!).platform ==
            TargetPlatform.iOS,
      }
    };
  }

  /// Display debug information in a dialog
  static void showDebugDialog(BuildContext context) {
    final report = generateReport();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔧 Zego Debug Report'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection('Configuration', report['configuration']),
              SizedBox(height: 16),
              _buildInfoSection('Zego Service', report['zegoService']),
              SizedBox(height: 16),
              _buildInfoSection('App Store', report['appStore']),
              SizedBox(height: 16),
              _buildInfoSection('Platform', report['platform']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              runDiagnostics();
            },
            child: Text('تشغيل التشخيص'),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoSection(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 8),
        ...data.entries
            .map((entry) => Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 4),
                  child: Text(
                    '• ${entry.key}: ${entry.value}',
                    style: TextStyle(fontSize: 14),
                  ),
                ))
            .toList(),
      ],
    );
  }

  static void _log(String message) {
    dev.log(message, name: _logTag);
  }
}

/// Quick debug widget for testing calls
class ZegoQuickTestWidget extends StatelessWidget {
  final String testDriverPhone;
  final String testDriverName;

  const ZegoQuickTestWidget({
    Key? key,
    this.testDriverPhone = "01234567890",
    this.testDriverName = "Test Driver",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🧪 Zego Quick Test',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ZegoDebugHelper.testCall(
                    context: context,
                    targetPhone: testDriverPhone,
                    targetName: testDriverName,
                    isVideoCall: true,
                  ),
                  icon: Icon(Icons.videocam),
                  label: Text('Video Test'),
                ),
                ElevatedButton.icon(
                  onPressed: () => ZegoDebugHelper.testCall(
                    context: context,
                    targetPhone: testDriverPhone,
                    targetName: testDriverName,
                    isVideoCall: false,
                  ),
                  icon: Icon(Icons.call),
                  label: Text('Voice Test'),
                ),
              ],
            ),
            SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ZegoDebugHelper.showDebugDialog(context),
              icon: Icon(Icons.info_outline),
              label: Text('Debug Info'),
            ),
          ],
        ),
      ),
    );
  }
}
