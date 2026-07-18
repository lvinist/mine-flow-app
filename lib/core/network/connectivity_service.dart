// Connectivity monitoring service.
//
// Wraps [connectivity_plus] and exposes a stream of bool values indicating
// whether the device currently has internet access. The background sync logic
// (Doc 15 — Native App Architecture, §2 Offline Capabilities & Syncing) listens
// to this stream and triggers a Supabase sync when isOnline becomes true.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mine_flow/core/utils/logger.dart';

/// Monitors device network connectivity and broadcasts changes.
class ConnectivityService {
  ConnectivityService() : _connectivity = Connectivity();

  final Connectivity _connectivity;
  final _log = buildLogger('ConnectivityService');

  /// Returns `true` if the device currently has a network connection.
  ///
  /// Note: a non-[ConnectivityResult.none] result does not guarantee internet
  /// access (e.g., a captive portal). This is sufficient for the MVP's
  /// last-write-wins sync strategy.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// A broadcast stream that emits `true` when connectivity is available and
  /// `false` when it is lost.
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map((results) {
        final online = results.any((r) => r != ConnectivityResult.none);
        _log.info('Connectivity changed → ${online ? "online" : "offline"}');
        return online;
      });
}
