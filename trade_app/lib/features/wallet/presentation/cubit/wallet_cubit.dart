import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/wallet_summary.dart';
import '../../domain/entities/wallet_transaction.dart';
import '../../domain/usecases/get_wallet_usecase.dart';
import '../../domain/usecases/get_wallet_transactions_usecase.dart';
import 'wallet_state.dart';

/// Wallet cubit
class WalletCubit extends Cubit<WalletState> {
  final GetWalletUseCase getWalletUseCase;
  final GetWalletTransactionsUseCase getWalletTransactionsUseCase;

  static const int _defaultPage = 1;
  static const int _defaultLimit = 20;

  WalletCubit({
    required this.getWalletUseCase,
    required this.getWalletTransactionsUseCase,
  }) : super(const WalletInitial());

  /// Load wallet summary and transactions
  Future<void> loadWallet() async {
    await _loadWalletData(showLoading: true);
  }

  /// Refresh wallet data
  Future<void> refresh() async {
    await _loadWalletData(showLoading: state is! WalletLoaded);
  }

  Future<void> _loadWalletData({required bool showLoading}) async {
    if (showLoading) {
      emit(const WalletLoading());
    }

    final walletFuture = getWalletUseCase();
    final transactionsFuture = getWalletTransactionsUseCase(
      page: _defaultPage,
      limit: _defaultLimit,
    );

    final walletResult = await walletFuture;
    final transactionsResult = await transactionsFuture;

    WalletSummary? walletSummary;
    String? errorMessage;
    String? errorCode;

    walletResult.fold((failure) {
      errorMessage = failure.message;
      errorCode = failure.code;
    }, (wallet) => walletSummary = wallet);

    if (walletSummary == null) {
      emit(
        WalletError(
          message: errorMessage ?? 'Failed to load wallet',
          code: errorCode,
        ),
      );
      return;
    }

    late List<WalletTransaction> transactions;
    transactionsResult.fold((_) {
      final currentState = state;
      if (currentState is WalletLoaded) {
        transactions = currentState.transactions;
        return;
      }
      transactions = const [];
    }, (data) => transactions = data);

    emit(
      WalletLoaded(walletSummary: walletSummary!, transactions: transactions),
    );
  }
}
