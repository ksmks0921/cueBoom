//
//  UserFindVenueVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/30/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import GeoFire
class UserFindVenueVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: DjMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let locationManager = CLLocationManager()
    
    var totalSessions = [Session]()
    var searchedSessions = [Session]()
    
    var originalTblViewFrame: CGRect!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        locationManager.delegate = self
        
        //Get keyboard height to shift up table view
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        navigationController?.navigationBar.backgroundColor = UIColor.black
        
        originalTblViewFrame = tableView.frame
        mapView.djMapDelegate = self
        mapView.getActiveVenues()
  
    }

    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus { (granted) in
            if granted == true {
                self.mapView.getActiveVenues()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.customMakeTranslucent()
    }
    
    func confirmationAlert(venueName: String) {
        let alert = UIAlertController(title: "Location Confirmation", message: "Please confirm that you are at \(venueName).", preferredStyle: UIAlertController.Style.alert)
        
        alert.addAction(UIAlertAction(title: "Change", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertAction.Style.default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            
            self.performSegue(withIdentifier: "toDJInstructions", sender: venueName)
        }))
        
       
        
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DJInstructionsVC {
            if let venueName = sender as? String {
                destination.venueName = venueName
            }
        }
    }
    
    //Have to shift table view up and give new frame when keyboard shows
    @objc func keyboardWillShow(notification: NSNotification) {
        print("KEYBOARD WILL SHOW")
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            //Table view height is keyboard y - yBottom of search bar
            let keyboardY = self.view.frame.height - keyboardHeight
            
            let searchBarYBottom = searchBar.frame.origin.y + searchBar.frame.height
            let tblViewHeight = keyboardY - searchBarYBottom
            let newTblViewFrame = CGRect(x: 0, y: searchBarYBottom, width: self.view.frame.width, height: tblViewHeight)
            
            mapView.isHidden = true //Hide map view until user dismisses keyboard
            tableView.frame = newTblViewFrame //Set tableView frame
            
        }
    }

}

extension UserFindVenueVC: CLLocationManagerDelegate {
    func locationAuthStatus(completion: @escaping (Bool) -> ()) {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            mapView.getActiveVenues()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            self.mapView.setRegion(region, animated: true)
            mapView.getActiveVenues()
        }
        
        
    }
}

extension UserFindVenueVC: DjMapDelegate {
    func didGetSessions(_ sessions: [Session]) {
        self.totalSessions = sessions
        
        for session in sessions {
            searchedSessions = totalSessions
        }
        tableView.reloadData()
    }
    
    func didSelectVenue(session: Session) {
      
    }
}

//MARK: Table View Extension
extension UserFindVenueVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedSessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "VenueCell") as? VenueCell {
            cell.configureCell(session: searchedSessions[indexPath.row])
            return cell
        } else {
            return VenueCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let session = searchedSessions[indexPath.row]
        confirmationAlert(venueName: session.venueName)
    }
}

extension UserFindVenueVC: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        //Shift up table view
    }
    
    //Filter the totalSessions into searchedSessions based on search text and reload tablew view data
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText != "" else {
            searchedSessions = totalSessions
            tableView.reloadData()
            return
        }
        
        //Lower case the search text
        let text = searchText.lowercased()
        
        //String.contains is case sensitive. Lowercase both search text and filtered fields for case-insensitive filter
        searchedSessions = totalSessions.filter({$0.venueName.lowercased().contains(text)})
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        mapView.isHidden = false //Unhide map view
        tableView.frame = originalTblViewFrame
        searchBar.showsCancelButton = false
    }
}
