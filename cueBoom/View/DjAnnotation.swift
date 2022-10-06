//
//  DjAnnotation.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/24/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import UIKit
import GeoFire
class DjAnnotation: MKPointAnnotation {
    
    private var _session: Session!
    
    var session: Session {
        return _session
    }
    
    
    init(session: Session) {
        super.init()
        
        self._session = session
        
        let venueCoord = CLLocationCoordinate2D(latitude: _session.venueCoord.latitude, longitude: _session.venueCoord.longitude)
        self.coordinate = venueCoord
        self.title = _session.djName
        self.subtitle = "\(_session.venueName) | \(_session.venueCityState)"
        
    }

}
