import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/connectivity_service.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ConnectivityService>()) {
      return child;
    }

    final connectivity = Get.find<ConnectivityService>();
    return Obx(() {
      final offline = connectivity.isOffline.value;
      final restored = connectivity.showConnectionRestored.value;

      return Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: offline
                ? const _NetworkStatusBar(
                    key: ValueKey('offline'),
                    icon: Icons.cloud_off_rounded,
                    message: 'No internet connection',
                    color: Color(0xFFB42318),
                  )
                : restored
                ? const _NetworkStatusBar(
                    key: ValueKey('restored'),
                    icon: Icons.cloud_done_rounded,
                    message: 'Back online',
                    color: Color(0xFF067647),
                  )
                : const SizedBox.shrink(key: ValueKey('online')),
          ),
          Expanded(child: child),
        ],
      );
    });
  }
}

class _NetworkStatusBar extends StatelessWidget {
  const _NetworkStatusBar({
    required this.icon,
    required this.message,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Semantics(
          liveRegion: true,
          label: message,
          child: SizedBox(
            width: double.infinity,
            height: 34,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 17),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
