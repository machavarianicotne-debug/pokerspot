import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

/// Root Flutter view controller that lets iOS auto-hide the home-indicator bar
/// after a few seconds of inactivity (it fades out, and reappears on touch).
/// The swipe-up-to-home gesture is a system gesture and keeps working — only the
/// visible white line is hidden. Wired up via Main.storyboard's custom class.
class RootFlutterViewController: FlutterViewController {
  override var prefersHomeIndicatorAutoHidden: Bool { true }
}
