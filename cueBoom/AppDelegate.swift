//
//  AppDelegate.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/14/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import Firebase
import HockeySDK
import UserNotifications
import SwiftKeychainWrapper
import Stripe
import StripeCore
import GoogleMaps
import GooglePlaces
import GoogleSignIn
import FBSDKCoreKit

import FirebaseMessaging
import SwiftMessages

var deviceTokenString = ""
    
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        
        //Get music api token
        getMusicApiToken()
        
        //Google maps/places init
        GMSServices.provideAPIKey("AIzaSyCgx44kA2826PcAGpZOaoeDNMS69PJKmW8")
        GMSPlacesClient.provideAPIKey("AIzaSyCgx44kA2826PcAGpZOaoeDNMS69PJKmW8")
        
        //HockeyApp
        //BITHockeyManager.shared().configure(withIdentifier: "b0907764bc484290830d93fd9337b608")
        //BITHockeyManager.shared().start()
        //BITHockeyManager.shared().authenticator.authenticateInstallation()
        
        let notificationTypes: UIUserNotificationType = [UIUserNotificationType.alert,UIUserNotificationType.badge, UIUserNotificationType.sound]
        let pushNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: nil)
        application.registerUserNotificationSettings(pushNotificationSettings)
        registerForPushNotifications()
        
        //Stripe
        //Live key:*/ "pk_live_B3JHufvwr7LRcpCjgAEjMV2d"
        //test key: pk_test_MHdU27LdkjAACZefxfKdmpru
        STPAPIClient.shared.publishableKey = "pk_live_B3JHufvwr7LRcpCjgAEjMV2d"
        STPPaymentConfiguration.shared.publishableKey = "pk_live_B3JHufvwr7LRcpCjgAEjMV2d"
        STPPaymentConfiguration.shared.appleMerchantIdentifier = "merchant.com.quincyjones.cueBoom"
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
    
//    func goToCart() {
//        guard let _ = KeychainWrapper.standard.string(forKey: KEY_UID), UserDefaults.standard.string(forKey: TYPE) == TYPE_USER else {return}
//        CloudFunctions.shared.getCurrentSession { (session) in
//            guard let session = session else {return}
//            //Instantiate cart vc
//            let storyboard = UIStoryboard(name: "UserMain", bundle: .main)
//            guard let vc = storyboard.instantiateViewController(withIdentifier: "CartVC") as? CartVC else {return}
//            vc.currentSession = session
//            self.window?.rootViewController?.present(vc, animated: true, completion: nil)
//        }
//    }
    
    func getMusicApiToken() {
        let musicSearch = MusicSearch()
        musicSearch.getApiToken()
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        getMusicApiToken()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        let defaults = UserDefaults.standard
        defaults.set(userService.shared.uid, forKey: "user_uid")
        defaults.set(userService.shared.type, forKey: "type")
        defaults.set(userService.shared.currentSession?.sessionUid, forKey: "session")
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        ApplicationDelegate.shared.application(
            app, open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        return GIDSignIn.sharedInstance.handle(url)
    }
        
    //MARK:-   set push notifations
    func registerForPushNotifications() {

        if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]//[.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {(granted, error) in
            if granted {
                print("Permission granted: \(granted)")
                    DispatchQueue.main.async() {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            })

            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
    }
    
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != [] {
            application.registerForRemoteNotifications()
        }
    }
   
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
        var tokenString = ""

        for i in 0..<deviceToken.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        print(":::::::::didRegisterForRemoteNotificationsWithDeviceToken::::::::: APNs_tokenString: \(tokenString)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for notifications: \(error.localizedDescription)")
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
//        let userInfo = notification.request.content.userInfo
//
//        let aps             = userInfo["aps"] as? [AnyHashable : Any]
//        let _               = aps!["badge"] as? Int ?? 0
//        let alertMessage    = aps!["alert"] as? [AnyHashable : Any]
//        let bodyMessage     = alertMessage!["body"] as! String
//        let titleMessage    = alertMessage!["title"] as! String
//
//        let view: MessageView
//        view = try! SwiftMessages.viewFromNib()
//        let icon = UIImage(named: "Icon-180")!.resize(to: CGSize(width: 35, height: 35))!.withRoundedCorners(radius: 5)
//
//        view.configureContent(title: titleMessage, body: bodyMessage, iconImage: icon, iconText: nil, buttonImage: nil, buttonTitle: "OK", buttonTapHandler: { _ in
//            SwiftMessages.hide()
////            UIApplication.shared.applicationIconBadgeNumber -= 1
//        })
//
//        view.configureTheme(backgroundColor: CONSTANT.COLOR_PRIMARY!, foregroundColor: UIColor.white, iconImage: icon, iconText: nil)
//        view.button?.setTitle("OK", for: .normal)
//        view.button?.backgroundColor = UIColor.white ///UIColor.clear
//        view.button?.tintColor = CONSTANT.COLOR_PRIMARY!
//
//        var config = SwiftMessages.defaultConfig
//        config.presentationStyle = .top
//        config.presentationContext = .window(windowLevel: UIWindow.Level.statusBar)
//        config.duration = .forever //.seconds(seconds: 5)
//        config.dimMode = .blur(style: .dark, alpha: 0.5, interactive: true)
//        config.shouldAutorotate = true
//        config.interactiveHide = true
//        config.preferredStatusBarStyle = .lightContent
//
//        SwiftMessages.show(config: config, view: view)
//
//        sleep(1)
//        completionHandler([])
    }
}

extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Messaging.messaging().subscribe(toTopic: "/topics/all")
        if let token = fcmToken {
            deviceTokenString = token
            print("fcmToken: ", token)
            UserDefaults.standard.set(token, forKey: FCM_TOKEN)
        }
    }
}
