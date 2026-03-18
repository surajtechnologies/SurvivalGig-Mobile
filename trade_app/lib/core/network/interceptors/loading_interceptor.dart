import 'package:dio/dio.dart';
import '../../../features/common/presentation/cubit/loading_cubit.dart';

/// Loading interceptor for Dio
/// Shows/hides global loading overlay during API calls
class LoadingInterceptor extends Interceptor {
  final LoadingCubit loadingCubit;
  int _requestCount = 0;

  LoadingInterceptor({required this.loadingCubit});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final shouldSkipLoading = options.extra['skipLoading'] == true;
    if (shouldSkipLoading) {
      options.extra['loadingTracked'] = false;
      handler.next(options);
      return;
    }

    _requestCount++;
    if (_requestCount == 1) {
      loadingCubit.showLoading();
    }
    options.extra['loadingTracked'] = true;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final isTracked = response.requestOptions.extra['loadingTracked'] == true;
    if (isTracked) {
      _decrementAndHideLoader();
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final isTracked = err.requestOptions.extra['loadingTracked'] == true;
    if (isTracked) {
      _decrementAndHideLoader();
    }
    handler.next(err);
  }

  void _decrementAndHideLoader() {
    _requestCount--;
    if (_requestCount <= 0) {
      _requestCount = 0;
      loadingCubit.hideLoading();
    }
  }
}
