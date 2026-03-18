import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity service
/// Monitors network connectivity status
/// Provides stream for real-time connectivity changes
class ConnectivityService {
  final Connectivity _connectivity;
  
  StreamController<bool>? _connectionStatusController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isConnected = true;
  bool _wasDisconnected = false;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Get current connection status
  bool get isConnected => _isConnected;

  /// Check if connection was just restored (for showing snackbar)
  bool get wasDisconnected => _wasDisconnected;

  /// Stream of connection status changes
  /// Emits true when connected, false when disconnected
  Stream<bool> get connectionStream {
    _connectionStatusController ??= StreamController<bool>.broadcast();
    return _connectionStatusController!.stream;
  }

  /// Initialize the connectivity service
  /// Call this on app startup
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isConnected = _hasConnection(result);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        final connected = _hasConnection(result);
        
        // Track if we were disconnected (for snackbar)
        if (!_isConnected && connected) {
          _wasDisconnected = true;
        }
        
        if (_isConnected != connected) {
          _isConnected = connected;
          _connectionStatusController?.add(connected);
        }
      },
    );
  }

  /// Check connectivity on demand
  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = _hasConnection(result);
    return _isConnected;
  }

  /// Reset the wasDisconnected flag (call after showing snackbar)
  void resetDisconnectedFlag() {
    _wasDisconnected = false;
  }

  /// Check if any connectivity result indicates a connection
  bool _hasConnection(List<ConnectivityResult> result) {
    return result.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  /// Dispose of the service
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStatusController?.close();
  }
}
