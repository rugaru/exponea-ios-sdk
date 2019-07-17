//
//  AppDelegate.swift
//  Example
//
//  Created by Dominik Hadl on 01/05/2018.
//  Copyright © 2018 Exponea. All rights reserved.
//

import UIKit
import ExponeaSDK
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let memoryLogger = MemoryLogger()
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Exponea.logger = AppDelegate.memoryLogger
        Exponea.logger.logLevel = .verbose
//
//        let url = UserDefaults.standard.string(forKey: "savedUrl") ?? "https://api.exponea.com"
//        let token = UserDefaults.standard.string(forKey: "savedToken") ?? ""
//        let auth = Authorization.token(UserDefaults.standard.string(forKey: "savedAuth") ?? "")
//        Exponea.shared.configure(projectToken: token,
//                                 authorization: auth,
//                                 baseUrl: url,
//                                 appGroup: "group.com.Exponea.ExponeaSDK-Example")
        
        UITabBar.appearance().tintColor = UIColor(red: 28/255, green: 23/255, blue: 50/255, alpha: 1.0)
        
        application.applicationIconBadgeNumber = 0
        
        // Set legacy exponea categories
        let category1 = UNNotificationCategory(identifier: "EXAMPLE_LEGACY_CATEGORY_1",
                                              actions: [
            ExponeaNotificationAction.createNotificationAction(type: .openApp, title: "Hardcoded open app", index: 0),
            ExponeaNotificationAction.createNotificationAction(type: .deeplink, title: "Hardcoded deeplink", index: 1)
            ], intentIdentifiers: [], options: [])
        
        let category2 = UNNotificationCategory(identifier: "EXAMPLE_LEGACY_CATEGORY_2",
                                               actions: [
            ExponeaNotificationAction.createNotificationAction(type: .browser, title: "Hardcoded browser", index: 0)
            ], intentIdentifiers: [], options: [])
        
        UNUserNotificationCenter.current().setNotificationCategories([category1, category2])
        
        return true
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL
            else { return false }
        Exponea.shared.trackCampaignClick(url: incomingURL, timestamp: nil)
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false), components.scheme == "exponea" {
            showAlert("Deeplink received", url.absoluteString)
            return true
        }
        return false
    }
}

extension AppDelegate {
    func showAlert(_ title: String, _ message: String?) {
        let alert = UIAlertController(title: title, message: message ?? "no body", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        (window?.rootViewController as? UINavigationController)?.topViewController?.present(alert, animated: true, completion: nil)
        
        let alertWindow = UIWindow(frame: UIScreen.main.bounds)
        alertWindow.rootViewController = UIViewController()
        alertWindow.windowLevel = .alert + 1
        alertWindow.makeKeyAndVisible()
        alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
    }
}

extension AppDelegate: PushNotificationManagerDelegate {
    func pushNotificationOpened(with action: ExponeaNotificationActionType, value: String?, extraData: [AnyHashable : Any]?) {
        Exponea.logger.log(.verbose, message: "Action \(action), value: \(String(describing: value)), extraData \(String(describing: extraData))")
    }
}
