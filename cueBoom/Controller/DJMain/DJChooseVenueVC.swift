//
//  DJChooseVenueVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//
/*
import UIKit
import CoreLocation
import MapKit
import GooglePlaces
import SwiftKeychainWrapper
import FirebaseFirestore


class DJChooseVenueVC: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var btnLabel: UILabel!
    
    var locationManager = CLLocationManager()
    var myLatitude: CLLocationDegrees?
    var myLongitude: CLLocationDegrees?
    let annotation = MKPointAnnotation()
    var session: Session!
    var place: GMSPlace!
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        //mapView delegate set in IB
        mapView.userTrackingMode = .follow
        
        //Set button and label hidden initially
        selectBtn.isHidden = true
        btnLabel.isHidden = true
        
        //Add Google Places API key
        //TODO: this needs to be hidden from client?
        GMSPlacesClient.provideAPIKey("AIzaSyCgx44kA2826PcAGpZOaoeDNMS69PJKmW8")
        
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Put the search bar in the navigation bar.
        searchController?.searchBar.sizeToFit()
        navigationItem.titleView = searchController?.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func selectBtnTapped(_ sender: Any) {
        self.handleDatabase()
    }
    
    // Shows location if it's been authorized; if not, ask for permission
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            locationManager.startUpdatingLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            mapView.showsUserLocation = true
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        }
    }
    
    //Add annotation to map view
    //@param place: A GMSPlace returned from the GMSAutocompleteViewController
    func addAnno() {

        annotation.coordinate = place.coordinate
        annotation.title = place.name
    
        mapView.addAnnotation(annotation)
        //Center the map on the annotation
        mapView.setCenter(annotation.coordinate, animated: false)
    }
    
    func handleDatabase() {
        selectBtn.isEnabled = false
    
        let lat = place.coordinate.latitude
        let long = place.coordinate.longitude
        let location = CLLocation(latitude: lat, longitude: long)
        //TODO: clean this up
        var city: String?
        var state: String?
        var venueCityState: String!
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
        
        
        //print("components \(place.addressComponents[0])")
        
        let djUid = KeychainWrapper.standard.string(forKey: KEY_UID)!
        let djName = UserDefaults.standard.string(forKey: DJ_NAME) as Any
        
        //Create session uid, which will be
        //1. location key in realtime database and
        //2. session uid in sessions collection in Firestore
        let sessionUid = NSUUID.init().uuidString
        //Create timestamp of session creation
        let timestamp = Date()
        
        //Add location to realtime database
        RealtimeService.shared.addActiveVenue(key: sessionUid, location: location) {
            //Add session to firestore
            let sessionData: [String: Any] = ["sessionUid": sessionUid,
                                            "djUid": djUid,
                                            "djName": djName,
                                            "venueCoord": GeoPoint(latitude: lat, longitude: long),
                                            "venueName": self.place.name,
                                            "venueAddress": self.place.formattedAddress ?? " ",
                                            "venueCityState": venueCityState,
                                            "timestamp": timestamp]
            FirestoreService.shared.createSession(sessionUid: sessionUid, sessionData: sessionData) {
                
                //Create session object to pass to next VC
                self.session = Session(sessionData: sessionData)
                
                //Segue
                self.performSegue(withIdentifier: "toQueue", sender: self.session)
            }
            
            
        }
    }
    
    func chooseVenueAlert(title: String, message: String) {
        let alert = UIAlertController(title: "Confirm", message: "Are you performing here tonight?", preferredStyle: UIAlertControllerStyle.alert)
        
        
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (action) in
            //Add venue location and session data to database
            self.handleDatabase()
            
        }))
        
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DJQueueVC {
            if let session = sender as? Session {
                destination.session = session
            }
        }
    }
}

extension DJChooseVenueVC: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        
        self.place = place
        
        //Remove previous annotation
        mapView.removeAnnotation(annotation)
        
        //Add new annotation at the selected place
        addAnno()
        
        //Unhide button and label
        selectBtn.isHidden = false
        btnLabel.isHidden = false
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



extension DJChooseVenueVC: MKMapViewDelegate {
    
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        chooseVenueAlert(title: "Activate venue", message: "Are you performing here?")
//    }
    
}

*/
