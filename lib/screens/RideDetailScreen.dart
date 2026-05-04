// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../components/AboutWidget.dart';
import '../main.dart';
import '../model/ComplaintModel.dart';
import '../model/CurrentRequestModel.dart';
import '../model/DriverRatting.dart';
import '../model/OrderHistory.dart';
import '../model/RiderModel.dart';
import '../model/UserDetailModel.dart';
import '../network/RestApis.dart';
import '../screens/ComplaintScreen.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/constant/app_colors.dart';
import 'ChatScreen.dart';
import 'DashBoardScreen.dart';
import 'PDF_Screen.dart';

class RideDetailScreen extends StatefulWidget {
  final int orderId;

  RideDetailScreen({required this.orderId});

  @override
  RideDetailScreenState createState() => RideDetailScreenState();
}

class RideDetailScreenState extends State<RideDetailScreen> {
  RiderModel? riderModel;
  List<RideHistory> rideHistory = [];
  DriverRatting? driverRatting;
  ComplaintModel? complaintData;
  Payment? payment;
  UserData? userData;
  String? invoice_name;
  String? invoice_url;
  bool? isChatHistory;

  @override
  void initState() {
    print(widget.orderId);
    super.initState();
    init();
  }

  void init() async {
    Future.delayed(
      Duration.zero,
      () {
        appStore.setLoading(true);
      },
    );
    try {
      isChatHistory = await chatMessageService.isRideChatHistory(rideId: widget.orderId.toString());

      final value = await rideDetail(orderId: widget.orderId);

      if (mounted) {
        setState(() {
          invoice_name = value.invoice_name ?? '';
          invoice_url = value.invoice_url ?? '';

          if (value.data != null) {
            riderModel = value.data;

            // Handle ride_has_bids safely
            if (value.ride_has_bids != null) {
              try {
                riderModel!.ride_has_bids = int.tryParse(value.ride_has_bids.toString()) ?? 0;
              } catch (e) {
                riderModel!.ride_has_bids = 0;
                print('Error parsing ride_has_bids: $e');
              }
            } else {
              riderModel!.ride_has_bids = 0;
            }

            // Handle ride history safely
            rideHistory.clear();
            if (value.rideHistory != null) {
              rideHistory.addAll(value.rideHistory!);
            }

            // Handle driver rating safely
            if (value.driverRatting != null) {
              driverRatting = value.driverRatting;
            }

            // Handle other data
            complaintData = value.complaintModel;
            payment = value.payment;

            // Handle driver details safely
            if (riderModel?.driverId != null) {
              _loadDriverDetails();
            }
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('لا يمكن تحميل تفاصيل الرحلة'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (error) {
      print('Error in init: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحميل تفاصيل الرحلة'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        appStore.setLoading(false);
      }
    }
  }

  Future<void> _loadDriverDetails() async {
    try {
      if (riderModel?.driverId == null) return;

      final driverId = int.tryParse(riderModel!.driverId.toString());
      if (driverId == null) return;

      final driverValue = await getDriverDetail(userId: driverId);

      if (driverValue.data != null && mounted) {
        setState(() {
          userData = driverValue.data;
        });
      }
    } catch (e) {
      print('Error loading driver details: $e');
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    print(widget.orderId);
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          return true;
        } else {
          launchScreen(context, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
          return false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: Text(riderModel != null ? "رحلة #${riderModel!.id}" : "", style: boldTextStyle(color: Colors.white)),
          actions: [
            if (riderModel != null)
              IconButton(
                  onPressed: () {
                    if (riderModel == null) {
                      return;
                    }
                    launchScreen(
                      context,
                      ComplaintScreen(
                        driverRatting: driverRatting ?? DriverRatting(),
                        complaintModel: complaintData,
                        riderModel: riderModel,
                      ),
                      pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
                    );
                  },
                  icon: Icon(MaterialCommunityIcons.head_question))
          ],
        ),
        body: Stack(
          children: [
            if (riderModel != null)
              SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    driverInformationComponent(),
                    SizedBox(height: 12),
                    if (riderModel!.otherRiderData != null) otherRiderInfoComponent(),
                    if (riderModel!.otherRiderData != null) SizedBox(height: 12),
                    addressComponent(),
                    SizedBox(height: 12),
                    paymentDetail(),
                    Visibility(
                      visible: Navigator.canPop(context) == false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: AppButtonWidget(
                          text: language.continueNewRide,
                          width: MediaQuery.of(context).size.width,
                          onTap: () {
                            launchScreen(context, DashboardScreen(),
                                isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            Observer(builder: (context) {
              if (!appStore.isLoading && riderModel == null) return emptyWidget();
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            })
          ],
        ),
      ),
    );
  }

  Widget addressComponent() {
    if (riderModel == null) return SizedBox();

    return Container(
      decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: dividerColor.withAlpha(127)),
          borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Ionicons.calendar, color: textSecondaryColorGlobal, size: 16),
                  SizedBox(width: 4),
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      '${printDate(riderModel?.createdAt?.toString() ?? DateTime.now().toString())}',
                      style: primaryTextStyle(size: 14),
                    ),
                  ),
                ],
              ),
              if (invoice_url?.isNotEmpty == true)
                inkWellWidget(
                  onTap: () {
                    if (invoice_url?.isEmpty ?? true) {
                      return toast("لا يوجد فاتورة متاحة");
                    }
                    launchScreen(
                      context,
                      PDFViewer(
                        invoice: invoice_url!,
                        filename: invoice_name ?? 'invoice',
                      ),
                      pageRouteAnimation: PageRouteAnimation.SlideBottomTop,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text("الفاتورة", style: primaryTextStyle(color: primaryColor)),
                      SizedBox(width: 4),
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(MaterialIcons.file_download, size: 18, color: primaryColor),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (riderModel?.distance != null) ...[
            SizedBox(height: 16),
            Text(
              '${language.lblDistance} ${riderModel!.distance!.toStringAsFixed(2)} ${riderModel?.distanceUnit ?? 'km'}',
              style: boldTextStyle(size: 14),
            ),
          ],
          if (riderModel?.seatCount != null && riderModel!.seatCount! > 0) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_seat, color: primaryColor, size: 18),
                SizedBox(width: 8),
                Text(
                  'عدد الركاب: ${riderModel!.seatCount}',
                  style: boldTextStyle(size: 14),
                ),
              ],
            ),
          ],
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.near_me, color: AppColors.primary, size: 18),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      riderModel?.startAddress ?? 'غير محدد',
                      style: primaryTextStyle(size: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (riderModel?.endAddress?.isNotEmpty == true) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red, size: 18),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        riderModel!.endAddress!,
                        style: primaryTextStyle(size: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget paymentDetail() {
    if (riderModel == null) return SizedBox();

    return Container(
      decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: dividerColor.withAlpha(127)),
          borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("تفاصيل الدفع", style: boldTextStyle(size: 16)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("الطريقة", style: secondaryTextStyle()),
              Text(paymentStatus(riderModel?.paymentType ?? ''), style: boldTextStyle()),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("الحالة", style: secondaryTextStyle()),
              Text(
                paymentStatus(riderModel?.paymentStatus ?? ''),
                style: boldTextStyle(
                  color: paymentStatusColor(riderModel?.paymentStatus ?? ''),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget otherRiderInfoComponent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: dividerColor.withAlpha(127)),
              borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("معلومات الراكب", style: boldTextStyle()),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Ionicons.person_outline, size: 18),
                  SizedBox(width: 8),
                  Text(riderModel!.otherRiderData!.name.validate(), style: primaryTextStyle()),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        )
      ],
    );
  }

  Widget driverInformationComponent() {
    if (riderModel == null) return SizedBox();

    return InkWell(
      onTap: () {
        if (userData != null) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: AboutWidget(userData: userData),
            ),
          );
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          border: Border.all(color: dividerColor.withAlpha(127)),
          borderRadius: BorderRadius.circular(defaultRadius),
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("عن السائق", style: boldTextStyle(size: 16)),
                if (userData != null)
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          contentPadding: EdgeInsets.zero,
                          content: AboutWidget(userData: userData),
                        ),
                      );
                    },
                    child: Icon(Icons.info_outline),
                  )
              ],
            ),
            SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(defaultRadius),
                  child: commonCachedNetworkImage(riderModel?.driverProfileImage ?? '',
                      height: 50, width: 50, fit: BoxFit.cover),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(riderModel?.driverName ?? '', style: boldTextStyle()),
                      SizedBox(height: 2),
                      if (driverRatting != null)
                        RatingBar.builder(
                          direction: Axis.horizontal,
                          glow: false,
                          allowHalfRating: false,
                          ignoreGestures: true,
                          wrapAlignment: WrapAlignment.spaceBetween,
                          itemCount: 5,
                          itemSize: 16,
                          initialRating: double.parse(driverRatting?.rating?.toString() ?? '0.0'),
                          itemPadding: EdgeInsets.symmetric(horizontal: 0),
                          itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                          onRatingUpdate: (rating) {
                            //
                          },
                        ),
                    ],
                  ),
                ),
                if (isChatHistory == true && riderModel?.id != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: InkWell(
                      onTap: () {
                        launchScreen(context, ChatScreen(userData: null, ride_id: riderModel!.id!, show_history: true));
                      },
                      child: Container(
                          decoration: BoxDecoration(border: Border.all(color: dividerColor), borderRadius: radius(10)),
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.chat_outlined, size: 20)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget priceDetailComponent() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: dividerColor.withAlpha(127)),
        borderRadius: BorderRadius.circular(defaultRadius),
      ),
      padding: EdgeInsets.all(12),
      child: riderModel!.ride_has_bids == 1
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.priceDetail, style: boldTextStyle(size: 16)),
                SizedBox(height: 12),
                totalCount(
                    title: language.amount,
                    amount: riderModel!.surgeCharge != null && riderModel!.surgeCharge! > 0
                        ? riderModel!.subtotal! - riderModel!.surgeCharge!
                        : riderModel!.subtotal!,
                    space: 8),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.couponDiscount, style: secondaryTextStyle()),
                      Row(
                        children: [
                          Text("-", style: boldTextStyle(color: AppColors.primary, size: 14)),
                          printAmountWidget(
                              amount: '${riderModel!.couponDiscount!.toStringAsFixed(digitAfterDecimal)}',
                              color: AppColors.primary,
                              size: 14,
                              weight: FontWeight.normal)
                        ],
                      ),
                    ],
                  ),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0) SizedBox(height: 8),
                if (riderModel!.tips != null) totalCount(title: language.tip, amount: riderModel!.tips),
                // if(riderModel!.surgeCharge != 0)
                //   SizedBox(height: 8,),
                // if (riderModel!.surgeCharge != null && riderModel!.surgeCharge! > 0) totalCount(title: language.fixedPrice, amount: riderModel!.surgeCharge, space: 0),
                if (riderModel!.extraCharges!.isNotEmpty)
                  SizedBox(
                    height: 8,
                  ),
                if (riderModel!.extraCharges!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.additionalFees, style: boldTextStyle()),
                      ...riderModel!.extraCharges!.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key.validate().capitalizeFirstLetter(), style: secondaryTextStyle()),
                              printAmountWidget(amount: e.value!.toStringAsFixed(digitAfterDecimal), size: 14)
                            ],
                          ),
                        );
                      }).toList()
                    ],
                  ),
                // if (riderModel!.tips != null || riderModel!.extraCharges!.isNotEmpty)
                Divider(height: 16, thickness: 1),

                // riderModel!.tips != null
                //     ? riderModel!.extraChargesAmount!=null?totalCount(title: language.total, amount: riderModel!.subtotal! + riderModel!.tips!+riderModel!.extraChargesAmount!, isTotal: true):totalCount(title: language.total, amount:
                // riderModel!.subtotal! + riderModel!.tips!, isTotal: true)
                //     :
                // riderModel!.extraChargesAmount!=null?totalCount(title: language.total, amount: riderModel!.subtotal!+riderModel!.extraChargesAmount!, isTotal: true):totalCount(title: language.total, amount: riderModel!.subtotal,
                //     isTotal: true),
                riderModel!.tips != null
                    ? riderModel!.extraChargesAmount != null
                        ? totalCount(
                            title: language.total,
                            amount: riderModel!.subtotal! + riderModel!.tips! + riderModel!.extraChargesAmount!,
                            isTotal: true)
                        : totalCount(title: language.total, amount: riderModel!.subtotal! + riderModel!.tips!, isTotal: true)
                    : riderModel!.extraChargesAmount != null
                        ? totalCount(
                            title: language.total,
                            amount: riderModel!.subtotal! + riderModel!.extraChargesAmount!,
                            isTotal: true)
                        : totalCount(title: language.total, amount: riderModel!.subtotal, isTotal: true),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.priceDetail, style: boldTextStyle(size: 16)),
                SizedBox(height: 12),
                riderModel!.subtotal! <= riderModel!.minimumFare!
                    ? totalCount(title: language.minimumFare, amount: riderModel!.minimumFare)
                    : Column(
                        children: [
                          totalCount(title: language.basePrice, amount: riderModel!.baseFare, space: 8),
                          totalCount(title: language.distancePrice, amount: riderModel!.perDistanceCharge, space: 8),
                          totalCount(
                              title: language.minutePrice,
                              amount: riderModel!.perMinuteDriveCharge,
                              space: riderModel!.perMinuteWaitingCharge != 0
                                  ? 8
                                  : riderModel!.surgeCharge != 0
                                      ? 8
                                      : 0),
                          totalCount(
                              title: language.waitingTimePrice,
                              amount: riderModel!.perMinuteWaitingCharge,
                              space: riderModel!.surgeCharge != 0 ? 8 : 0),
                        ],
                      ),
                /*    if (riderModel!.surgeCharge != null &&
                    riderModel!.surgeCharge! > 0)
                  totalCount(
                      title: language.fixedPrice,
                      amount: riderModel!.surgeCharge,
                      space: 0),
                SizedBox(height: 8),
                if (riderModel!.couponData != null &&
                    riderModel!.couponDiscount != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.couponDiscount,
                          style: secondaryTextStyle()),
                      Row(
                        children: [
                          Text("-",
                              style:
                                  boldTextStyle(color: AppColors.primary, size: 14)),
                          printAmountWidget(
                              amount:
                                  '${riderModel!.couponDiscount!.toStringAsFixed(digitAfterDecimal)}',
                              color: AppColors.primary,
                              size: 14,
                              weight: FontWeight.normal)
                        ],
                      ),
                    ],
                  ),
                if (riderModel!.couponData != null &&
                    riderModel!.couponDiscount != 0)
                  SizedBox(height: 8),
                if (riderModel!.tips != null)
                  totalCount(title: language.tip, amount: riderModel!.tips),
                if (riderModel!.tips != null) SizedBox(height: 8),
                if (riderModel!.extraCharges!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.additionalFees, style: boldTextStyle()),
                      ...riderModel!.extraCharges!.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key.validate().capitalizeFirstLetter(),
                                  style: secondaryTextStyle()),
                              printAmountWidget(
                                  amount:
                                      '${e.value!.toStringAsFixed(digitAfterDecimal)}',
                                  weight: FontWeight.normal,
                                  size: 14),
                            ],
                          ),
                        );
                      }).toList()
                    ],
                  ),
           /*      Divider(thickness: 1),
                payment != null && payment!.driverTips != 0
                    ? totalCount(
                        title: language.total,
                        amount: riderModel!.totalAmount! + payment!.driverTips!,
                        isTotal: true)
                    : totalCount(
                        title: language.total,
                        amount: riderModel!.totalAmount,
                        isTotal: true),  */*/

                // payment != null && payment!.driverTips != 0
                //     ? totalCount(title: language.total, amount: riderModel!.subtotal! + payment!.driverTips!, isTotal: true)
                //     : totalCount(title: language.total, amount: riderModel!.subtotal, isTotal: true),
              ],
            ),
    );
  }
}
