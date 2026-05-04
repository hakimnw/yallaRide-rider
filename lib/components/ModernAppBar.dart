import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constant/app_colors.dart';

class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final double? elevation;
  final Color? shadowColor;
  final Function()? onBackPressed;

  const ModernAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.elevation,
    this.shadowColor,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: elevation != null && elevation! > 0
              ? [
                  BoxShadow(
                    color: shadowColor ?? Colors.black.withAlpha(25),
                    blurRadius: elevation! * 3,
                    offset: Offset(0, elevation!),
                  ),
                ]
              : null,
        ),
        child: AppBar(
          automaticallyImplyLeading: automaticallyImplyLeading,
          flexibleSpace: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  image: DecorationImage(
                    image: AssetImage('assets/assets/images/Vector.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(76),
                      Colors.black.withAlpha(13),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              Opacity(
                opacity: 0.05,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.8,
                      colors: [
                        Colors.white.withAlpha(25),
                        Colors.transparent,
                      ],
                      stops: [0.1, 1.0],
                    ),
                  ),
                  child: CustomPaint(
                    painter: PatternPainter(),
                    size: Size.infinite,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: centerTitle,
          iconTheme: IconThemeData(color: Colors.white),
          titleSpacing: 0,
          actions: actions,
          leading: leading,
          title: Padding(
            padding: EdgeInsets.symmetric(horizontal: centerTitle ? 0 : 8),
            child: title.isNotEmpty
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      /*      SizedBox(width: 8),
                      Container(
                        height: 8,
                        width: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withAlpha(127),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                   */
                    ],
                  )
                : null,
          ),
          systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle?.copyWith(
                    statusBarColor: Colors.transparent,
                    statusBarIconBrightness: Brightness.light,
                  ) ??
              const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(100);
}

/// Custom painter to draw a subtle dot pattern for visual depth
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(76)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    final dotSize = 1.0;
    final spacing = 12.0;
    final random = math.Random(42); // Fixed seed for consistency

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Add some randomness to dot positions
        final offsetX = random.nextDouble() * 3 - 1.5;
        final offsetY = random.nextDouble() * 3 - 1.5;

        // Vary opacity slightly
        final opacity = 0.1 + random.nextDouble() * 0.2;
        paint.color = Colors.white.withOpacity(opacity);

        canvas.drawCircle(Offset(x + offsetX, y + offsetY), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
