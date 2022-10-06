//
//  notificationServices.swift
//  cueBoom
//
//  Created by Charles Oxendine on 3/29/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import Foundation


class notificationServices {
    
    static var shared = notificationServices()
    
    var fcmToken: [String:Any]
    var fcm_string: String = ""
    
    ///Setting fcm without a value will result in notifications not working properly...
    init() {
        self.fcmToken = ["":""]
    }
    
    func setNotifications(fcm: [String:Any], fcm_string: String) {
        self.fcmToken = fcm
        self.fcm_string = fcm_string
    }
}
