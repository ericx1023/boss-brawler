import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Utility class to check iOS configuration for Google Sign-In
class IOSConfigChecker {
  /// Check if running on iOS Simulator
  static bool get isIOSSimulator {
    if (defaultTargetPlatform != TargetPlatform.iOS) return false;
    // This is a heuristic - iOS Simulator typically has specific characteristics
    // In a real app, you might want to use a more reliable method
    return kDebugMode; // Assume debug mode often means simulator
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
    debugPrint('Is Simulator: ${config['isSimulator']}');
    
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