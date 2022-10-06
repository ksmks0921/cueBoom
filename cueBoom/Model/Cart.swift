//
//  Cart.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/7/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation

struct Cart {
    private var _total: Double!
    
    
    var total: Double? {
        if _total != nil {
            return _total
        }
        return nil
    }
    
    init(data: [String: Any]) {
        if let total = data["total"] as? Double {
            _total = total
        }
    }
}
