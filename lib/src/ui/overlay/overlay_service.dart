import 'package:flutter/material.dart';

// import '../../main.dart';
// Update the import path below if main.dart is located elsewhere, for example:
import 'package:wanderers_trail/main.dart';

class OverlayService {
  static void showToast(String message, {Duration duration = const Duration(seconds: 2)}) {
    final overlayState = WanderersApp.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    final entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.2),
                  ),
                ),
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
