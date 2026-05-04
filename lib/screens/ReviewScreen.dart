import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:taxi_booking/screens/ComplaintScreen.dart';
import 'package:taxi_booking/screens/MainScreen.dart';
import 'package:taxi_booking/service/RideService.dart';

import '../main.dart';
import '../model/CurrentRequestModel.dart';
import '../model/DriverRatting.dart';
import '../model/RiderModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/constant/app_colors.dart';

class ReviewScreen extends StatefulWidget {
  final Driver? driverData;
  final OnRideRequest rideRequest;

  const ReviewScreen({Key? key, this.driverData, required this.rideRequest}) : super(key: key);

  @override
  ReviewScreenState createState() => ReviewScreenState();
}

class ReviewScreenState extends State<ReviewScreen> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final RideService _rideService = RideService();
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _ratingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _ratingScaleAnimation;

  double _currentRating = 0;
  // int _selectedTipIndex = -1;
  // bool _isMoreTip = false;
  bool _isSubmitting = false;
  // OnRideRequest? _servicesListData;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _ratingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _ratingScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ratingAnimationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  void _initializeData() async {
    try {
      // Validate ride request data first
      if (!_validateRideRequestData()) {
        return;
      }

      if (appStore.walletPresetTipAmount.isNotEmpty) {
        appStore.setWalletTipAmount(appStore.walletPresetTipAmount);
      } else {
        appStore.setWalletTipAmount('10|20|50');
      }
    } catch (e) {
      _handleError('خطأ في تحميل البيانات', e.toString());
    }
  }

  bool _validateRideRequestData() {
    // Check if ride request is valid
    if (widget.rideRequest.id == null || widget.rideRequest.id == 0) {
      _handleError('خطأ في بيانات الرحلة', 'Invalid ride request data');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _navigateToHome();
      });
      return false;
    }

    // Check if driver data is available
    if (widget.driverData == null) {
      _handleError('بيانات السائق غير متوفرة', 'Driver data is missing');
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _navigateToHome();
      });
      return false;
    }

    return true;
  }

  void _handleError(String message, String details) {
    log('Error: $details');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _submitReview({bool skip = false}) async {
    // Validate ride request data
    if (widget.rideRequest.id == null || widget.rideRequest.id == 0) {
      //_handleError('خطأ في بيانات الرحلة', 'Invalid ride request ID');
      _navigateToHome();
      return;
    }

    if (!skip) {
      if (!_formKey.currentState!.validate()) return;
      if (_currentRating == 0) {
        _handleError('يرجى اختيار التقييم', 'Rating is required');
        return;
      }
    }

    setState(() => _isSubmitting = true);
    hideKeyboard(context);

    try {
      // Validate tip amount if provided
      double? tipAmount;
      if (_tipController.text.isNotEmpty) {
        tipAmount = double.tryParse(_tipController.text);
        if (tipAmount == null || tipAmount < 0) {
          _handleError('يرجى إدخال مبلغ إكرامية صحيح', 'Invalid tip amount');
          setState(() => _isSubmitting = false);
          return;
        }
      }

      final Map<String, dynamic> request = {
        "ride_request_id": widget.rideRequest.id.toString(),
        "rating": skip ? 0 : _currentRating.toInt(),
        "comment": skip ? '' : _reviewController.text.trim(),
        if (tipAmount != null && tipAmount > 0) "tips": tipAmount.toString(),
      };

      // Log the request for debugging
      log('Submitting rating review with request: $request');

      await ratingReview(request: request);

      if (tipAmount != null && tipAmount > 0) {
        try {
          await _rideService.updateStatusOfRide(
            rideID: widget.rideRequest.id,
            req: {"on_stream_api_call": 0},
          );
        } catch (tipError) {
          log('Error updating tip status: $tipError');
          // Continue even if tip update fails
        }
      }

      _showSuccessMessage('تم إرسال التقييم بنجاح');

      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainScreen(initialIndex: 0)),
          (route) => false,
        );
      }
    } catch (error) {
      String errorMessage = 'حدث خطأ أثناء إرسال التقييم';
      String errorDetails = error.toString();

      // Handle specific error cases
      if (errorDetails.contains('payment_status') && errorDetails.contains('null')) {
        errorMessage = 'خطأ في بيانات الرحلة - يرجى المحاولة مرة أخرى';
        errorDetails = 'Ride request data is invalid or incomplete';
      } else if (errorDetails.contains('ride_request_id')) {
        errorMessage = 'رقم الرحلة غير صحيح';
        errorDetails = 'Invalid ride request ID';
      } else if (errorDetails.contains('network') || errorDetails.contains('connection')) {
        errorMessage = 'خطأ في الاتصال - يرجى التحقق من الإنترنت';
      }

      _handleError(errorMessage, errorDetails);

      // Navigate to dashboard even on error after delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MainScreen(initialIndex: 0)),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => MainScreen(initialIndex: 0)),
      (route) => false,
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            primaryColor.withAlpha(201),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha(76),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              IconButton(
                onPressed: _navigateToHome,
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  'تقييم السائق',
                  textAlign: TextAlign.center,
                  style: boldTextStyle(color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildActionButton(String text, VoidCallback onPressed) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.white.withAlpha(76)),
  //       borderRadius: BorderRadius.circular(20),
  //     ),
  //     child: MaterialButton(
  //       onPressed: onPressed,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //       minWidth: 0,
  //       child: Text(
  //         text,
  //         style: boldTextStyle(color: Colors.white, size: 12),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDriverCard() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'كيف كانت رحلتك؟',
                    style: boldTextStyle(size: 18),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Hero(
                        tag: 'driver_image_${widget.driverData?.id ?? 'default'}',
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withAlpha(76),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(35),
                            child: _buildDriverImage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getDriverName(),
                              style: boldTextStyle(size: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getDriverEmail(),
                              style: primaryTextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverImage() {
    try {
      final imageUrl = widget.driverData?.profileImage?.validate() ?? '';
      if (imageUrl.isNotEmpty) {
        return commonCachedNetworkImage(
          imageUrl,
          height: 70,
          width: 70,
          fit: BoxFit.cover,
        );
      } else {
        return Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person,
            size: 35,
            color: primaryColor,
          ),
        );
      }
    } catch (e) {
      log('Error loading driver image: $e');
      return Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          color: primaryColor.withAlpha(25),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: 35,
          color: primaryColor,
        ),
      );
    }
  }

  String _getDriverName() {
    try {
      final firstName = widget.driverData?.firstName?.validate().capitalizeFirstLetter() ?? '';
      final lastName = widget.driverData?.lastName?.validate().capitalizeFirstLetter() ?? '';

      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        return '$firstName $lastName'.trim();
      } else {
        return 'السائق';
      }
    } catch (e) {
      log('Error getting driver name: $e');
      return 'السائق';
    }
  }

  String _getDriverEmail() {
    try {
      return widget.driverData?.email?.validate() ?? 'غير متوفر';
    } catch (e) {
      log('Error getting driver email: $e');
      return 'غير متوفر';
    }
  }

  Widget _buildRatingSection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 1.5),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'قيم تجربتك',
                    style: boldTextStyle(size: 16),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _ratingScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _ratingScaleAnimation.value,
                        child: RatingBar.builder(
                          initialRating: _currentRating,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: false,
                          itemCount: 5,
                          itemSize: 40,
                          itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                          itemBuilder: (context, index) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (rating) {
                            setState(() => _currentRating = rating);
                            _ratingAnimationController.forward().then((_) {
                              _ratingAnimationController.reverse();
                            });
                            HapticFeedback.lightImpact();
                          },
                        ),
                      );
                    },
                  ),
                  if (_currentRating > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      _getRatingText(_currentRating),
                      style: primaryTextStyle(color: primaryColor),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'سيء جداً';
      case 2:
        return 'سيء';
      case 3:
        return 'جيد';
      case 4:
        return 'جيد جداً';
      case 5:
        return 'ممتاز';
      default:
        return '';
    }
  }

  Widget _buildCommentSection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 2),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أضف تعليقك',
                    style: boldTextStyle(size: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.withAlpha(76)),
                    ),
                    child: AppTextField(
                      controller: _reviewController,
                      decoration: InputDecoration(
                        hintText: 'شاركنا تجربتك مع السائق...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                        hintStyle: primaryTextStyle(color: Colors.grey[400]),
                      ),
                      textFieldType: TextFieldType.NAME,
                      minLines: 3,
                      maxLines: 5,
                      isValidationRequired: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 3),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withAlpha(201)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(76),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: MaterialButton(
                    onPressed: _isSubmitting ? null : () => _submitReview(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'إرسال التقييم',
                            style: boldTextStyle(color: Colors.white, size: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: primaryColor.withAlpha(76)),
                  ),
                  child: MaterialButton(
                    onPressed: () {
                      // Create DriverRatting object with current rating data
                      final driverRating = DriverRatting(
                        rating: _currentRating.toInt(),
                        comment: _reviewController.text.trim(),
                        driverId: widget.driverData?.id,
                        rideRequestId: widget.rideRequest.id,
                        riderId: sharedPref.getInt(USER_ID),
                        createdAt: DateTime.now().toIso8601String(),
                      );

                      // Create RiderModel object with complete ride data
                      final riderModel = RiderModel(
                        id: widget.rideRequest.id,
                        riderId: widget.rideRequest.riderId,
                        driverId: widget.driverData?.id,
                        driverName: _getDriverName(),
                        driverProfileImage: widget.driverData?.profileImage,
                        driverContactNumber: widget.driverData?.contactNumber,
                        startAddress: widget.rideRequest.startAddress,
                        endAddress: widget.rideRequest.endAddress,
                        startLatitude: widget.rideRequest.startLatitude,
                        startLongitude: widget.rideRequest.startLongitude,
                        endLatitude: widget.rideRequest.endLatitude,
                        endLongitude: widget.rideRequest.endLongitude,
                        status: widget.rideRequest.status,
                        createdAt: widget.rideRequest.createdAt,
                        datetime: widget.rideRequest.datetime,
                        distance: widget.rideRequest.distance,
                        duration: widget.rideRequest.duration,
                        paymentStatus: widget.rideRequest.paymentStatus,
                        paymentType: widget.rideRequest.paymentType,
                        totalAmount: widget.rideRequest.totalAmount,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintScreen(
                            driverRatting: driverRating,
                            riderModel: riderModel,
                          ),
                        ),
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'تقديم شكوى',
                      style: boldTextStyle(color: primaryColor, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _ratingAnimationController.dispose();
    _reviewController.dispose();
    _tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDriverCard(),
                      const SizedBox(height: 16),
                      _buildRatingSection(),
                      const SizedBox(height: 16),
                      _buildCommentSection(),
                      // const SizedBox(height: 16),

                      const SizedBox(height: 24),
                      _buildActionButtons(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
