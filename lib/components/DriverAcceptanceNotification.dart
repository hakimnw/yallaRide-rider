import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DriverAcceptanceNotification extends StatefulWidget {
  final String? driverName;
  final VoidCallback? onDismiss;

  const DriverAcceptanceNotification({
    Key? key,
    this.driverName,
    this.onDismiss,
  }) : super(key: key);

  @override
  _DriverAcceptanceNotificationState createState() =>
      _DriverAcceptanceNotificationState();
}

class _DriverAcceptanceNotificationState
    extends State<DriverAcceptanceNotification> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.bounceOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Start animations
    _startAnimations();

    // Add haptic feedback and sound
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.alert);
  }

  void _startAnimations() async {
    await Future.delayed(Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _slideController.forward();
    await Future.delayed(Duration(milliseconds: 300));
    _scaleController.forward();
    await Future.delayed(Duration(milliseconds: 500));
    _pulseController.repeat(reverse: true);
  }

  void _dismiss() {
    _pulseController.stop();
    _fadeController.reverse().then((_) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF4CAF50),
                      Color(0xFF45A049),
                      Color(0xFF2E7D32),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0xFF4CAF50).withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Success animation
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 35,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 16),
                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "تم قبول طلبك!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "لقد قبل السائق طلبك",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (widget.driverName != null &&
                              widget.driverName!.isNotEmpty) ...[
                            SizedBox(height: 8),
                            Text(
                              "السائق: ${widget.driverName}",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ] else ...[
                            SizedBox(height: 8),
                            Text(
                              "يرجى اختيار السائق المناسب لرحلتك",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _dismiss,
                      icon: Icon(
                        Icons.close,
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dialog version for use in showDialog
class DriverAcceptanceNotificationDialog extends StatelessWidget {
  final String? driverName;
  final VoidCallback? onDismiss;

  const DriverAcceptanceNotificationDialog({
    Key? key,
    this.driverName,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: DriverAcceptanceNotification(
        driverName: driverName,
        onDismiss: onDismiss,
      ),
    );
  }
}

// Function to show the notification as an overlay
void showDriverAcceptanceNotification(
  BuildContext context, {
  String? driverName,
  Duration duration = const Duration(seconds: 4),
}) {
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 0,
      right: 0,
      child: DriverAcceptanceNotification(
        driverName: driverName,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    ),
  );

  Overlay.of(context)?.insert(overlayEntry);

  // Auto remove after duration
  Future.delayed(duration, () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}
