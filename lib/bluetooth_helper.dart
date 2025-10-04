import 'package:flutter/material.dart';
// Note: flutter_blue_plus calls were removed from this helper because the
// plugin API in this workspace previously caused analyzer/compile errors.
// We'll keep a safe, manual enable flow here and re-introduce programmatic
// enabling once plugin issues are resolved and tested on a device.
import 'package:permission_handler/permission_handler.dart';
import 'platform_bluetooth.dart';

/// Requests runtime permissions required for Bluetooth (scan/connect) and location.
/// Tries to programmatically enable Bluetooth when available, otherwise opens
/// system Bluetooth settings as a fallback. Returns true when Bluetooth is ON
/// and required permissions are granted; returns false otherwise.
Future<bool> enableBluetooth(BuildContext context) async {
  // Ask the user if they want to enable Bluetooth now.
  final enable = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Enable Bluetooth'),
      content: const Text('This app needs Bluetooth enabled. Would you like to enable it now?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Yes')),
      ],
    ),
  );

  if (enable != true) return false;

  // Request necessary permissions first (Android 12+ separates bluetooth perms)
  final statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();

  final allGranted = statuses.values.every((s) => s.isGranted);
  if (!allGranted) {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Permissions required'),
        content: const Text('Bluetooth and location permissions are required to use this feature.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
        ],
      ),
    );
    return false;
  }

    // At this point we have permissions. Use the platform channel to request the
    // system enable-Bluetooth prompt on Android; this opens the native dialog
    // that asks the user to enable Bluetooth. It returns true if the user
    // accepted and Bluetooth is now enabled.
    final enabled = await PlatformBluetooth.requestEnableBluetooth();
    if (enabled) return true;

    // If the platform prompt didn't enable Bluetooth, fall back to asking the
    // user to enable it manually and confirm.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Enable Bluetooth'),
        content: const Text('Please enable Bluetooth in your device settings, then tap "I enabled it".'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('I enabled it')),
        ],
      ),
    );

    return confirmed == true;
}
