//
//  AppCheck.swift
//  Nearby Food
//
//  See LICENSE folder for this project's licensing information.
//
//  Created by Bhavin Patel on 1/2/22.
//

import Foundation
import Firebase
import OSLog
class NearbyFoodAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
#if targetEnvironment(simulator)
        // App Attest is not available on simulators.
        // Use a debug provider.
        let provider = AppCheckDebugProvider(app: app)
        
        // Print only locally generated token to avoid a valid token leak on CI.
        Logger().info("Firebase App Check debug token: \(provider?.localDebugToken() ?? "" )")
        return provider
#else
        // Use App Attest provider on real devices.
        return AppAttestProvider(app: app)
#endif
    }
}
