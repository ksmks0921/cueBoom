//
//  SearchResults.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/20/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation
import Alamofire

protocol MusicSearchDelegate {
    func didGetSearchResults(songs: [Song]?)
}

class MusicSearch {
    var songsForTable: [Song] = []
    var musicAPI = ""
    var delegate: MusicSearchDelegate!
    fileprivate var searchTimer: Timer!
    fileprivate var searchText: String!
    
    func start() {
    }
    
    func stop() {
        
    }
    
    func getApiToken() {
        
        let queue = DispatchQueue(label: "music search", qos: .background, attributes: .concurrent)

        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/getAppleMusicToken"
        AF.request(url, method: .post, parameters: [:] as [String: Any], encoding: JSONEncoding.default, headers: [:]).responseJSON(queue: queue) { response in
            
            guard let dict = response.value as? Dictionary<String, Any> else {return}
            guard let body = dict["body"] as? Dictionary<String, Any> else {return}
            guard let token = body["Token"] as? String else {return}
            print("Got music api token: \(token)")
            USER_DEFAULTS.set(token, forKey: APPLE_MUSIC_API_TOKEN)
            self.musicAPI = token
        }
    }

    
    func search(searchText: String) {
       
       
            //If user types faster than timer, invalidate the previous timer to prevent
            //unnecessary api calls
            if searchTimer != nil {
                searchTimer.invalidate()
            }
            //Set search text
            self.searchText = searchText
            
            //Set a delay before triggering apple music api call
            searchTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(internalSearch), userInfo: nil, repeats: false)
    
    }
    
    
    @objc fileprivate func internalSearch() {
       
        guard let apiToken = USER_DEFAULTS.string(forKey: APPLE_MUSIC_API_TOKEN)  else {
            getApiToken()
            return
        }
        
        //Call Apple Music api
        let searchTerm = self.searchText.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
        let countryCode = "us"
        var components = URLComponents()
    
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = "/v1/catalog/\(countryCode)/search"
                
        components.queryItems = [
            URLQueryItem(name: "term", value: searchTerm),
            URLQueryItem(name: "limit", value: "25"),
            URLQueryItem(name: "types", value: "songs"),
            URLQueryItem(name: "limit", value: "10")
        ]
        
        let url = components.url
        
        print("URL: \(url)")
                
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
                
        let session = URLSession.shared
                
        let task = session.dataTask(with: request) { (data, res, err) in
            print(res?.description)
            print(data?.description)
            
            guard let dict = try! JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
                print("getting token....")
                self.getApiToken()
                return
            }
            
            var songs = self.getSongs(dict: dict)
            
            self.delegate.didGetSearchResults(songs: songs)
        }
                
        task.resume()
    }
    
    //Parse apple music api search response to create array of items of type Song
    func getSongs(dict: Dictionary<String, Any>) -> [Song]? {
        
        var songs = [Song]()
        
        guard let resultsDict = dict["results"] as? Dictionary<String, Any> else {return nil}
        guard let songsDict = resultsDict["songs"] as? Dictionary<String, Any> else {return nil}
        guard let data = songsDict["data"] as? [Dictionary<String, Any>] else {return nil}
        var i = 0
        while i < data.count {
            guard let songData = data[i]["attributes"] as? Dictionary<String, Any> else {continue}
            let song = Song(data: songData)
            songs.append(song)
            i += 1
        }
        return songs
    }

}
