import 'package:flutter/material.dart';

// import '../../main.dart';
// Update the import path below if main.dart is located elsewhere, for example:
import 'package:wanderers_trail/main.dart';

class OverlayService {
  static void showToast(String message, {Duration duration = const Duration(seconds: 2)}) {
    final overlayState = WanderersApp.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 60,
        left: 0,
        right: 0,
        child: IgnorePointer(
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(message, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(entry);
    Future.delayed(duration, () {
      entry.remove();
    });
  }
}
