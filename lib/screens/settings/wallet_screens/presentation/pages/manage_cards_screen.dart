import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taxi_booking/model/PaymentCardModel.dart';
import 'package:taxi_booking/network/RestApis.dart';
import 'package:taxi_booking/utils/Extensions/app_common.dart';
import 'package:taxi_booking/utils/core/constant/app_colors.dart';
import 'package:taxi_booking/utils/core/constant/styles/app_text_style.dart';
import 'package:taxi_booking/utils/core/utils/responsive_vertical_space.dart';
import 'package:taxi_booking/utils/core/widget/appbar/back_app_bar.dart';

class ManageCardsScreen extends StatefulWidget {
  const ManageCardsScreen({super.key});

  @override
  State<ManageCardsScreen> createState() => _ManageCardsScreenState();
}

class _ManageCardsScreenState extends State<ManageCardsScreen> {
  List<PaymentCardModel> _cards = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    setState(() => _loading = true);
    try {
      final cards = await getPaymentCards();
      setState(() => _cards = cards);
    } catch (e) {
      toast('فشل في تحميل البطاقات');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteCard(int cardId) async {
    try {
      await deletePaymentCard(cardId: cardId);
      toast('تم حذف البطاقة');
      await _fetchCards();
    } catch (e) {
      toast('فشل حذف البطاقة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackAppBar(title: 'البطاقات البنكيه'),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _cards.isEmpty
                      ? Center(
                          child: Text('لا توجد بطاقات محفوظة', style: AppTextStyles.sMedium16(color: AppColors.gray)),
                        )
                      : ListView.separated(
                          itemBuilder: (context, index) {
                            final card = _cards[index];
                            final last4 = (card.cardNumber ?? '').length >= 4
                                ? card.cardNumber!.substring(card.cardNumber!.length - 4)
                                : card.cardNumber ?? '';
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x15000000),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    'assets/assets/images/visa.png',
                                    width: 64.r,
                                    height: 58.h,
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          card.cardHolderName ?? 'بطاقة',
                                          style: TextStyle(
                                            color: AppColors.textColor,
                                            fontSize: 16.spMin,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '**** **** **** $last4',
                                          style: TextStyle(
                                            color: AppColors.gray,
                                            fontSize: 14.spMin,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () {
                                      if (card.id != null) _deleteCard(card.id!);
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => const ResponsiveVerticalSpace(16),
                          itemCount: _cards.length,
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
