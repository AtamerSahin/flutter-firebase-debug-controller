# Firebase Analytics Debug Controller for Flutter/iOS

A lightweight solution to control Firebase Analytics debug mode in Flutter iOS apps

## The Problem

Firebase Analytics provides a useful DebugView feature that allows developers to see analytics events in real-time during development. However, the official way to enable this involves several limitations:
- You need to add `-FIRAnalyticsDebugEnabled` and `-FIRDebugEnabled` flags to your Xcode scheme
- It only works when launching directly from Xcode (not from VS Code, Android Studio, or flutter run)
- Once enabled, debug mode tends to "stick" and may remain enabled until the app is uninstalled
- No easy way to toggle debug mode in TestFlight builds

As mentioned in multiple issues and articles:

> "Note that this flag will only work if you run your application directly from Xcode. Running the app using flutter run or through an IDE will not trigger the arguments to be executed on launch." - Walturn Article

From Stack Overflow:
> "Launch the app with XCode; for some reason when I was doing the first launch in VS Code, it didn't pick up that arguments."

[flutter/flutter#17043](https://github.com/flutter/flutter/issues/17043):
> "Add some Arguments on Launch to your Schema in iOS for example `-FIRAnalyticsDebugEnabled`. Run your application through flutter run or Android Studio. This is not working at all."

## Why Command-Line Arguments Don't Work Outside Xcode

The reason the launch arguments only work in Xcode is that they're specifically tied to Xcode's launch process. When you use flutter run or another IDE, a different launch sequence is used that doesn't process these arguments the same way. Additionally, in continuous integration pipelines or automated builds, you can't directly launch from Xcode UI.

## The Solution

Instead of relying on launch arguments, we can use `UserDefaults` to directly control Firebase Analytics debug mode. This approach works:
- Regardless of where you launch your app from (Xcode, VS Code, Android Studio, or CLI)
- In TestFlight builds
- Without requiring app reinstallation to change debug status

This was initially discovered in [firebase-ios-sdk#14182](https://github.com/firebase/firebase-ios-sdk/issues/14182):

> "We tried this UserDefaults workaround... This workaround is actually working, but only on the second launch of the app."

## Installation

1. **Add `FirebaseDebugHelper.swift` to your iOS project:**

    ```swift
    import Foundation

    @objc class FirebaseDebugHelper: NSObject {
        
        // Method with development flavor check included
        @objc static func setDebugModeForDevelopment(enabled: Bool) {
            // Bundle identifier check
            let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
            
            // Only apply for development flavor
            if bundleIdentifier.contains(".dev") {
                // First clear all Firebase debug flags
                let keysToRemove = [
                    "/google/firebase/debug_mode",
                    "/google/measurement/debug_mode",
                    "FIRAnalyticsDebugEnabled",
                    "FIRDebugEnabled",
                    "FirebaseDebugEnabled",
                    "FirebaseDebugModeEnabled",
                    "GoogleDebugMode"
                ]
                
                for key in keysToRemove {
                    UserDefaults.standard.removeObject(forKey: key)
                }
                
                // Set according to parameter
                if enabled {
                    UserDefaults.standard.set(true, forKey: "/google/firebase/debug_mode")
                    UserDefaults.standard.set(true, forKey: "/google/measurement/debug_mode")
                    print("Firebase Debug Mode: ENABLED for development flavor")
                } else {
                    print("Firebase Debug Mode: DISABLED for development flavor")
                }
                
                // Apply changes immediately
                UserDefaults.standard.synchronize()
            } else {
                print("Firebase Debug Mode: Not applied (not development flavor)")
            }
        }
    }
    ```

2. **In your `AppDelegate.swift`, add:**

    ```swift
    import UIKit
    import Flutter

    @UIApplicationMain
    @objc class AppDelegate: FlutterAppDelegate {
      override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
      ) -> Bool {
        // Set to true to enable Firebase Analytics debug mode
        FirebaseDebugHelper.setDebugModeForDevelopment(enabled: true)
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
      }
    }
    ```

## Usage

### Toggle Debug Mode

Simply change the parameter in `AppDelegate`:

Enable debug mode
```swift
FirebaseDebugHelper.setDebugModeForDevelopment(enabled: true)
```

Disable debug mode
```swift
FirebaseDebugHelper.setDebugModeForDevelopment(enabled: false)
```

# TestFlight Builds

You can now easily create TestFlight builds with debug mode enabled or disabled without requiring users to reinstall the app. Just update the parameter before building.

## How It Works

- The helper clears all known Firebase debug flags from `UserDefaults`.
- It then sets the correct flags based on your parameter.
- This happens at app startup, so it overrides any previous state.
- The changes take effect immediately due to the `synchronize()` call.

## Flavor-Aware Debug Mode

One of the key advantages of this solution is its flavor awareness. The sample implementation checks if your app is running with a specific flavor (by checking the bundle identifier) and only applies the debug mode in that environment.

You can customize the bundle identifier check to match your project's naming conventions or remove it entirely if you want to apply debug mode to all builds.

## Extending Functionality

This solution can be extended with Flutter Method Channels to toggle Firebase Analytics debug mode directly from within your app. This could be useful for:
- Creating a developer menu in your app.
- Allowing QA testers to toggle debug mode without requiring a new build.
- Remotely enabling debug mode for specific users to troubleshoot issues.

## License

MIT

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
