import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
// import removed: wallet_charged_screen.dart

import 'package:provider/provider.dart';

import '../../../../../../../../../../main.dart';
import '../../../../../../../../../components/ModernAppBar.dart';
import '../../../../../../../../../model/WalletListModel.dart';
import '../../../../../../../../../utils/Colors.dart';
import '../../../../../../../../../utils/Common.dart';
import '../../../../../../../../../utils/Constants.dart';
import '../../../../../../../../../utils/Extensions/app_common.dart';
import '../../../../../../../../../utils/Extensions/app_textfield.dart';
import '../../../../../utils/constant/app_colors.dart';
import '../providers/wallet_provider.dart';
import 'payment_webview_page.dart';

class WalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Provider.of<WalletProvider>(context, listen: false).fetchWallet();
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: ModernAppBar(title: "المحفظة"),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  await provider.refresh();
                },
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWalletCard(context, provider),
                      _buildQuickActions(context, provider),
                      _buildStatisticsCards(context, provider),
                      _buildTransactionsList(context, provider),
                    ],
                  ),
                ),
              ),
              if (provider.isLoading)
                Container(
                  color: Colors.black12,
                  child: Center(
                    child: loaderWidget(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletCard(BuildContext context, WalletProvider provider) {
    return Container(
      margin: EdgeInsets.all(16),
      child: Stack(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E3C72),
                  Color(0xFF2A5298),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1E3C72).withAlpha(76),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
          ),
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(25),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(25),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        MaterialCommunityIcons.wallet_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "رصيد المحفظة",
                        style: TextStyle(
                          color: Colors.white.withAlpha(226),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          provider.formattedBalance,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          MaterialCommunityIcons.shield_check_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "محفظة آمنة 100%",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WalletProvider provider) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: MaterialCommunityIcons.cash_plus,
              label: "إيداع",
              gradient: LinearGradient(
                colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              ),
              onTap: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _buildAddMoneyBottomSheet(context),
                );
              },
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: _buildActionButton(
              icon: MaterialCommunityIcons.cash_minus,
              label: "سحب",
              gradient: LinearGradient(
                colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
              ),
              onTap: () async {
                toast("Comming Soon...");

                // if (amount > 0) {
                //   // Use provider for withdraw logic
                //   final userBankAccount = Provider.of<UserDetailModel?>(context, listen: false)?.data?.userBankAccount;
                //   if (userBankAccount == null ||
                //       userBankAccount.accountNumber == null ||
                //       userBankAccount.accountNumber!.isEmpty) {
                //     toast("يرجى إضافة معلومات الحساب البنكي أولاً");
                //     Navigator.push(context, MaterialPageRoute(builder: (_) => BankInfoScreen()));
                //     return;
                //   }
                //   showModalBottomSheet(
                //     context: context,
                //     isScrollControlled: true,
                //     backgroundColor: Colors.transparent,
                //     builder: (_) => _buildWithdrawBottomSheet(context, provider, userBankAccount),
                //   );
                // } else {
                //   toast("لا يوجد رصيد كافي للسحب");
                // }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildWithdrawBottomSheet(BuildContext context, WalletProvider provider, UserBankAccount userBankAccount) {
  //   TextEditingController withdrawController = TextEditingController();
  //   final formKey = GlobalKey<FormState>();
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(32),
  //         topRight: Radius.circular(32),
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withAlpha(25),
  //           blurRadius: 10,
  //           offset: Offset(0, -5),
  //         ),
  //       ],
  //     ),
  //     padding: MediaQuery.of(context).viewInsets,
  //     child: Form(
  //       key: formKey,
  //       child: StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return SafeArea(
  //             child: SingleChildScrollView(
  //               padding: EdgeInsets.all(24),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   Center(
  //                     child: Container(
  //                       height: 5,
  //                       width: 50,
  //                       decoration: BoxDecoration(
  //                         color: Colors.grey.shade300,
  //                         borderRadius: BorderRadius.circular(20),
  //                       ),
  //                     ),
  //                   ),
  //                   SizedBox(height: 20),
  //                   Row(
  //                     children: [
  //                       Container(
  //                         padding: EdgeInsets.all(12),
  //                         decoration: BoxDecoration(
  //                           color: primaryColor.withAlpha(25),
  //                           shape: BoxShape.circle,
  //                         ),
  //                         child: Icon(
  //                           Icons.account_balance,
  //                           color: primaryColor,
  //                           size: 24,
  //                         ),
  //                       ),
  //                       SizedBox(width: 16),
  //                       Text(
  //                         "سحب الرصيد",
  //                         style: TextStyle(
  //                           fontSize: 22,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.grey.shade800,
  //                         ),
  //                       ),
  //                       Spacer(),
  //                       IconButton(
  //                         onPressed: () {
  //                           Navigator.pop(context);
  //                         },
  //                         icon: Container(
  //                           padding: EdgeInsets.all(4),
  //                           decoration: BoxDecoration(
  //                             color: Colors.grey.shade200,
  //                             shape: BoxShape.circle,
  //                           ),
  //                           child: Icon(
  //                             Icons.close,
  //                             color: Colors.grey.shade700,
  //                             size: 20,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   SizedBox(height: 30),
  //                   Row(
  //                     children: [
  //                       Text(
  //                         "المبلغ",
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.w600,
  //                           color: Colors.grey.shade800,
  //                         ),
  //                       ),
  //                       Text(
  //                         ' *',
  //                         style: TextStyle(
  //                           fontSize: 16,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.red,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   SizedBox(height: 12),
  //                   AppTextField(
  //                     controller: withdrawController,
  //                     textFieldType: TextFieldType.PHONE,
  //                     keyboardType: TextInputType.number,
  //                     inputFormatters: [
  //                       FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
  //                     ],
  //                     errorThisFieldRequired: language.thisFieldRequired,
  //                     validator: (String? val) {
  //                       if (val == null || val.isEmpty) return language.thisFieldRequired;
  //                       final numValue = double.tryParse(val);
  //                       if (numValue == null || numValue <= 0) return language.pleaseSelectAmount;
  //                       if (numValue > (provider.balance ?? 0)) return 'المبلغ أكبر من الرصيد المتاح';
  //                       return null;
  //                     },
  //                     decoration: InputDecoration(
  //                       filled: true,
  //                       fillColor: Colors.grey.shade100,
  //                       hintText: "المبلغ",
  //                       hintStyle: TextStyle(color: Colors.grey.shade500),
  //                       prefixIcon: Icon(Icons.monetization_on_rounded, color: primaryColor),
  //                       enabledBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(16),
  //                         borderSide: BorderSide(color: Colors.transparent),
  //                       ),
  //                       focusedBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(16),
  //                         borderSide: BorderSide(color: primaryColor, width: 1.5),
  //                       ),
  //                       errorBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(16),
  //                         borderSide: BorderSide(color: Colors.red),
  //                       ),
  //                       focusedErrorBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(16),
  //                         borderSide: BorderSide(color: Colors.red),
  //                       ),
  //                       contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  //                     ),
  //                   ),
  //                   SizedBox(height: 24),
  //                   Container(
  //                     height: 56,
  //                     width: double.infinity,
  //                     decoration: BoxDecoration(
  //                       gradient: LinearGradient(
  //                         begin: Alignment.topLeft,
  //                         end: Alignment.bottomRight,
  //                         colors: [
  //                           Color(0xFFFF416C),
  //                           Color(0xFFFF4B2B),
  //                         ],
  //                       ),
  //                       borderRadius: BorderRadius.circular(16),
  //                       boxShadow: [
  //                         BoxShadow(
  //                           color: primaryColor.withAlpha(76),
  //                           blurRadius: 10,
  //                           offset: Offset(0, 5),
  //                         ),
  //                       ],
  //                     ),
  //                     child: Material(
  //                       color: Colors.transparent,
  //                       child: InkWell(
  //                         borderRadius: BorderRadius.circular(16),
  //                         onTap: () async {
  //                           if (formKey.currentState!.validate()) {
  //                             final amount = double.tryParse(withdrawController.text);
  //                             if (amount != null && amount > 0) {
  //                               Navigator.pop(context);
  //                               final msg = await provider.withdraw(amount: amount, bankAccount: userBankAccount);
  //                               if (msg != null) {
  //                                 toast(msg);
  //                               } else {
  //                                 toast('تعذر تنفيذ عملية السحب');
  //                               }
  //                             }
  //                           }
  //                         },
  //                         child: Center(
  //                           child: Row(
  //                             mainAxisSize: MainAxisSize.min,
  //                             children: [
  //                               Icon(
  //                                 Icons.remove_circle_outline_rounded,
  //                                 color: Colors.white,
  //                                 size: 20,
  //                               ),
  //                               SizedBox(width: 10),
  //                               Text(
  //                                 "سحب الرصيد",
  //                                 style: TextStyle(
  //                                   color: Colors.white,
  //                                   fontWeight: FontWeight.bold,
  //                                   fontSize: 16,
  //                                   letterSpacing: 0.5,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                   SizedBox(height: 20),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  Widget _buildStatisticsCards(BuildContext context, WalletProvider provider) {
    final deposits = provider.info?.walletData?.totalAmount ?? 0;
    final withdrawals = provider.info?.walletData?.totalWithdrawn ?? 0;
    final depositsStr = deposits.toStringAsFixed(2);
    final withdrawalsStr = withdrawals.toStringAsFixed(2);

    return Container(
      margin: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "إحصائيات المحفظة",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  key: ValueKey('deposits_$depositsStr'),
                  title: "إجمالي الإيداعات",
                  value: "+${depositsStr}",
                  icon: MaterialCommunityIcons.trending_up,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  key: ValueKey('withdrawals_$withdrawalsStr'),
                  title: "إجمالي السحوبات",
                  value: "-${withdrawalsStr}",
                  icon: MaterialCommunityIcons.trending_down,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    Key? key,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      key: key,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(25),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Spacer(),
              Icon(
                MaterialCommunityIcons.chevron_right,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withAlpha(76),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, WalletProvider provider) {
    final transactions = provider.transactions ?? [];

    // Debug logging for transaction display
    print('WalletScreen: Building transactions list with ${transactions.length} items');
    if (transactions.isNotEmpty) {
      print(
          'WalletScreen: First transaction display - ID: ${transactions[0].id}, Amount: ${transactions[0].amount}, Type: ${transactions[0].type}');
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "آخر المعاملات",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              Icon(
                Icons.history_rounded,
                color: primaryColor,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 16),
          transactions.isEmpty && !provider.isLoading
              ? _buildEmptyTransactions()
              : AnimationLimiter(
                  child: ListView.builder(
                    padding: EdgeInsets.all(0),
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    shrinkWrap: true,
                    itemBuilder: (_, index) {
                      final data = transactions[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _buildTransactionCard(data),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 48,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            "لا توجد معاملات",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "سيظهر المعاملات هنا",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(WalletModel data) {
    final bool isCredit = data.type == CREDIT;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Transaction details could be shown here in the future
          },
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enhanced Transaction Type Icon
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isCredit ? AppColors.primary : Colors.red.shade50,
                    boxShadow: [
                      BoxShadow(
                        color: (isCredit ? AppColors.primary : Colors.red).withAlpha(51),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    isCredit ? Icons.add_rounded : Icons.remove_rounded,
                    color: isCredit ? AppColors.primary : Colors.red.shade700,
                    size: 22,
                  ),
                ),
                SizedBox(width: 16),

                // Transaction Details with Better Typography
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.type == DEBIT ? language.moneyDebit : language.moneyDeposited,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                          SizedBox(width: 4),
                          Text(
                            printDate(data.createdAt ?? DateTime.now().toString()),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Enhanced Amount Display
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCredit ? AppColors.primary : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${isCredit ? "+" : "-"}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isCredit ? AppColors.primary : Colors.red.shade700,
                        ),
                      ),
                      printAmountWidget(
                        amount: '${(data.amount ?? 0).toStringAsFixed(digitAfterDecimal)}',
                        color: isCredit ? AppColors.primary : Colors.red.shade700,
                        weight: FontWeight.bold,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  final formKey = GlobalKey<FormState>();
  final addMoneyController = TextEditingController();
  // Redesigned Add Money Bottom Sheet
  Widget _buildAddMoneyBottomSheet(BuildContext context) {
    int currentIndex = -1;
    return Consumer<WalletProvider>(
      builder: (_, provider, __) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          padding: MediaQuery.of(context).viewInsets,
          child: Form(
            key: formKey,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            height: 5,
                            width: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Header with Money Icon
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primaryColor.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              language.addMoney,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                                addMoneyController.clear();
                                currentIndex = -1;
                              },
                              icon: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.grey.shade700,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),

                        // Amount Label
                        Row(
                          children: [
                            Text(
                              language.amount,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        // Enhanced Amount Field
                        AppTextField(
                          controller: addMoneyController,
                          textFieldType: TextFieldType.PHONE,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                          ],
                          errorThisFieldRequired: language.thisFieldRequired,
                          onChanged: (val) {},
                          validator: (String? val) {
                            if (appStore.minAmountToAdd != null && num.parse(val!) < appStore.minAmountToAdd!) {
                              addMoneyController.text = appStore.minAmountToAdd.toString();
                              addMoneyController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: appStore.minAmountToAdd.toString().length));
                              return "${language.minimum} ${appStore.minAmountToAdd} ${language.required}";
                            } else if (appStore.maxAmountToAdd != null && num.parse(val!) > appStore.maxAmountToAdd!) {
                              addMoneyController.text = appStore.maxAmountToAdd.toString();
                              addMoneyController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: appStore.maxAmountToAdd.toString().length));
                              return "${language.maximum} ${appStore.maxAmountToAdd} ${language.required}";
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            hintText: language.amount,
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            prefixIcon: Icon(Icons.monetization_on_rounded, color: primaryColor),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: primaryColor, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Quick Amounts Label
                        Text(
                          'Quick Amounts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 12),

                        // Enhanced Quick Amount Selection
                        Wrap(
                          runSpacing: 12,
                          spacing: 12,
                          children: appStore.walletPresetTopUpAmount.split('|').map((e) {
                            bool isSelected = currentIndex == appStore.walletPresetTopUpAmount.split('|').indexOf(e);
                            return GestureDetector(
                              onTap: () {
                                currentIndex = appStore.walletPresetTopUpAmount.split('|').indexOf(e);
                                if (appStore.minAmountToAdd != null && num.parse(e) < appStore.minAmountToAdd!) {
                                  addMoneyController.text = appStore.minAmountToAdd.toString();
                                  addMoneyController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: appStore.minAmountToAdd.toString().length));
                                  toast("${language.minimum} ${appStore.minAmountToAdd} ${language.required}");
                                } else if (appStore.minAmountToAdd != null &&
                                    int.parse(e) < appStore.minAmountToAdd! &&
                                    appStore.maxAmountToAdd != null &&
                                    int.parse(e) > appStore.maxAmountToAdd.toString().length) {
                                  addMoneyController.text = appStore.maxAmountToAdd.toString();
                                  addMoneyController.selection = TextSelection.fromPosition(
                                      TextPosition(offset: appStore.maxAmountToAdd.toString().length));
                                  toast("${language.maximum} ${appStore.maxAmountToAdd} ${language.required}");
                                } else {
                                  addMoneyController.text = e;
                                  addMoneyController.selection = TextSelection.fromPosition(TextPosition(offset: e.length));
                                }
                                setState(() {});
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                  border: isSelected ? null : Border.all(color: Colors.grey.shade200),
                                ),
                                child: printAmountWidget(
                                  amount: '${e}',
                                  color: isSelected ? Colors.white : Colors.grey.shade800,
                                  size: 16,
                                  weight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 36),
                        // // Quick access: Manage Cards
                        // Align(
                        //   alignment: Alignment.centerRight,
                        //   child: TextButton.icon(
                        //     onPressed: () {
                        //       Navigator.pushNamed(context, RouterNames.manageCardsScreen);
                        //     },
                        //     icon: Icon(Icons.credit_card, color: primaryColor),
                        //     label:
                        //         Text('إدارة البطاقات', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                        //   ),
                        // ),
                        // SizedBox(height: 12),

                        // Enhanced Add Money Button
                        Container(
                          height: 56,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.darkPrimary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withAlpha(76),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                if (addMoneyController.text.isNotEmpty) {
                                  if (formKey.currentState!.validate() && addMoneyController.text.isNotEmpty) {
                                    final amount = double.tryParse(addMoneyController.text);
                                    if (amount != null && amount > 0) {
                                      // Close bottom sheet first
                                      Navigator.pop(context);

                                      try {
                                        final url = await provider.createCheckout(amount: amount);

                                        if (url != null) {
                                          // Navigate to payment webview using root navigator
                                          final result = await Navigator.of(navigatorKey.currentContext!).push(
                                            MaterialPageRoute(
                                              builder: (context) => PaymentWebViewPage(
                                                title: 'إضافة رصيد',
                                                initialUrl: url,
                                              ),
                                            ),
                                          );
                                          // Handle payment result and refresh wallet balance
                                          if (result == 'success' || result == 'completed') {
                                            toast('تم إضافة الرصيد بنجاح');
                                          } else if (result == 'failed') {
                                            toast('فشلت عملية الدفع، يرجى المحاولة مرة أخرى');
                                          } else {
                                            await provider.refresh();
                                            toast('تم تحديث الرصيد');
                                          }
                                        } else {
                                          toast('تعذر بدء عملية الدفع - لم يتم العثور على رابط صحيح');
                                        }
                                        await provider.refresh();
                                      } catch (e) {
                                        // Dismiss loading dialog on error
                                        if (navigatorKey.currentContext != null) {
                                          Navigator.of(navigatorKey.currentContext!).pop();
                                        }
                                        print('Checkout error: $e');
                                        toast('حدث خطأ أثناء إنشاء جلسة الدفع: ${e.toString()}');
                                      }

                                      addMoneyController.clear();
                                      currentIndex = -1;
                                    } else {
                                      toast(language.pleaseSelectAmount);
                                    }
                                  } else {
                                    toast(language.pleaseSelectAmount);
                                  }
                                } else {
                                  toast(language.pleaseSelectAmount);
                                }
                              },
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      language.addMoney,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
