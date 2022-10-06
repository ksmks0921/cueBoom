//
//  QueueItem.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/5/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation

open class QueueItem: Song {
    
    private var _id: String!
    private var _userUid: String!
    private var _djUid: String!
    private var _price: Double!
    private var _timestamp: Date! //TODO: Look up change to timestamp processing in firebase
    private var _queueStatus: QueueStatus!
    private var _numRequests = 1
    
    func getDict() -> [String: Any] {
        var dict: [String: Any] = [
           "id" : id,
           "userUid" : userUid,
           "djUid" : djUid,
           "price" : price,
           "timestamp" : timestamp,
           "queueStatus" : queueStatus,
           "numRequests" : numRequests
        ]
        
        return dict
    }
    
    var id: String {
        if _id != nil {
            return _id
        }
        return ""
    }

    
    var userUid: String {
        if _userUid != nil {
            return _userUid
        }
        return ""
    }
    
    var djUid: String {
        if _djUid != nil {
            return _djUid
        }
        return ""
    }
    
    var price: Double {
       return _price
    }
    
    var timestamp: Date {
        return _timestamp
    }
    
    var queueStatus: QueueStatus {
        return _queueStatus
    }
    
    var numRequests: Int {
        return _numRequests
    }
 
    //TODO: failable intiializer?
    
    init(id: String, data: [String: Any]) {
        super.init(queueItemData: data)
        
        self._id = id
        
        if let userUid = data["userUid"] as? String {
            _userUid = userUid
        }
        
        if let djUid = data["djUid"] as? String {
            _djUid = djUid
        }
        
        if let price = data["price"] as? Double {
            _price = price
        }
        
        if let timestamp = data["timestamp"] as? Date {
            _timestamp = timestamp
        }
        
        if let queueStatusRawValue = data["queueStatus"] as? Int {
            switch queueStatusRawValue {
            case 0:
                _queueStatus = .pending
            case 1:
                _queueStatus = .accepted
            case 2:
                _queueStatus = .rejected
            case 3:
                _queueStatus = .paid
            case 4:
                _queueStatus = .played
            default:
                print("Init should fail")
                //initializer should fail
            }
        }
    
    }
    
    required public init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
    
    func incrementNumRequests(prevCount: Int) {
        _numRequests = prevCount + 1
    }
    
    func setRequestAccepted() {
        self._queueStatus = QueueStatus.accepted
    }
    
    func setRequestRejected() {
        self._queueStatus = QueueStatus.rejected
    }
    
    func setRequestPaid() {
        self._queueStatus = QueueStatus.paid
    }
    
    func setRequestPlayed() {
        self._queueStatus = QueueStatus.played
    }
    
}
