//
//  FormatDate.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/4/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation

class FormatDate {
    private init () {}
    static let shared = FormatDate()
    
    
    func getString(_ date: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yy hh:mm a"
        let stringDate = dateFormatter.string(from: date)
        
        return stringDate
        
    }
    
    func getGigCellTimeString(forDate date: Date) {
        
    }
    
}


