import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/buy_now_usecase.dart';
import 'buy_now_state.dart';

/// Buy now cubit
class BuyNowCubit extends Cubit<BuyNowState> {
  final BuyNowUseCase buyNowUseCase;

  BuyNowCubit({required this.buyNowUseCase}) : super(const BuyNowInitial());

  /// Execute buy now for a listing
  Future<void> buyNow({required String listingId}) async {
    emit(BuyNowLoading(listingId: listingId));

    final result = await buyNowUseCase(listingId: listingId);

    result.fold(
      (failure) => emit(BuyNowError(
        listingId: listingId,
        message: failure.message,
      )),
      (_) => emit(BuyNowSuccess(listingId: listingId)),
    );
  }

  /// Reset state to initial
  void reset() {
    emit(const BuyNowInitial());
  }
}
