//
//  FavoriteSong.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation

open class Song: Decodable {
    
    private var _songTitle: String!
    private var _artistName: String!
    private var _albumName: String!
    private var _albumArtUrl: String!
    
    var songTitle: String {
        return _songTitle ?? " "
    }

    var artistName: String {
        return _artistName ?? " "
    }
    
    var albumName: String {
        return _albumName ?? " "
    }

    var albumArtUrl: String {
        return _albumArtUrl ?? " "
    }
    
    
    //Initialized from apple music api search result dictionary: https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/AppleMusicWebServicesReference/Searchforresources.html#//apple_ref/doc/uid/TP40017625-CH58-SW1
    init(data: Dictionary<String, Any>) {
        //Parsing apple music API search result--
        
        if let songTitle = data["name"] as? String {
            self._songTitle = songTitle
        }

        if let artistName = data["artistName"] as? String {
            self._artistName = artistName
        }
        
        if let albumName = data["albumName"] as? String {
            self._albumName = albumName
        }
        
        if let artwork = data["artwork"] as? Dictionary<String, Any> {
            if let albumArtUrl = artwork["url"] as? String {
                self._albumArtUrl = albumArtUrl
            }
        }
    }
    
    //Initialized with dictionary from QueueItem, which inherits from this class
    init(queueItemData: [String: Any]) {
        
        if let songTitle = queueItemData["songTitle"] as? String {
            _songTitle = songTitle
        }
        
        if let artistName = queueItemData["artistName"] as? String {
            _artistName = artistName
        }
        
        if let albumName = queueItemData["albumName"] as? String {
            _albumName = albumName
        }
        
        if let albumArtUrl = queueItemData["albumArtUrl"] as? String {
            _albumArtUrl = albumArtUrl
        }
        
    }
    
}
