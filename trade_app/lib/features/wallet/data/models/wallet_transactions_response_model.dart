import 'wallet_transaction_model.dart';

/// Wallet transactions response model (DTO)
class WalletTransactionsResponseModel {
  final List<WalletTransactionModel> transactions;

  const WalletTransactionsResponseModel({required this.transactions});

  factory WalletTransactionsResponseModel.fromJson(Map<String, dynamic> json) {
    final rawTransactions = _extractTransactions(json);

    return WalletTransactionsResponseModel(
      transactions: rawTransactions
          .whereType<Map<String, dynamic>>()
          .map(WalletTransactionModel.fromJson)
          .toList(),
    );
  }

  static WalletTransactionsResponseModel fromResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return WalletTransactionsResponseModel.fromJson(data);
    }

    if (data is List) {
      return WalletTransactionsResponseModel(
        transactions: data
            .whereType<Map<String, dynamic>>()
            .map(WalletTransactionModel.fromJson)
            .toList(),
      );
    }

    throw const FormatException('Invalid wallet transactions response');
  }

  Map<String, dynamic> toJson() {
    return {
      'transactions': transactions
          .map((transaction) => transaction.toJson())
          .toList(),
    };
  }

  static List<dynamic> _extractTransactions(Map<String, dynamic> json) {
    final direct =
        _readList(json['transactions']) ??
        _readList(json['walletTransactions']) ??
        _readList(json['items']) ??
        _readList(json['results']);

    if (direct != null) {
      return direct;
    }

    final data = json['data'];
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final nested =
          _readList(data['transactions']) ??
          _readList(data['walletTransactions']) ??
          _readList(data['items']) ??
          _readList(data['results']) ??
          _readList(data['data']);

      if (nested != null) {
        return nested;
      }
    }

    throw const FormatException('Invalid wallet transactions response');
  }

  static List<dynamic>? _readList(dynamic value) {
    if (value is List) {
      return value;
    }
    return null;
  }
}
