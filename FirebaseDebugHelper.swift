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