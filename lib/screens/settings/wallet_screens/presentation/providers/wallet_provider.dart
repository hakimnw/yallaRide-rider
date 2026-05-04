import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:taxi_booking/model/UserDetailModel.dart';
import 'package:taxi_booking/model/WalletInfoModel.dart';
import 'package:taxi_booking/model/WalletListModel.dart';
import 'package:taxi_booking/network/RestApis.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider._();
  static final _instance = WalletProvider._();
  factory WalletProvider() => _instance;
  UserBankAccount? _bankAccount;
  UserBankAccount? get bankAccount => _bankAccount;

  bool _loading = false;
  bool _checkoutLoading = false;
  WalletInfoModel? _info;
  List<WalletModel>? _transactions;
  String? _error;

  bool get isLoading => _loading;
  bool get isCheckoutLoading => _checkoutLoading;
  WalletInfoModel? get info => _info;
  List<WalletModel>? get transactions => _transactions;
  num? get balance => _info?.totalAmount ?? _info?.walletData?.totalAmount;
  String? get error => _error;
  bool get hasWallet => _info != null;

  String get formattedBalance {
    final b = balance;
    if (b == null) return '—';
    // Format in Arabic with SAR label
    final f = NumberFormat.currency(locale: 'ar_SA', symbol: '', decimalDigits: 2);
    final amount = f.format(b);
    return '$amount ر.س';
  }

  Future<void> fetchWallet() async {
    _setLoading(true);
    try {
      final data = await getWalletData();
      _info = data;
      // Fetch transactions
      final transactionsData = await getWalletList(page: 1);
      _transactions = transactionsData.data;

      // Update wallet info from wallet list response if available (more up-to-date)
      if (transactionsData.walletBalance != null) {
        _info = WalletInfoModel(
          walletData: WalletData(
            id: transactionsData.walletBalance!.id,
            userId: transactionsData.walletBalance!.userId,
            totalAmount: transactionsData.walletBalance!.totalAmount,
            totalWithdrawn: transactionsData.walletBalance!.totalWithdrawn,
            currency: transactionsData.walletBalance!.currency,
            createdAt: transactionsData.walletBalance!.createdAt,
            updatedAt: transactionsData.walletBalance!.updatedAt,
          ),
          totalAmount: transactionsData.walletBalance!.totalAmount,
        );
        print('WalletProvider: Updated wallet info from wallet list response');
      }

      // Debug logging for wallet list parsing
      print('WalletProvider: Parsed ${transactionsData.data?.length ?? 0} transactions');
      if (transactionsData.data != null && transactionsData.data!.isNotEmpty) {
        print(
            'WalletProvider: First transaction - ID: ${transactionsData.data![0].id}, Amount: ${transactionsData.data![0].amount}, Type: ${transactionsData.data![0].type}');
      }
      if (transactionsData.pagination != null) {
        print(
            'WalletProvider: Pagination - Total: ${transactionsData.pagination!.totalItems}, Current Page: ${transactionsData.pagination!.currentPage}');
      }

      _error = null;
      // Set bank account if available
      if (data.walletData != null && data.walletData is WalletData) {
        // If walletData has bank info, set it here if needed
      }
      // Try to get bank account from user profile if available
      // This is a placeholder; in a real app, fetch user profile and set _bankAccount
      // _bankAccount = ...
    } catch (e) {
      _error = e.toString();
      print('WalletProvider: Error fetching wallet data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Withdraws money to the user's bank account
  Future<String?> withdraw({required double amount, required UserBankAccount bankAccount}) async {
    try {
      final res = await saveWithDrawRequest({
        "user_id": bankAccount.userId,
        "currency": _info?.walletData?.currency ?? 'SAR',
        "amount": amount,
        "status": "0",
        "account_number": bankAccount.accountNumber,
        "bank_code": bankAccount.bankCode,
        "bank_name": bankAccount.bankName,
        "account_holder_name": bankAccount.accountHolderName,
        "bank_iban": bankAccount.bankIban,
        "bank_swift": bankAccount.bankSwift,
        "routing_number": bankAccount.routingNumber,
      });
      await fetchWallet();
      return res.message?.toString() ?? 'تم إرسال طلب السحب';
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Creates a checkout session for charging the wallet and returns a URL if available
  Future<String?> createCheckout({required double amount, String paymentType = 'MADA'}) async {
    _setCheckoutLoading(true);
    try {
      final res = await createCheckoutPayment(amount: amount, paymentType: paymentType);

      // Debug logging
      print('Checkout API Response: $res');

      // Extract URL with multiple fallbacks
      String? url;
        url = res['redirect_url']?.toString() ??
            res['checkout_url']?.toString() ??
            res['url']?.toString() ??
            res['payment_url']?.toString();
      // Validate URL
      if (url != null && url.isNotEmpty) {
        // Basic URL validation
        if (url.startsWith('http://') || url.startsWith('https://')) {
          print('Valid checkout URL extracted: $url');
          return url;
        } else {
          print('Invalid URL format: $url');
          return null;
        }
      }

      print('No valid URL found in checkout response');
      return null;
    } catch (e) {
      print('Error in createCheckout: $e');
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setCheckoutLoading(false);
    }
  }

  Future<void> refresh() async {
    await fetchWallet();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setCheckoutLoading(bool value) {
    _checkoutLoading = value;
    notifyListeners();
  }
}
