import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final isOffline = false.obs;
  final showConnectionRestored = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _restoredTimer;

  Future<ConnectivityService> init() async {
    _setConnectivity(await _connectivity.checkConnectivity(), initial: true);
    _subscription = _connectivity.onConnectivityChanged.listen(
      _setConnectivity,
    );
    return this;
  }

  Future<bool> waitUntilOnline({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (!isOffline.value) {
      return true;
    }

    try {
      await isOffline.stream.firstWhere((offline) => !offline).timeout(timeout);
      return true;
    } on TimeoutException {
      return false;
    }
  }

  void _setConnectivity(
    List<ConnectivityResult> results, {
    bool initial = false,
  }) {
    final offline =
        results.isEmpty || results.contains(ConnectivityResult.none);
    final wasOffline = isOffline.value;
    isOffline.value = offline;

    if (!initial && wasOffline && !offline) {
      showConnectionRestored.value = true;
      _restoredTimer?.cancel();
      _restoredTimer = Timer(const Duration(seconds: 3), () {
        showConnectionRestored.value = false;
      });
    } else if (offline) {
      _restoredTimer?.cancel();
      showConnectionRestored.value = false;
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _restoredTimer?.cancel();
    super.onClose();
  }
}
