//
//  Transaction.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation

final class Transaction {
    
    private var _amount: Double!
    private var _timestamp: Date!
    private var _userUid: String!
    private var _sessionId: String!
    
    var amount: Double {
        return _amount
    }
    
    var timestamp: Date {
        return _timestamp
    }
    
    var userUid: String {
        return _userUid
    }
    
    var sessionId: String {
        return _sessionId
    }
    
    init(transactionData: Dictionary<String, Any>) {
        if let amount = transactionData["amount"] as? Double {
            self._amount = amount
        }
        
        if let timestamp = transactionData["timestamp"] as? Date  {
            self._timestamp  = timestamp
        }
        
        if let userUid = transactionData["userUid"] as? String {
            self._userUid  = userUid
        }
        
        if let sessionId = transactionData["sessionId"] as? String {
            self._sessionId = sessionId
        }
       
    }
}
