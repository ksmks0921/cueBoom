//
//  Venue.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation


final class Venue {
    
    private var _name: String!
    private var _physicalAddress: String!
    private var _picUrl: String!
    private var _requestRadius: Double!
    
    var name: String {
        return _name
    }
    
    var physicalAddress: String {
        return _physicalAddress
    }
    
    var picUrl: String {
        return _picUrl
    }
    
    var requestRadius: Double {
        return _requestRadius
    }
    
    init(venueData: Dictionary<String, Any>) {
        if let name = venueData["venueData"] as? String {
            self._name = name
        }
        
        if let physicalAddress = venueData["physicalAddress"] as? String {
            self._physicalAddress = physicalAddress
        }
        
        if let picUrl = venueData["picUrl"] as? String {
            self._picUrl = picUrl
        }
        
        if let requestRadius = venueData["requestRadius"] as? Double {
            self._requestRadius = requestRadius
        }
    }
    
}
