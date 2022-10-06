//
//  UserChooseVenueVC.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit


class UserChooseVenueVC: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var requestSongBtn: UIButton!
    @IBOutlet weak var seeDjProfileBtn: UIButton!
    
    var locationManager = CLLocationManager()
    var djMapView: DjMapView!
    var selectedSession: Session!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        locationManager.delegate = self
        
        //Hide button and label initially until annotation tap
        requestSongBtn.isHidden = true
        seeDjProfileBtn.isHidden = true
        
        //Load map view
        djMapView = Bundle.main.loadNibNamed("DjMapView", owner: self, options: nil)?.first as? DjMapView
        djMapView.bounds = self.view.bounds
        djMapView.djMapDelegate = self
        self.view.addSubview(djMapView)
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    @IBAction func seeDjProfileBtnTapped(_ sender: Any) {
        
    }
    
    @IBAction func requestSongBtnTapped(_ sender: Any) {
        guard selectedSession != nil else {return}
        performSegue(withIdentifier: "toSearch", sender: selectedSession)
    }
    
    // Shows location if it's been authorized; if not, ask for permission
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            djMapView.getActiveVenues()
        }
    }

}

extension UserChooseVenueVC: DjMapDelegate {
    
    func didGetSessions(_ sessions: [Session]) {
        djMapView.getActiveVenues()
    }
    
    func didSelectVenue(session: Session) {
        print(session.venueAddress)
        selectedSession = session
        view.bringSubviewToFront(seeDjProfileBtn)
        view.bringSubviewToFront(requestSongBtn)
        seeDjProfileBtn.isHidden = false
        requestSongBtn.isHidden = false
    }

}
