import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../components/BottomNavBar.dart';
import '../main.dart';
import '../service/ZegoService.dart';
import '../service/ZegoDebugHelper.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import 'DashBoardScreen.dart';
import 'HomeScreen.dart';
import 'RideListScreen.dart';
import 'WalletScreen.dart';
import 'SettingScreen.dart';
import 'settings_screen_new.dart';
import 'ZegoDebugScreen.dart';
import 'EditProfileScreen.dart';
import 'EmergencyContactScreen.dart';
import 'GoogleMapScreen.dart';
import 'NoInternetScreen.dart';
import 'ScheduleRideListScreen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  MainScreen({this.initialIndex = 0});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _screens = [
      HomeScreen(),
      DashBoardScreen(),
      RideListScreen(),
      // WalletScreen(),
      SettingScreen(),
      SettingsScreenNew(),
    ];

    // Set the initial page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _currentIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  /// Build Zego debug FAB for development testing
  Widget? _buildZegoDebugFAB() {
    // Only show in debug mode for development
    if (kDebugMode) {
      return FloatingActionButton(
        mini: true,
        backgroundColor: zegoService.isLoggedIn ? Colors.green : Colors.orange,
        onPressed: _showZegoQuickDebug,
        child: Icon(Icons.video_call, color: Colors.white, size: 20),
        tooltip: 'Zego Debug',
      );
    }
    return null;
  }

  /// Show enhanced Zego debug options
  void _showZegoQuickDebug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🔧 Zego Quick Debug'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quick Zego Connection Test',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 16),

              // Test Connection Button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _performZegoConnectionTest();
                  },
                  icon: Icon(Icons.network_check),
                  label: Text('🔍 Test Connection'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ),
              SizedBox(height: 8),

              // Force Reinitialize Button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _forceReinitializeZego();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('🔄 Force Reinitialize'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ),
              SizedBox(height: 8),

              // Full Debug Screen Button
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ZegoDebugScreen()),
                    );
                  },
                  icon: Icon(Icons.settings),
                  label: Text('🛠️ Full Debug Screen'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                ),
              ),
              SizedBox(height: 16),

              // Current Status
              Text('Current Status:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('SDK Initialized: ${zegoService.isInitialized}'),
              Text('User Logged In: ${zegoService.isLoggedIn}'),
              Text('App User Phone: ${appStore.userPhone}'),
              Text('App User Name: ${appStore.userName}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Perform comprehensive Zego connection test
  Future<void> _performZegoConnectionTest() async {
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
                Text('Testing Zego Connection...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      List<String> results = [];

      // Test 1: Check credentials
      results.add('1. Checking Zego Credentials:');
      if (ZEGO_APP_ID > 0 && ZEGO_APP_SIGN.isNotEmpty) {
        results.add('   ✅ Credentials OK');
      } else {
        results.add('   ❌ Credentials INVALID');
      }

      // Test 2: Check app user
      results.add('2. Checking App User:');
      if (appStore.isLoggedIn && appStore.userPhone.isNotEmpty) {
        results.add('   ✅ User logged in: ${appStore.userPhone}');
      } else {
        results.add('   ❌ User not logged in or no phone');
      }

      // Test 3: Initialize SDK
      results.add('3. Testing SDK Initialization:');
      try {
        bool initResult = await zegoService.initializeZegoSDK();
        results
            .add(initResult ? '   ✅ SDK initialized' : '   ❌ SDK init failed');
      } catch (e) {
        results.add('   ❌ SDK init error: $e');
      }

      // Test 4: Login to Zego
      results.add('4. Testing Zego Login:');
      if (appStore.isLoggedIn) {
        try {
          bool loginResult = await zegoService.loginToZego(
            userID: appStore.userPhone,
            userName: appStore.userName.isNotEmpty
                ? appStore.userName
                : appStore.firstName,
          );
          results.add(loginResult
              ? '   ✅ Zego login successful'
              : '   ❌ Zego login failed');
        } catch (e) {
          results.add('   ❌ Zego login error: $e');
        }
      } else {
        results.add('   ⚠️ Skipped - user not authenticated');
      }

      // Test 5: Final status
      results.add('5. Final Status:');
      results.add('   SDK Ready: ${zegoService.isInitialized}');
      results.add('   User Ready: ${zegoService.isLoggedIn}');
      results.add(
          '   Overall: ${zegoService.isInitialized && zegoService.isLoggedIn ? "✅ READY" : "❌ NOT READY"}');

      Navigator.pop(context); // Close loading

      // Show results
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('🔍 Connection Test Results'),
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
            if (zegoService.isInitialized && zegoService.isLoggedIn)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 Zego is ready! Try making a call now!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: Text('Test Passed! 🎉'),
              ),
          ],
        ),
      );
    } catch (error) {
      Navigator.pop(context); // Close loading
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('❌ Test Failed'),
          content: Text('Error: $error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  /// Force reinitialize Zego service
  Future<void> _forceReinitializeZego() async {
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
                Text('Reinitializing Zego...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Step 1: Logout first
      await zegoService.logoutFromZego();

      // Step 2: Reinitialize
      bool initResult = await zegoService.initializeZegoSDK();

      // Step 3: Login again if user is authenticated
      bool loginResult = false;
      if (appStore.isLoggedIn && appStore.userPhone.isNotEmpty) {
        loginResult = await zegoService.loginToZego(
          userID: appStore.userPhone,
          userName: appStore.userName.isNotEmpty
              ? appStore.userName
              : appStore.firstName,
        );
      }

      Navigator.pop(context); // Close loading

      String message;
      Color color;

      if (initResult && loginResult) {
        message = '🎉 Zego reinitialized successfully! Ready for calls!';
        color = Colors.green;
      } else if (initResult) {
        message =
            '⚠️ SDK initialized but login failed. Check user authentication.';
        color = Colors.orange;
      } else {
        message = '❌ Reinitialize failed. Check credentials and network.';
        color = Colors.red;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (error) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Reinitialize error: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),

      // Zego Debug FAB for development
      floatingActionButton: FloatingActionButton(
        onPressed: _showZegoQuickDebug,
        child: Icon(Icons.bug_report),
        backgroundColor: Colors.orange,
        tooltip: 'Test Zego Connection',
      ),
    );
  }
}
