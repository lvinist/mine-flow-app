import 'dart:async';

import 'package:mine_flow/core/network/connectivity_service.dart';

/// Abstract contract for checking device network connectivity status.
abstract class NetworkInfo {
  /// Returns `true` if the device currently has active network connection.
  Future<bool> get isConnected;

  /// Broadcast stream emitting `true` when network connection is established
  /// and `false` when connection is lost.
  Stream<bool> get onConnectivityChanged;
}

/// Implementation of [NetworkInfo] backed by [ConnectivityService].
class NetworkInfoImpl implements NetworkInfo {
  final ConnectivityService _connectivityService;

  NetworkInfoImpl(this._connectivityService);

  @override
  Future<bool> get isConnected => _connectivityService.isOnline;

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivityService.onConnectivityChanged;
}
