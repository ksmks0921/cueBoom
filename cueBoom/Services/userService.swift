//
//  userService.swift
//  cueBoom
//
//  Created by Charles Oxendine on 1/27/20.
//  Copyright © 2020 CueBoom LLC. All rights reserved.
//

import Foundation

class userService {
    
    static var shared = userService()
    
    var uid: String
    var type: String
    var fcmToken: String
    var currentSession: Session?
    var name: String = ""
    var connectID: String
    
    init() {
        self.uid = ""
        self.type = "" //dj or user
        self.fcmToken = ""
        self.connectID = ""
    }
    
    func setUser(userUID: String, fcmToken: String?, type: String?, session: Session?, connectID: String?) {
        self.uid = userUID
        self.fcmToken = fcmToken ?? ""
        self.type = type ?? ""
        self.connectID = connectID ?? ""
    }
}
