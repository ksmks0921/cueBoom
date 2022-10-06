//
//  RealtimeService.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation
import FirebaseDatabase
import SwiftKeychainWrapper
import CoreLocation
import GeoFire
//Data service for Realtime Database
let RT_BASE = Database.database().reference()


class RealtimeService {
    private init() {}
    static let shared = RealtimeService()
    
    //Geofire
    var geoFire: GeoFire!
    //Database references
    private var _REF_ACTIVE_VENUES = RT_BASE.child("sessions")
    private var _REF_SESSIONS = RT_BASE.child("sessions")
    
    
    var REF_ACTIVE_VENUES: DatabaseReference {
        return _REF_ACTIVE_VENUES
    }
    
    
//    func getActiveVenuesNear(_ location: CLLocation) -> [Venue] {
//
//    }
    
    
    //Add active venue location to realtime database using geofire
    func addActiveVenue(key: String, location: CLLocation, completion: @escaping(Bool) -> Void) {
        geoFire = GeoFire(firebaseRef: REF_ACTIVE_VENUES)
        geoFire.setLocation(location, forKey: key) { (error) in
            if error == nil {
                //Add the timestamp within completion block, so writes do not overwrite one another. Child key should be same as geofire location key so values are under same child
                self.REF_ACTIVE_VENUES.child(key).updateChildValues(["timestamp": ServerValue.timestamp()], withCompletionBlock: { (error, ref) in
                    if error == nil {
                        completion(true)
                    } else {
                        completion(false)
                        //TODO: catch these errors
                    }
                })
            } else {
                completion(false)
                //TODO: handle error
            }
        }
    }
    
    //Add active venue location to realtime database using geofire
    func getAllVenue(completion: @escaping([String]) -> Void) {
        REF_ACTIVE_VENUES.observe(.value, with: { (snapshot) in
            var newItems = [String]()
            
            for itemSnapShot in snapshot.children {
                let item = itemSnapShot as! DataSnapshot
                newItems.append(item.key)
            }
            completion(newItems)
        })

    }
    
    //Remove venue from realtime database when DJ's session has ended
    func removeInactiveVenue() {
        
    }
    
    func deleteSession(sessionUid: String) {
        REF_ACTIVE_VENUES.child(sessionUid).removeValue()
    }  	
    
}

