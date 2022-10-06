//
//  PushNotificationManager.swift
//  cueBoom
//
//  Created by Charles Oxendine on 5/29/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseMessaging
import UIKit
import UserNotifications

class PushNotificationManager: NSObject, MessagingDelegate, UNUserNotificationCenterDelegate {
    let userID: String
    
    init(userID: String) {
        self.userID = userID
        super.init()
    }
    
    func registerForPushNotifications(uid: String) {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM)
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
        addFcmToDatabase(uid: uid)
    }
    
    func addFcmToDatabase(uid: String) {
        Messaging.messaging().token { (token, error) in
//        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instance ID: \(error)")
            } else if let token = token {
                let db = Firestore.firestore()
                if userService.shared.type == TYPE_USER {
                    db.collection("users_private").document(userService.shared.uid).updateData(["fcmToken" : token]) { (err) in
                        if err != nil {
                            print("ERROR SETTING FCM TO FIRESTORE: \(err!.localizedDescription)")
                        }
                    }
                } else if userService.shared.type == TYPE_DJ {
                    db.collection("djs_private").document(userService.shared.uid).updateData(["fcmToken" : token]) { (err) in
                        if err != nil {
                            print("ERROR SETTING FCM TO FIRESTORE: \(err!.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        addFcmToDatabase(uid: userService.shared.uid)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response)
    }
}
