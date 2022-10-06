//
//  DJMainFindVenueVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/9/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//


//MARK: ACTIVE VIEW CONTROLLER//
//ADD GIG AND FIND VENUES


import UIKit
import MapKit
import GooglePlaces
import MapKit
import FirebaseFirestore
import SwiftKeychainWrapper


//ACTIVE VC FOR MAP ON DJMAIN

class DJMainFindVenueVC: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: DjMapView!
    @IBOutlet weak var tableView: UITableView!
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    var locationManager = CLLocationManager()
    var totalSessions = [Session]()
    var place: GMSPlace? = nil
    let annotation = MKPointAnnotation()
    var databaseAnno = MKPointAnnotation()
    var selectionType: Int!
    var selectedSession: Session? //This is used when a user selects a venue by tapping a table view row
    var placemark: CLPlacemark? = nil
    var pickedCoordinate: CLLocationCoordinate2D? = nil
    
    
    @objc func longTap(sender: UILongPressGestureRecognizer){
        print("long tap")
        
        if sender.state == .began {
            let touch: CGPoint = sender.location(in: mapView)
            pickedCoordinate = mapView.convert(touch, toCoordinateFrom: mapView)
//            mapView.setCenter(pickedCoordinate!, animated: false)

            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            annotation.coordinate = locationOnMap
            
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: pickedCoordinate!.latitude, longitude: pickedCoordinate!.longitude)) { (placemarks, error) in
                if let places = placemarks {
                    for place in places {
                        self.placemark = place
                        self.addAnno()
                        print("found placemark \(place.name!) at address \(place.postalAddress!)")
                    }
                }
            }
        }
    }

    func addAnnotation(location: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "Some Title"
        annotation.subtitle = "Some Subtitle"
        self.mapView.addAnnotation(annotation)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Tbl view and search bar delegates set in IB
        
        locationManager.delegate = self
        mapView.delegate = self
//        mapView.djMapDelegate = self
        
//        tableView.dataSource = self
//        tableView.delegate = self
        tableView.isHidden = true
        
        //Add Google Places API key
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
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        longGesture.minimumPressDuration = 0.5
        longGesture.numberOfTouchesRequired = 1
        longGesture.allowableMovement = 100
        longGesture.delegate = self
        mapView.addGestureRecognizer(longGesture)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func addAnno() {
        if let place = place {
            annotation.coordinate = place.coordinate
            annotation.title = place.name
        } else if let placemark = placemark {
            annotation.coordinate = pickedCoordinate!
            annotation.title = placemark.postalAddress?.city
        }
        
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
        var venueCityState: String!
        var venueAddress: String!
        var venueName: String!
        let djUid = userService.shared.uid
        let djName = UserDefaults.standard.string(forKey: DJ_NAME) as Any
        
        let sessionUid = NSUUID.init().uuidString.replacingOccurrences(of: "-", with: "")
        
        if selectionType == 0 {
            if let place = place {
                lat = place.coordinate.latitude
                long = place.coordinate.longitude
                venueName = place.name
                venueAddress = place.formattedAddress ?? " "
                var city: String?
                var state: String?
                for component in place.addressComponents! {
                    if component.type == kGMSPlaceTypeLocality {city = component.name}
                    if component.type == kGMSPlaceTypeAdministrativeAreaLevel1 {state = component.name}
                }
                
                if city != nil, state != nil {
                    venueCityState = "\(city!), \(state!)"
                } else {
                    venueCityState = " "
                }
            } else if let placemark = placemark {
                venueCityState = ""
                let city = placemark.postalAddress?.city
                let state = placemark.postalAddress?.state
                if city != nil, state != nil {
                    venueCityState = "\(city!), \(state!)"
                } else {
                    venueCityState = " "
                }
                
                lat = pickedCoordinate!.latitude
                long = pickedCoordinate!.longitude
                venueName = placemark.postalAddress!.city
                venueAddress = placemark.postalAddress?.street
            }
        } else if selectionType == 1 || selectionType == 2 {
            lat = selectedSession!.venueCoord.latitude
            long = selectedSession!.venueCoord.latitude
            venueName = selectedSession!.venueName
            venueAddress = selectedSession!.venueAddress
            venueCityState = selectedSession!.venueCityState
        }
        
        let location: CLLocation! = CLLocation(latitude: lat, longitude: long)
        
        let sessionData: [String: Any] = [
            "sessionUid"    : sessionUid,
            "djUid"         : djUid,
            "djName"        : djName,
            "venueCoord"    : GeoPoint(latitude: lat, longitude: long),
            "venueName"     : venueName!,
            "venueAddress"  : venueAddress!,
            "venueCityState": venueCityState!,
            "timestamp"     : Date(),
            "djImgUrl"      : UserDefaults.standard.string(forKey: DJ_IMG_URL) ?? "",
            "totalEarnings" : Double(0),
            "startTime"     : Date(),
            "endTime"       : Date(),
        ]
        
        let session = Session(data: sessionData)
        self.performSegue(withIdentifier: "toSetTime", sender: session)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? DJMainSetTimeVC {
            if let session = sender as? Session {
                dest._session = session
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
       return true
    }
}

//MARK: Extensions
extension DJMainFindVenueVC: CLLocationManagerDelegate {
    func locationAuthStatus() {
        let status = CLLocationManager.authorizationStatus()
        if status != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
//            mapView.getActiveVenues()
            mapView.setCenter(locationManager.location!.coordinate, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
//            mapView.getActiveVenues()
            mapView.setCenter(manager.location!.coordinate, animated: true)
        }
    }
}

extension DJMainFindVenueVC: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        self.place = place
        
        //Remove previous annotation
        mapView.removeAnnotation(annotation)
        
        //Add new annotation at the selected place
        addAnno()
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController, didFailAutocompleteWithError error: Error){
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

extension DJMainFindVenueVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let anno = view.annotation {
            if let venueName = anno.title {
                if venueName == annotation.title {
                    selectionType = 0
                } else {
                    for session in totalSessions {
                        if session.venueName == venueName {
                            selectedSession = session
                            selectionType = 1
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

/*extension DJMainFindVenueVC: DjMapDelegate {
    func didGetSessions(_ sessions: [Session]) {
        //totalSessions.append(session)
        totalSessions = sessions
        tableView.reloadData()
    }

    func didSelectVenue(session: Session) {}
}

extension DJMainFindVenueVC: UITableViewDelegate, UITableViewDataSource {
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
*/
