//
//  GlobalEnums.swift
//  cueBoom
//
//  Created by CueBoom LLC on 6/5/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation

//Queue status for identifying a queue item as accepted, rejected, pending, or unpaid
//Raw type will be posted to firebase
public enum QueueStatus: Int {
    case pending = 0
    case accepted = 1
    case rejected =  2
    case paid = 3
    case played = 4
}


//Also property names of QueueItem struct
//Database key names for a queue item document.
enum QueueItemPropertyName: String {
    case songTitle = "songTitle"
    case artistName = "artistName"
    case albumArtUrl = "albumArtUrl"
    case userUid = "userUid"
    case djUid = "djUid"
    case price = "price"
    case timestamp = "timestamp"
    case queueStatus = "queueStatus"
}

var CHECKING = "checking"
var SAVINGS = "savings"
