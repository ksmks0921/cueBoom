//
//  Dj.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation

final class Dj {
    
    private var _name: String!
    private var _cityState: String!
    private var _profileImgUrl: String!
    private var _tagline: String!
    private var _songRate: Double!
    
    var name: String {
        return _name
    }
    
    var cityState: String {
        return _cityState
    }
    
    var profileImgUrl: String {
        return _profileImgUrl
    }
    
    var tagline: String {
        return _tagline
    }
    
    var songRate: Double {
        return _songRate
    }
    
    init(djData: Dictionary<String, Any>) {
        if let name = djData["name"] as? String {
            self._name = name
        }
        
        if let cityState = djData["cityState"] as? String {
            self._cityState = cityState
        }
        
        if let profileImgUrl = djData["profPicUrl"] as? String {
            self._profileImgUrl = profileImgUrl
        }
        
        if let tagline = djData["tagline"] as? String {
            self._tagline = tagline
        }
        
        if let songRate = djData["songRate"] as? Double {
            self._songRate = songRate
        }
    }
    
}
