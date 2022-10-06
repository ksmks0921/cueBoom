//
//  Session.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation
import FirebaseFirestore
import GeoFire
struct Session {
    
    var startTime: Timestamp = Timestamp(date: Date())
    var endTime: Timestamp = Timestamp(date: Date())
    var sessionUid: String = ""
    var venueName: String = ""
    var timestamp: Timestamp = Timestamp(date: Date())
    var djUid: String = ""
    var djName: String = ""
    var djImgUrl: String = ""
    var venueAddress: String = ""
    var venueCoord: GeoPoint = GeoPoint(latitude: 0, longitude: 0)
    var venueCityState: String = ""
    var distanceFromUser: CLLocationDistance?
    var totalEarnings: Double = 0
    var ended: Bool = false
    var onlineEvent: Bool?
    var eventInfo: String? //Only for online events
    
    init(data: Dictionary<String, Any>, userLoc: CLLocation? = nil) {
        self.startTime = data["startTime"] as? Timestamp ?? Timestamp()
        self.djImgUrl = data["djImgUrl"] as? String ?? ""
        self.djName = data["djName"] as? String ?? ""
        self.djUid = data["djUid"] as? String ?? ""
        self.sessionUid = data["sessionUid"] as? String ?? ""
        self.totalEarnings = data["totalEarnings"] as? Double ?? 0.0
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp()
        self.venueName = data["venueName"] as? String ?? ""
        self.venueCoord = data["venueCoord"] as? GeoPoint ?? GeoPoint(latitude: 10, longitude: 10)
        self.venueAddress = data["venueAddress"] as? String ?? ""
        self.venueCityState = data["venueCityState"] as? String ?? ""
        self.endTime = data["endTime"] as? Timestamp ?? Timestamp()
        self.ended = data["ended"] as? Bool ?? false
        self.onlineEvent = data["onlineEvent"] as? Bool ?? false
        self.eventInfo = data["eventInfo"] as? String ?? nil
        
        if userLoc != nil {
            let venueLoc = CLLocation(latitude: venueCoord.latitude, longitude: venueCoord.longitude)
            self.distanceFromUser = userLoc!.distance(from: venueLoc)
        }
    }
    
    init () {}
    
    func getDataDict() -> [String: Any] {
        
        let data: [String: Any] = ["sessionUid": sessionUid,
                                   "venueName": venueName,
                                   "timestamp": timestamp,
                                   "startTime": startTime,
                                   "endTime": endTime,
                                   "djUid": djUid,
                                   "djName": djName,
                                   "venueAddress": venueAddress,
                                   "venueCoord": venueCoord,
                                   "venueCityState": venueCityState,
                                   "djImgUrl": djImgUrl != nil ? djImgUrl : "",
                                   "totalEarnings": totalEarnings,
                                   "ended" : ended,
                                   "onlineEvent": self.onlineEvent ?? false,
                                   "eventInfo" : self.eventInfo ?? nil
                                ]
        return data
        
    }
}
