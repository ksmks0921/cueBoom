//
//  UserMainSelectVenueVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/11/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import SwiftKeychainWrapper
import FirebaseFirestore
import GeoFire

class UserMainSelectVenueVC: UIViewController {
    
    @IBOutlet weak var sessionInfoViewContainer: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchQueryTable: UITableView!
    
    var locationManager = CLLocationManager()
    var sessionInfoView: SessionInfoView!
    var filteredSessions = [Session]()
    var sessions = [Session]()
    
    private var _currentSession: Session!
    var currentSession: Session {
        get {
            return _currentSession
        } set {
            _currentSession = newValue
        }
    }
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        get { .fullScreen }
        set { assertionFailure("Shouldnt change that 😠") }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.alpha = 1
        self.tableView.isHidden = false
        
        //Configure session info view
        sessionInfoView = SessionInfoView(frame: sessionInfoViewContainer.bounds)
        if _currentSession != nil { //Update the UI with the current session
            sessionInfoView.updateUI(forSession: _currentSession, shouldDisplayCartInfo: false)
        }
        sessionInfoViewContainer.addSubview(sessionInfoView)
        initSessionInfoViewModel()
        
        //Location
        locationManager.delegate = self
        locationAuthStatus()
        print("UserMainSelectVenue_________")
        mapView.userTrackingMode = .follow
    }
    
    func queryActiveVenues() {
        guard let currentLoc = locationManager.location else {return}
        let db = Firestore.firestore()
        db.collection("sessions").whereField("ended", isEqualTo: false).whereField("onlineEvent", isEqualTo: false).whereField("startTime", isLessThan: Date()).getDocuments { (snap, err) in
            if err !=  nil {
                Alerts.errMessage(view: self, message: "Server Error: \(err!.localizedDescription)")
                return
            }
            
            guard snap != nil else {
                Alerts.errMessage(view: self, message: "Error parsing server data. Please try again.")
                return
            }
            
            var sessionsLoaded: [Session] = []
            for sessionData in snap!.documents {
                let session = Session(data: sessionData.data())
                sessionsLoaded.append(session)
                self.addAnnotation(session: session)
            }
            
            self.sessions = sessionsLoaded
            self.filteredSessions = sessionsLoaded
            self.tableView.reloadData()
        }
    }
    
    //Update UI when there are no active venues in the area.
    //Hide table view to dislay the "No active venues" label behind table view
    func noActiveSessionsUI() {
        tableView.isHidden = true
    }
    
    func getSessionData(sessionUids: [String]) {
        let group = DispatchGroup()
        
        for key in sessionUids {
            group.enter()
            
            FirestoreService.shared.getSessionData(sessionUid: key) { data in
                guard let data = data else {
                    return group.leave()
                }
                
                let session = Session(data: data)
        
                if session.startTime.dateValue() > Date() && session.startTime.dateValue().addingTimeInterval(TimeInterval(-43200)) > Date() && session.ended == false {
                    return group.leave()
                }
                
                //Prevent duplicate venues from appearing on map and subsequenty in table view in FindVenueVC's
                guard !self.sessions.contains(where:{$0.venueName == session.venueName}) else {
                    return group.leave()
                }
        
                self.addAnnotation(session: session) //Add pin to map
                self.sessions.append(session)
                //self.djMapDelegate.didGetSessions(self._totalSessions)
                
                group.leave()
            }
            
            /* group.notify(queue: .main) {
                //self._totalSessions.sort(by: {$0.distanceFromUser < $1.distanceFromUser})
                self.djMapDelegate.didGetSessions(self._totalSessions) //Delegate method
            }*/
        }
        
        group.notify(queue: .main) {
            //self._totalSessions.sort(by: {$0.distanceFromUser < $1.distanceFromUser})
            self.filteredSessions = self.sessions
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }

        /*let group = DispatchGroup()
        
        for uid in sessionUids {
            
            group.enter()
            
            FirestoreService.shared.REF_SESSIONS.document(uid).getDocument { (snapshot, error) in
                
                if var data = snapshot?.data() {
                    
                    //Format Date Values
                    var startDate = data["startTime"] as! Timestamp
                    var timeStamp = data["timestamp"] as! Timestamp
                    var endTime = data["endTime"] as! Timestamp
                    
                    data.updateValue(startDate.dateValue(), forKey: "startTime")
                    data.updateValue(timeStamp.dateValue(), forKey: "timestamp")
                    data.updateValue(endTime.dateValue(), forKey: "endTime")
                    
                    let session = Session(data: data, userLoc: self.locationManager.location)
                    //Check that session end < now
                    if session.endTime.dateValue() < Date() {
                        self.sessions.append(session) //Add session to sessions array
                        //self.filteredSessions.append(session) //Add session to filtered sessions array
                        self.addAnnotation(session: session) //Add annotation for the session
                        self.tableView.reloadData()
                        self.tableView.isHidden = false
                        
                        group.leave()
                    } else {
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            //self.sessions.sort(by: {$0.distanceFromUser < $1.distanceFromUser})
            self.filteredSessions = self.sessions
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    */
    }
    
    //TODO
    //Edge cases
    //1. No sessions present
        //Display "no sessions present" label behind table view and hide table view
        //Check what happens with search bar in this case
    
    func noSessionsUIUpdate() {
        self.searchQueryTable.alpha = 0
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? RequestVC {
            if let currentSession = sender as? Session {
                dest.self.currentSession = currentSession
            }
        }
    }
   

}

extension UserMainSelectVenueVC: MKMapViewDelegate {
    func addAnnotation(session: Session) {
        let annotation = MKPointAnnotation()
        let venueCoord = CLLocationCoordinate2D(latitude: session.venueCoord.latitude, longitude: session.venueCoord.longitude)
        annotation.coordinate = venueCoord
        annotation.title = session.venueName
        mapView.addAnnotation(annotation) //Add pin to map
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else {
            return nil
        }
        let reuseIdentifier = "pinAnnotation"
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
        annotationView.canShowCallout = true
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didUpdate
                    userLocation: MKUserLocation) {
        self.mapView.centerCoordinate = userLocation.location!.coordinate
    }
}

extension UserMainSelectVenueVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredSessions.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 79
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserMainSessionCell") as? UserMainSessionCell else {
            return UserMainSessionCell()
        }
        
        cell.configureCell(session: filteredSessions[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let session = filteredSessions[indexPath.row]
        Alerts.shared.standardAlert(vc: self, title: "Confirmation", message: "Please confirm you are at \(session.venueName)", negativeOption: "Change", affirmativeOption: "Confirm") { didConfirm in
            guard didConfirm == true else {return}
            //Update current session field in db
            let data: [String:Any] = ["currentSessionId": session.sessionUid]
            FirestoreService.shared.setData(document: FirestoreService.shared.REF_CURRENT_USER_PRIVATE, data: data) {
                userService.shared.currentSession = session
                self.performSegue(withIdentifier: "unwindToRequestVC", sender: session) //Unwind to RequestVC and pass back the selected session
            }
        }
    }
}

extension UserMainSelectVenueVC: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText != "" else {
            filteredSessions = sessions
            tableView.reloadData()
            return
        }
        
        //Filter filteredSessions array to include dj names or venue name in sessions array that contain search text
        filteredSessions = sessions.filter({$0.djName.lowercased().contains(searchText.lowercased()) || $0.venueName.lowercased().contains(searchText.lowercased())})
        //Then reload the table view
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.showsCancelButton = false
    }
}

extension UserMainSelectVenueVC: CLLocationManagerDelegate {
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            queryActiveVenues()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            queryActiveVenues()
        }
        queryActiveVenues()
    }
    
}

//Session info view "view model"
extension UserMainSelectVenueVC {
    func initSessionInfoViewModel() {
        sessionInfoView.handleViewTap = {() in
            //Dismiss the vc to display RequestVC
            self.dismiss(animated: true, completion: nil)
        }
    
    }
}
