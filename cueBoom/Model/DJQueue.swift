//
//  DJQueue.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/25/19.
//  Copyright © 2019 CueBoom LLC. All rights reserved.
//

import Foundation

public class StackedQueueItem {
    
    private var _allQueueItems: [QueueItem]!
    
    public var allQueueItems: [QueueItem] {
        get {
            return _allQueueItems
        }
    }
    
    public var numRequests: Int {
        get {
            if _allQueueItems == nil {
                return 0
            }
            return _allQueueItems.count
        }
    }
    
    public var totalValue: Double {
        get {
            var total: Double = 0
            _ = _allQueueItems.map({ total += $0.price })
            return total
        }
    }
    
    public private(set) var song: Song!
    
    public private(set) var stackedQueueStatus: QueueStatus!
    
    init(queueItem: QueueItem) {
        _allQueueItems = [QueueItem]()
        _allQueueItems.append(queueItem)
        
        self.song = queueItem

        stackedQueueStatus = queueItem.queueStatus // stacked queue status initially set to the queue item used to initialize
        
    }
    
    public func Add(_ q: QueueItem) {
        _allQueueItems.append(q)

        //Check if this item has a higher stacked queue status than the current one
        if (q.queueStatus.rawValue > stackedQueueStatus.rawValue) {
            stackedQueueStatus = q.queueStatus
        }
        
    }
    
    public func Update(_ q: QueueItem) {
        if (q.queueStatus.rawValue > stackedQueueStatus.rawValue) {
            stackedQueueStatus = q.queueStatus
        }
    }

}

public class DJQueue {
    
    fileprivate let queueItemExistsInStack: ((StackedQueueItem, QueueItem) -> Bool) = {stack, queueItem in
        return stack.song.songTitle == queueItem.songTitle &&
            stack.song.artistName == queueItem.artistName &&
            stack.song.albumName == queueItem.albumName
    }
    
    private var allStackedRequests: [StackedQueueItem]

    
    public var stackedNewRequests: [StackedQueueItem] {
        get {
            return allStackedRequests.filter({ $0.stackedQueueStatus == QueueStatus.pending })
        }
    }
    
    public var stackedAcceptedRequests: [StackedQueueItem] {
        get {
            return allStackedRequests.filter({ $0.stackedQueueStatus == QueueStatus.accepted })
        }
    }
    
    public var stackedReadyRequests: [StackedQueueItem] {
        get {
            return allStackedRequests.filter({ $0.stackedQueueStatus == QueueStatus.paid || $0.stackedQueueStatus == QueueStatus.played }) //return both PAID and PLAYED songs
        }
    }
    
    init() {
        allStackedRequests = [StackedQueueItem]()
    }
    
    public func ProcessNew(_ queueItem: QueueItem) {
        
        //Check if stack exists. If so, add to existing stack
        if let stack = allStackedRequests.filter({ queueItemExistsInStack($0, queueItem) }).first {
            stack.Add(queueItem)
            return
        }
        
        //Stack does not exist for the queue item's song. Initialize new stack with the queue item
        allStackedRequests.append(StackedQueueItem(queueItem: queueItem))
    }
    
    public func ProcessModified(_ queueItem: QueueItem) {
        
        //Check if stack exists. If so, update stack
        if let stack = allStackedRequests.filter({ queueItemExistsInStack($0, queueItem) }).first {
            stack.Update(queueItem)
        }
    }
    
    public func ProcessRemoved(_ queueItem: QueueItem) {
        
        //Check if stack exists. If so, remove stack
        if let _ = allStackedRequests.filter({ queueItemExistsInStack($0, queueItem) }).first {
            allStackedRequests = allStackedRequests.filter({ !queueItemExistsInStack($0, queueItem) })
        }
    }
    
}
