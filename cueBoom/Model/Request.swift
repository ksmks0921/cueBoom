//
//  Request.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation

class Request {
    
    private var _songName: String!
    private var _artistName: String!
    private var _songLength: String!
    private var _djUid: String!
    private var _timestamp: Date!
    private var _venueUid: String!
    private var _albumArtUrl: String!
    private var _albumName: String!
    //Add session uid
    //Add cost
    //...etc
    
    
    var songName: String {
        return _songName
    }
    
    var albumName: String {
        return _albumName
    }
    
    var artistName: String {
        return _artistName
    }
    
    var songLength: String {
        return _songLength
    }
    
    var djUid: String {
        return _djUid
    }
    
    var timestamp: Date {
        //Compute this
        return _timestamp
    }
    
    var venueUid: String {
        return _venueUid
    }
    
    var albumArtUrl: String {
        return _albumArtUrl
    }
    
    init(requestData: Dictionary<String, Any>) {
        if let songName = requestData["songName"] as? String {
            self._songName = songName
        }
        
        if let artistName = requestData["artistName"] as? String {
            self._artistName = artistName
        }
        
        if let songLength = requestData["songLength"] as? String {
            self._songLength = songLength
        }
        
        if let djUid = requestData["djUid"] as? String {
            self._djUid = djUid
        }
        
        if let timestamp = requestData["timestamp"] as? Date {
            self._timestamp = timestamp
        }
        
        if let venueUid = requestData["venueUid"] as? String {
            self._venueUid = venueUid
        }
        
        if let albumArtUrl = requestData["albumArtUrl"] as? String {
            self._albumArtUrl = albumArtUrl
        }
        
        if let albumName = requestData["albumName"] as? String {
            self._albumName = albumName
        }
    }

    
    
    
}
