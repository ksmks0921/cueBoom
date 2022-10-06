//
//  ChooseDJVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/23/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import GeoFire
class ChooseDJVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var requestLbl: UILabel!
    
    var activeSessions = [Session]()
    var locationManager = CLLocationManager()
    
    private var _song: Song!
    var song: Song {
        get {
            return _song
        } set {
            _song = newValue
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Table view delegate/datasource set in IB
        
        getActiveVenues()
        if _song != nil {
        
            requestLbl.text = "Choose a DJ to play \(_song.songTitle)"
        }
    }
    
    func getActiveVenues() {
        guard let currentLoc = locationManager.location else {return}
        
        var keys = [String]()
        let geoFire = GeoFire(firebaseRef: RealtimeService.shared.REF_ACTIVE_VENUES)
        var query: GFCircleQuery?
        query = geoFire.query(at: currentLoc, withRadius: 3000)
        
        //The key that enters is the sessionUid of the session stored in Firestore
        query?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
            //Add key to keys array
            keys.append(key)
        })
        
        query?.observeReady({
            self.getSessionData(keys: keys)
        })
        
    }
    
    func getSessionData(keys: [String]) {
        for key in keys {
            FirestoreService.shared.getSessionData(sessionUid: key) { data in
                guard let data = data else {return}
                let session = Session(data: data)
                self.activeSessions.append(session)
                self.tableView.reloadData()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ConfirmRequestVC {
            if let tuple = sender as? (Song, Session) {
                destination.confirmationTuple = tuple
            }
        }
    }


}

extension ChooseDJVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activeSessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "DjCell") as? DjCell {
            cell.configureCell(session: activeSessions[indexPath.row])
            return cell
        } else {
            return DjCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let confirmationTuple = (_song, activeSessions[indexPath.row])
        performSegue(withIdentifier: "toConfirm", sender: confirmationTuple)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 191.5
    }
}
