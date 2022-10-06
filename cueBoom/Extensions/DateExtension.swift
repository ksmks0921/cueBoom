//
//  DateExtension.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/9/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import MapKit

extension Date {
    
    func getCustomTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d - h:mma"
        dateFormatter.amSymbol = "am"
        dateFormatter.pmSymbol = "pm"
        let stringDate = dateFormatter.string(from: self)

        
        
        return stringDate
    }
    
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }

    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

