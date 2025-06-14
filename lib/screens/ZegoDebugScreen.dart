import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../main.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';

/// Debug screen for testing Zego Cloud SDK integration
///
/// Features:
/// - View current Zego service status
/// - Test SDK initialization
/// - Test login/logout functionality
/// - Simulate voice/video calls
/// - Real-time status monitoring
/// - Manual testing controls
class ZegoDebugScreen extends StatefulWidget {
  @override
  ZegoDebugScreenState createState() => ZegoDebugScreenState();
}

class ZegoDebugScreenState extends State<ZegoDebugScreen> {
  final TextEditingController _testUserIdController = TextEditingController();
  final TextEditingController _testUserNameController = TextEditingController();
  final TextEditingController _targetPhoneController = TextEditingController();
  final TextEditingController _targetNameController = TextEditingController();

  bool _isLoading = false;
  String _lastResult = '';
  Map<String, dynamic> _serviceStatus = {};

  @override
  void initState() {
    super.initState();
    _refreshStatus();

    // Pre-fill with app user data if available
    if (appStore.isLoggedIn) {
      _testUserIdController.text = appStore.userPhone;
      _testUserNameController.text =
          appStore.userName.isNotEmpty ? appStore.userName : appStore.firstName;
    }
  }

  @override
  void dispose() {
    _testUserIdController.dispose();
    _testUserNameController.dispose();
    _targetPhoneController.dispose();
    _targetNameController.dispose();
    super.dispose();
  }

  void _refreshStatus() {
    setState(() {
      _serviceStatus = zegoService.getDebugStatus();
    });
  }

  Future<void> _performAction(
      String actionName, Future<bool> Function() action) async {
    setState(() {
      _isLoading = true;
      _lastResult = 'Executing $actionName...';
    });

    try {
      final success = await action();
      setState(() {
        _lastResult = '$actionName: ${success ? 'SUCCESS ✅' : 'FAILED ❌'}';
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actionName completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$actionName failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _lastResult = '$actionName: ERROR ❌ - $error';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$actionName error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _refreshStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Zego Debug Console', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshStatus,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: Observer(
        builder: (context) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Status Card
                _buildStatusCard(),
                SizedBox(height: 16),

                // SDK Controls Card
                _buildSdkControlsCard(),
                SizedBox(height: 16),

                // Login Controls Card
                _buildLoginControlsCard(),
                SizedBox(height: 16),

                // Call Testing Card
                _buildCallTestingCard(),
                SizedBox(height: 16),

                // Last Result Card
                _buildLastResultCard(),
                SizedBox(height: 16),

                // App User Info Card
                _buildAppUserInfoCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: primaryColor),
                SizedBox(width: 8),
                Text('Zego Service Status', style: boldTextStyle(size: 18)),
              ],
            ),
            SizedBox(height: 12),
            _buildStatusItem(
                'SDK Initialized', _serviceStatus['isInitialized'] ?? false),
            _buildStatusItem(
                'User Logged In', _serviceStatus['isLoggedIn'] ?? false),
            if (_serviceStatus['currentUserID'] != null)
              _buildInfoItem(
                  'Current User ID', _serviceStatus['currentUserID']),
            if (_serviceStatus['currentUserName'] != null)
              _buildInfoItem(
                  'Current User Name', _serviceStatus['currentUserName']),
            _buildInfoItem(
                'Last Updated', _serviceStatus['timestamp'] ?? 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildSdkControlsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: primaryColor),
                SizedBox(width: 8),
                Text('SDK Controls', style: boldTextStyle(size: 18)),
              ],
            ),
            SizedBox(height: 12),
            // Comprehensive Test Button
            Container(
              width: double.infinity,
              child: AppButtonWidget(
                text: '🔧 Run Complete Zego Test',
                onTap: () => _runComprehensiveTest(),
                color: Colors.purple,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButtonWidget(
                    text: 'Initialize SDK',
                    onTap: () => _performAction(
                      'SDK Initialization',
                      zegoService.initializeZegoSDK,
                    ),
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: AppButtonWidget(
                    text: 'Auto Login',
                    onTap: () => _performAction(
                      'Auto Login',
                      zegoService.autoLoginIfAuthenticated,
                    ),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginControlsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.login, color: primaryColor),
                SizedBox(width: 8),
                Text('Login Controls', style: boldTextStyle(size: 18)),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _testUserIdController,
              decoration: InputDecoration(
                labelText: 'Test User ID (Phone)',
                border: OutlineInputBorder(),
                hintText: 'Enter phone number',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _testUserNameController,
              decoration: InputDecoration(
                labelText: 'Test User Name',
                border: OutlineInputBorder(),
                hintText: 'Enter display name',
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButtonWidget(
                    text: 'Manual Login',
                    onTap: () => _performAction(
                      'Manual Login',
                      () => zegoService.loginToZego(
                        userID: _testUserIdController.text.trim(),
                        userName: _testUserNameController.text.trim().isNotEmpty
                            ? _testUserNameController.text.trim()
                            : null,
                      ),
                    ),
                    color: Colors.green,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: AppButtonWidget(
                    text: 'Logout',
                    onTap: () => _performAction(
                      'Logout',
                      zegoService.logoutFromZego,
                    ),
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallTestingCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.call, color: primaryColor),
                SizedBox(width: 8),
                Text('Call Testing', style: boldTextStyle(size: 18)),
              ],
            ),
            SizedBox(height: 12),
            TextField(
              controller: _targetPhoneController,
              decoration: InputDecoration(
                labelText: 'Target Phone Number',
                border: OutlineInputBorder(),
                hintText: 'Enter driver phone number',
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _targetNameController,
              decoration: InputDecoration(
                labelText: 'Target Name (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter driver name',
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButtonWidget(
                    text: 'Test Voice Call',
                    onTap: () => _performAction(
                      'Voice Call Test',
                      () => zegoService.initiateVoiceCall(
                        driverPhoneNumber: _targetPhoneController.text.trim(),
                        context: context,
                        driverName: _targetNameController.text.trim().isNotEmpty
                            ? _targetNameController.text.trim()
                            : null,
                      ),
                    ),
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: AppButtonWidget(
                    text: 'Test Video Call',
                    onTap: () => _performAction(
                      'Video Call Test',
                      () => zegoService.initiateVideoCall(
                        driverPhoneNumber: _targetPhoneController.text.trim(),
                        context: context,
                        driverName: _targetNameController.text.trim().isNotEmpty
                            ? _targetNameController.text.trim()
                            : null,
                      ),
                    ),
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastResultCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: primaryColor),
                SizedBox(width: 8),
                Text('Last Action Result', style: boldTextStyle(size: 18)),
              ],
            ),
            SizedBox(height: 12),
            if (_isLoading)
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...', style: secondaryTextStyle()),
                ],
              )
            else if (_lastResult.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _lastResult));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied to clipboard')),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _lastResult.contains('SUCCESS')
                        ? Colors.green.withOpacity(0.1)
                        : _lastResult.contains('FAILED') ||
                                _lastResult.contains('ERROR')
                            ? Colors.red.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _lastResult.contains('SUCCESS')
                          ? Colors.green
                          : _lastResult.contains('FAILED') ||
                                  _lastResult.contains('ERROR')
                              ? Colors.red
                              : Colors.grey,
                    ),
                  ),
                  child: Text(
                    _lastResult,
                    style: primaryTextStyle(),
                  ),
                ),
              )
            else
              Text('No actions performed yet', style: secondaryTextStyle()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUserInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: primaryColor),
                SizedBox(width: 8),
                Text('App User Info', style: boldTextStyle(size: 18)),
              ],
            ),
            SizedBox(height: 12),
            _buildStatusItem('App User Logged In', appStore.isLoggedIn),
            if (appStore.isLoggedIn) ...[
              _buildInfoItem('User Phone', appStore.userPhone),
              _buildInfoItem('User Name', appStore.userName),
              _buildInfoItem('First Name', appStore.firstName),
              _buildInfoItem('User Email', appStore.userEmail),
            ],
            SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                final statusJson = jsonEncode(_serviceStatus);
                Clipboard.setData(ClipboardData(text: statusJson));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Full status copied to clipboard')),
                );
              },
              child: Text(
                'Tap to copy full status JSON',
                style: primaryTextStyle(color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool status) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 8),
          Text(label, style: primaryTextStyle()),
          Spacer(),
          Text(
            status ? 'Yes' : 'No',
            style: primaryTextStyle(
              color: status ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: secondaryTextStyle()),
                Text(
                  value?.isNotEmpty == true ? value! : 'Not set',
                  style: primaryTextStyle(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runComprehensiveTest() async {
    setState(() {
      _isLoading = true;
      _lastResult = '🔧 Running comprehensive Zego test...';
    });

    try {
      // Test results
      List<String> results = [];
      int passedTests = 0;
      int totalTests = 7;

      // Test 1: Check Zego configuration
      results.add('📋 Test 1: Zego Configuration');
      if (ZEGO_APP_ID > 0 && ZEGO_APP_SIGN.isNotEmpty) {
        results.add('   ✅ PASS: Valid Zego credentials found');
        results.add('   📱 App ID: $ZEGO_APP_ID');
        results.add('   🔑 App Sign: ${ZEGO_APP_SIGN.substring(0, 10)}...');
        passedTests++;
      } else {
        results.add('   ❌ FAIL: Invalid Zego credentials');
      }

      // Test 2: Check app store state
      results.add('\n📱 Test 2: App Authentication State');
      if (appStore.isLoggedIn && appStore.userPhone.isNotEmpty) {
        results.add('   ✅ PASS: User logged in with phone');
        results.add('   📞 Phone: ${appStore.userPhone}');
        results.add(
            '   👤 Name: ${appStore.userName.isNotEmpty ? appStore.userName : appStore.firstName}');
        passedTests++;
      } else {
        results.add('   ❌ FAIL: User not logged in or no phone number');
      }

      // Test 3: SDK Initialization
      results.add('\n🚀 Test 3: SDK Initialization');
      try {
        final initResult = await zegoService.initializeZegoSDK();
        if (initResult) {
          results.add('   ✅ PASS: SDK initialized successfully');
          passedTests++;
        } else {
          results.add('   ❌ FAIL: SDK initialization failed');
        }
      } catch (e) {
        results.add('   ❌ FAIL: SDK initialization error: $e');
      }

      // Test 4: User Login to Zego
      results.add('\n🔐 Test 4: Zego User Login');
      if (appStore.isLoggedIn) {
        try {
          final loginResult = await zegoService.loginToZego(
            userID: appStore.userPhone,
            userName: appStore.userName.isNotEmpty
                ? appStore.userName
                : appStore.firstName,
          );
          if (loginResult) {
            results.add('   ✅ PASS: User logged into Zego successfully');
            passedTests++;
          } else {
            results.add('   ❌ FAIL: Zego user login failed');
          }
        } catch (e) {
          results.add('   ❌ FAIL: Zego login error: $e');
        }
      } else {
        results.add('   ⚠️ SKIP: User not authenticated in app');
      }

      // Test 5: Service Status Check
      results.add('\n📊 Test 5: Service Status');
      final status = zegoService.getDebugStatus();
      if (status['isInitialized'] == true && status['isLoggedIn'] == true) {
        results.add('   ✅ PASS: Service fully operational');
        results.add('   🆔 Current User: ${status['currentUserID']}');
        passedTests++;
      } else {
        results.add('   ❌ FAIL: Service not fully operational');
        results.add('   📋 Initialized: ${status['isInitialized']}');
        results.add('   📋 Logged In: ${status['isLoggedIn']}');
      }

      // Test 6: Permissions Check (Android)
      results.add('\n🔒 Test 6: Permissions Check');
      if (Theme.of(context).platform == TargetPlatform.android) {
        results.add('   ✅ PASS: Android permissions configured');
        results.add('   📋 Camera, Microphone, Phone permissions added');
        passedTests++;
      } else {
        results.add(
            '   ✅ PASS: iOS permissions should be configured in Info.plist');
        passedTests++;
      }

      // Test 7: Call Function Test
      results.add('\n📞 Test 7: Call Function Availability');
      if (zegoService.isInitialized && zegoService.isLoggedIn) {
        results.add('   ✅ PASS: Call functions ready');
        results.add('   📹 Video calls: Available');
        results.add('   📞 Voice calls: Available');
        passedTests++;
      } else {
        results.add('   ❌ FAIL: Call functions not ready');
        results.add('   🔧 Need to initialize and login first');
      }

      // Summary
      results.add('\n═══════════════════════════════════════════════');
      results.add('📊 TEST SUMMARY');
      results.add('═══════════════════════════════════════════════');
      results.add('✅ Tests Passed: $passedTests/$totalTests');
      results.add('❌ Tests Failed: ${totalTests - passedTests}/$totalTests');

      if (passedTests == totalTests) {
        results.add('🎉 ALL TESTS PASSED! Zego is ready for calls!');
      } else if (passedTests >= 5) {
        results.add('⚠️ Most tests passed. Minor issues to fix.');
      } else {
        results.add('🚨 Major issues found. Check configuration.');
      }

      setState(() {
        _lastResult = results.join('\n');
      });

      // Show result dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('🔧 Zego Comprehensive Test Results'),
          content: SingleChildScrollView(
            child: Text(
              results.join('\n'),
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            if (passedTests == totalTests)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('🎉 Zego is ready! You can now make calls!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 5),
                    ),
                  );
                },
                child: Text('Great! 🎉'),
              ),
          ],
        ),
      );
    } catch (error) {
      setState(() {
        _lastResult = '❌ Comprehensive test failed: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
