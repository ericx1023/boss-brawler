import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility class to check iOS configuration for Google Sign-In
class IOSConfigChecker {
  /// Check if running on iOS Simulator
  static bool get isIOSSimulator {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    // Better detection method - check for specific simulator characteristics
    // This is still a heuristic, but more reliable
    return kDebugMode && const bool.fromEnvironment('dart.vm.product') == false;
  }

  /// Validate iOS Google Sign-In configuration
  static Future<Map<String, dynamic>> validateConfiguration() async {
    final results = <String, dynamic>{
      'platform': defaultTargetPlatform.toString(),
      'isSimulator': isIOSSimulator,
      'issues': <String>[],
      'warnings': <String>[],
      'recommendations': <String>[],
    };

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Check for common iOS issues
      if (isIOSSimulator) {
        results['warnings'].add('Running on iOS Simulator - Google Sign-In may be unstable');
        results['recommendations'].add('Test on physical iOS device for better stability');
      }

      // Add more checks as needed
      results['recommendations'].add('Ensure GoogleService-Info.plist is properly configured');
      results['recommendations'].add('Verify URL schemes in Info.plist match Firebase configuration');
    }

    return results;
  }

  /// Print configuration report to debug console
  static Future<void> printConfigurationReport() async {
    final config = await validateConfiguration();
    
    debugPrint('=== iOS Google Sign-In Configuration Report ===');
    debugPrint('Platform: ${config['platform']}');
    debugPrint('Debug Mode: $kDebugMode');
    debugPrint('Profile Mode: $kProfileMode');
    debugPrint('Release Mode: $kReleaseMode');
    debugPrint('Is Simulator (our detection): ${config['isSimulator']}');
    debugPrint('💡 If you\'re on a real device, our detection might be wrong');
    
    if (config['issues'].isNotEmpty) {
      debugPrint('Issues:');
      for (final issue in config['issues']) {
        debugPrint('  ❌ $issue');
      }
    }
    
    if (config['warnings'].isNotEmpty) {
      debugPrint('Warnings:');
      for (final warning in config['warnings']) {
        debugPrint('  ⚠️ $warning');
      }
    }
    
    if (config['recommendations'].isNotEmpty) {
      debugPrint('Recommendations:');
      for (final rec in config['recommendations']) {
        debugPrint('  💡 $rec');
      }
    }
    
    debugPrint('=== End Configuration Report ===');
  }
} 