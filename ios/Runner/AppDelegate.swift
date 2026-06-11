import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String, !key.isEmpty {
      GMSServices.provideAPIKey(key)
    }

    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let localeChannel = FlutterMethodChannel(
        name: "app.locale",
        binaryMessenger: controller.binaryMessenger
      )

      localeChannel.setMethodCallHandler { call, result in
        if call.method == "setLocale" {
          guard let args = call.arguments as? [String: Any],
                let lang = args["lang"] as? String else {
            result(FlutterError(code: "invalid_args", message: "lang required", details: nil))
            return
          }
          UserDefaults.standard.set([lang], forKey: "AppleLanguages")
          UserDefaults.standard.synchronize()
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }

      let mapsConfigChannel = FlutterMethodChannel(
        name: "app.maps_config",
        binaryMessenger: controller.binaryMessenger
      )

      mapsConfigChannel.setMethodCallHandler { call, result in
        guard call.method == "getApiKey" else {
          result(FlutterMethodNotImplemented)
          return
        }

        let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
        result(apiKey)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
