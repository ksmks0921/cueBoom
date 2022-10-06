//
//  SearchResultsVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/19/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import Alamofire

class SearchResultsVC: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var songs = [Song]()
    var searchTimer: Timer?
    var count = 0
    
    private var _session: Session!
    var session: Session {
        get {
            return _session
        } set {
            _session = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        USER_DEFAULTS.set("eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ikc5NkRCTjJSOTQifQ.eyJpc3MiOiJVSEY5WjJVNjYzIiwiaWF0IjoxNTI0NTE5NDAxLCJleHAiOjE1MjQ2MDk0MDF9.lAaHjc4ZzGYJPfbUtKi5VR2PBZYD6AFCr5yRGPStqkpIz6Q4VWwSz72kotW-T6RV15S7ZWNh0ZwW7aU6BLZynw", forKey: APPLE_MUSIC_API_TOKEN)
    }
    

    func getApiToken() {
        let url = "https://us-central1-cueboom-46a61.cloudfunctions.net/getAppleMusicToken"
        AF.request(url, method: .post, parameters: [:] as [String: Any], encoding: JSONEncoding.default, headers: [:]).responseJSON { response in
      
            guard let dict = response.value as? Dictionary<String, Any> else {return}
            guard let body = dict["body"] as? Dictionary<String, Any> else {return}
            guard let token = body["Token"] as? String else {return}
            USER_DEFAULTS.set(token, forKey: APPLE_MUSIC_API_TOKEN)
        }
    }
    
    @objc func search() {
        //TODO: refresh apple music api dev token
        guard let apiToken = USER_DEFAULTS.string(forKey: APPLE_MUSIC_API_TOKEN)  else {
            getApiToken()
            return
        }
        
        guard let searchText = searchBar.text else {return}
        let term = searchText.replacingOccurrences(of: " ", with: "+", options: .literal, range: nil)
        
        //Remove previous songs in the songs araray
        self.songs.removeAll()
        //Call Apple Music api

        let searchTerm = ""
        let countryCode = "us"
        var components = URLComponents()
        
        components.scheme = "https"
        components.host = "api.music.apple.com"
        components.path = "/v1/catalog/\(countryCode)/search"
        
        components.queryItems = [
            URLQueryItem(name: "term", value: searchTerm),
            URLQueryItem(name: "limit", value: "25"),
            URLQueryItem(name: "types", value: "songs")
        ]
        
        let url = components.url
        
        print("URL: \(url)")
        
        var request = URLRequest(url: url!)
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession()
        let task = session.dataTask(with: request) { (data, res, err) in
            
            guard let dict = res as? Dictionary<String, Any> else {
                print("getting token....")
                self.getApiToken()
                return
            }
            
            //Convert dict to an array of Song items
            var search = MusicSearch()
            var songsLocal = search.getSongs(dict: dict)
            self.songs = songsLocal!
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ChooseDJVC {
            if let song = sender as? Song {
                destination.song = song
            }
        } else if let destination = segue.destination as? ConfirmRequestVC {
            if let tuple = sender as? (Song, Session) {
                destination.confirmationTuple = tuple
            }
        }
    }
}

extension SearchResultsVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        if let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as? SearchResultCell {
            
            cell.configureCell(song: songs[indexPath.row])
            return cell
        } else {
            return SearchResultCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if _session == nil {
            performSegue(withIdentifier: "toChooseDJ", sender: songs[indexPath.row])
        } else {
            let confirmationTuple = (songs[indexPath.row], _session)
            performSegue(withIdentifier: "toConfirm", sender: confirmationTuple)
        }
        
        
        //Initiate a request
        //Add request to database under requests and user recents
        //Pop the view controller
        //UserRequestVC should update with this most recent request at top
    }
    
}

extension SearchResultsVC: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        guard let searchText = searchBar.text else {return}
        guard searchText.count > 2 else {
            songs.removeAll()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return
        }
        
        //If user types faster than timer, invalidate the previous timer to prevent
        //unnecessary api calls
        if searchTimer != nil {
            searchTimer!.invalidate()
        }
        
        //Set a delay before triggering apple music api call
        searchTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(search), userInfo: nil, repeats: false)
    
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        songs.removeAll()
        DispatchQueue.main.async {
           self.tableView.reloadData()
        }
        
    }
}

