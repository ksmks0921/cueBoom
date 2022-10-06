//
//  DJUpdateVenueVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/10/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//


import UIKit
import MapKit
import GooglePlaces
import MapKit
import FirebaseFirestore
import SwiftKeychainWrapper

class DJEditVenueVC: UIViewController {
    
    //Differences between this VC and other dj find venue vc's are noted with //*
    
    @IBOutlet weak var mapView: DjMapView!
    @IBOutlet weak var tableView: UITableView!
    
    private var _session: Session!
    var session: Session {
        get {
            return _session
        } set {
            _session = newValue
        }
    }
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var locationManager = CLLocationManager()
    
    var totalSessions = [Session]()
    var place: GMSPlace!
    let annotation = MKPointAnnotation()
    var selectionType: Int!
    var selectedSession: Session? //This is used when a user selects a venue by tapping a table view row
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Tbl view and search bar delegates set in IB
        
        print("EDITING VENUE FOR \(_session.sessionUid)")
        locationManager.delegate = self
        mapView.djMapDelegate = self
        mapView.delegate = self
        
        //Add Google Places API key
        //TODO: this needs to be hidden from client?
        GMSPlacesClient.provideAPIKey("AIzaSyCgx44kA2826PcAGpZOaoeDNMS69PJKmW8")
        
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        if let searchBar = searchController?.searchBar {
            searchBar.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 56)
            self.view.addSubview(searchBar)
            searchController?.searchResultsUpdater = resultsViewController
        }
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
        
        
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        navigationController?.customMakeOpaque()
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        navigationController?.customMakeTranslucent()
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func addAnno() {
        
        annotation.coordinate = place.coordinate
        annotation.title = place.name
        
        mapView.addAnnotation(annotation)
        //Center the map on the annotation
        mapView.setCenter(annotation.coordinate, animated: false)
    }
    
    func confirmationAlert(venueName: String) {
        let alert = UIAlertController(title: "Location Confirmation", message: "Please confirm that you are at \(venueName).", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Change", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
            self.addNewSession()
        }))
        
        
        
        present(alert, animated: true, completion: nil)
    }
    
    //There are three ways a DJ can select a venue
    //1. Tap a pin that drops after they select a google search result
    //selectionType = 0
    //2. Tap a pin that is autoloaded from db
    //selectionType = 1
    //3. Tap a table view row
    //selectionType = 2
    
    func addNewSession() {
        
        var lat: CLLocationDegrees!
        var long: CLLocationDegrees!
        var location: CLLocation!
        var venueCityState: String!
        var venueAddress: String!
        var venueName: String!
        let djUid = KeychainWrapper.standard.string(forKey: KEY_UID)!
        let djName = UserDefaults.standard.string(forKey: DJ_NAME) as Any
        //Create session uid, which will be
        //1. location key in realtime database and
        //2. session uid in sessions collection in Firestore
        let sessionUid = NSUUID.init().uuidString.replacingOccurrences(of: "-", with: "")
        //Create timestamp of session creation
        let timestamp = Date()
        
        if selectionType == 0 {
            lat = place.coordinate.latitude
            long = place.coordinate.longitude
            location = CLLocation(latitude: lat, longitude: long)
            venueName = self.place.name
            venueAddress = self.place.formattedAddress ?? " "
            var city: String?
            var state: String?
            for component in place.addressComponents! {
                if component.type == kGMSPlaceTypeLocality {
                    city = component.name
                }
                
                if component.type == kGMSPlaceTypeAdministrativeAreaLevel1 {
                    state = component.name
                    
                }
            }
            
            if city != nil, state != nil {
                venueCityState = "\(city!), \(state!)"
            } else {
                venueCityState = " "
            }
        } else if selectionType == 1 || selectionType == 2 {
            guard selectedSession != nil else {return}
            lat = selectedSession!.venueCoord.latitude
            long = selectedSession!.venueCoord.longitude
            location = CLLocation(latitude: lat, longitude: long)
            venueCityState = selectedSession!.venueCityState
            venueAddress = selectedSession!.venueAddress
            venueName = selectedSession!.venueName
            
        }
        
        //* Changing "sessionUid" value to _session.sessionUid
        let sessionData: [String: Any] = [
            "sessionUid": _session.sessionUid,
            "djUid": djUid,
            "djName": djName,
            "venueCoord": GeoPoint(latitude: lat, longitude: long),
            "venueName": venueName!,
            "venueAddress": venueAddress!,
            "venueCityState": venueCityState!,
            "timestamp": timestamp,
            "startTime": _session.startTime,
            "endTime": _session.endTime,
            "totalEarnings": _session.totalEarnings
        ]
        let updatedSession = Session(data: sessionData)
        
        //* Updating firestore AND realtime db (since location has changed)
        RealtimeService.shared.addActiveVenue(key: updatedSession.sessionUid, location: location) { (success) in
            FirestoreService.shared.createSession(sessionUid: updatedSession.sessionUid, sessionData: sessionData, completion: { (success) in
                //* Unwind to confirmation screen
                self.performSegue(withIdentifier: "backToEdit", sender: updatedSession)
            })
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dest = segue.destination as? DJEditGigVC else {return}
        guard let updatedSession = sender as? Session else {return}
        dest.session = updatedSession
    }
    
}

extension DJEditVenueVC: CLLocationManagerDelegate {
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            mapView.getActiveVenues()
        }
    }
}

extension DJEditVenueVC: DjMapDelegate {
    func didGetSessions(_ sessions: [Session]) {
        //totalSessions.append(session)
        totalSessions = sessions
        tableView.reloadData()
    }
    
    func didSelectVenue(session: Session) {
        
    }
    
}

extension DJEditVenueVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return totalSessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "VenueCell") as? VenueCell {
            cell.configureCell(session: totalSessions[indexPath.row])
            return cell
        } else {
            return VenueCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    //TODO: change selection color
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedSession = totalSessions[indexPath.row]
        selectionType = 2
        confirmationAlert(venueName: selectedSession!.venueName)
    }
}

extension DJEditVenueVC: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        
        self.place = place
        
        //Remove previous annotation
        mapView.removeAnnotation(annotation)
        
        //Add new annotation at the selected place
        addAnno()
        
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

extension DJEditVenueVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if let anno = view.annotation {
            if let venueName = anno.title {
                if venueName == annotation.title {
                    selectionType = 0
                } else {
                    selectionType = 1
                    for session in totalSessions {
                        if session.venueName == venueName {
                            selectedSession = session
                        }
                    }
                }
                if venueName != nil {
                    confirmationAlert(venueName: venueName!)
                }
            }
        }
    }
    
    
}
