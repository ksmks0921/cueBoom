//
//  JSONHelper.swift
//  cueBoom
//
//  Created by CueBoom LLC on 5/2/19.
//  Copyright © 2019 CueBoom LLC. All rights reserved.
//

import Foundation

internal class JSONHelper {
    
    enum JSONError: Error {
        case serializationEror
        case generalError
    }
    
    static func getDictionary<T>(obj: T) throws -> Dictionary<String,Any> where T: Encodable {
        do {
            let data = try JSONEncoder().encode(obj)
            guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String,Any> else {
                throw JSONError.serializationEror
            }
            
            return dict
        } catch {
            print("Error getting dictionary")
            throw JSONError.generalError
        }
        
    }
    
    
    
}
