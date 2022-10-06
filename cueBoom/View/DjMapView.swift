//
//  DjMapView.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/24/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import FirebaseFirestore
import GeoFire
class DjMapView: MKMapView {

   // @IBOutlet weak var mapView: MKMapView!
    var djMapDelegate: DjMapDelegate!
   
    public var selectedAnno: DjAnnotation!
  
    private var _totalSessions = [Session]()
    var locationManager = CLLocationManager()
    override func awakeFromNib() {
        
//        self.userTrackingMode = .follow
        self.showsUserLocation = true
    
    }
    
    //Query the active venues in realtime database and display as annotations on the map
    func getActiveVenues() {
        
//        guard let currentLoc = self.userLocation.location else {return}
//        var keys = [String]()
//        let geoFire = GeoFire(firebaseRef: RealtimeService.shared.REF_ACTIVE_VENUES)
//        var query: GFCircleQuery?
//        query = geoFire.query(at: currentLoc, withRadius: 3000)
//
//        //The key that enters is the sessionUid of the session stored in Firestore
//        query?.observe(.keyEntered, with: { (key: String!, location: CLLocation!) in
//
//            keys.append(key)
//
//        })
//        print("here_____dddddd_______________");
//        print(keys)
//        query?.observeReady({
//            self.addAnnotations(keys: keys) { (sessions) in
//                //self._totalSessions.sort(by: {$0.distanceFromUser < $1.distanceFromUser})
//                print("here____________________");
//                print(sessions)
//                self.djMapDelegate.didGetSessions(sessions)
//            }
//        })
        
        
        guard let currentLoc = locationManager.location else {return}
        let db = Firestore.firestore()
        db.collection("sessions").whereField("ended", isEqualTo: false).whereField("onlineEvent", isEqualTo: false).whereField("startTime", isLessThan: Date()).getDocuments { (snap, err) in
            if err !=  nil {
//                Alerts.errMessage(view: self, message: "Server Error: \(err!.localizedDescription)")
                return
            }

            guard snap != nil else {
//                Alerts.errMessage(view: self, message: "Error parsing server data. Please try again.")
                return
            }

            var sessionsLoaded: [Session] = []
            for sessionData in snap!.documents {
                let session = Session(data: sessionData.data())
                sessionsLoaded.append(session)
//                self.addAnnotations(session)
            }
            print("sessions_______")
            print(sessionsLoaded)
            self.djMapDelegate.didGetSessions(sessionsLoaded)
//            self.sessions = sessionsLoaded

        }
        
//        RealtimeService.shared.getAllVenue { keys in
//            self.addAnnotations(keys: keys) { (sessions) in
//                //self._totalSessions.sort(by: {$0.distanceFromUser < $1.distanceFromUser})
//                self.djMapDelegate.didGetSessions(sessions)
//            }
//        }
    }
    
    func addAnnotations(keys: [String], completion: ([Session]) -> ()) {
        
        let group = DispatchGroup()
        
        for key in keys {
            group.enter()
            FirestoreService.shared.getSessionData(sessionUid: key) { data in
                guard let data = data else {
                    return group.leave()
                }
                
                // Converting Dates to correct data type so the compiler understands
                let session = Session(data: data)
                
                if session.startTime.dateValue() > Date() && session.endTime.dateValue().addingTimeInterval(TimeInterval(-43200)) < Date(timeIntervalSinceNow: TimeInterval(exactly: 86400)!) && session.ended == false {
                    print("NEW: \(session.startTime.dateValue().getCustomTimeString())")
                } else {
                    print("OLD: \(session.startTime.dateValue().getCustomTimeString())")
                    return group.leave()
                }
                
                //Prevent duplicate venues from appearing on map and subsequenty in table view in FindVenueVC's
                guard !self._totalSessions.contains(where:{$0.venueName == session.venueName}) else {
                    return group.leave()
                }
                
                let annotation = MKPointAnnotation()
                let venueCoord = CLLocationCoordinate2D(latitude: session.venueCoord.latitude, longitude: session.venueCoord.longitude)
                annotation.coordinate = venueCoord
                annotation.title = session.venueName
                self.addAnnotation(annotation) //Add pin to map
                self._totalSessions.append(session) 
                //self.djMapDelegate.didGetSessions(self._totalSessions)
                
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            //self._totalSessions.sort(by: {$0.distanceFromUser < $1.distanceFromUser})
            self.djMapDelegate.didGetSessions(self._totalSessions) //Delegate method
        }
    }
    
    func getSpecificSession(SessionID: String, completion: @escaping () -> ()) {
    }
}


extension DjMapView: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else {
            return nil
        }
        
        let reuseIdentifier = "pinAnnotation"
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
 
        annotationView.canShowCallout = true
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let djAnno = view.annotation as? DjAnnotation {
            djMapDelegate.didSelectVenue(session: djAnno.session)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didUpdate
                    userLocation: MKUserLocation) {
        self.centerCoordinate = userLocation.location!.coordinate
    }
}
 
