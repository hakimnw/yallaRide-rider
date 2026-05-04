import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../utils/constant/app_colors.dart';

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Icons for the nav bar
  final List<String> _icons = [
    'assets/assets/images/home.svg',
    'assets/assets/images/basil_location-outline.svg',
    'assets/assets/icons/car.svg',
    'assets/assets/icons/edit.svg',
    'assets/assets/images/iconamoon_profile-light.svg',
  ];
  // Titles for the nav bar items
  final List<String> _titles = [
    'الرئيسية',
    'الخريطة',
    'الرحلات',
    'الإعدادات',
    'الملف',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 70 + bottomPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _icons.length,
            (index) => _buildNavItem(
              icon: _icons[index].toString(),
              title: _titles[index],
              index: index,
              isSelected: widget.currentIndex == index,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String icon,
    required String title,
    required int index,
    required bool isSelected,
  }) {
    // Animation for selected item
    final Animation<double> animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        index * 0.1,
        0.5 + index * 0.1,
        curve: Curves.fastOutSlowIn,
      ),
    ));

    return InkWell(
      onTap: () => widget.onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 100),
        width: 70,
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, isSelected ? -4 * animation.value : 0),
                  child: SvgPicture.asset(
                    icon,
                    color: isSelected ? AppColors.primary : Colors.grey,
                    width: isSelected ? 20 : 18,
                    height: isSelected ? 20 : 18,
                  ),
                );
              },
            ),
            SizedBox(height: 4),
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: isSelected ? animation.value : 0.7,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
