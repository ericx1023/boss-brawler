import Flutter
import UIKit
import Firebase
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // Set the presenting view controller for Google Sign-In
    // Temporary hardcoded CLIENT_ID for testing
    let clientId = "750386372057-03li2kvdjlgmeop0kigb8gd329sfsbf5.apps.googleusercontent.com"
    print("🔧 Using hardcoded CLIENT_ID: \(clientId)")
      GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    print("✅ GIDSignIn configuration set successfully")
    
    // Keep the original plist loading for debugging
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
      print("✅ GoogleService-Info.plist found at: \(path)")
      if let plist = NSDictionary(contentsOfFile: path) {
        print("✅ GoogleService-Info.plist loaded successfully")
        if let plistClientId = plist["CLIENT_ID"] as? String {
          print("✅ CLIENT_ID found in plist: \(plistClientId)")
        } else {
          print("❌ CLIENT_ID not found in GoogleService-Info.plist")
        }
      } else {
        print("❌ Failed to load GoogleService-Info.plist")
      }
    } else {
      print("❌ GoogleService-Info.plist not found in bundle")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, 
                            open url: URL, 
                            options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    
    // Set the presenting view controller when app becomes active
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
      return
    }
    
    GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
      // Handle restore result if needed
    }
  }
}
