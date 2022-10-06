//
//  GeopointExtensions.swift
//  cueBoom
//
//  Created by Shahin Firouzbakht on 5/2/19.
//  Copyright © 2019 Shahin Firouzbakht. All rights reserved.
//

import Foundation
import FirebaseFirestore

class CodableGeopoint: GeoPoint, Encodable {
    
    enum CodingKeys: String, CodingKey {
        case longitude, latitude
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try values.decode(Double.self, forKey: .latitude)
        let longitude = try values.decode(Double.self, forKey: .longitude)
        
        super.init(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
}
