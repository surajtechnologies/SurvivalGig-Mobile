import 'package:equatable/equatable.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';

/// Wallet state
abstract class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class WalletInitial extends WalletState {
  const WalletInitial();
}

/// Loading state
class WalletLoading extends WalletState {
  const WalletLoading();
}

/// Loaded state
class WalletLoaded extends WalletState {
  final WalletSummary walletSummary;
  final List<WalletTransaction> transactions;

  const WalletLoaded({required this.walletSummary, required this.transactions});

  @override
  List<Object?> get props => [walletSummary, transactions];

  WalletLoaded copyWith({
    WalletSummary? walletSummary,
    List<WalletTransaction>? transactions,
  }) {
    return WalletLoaded(
      walletSummary: walletSummary ?? this.walletSummary,
      transactions: transactions ?? this.transactions,
    );
  }
}

/// Error state
class WalletError extends WalletState {
  final String message;
  final String? code;

  const WalletError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}
