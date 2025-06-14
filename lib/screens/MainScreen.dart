import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../components/BottomNavBar.dart';
import '../main.dart';
import '../service/ZegoService.dart';
import '../service/ZegoDebugHelper.dart';
import '../utils/constant/app_colors.dart';
import 'DashBoardScreen.dart';
import 'HomeScreen.dart';
import 'RideListScreen.dart';
import 'WalletScreen.dart';
import 'SettingScreen.dart';
import 'settings_screen_new.dart';

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              '🔧 Zego Professional Debug',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Status Card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: zegoService.isLoggedIn
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: zegoService.isLoggedIn
                      ? Colors.green.withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    zegoService.isLoggedIn ? Icons.check_circle : Icons.warning,
                    color:
                        zegoService.isLoggedIn ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zegoService.isLoggedIn
                              ? 'Zego Service Connected ✅'
                              : 'Zego Service Disconnected ⚠️',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'User: ${zegoService.currentUserID ?? "Not logged in"}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ZegoDebugHelper.runDiagnostics();
                    },
                    icon: Icon(Icons.analytics),
                    label: Text('Run Diagnostics'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ZegoDebugHelper.showDebugDialog(context);
                    },
                    icon: Icon(Icons.info),
                    label: Text('Debug Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Test Call Section
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showTestCallDialog();
                },
                icon: Icon(Icons.call),
                label: Text('Test Call Function'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Show test call dialog
  void _showTestCallDialog() {
    final TextEditingController phoneController =
        TextEditingController(text: '01234567890');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📞 Test Zego Call'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Test Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This will send a real call invitation to the entered number.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await ZegoDebugHelper.testCall(
                context: context,
                targetPhone: phoneController.text,
                targetName: 'Debug Test Driver',
                isVideoCall: true,
              );
            },
            icon: Icon(Icons.videocam),
            label: Text('Video Call'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await ZegoDebugHelper.testCall(
                context: context,
                targetPhone: phoneController.text,
                targetName: 'Debug Test Driver',
                isVideoCall: false,
              );
            },
            icon: Icon(Icons.call),
            label: Text('Voice Call'),
          ),
        ],
      ),
    );
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
      floatingActionButton: _buildZegoDebugFAB(),
    );
  }
}
