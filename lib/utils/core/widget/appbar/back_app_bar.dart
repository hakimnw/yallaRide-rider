import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BackAppBar extends StatelessWidget {
  final String title;
  const BackAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        height: 105.h,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/assets/images/home_screen_app_bar.png"),
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 21.w, vertical: 20.h),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.spMin,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.30,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                    onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_forward, color: Colors.white)),
              ],
            ),
          ),
        ));
  }

  // @override
  // Size get preferredSize => Size.fromHeight(105.h);
}
