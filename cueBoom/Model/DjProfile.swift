 //
//  DjProfile.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/7/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation

 class DjProfile {
 
    private var _name: String?
    private var _facebookName: String?
    private var _instagramHandle: String?
    private var _twitterHandle: String?
    private var _djImgUrl: String?
    private var _musicType: musicCategory?
    private var _uid: String?
    
    var name: String? {
        return _name
    }
    
    var facebookName: String? {
        return _facebookName
    }
    
    var instagramHandle: String? {
        return _instagramHandle
    }
    
    var twitterHandle: String? {
        return _twitterHandle
    }
    
    var djImgUrl: String? {
        return _djImgUrl
    }
    
    var musicType: musicCategory? {
        return _musicType
    }
    
    var uid: String? {
        return _uid
    }
    
    init(profileData: [String: Any], uid: String) {
        
        if let name = profileData["name"] as? String {
            self._name = name
        }
        
        if let fb = profileData["facebookName"] as? String {
            self._facebookName = fb
        }
        
        if let ig = profileData["instagramHandle"] as? String {
            self._instagramHandle = ig
        }
        
        if let twitter = profileData["twitterHandle"] as? String {
            self._twitterHandle = twitter
        }
        
        if let djImgUrl = profileData["djImgUrl"] as? String {
            self._djImgUrl = djImgUrl
        }
        
        if let musicTypeLoaded = profileData["musicCat"] as? Int {
            let musicType = musicCategory(rawValue: musicTypeLoaded)
            self._musicType = musicType
        }
        
        self._uid = uid
    }
 }
