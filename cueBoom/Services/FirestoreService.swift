//
//  FirestoreService.swift
//  cueBoom
//
//  Created by CueBoom LLC on 4/17/18.
//  Copyright © 2018 CueBoom LLC. All rights reserved.
//

import Foundation
import FirebaseFirestore
import SwiftKeychainWrapper
import GooglePlaces

//Data service for Cloud Firestore
let FS_BASE = Firestore.firestore()

class FirestoreService {
    
    private init() {}
    static let shared = FirestoreService()
    
    private var _REF_USERS_PUBLIC = FS_BASE.collection("users_public")
    private var _REF_USERS_PRIVATE = FS_BASE.collection("users_private")
    private var _REF_DJS_PUBLIC = FS_BASE.collection("djs_public")
    private var _REF_DJS_PRIVATE = FS_BASE.collection("djs_private")
    private var _REF_TRANSACTIONS = FS_BASE.collection("transactions")
    private var _REF_VENUES = FS_BASE.collection("venues")
    private var _REF_SESSIONS = FS_BASE.collection("sessions")
    
    var REF_USERS_PUBLIC: CollectionReference {
        return _REF_USERS_PUBLIC
    }
    
    var REF_USERS_PRIVATE: CollectionReference {
        return _REF_USERS_PRIVATE
    }
    
    var REF_DJS_PUBLIC: CollectionReference {
        return _REF_DJS_PUBLIC
    }
    
    var REF_DJS_PRIVATE: CollectionReference {
        return _REF_DJS_PRIVATE
    }
    
    var REF_TRANSACTIONS: CollectionReference {
        return _REF_TRANSACTIONS
    }
    
    var REF_VENUES: CollectionReference {
        return _REF_VENUES
    }
    
    var REF_SESSIONS: CollectionReference {
        return _REF_SESSIONS
    }
    
    var REF_CURRENT_USER_PRIVATE: DocumentReference {
        let uid = userService.shared.uid
        return REF_USERS_PRIVATE.document(uid)
    }
    
    var REF_CURRENT_DJ_PRIVATE: DocumentReference {
        let uid = userService.shared.uid 
        return REF_DJS_PRIVATE.document(uid)
    }
    
    var REF_CURRENT_DJ_PUBLIC: DocumentReference {
        let uid = userService.shared.uid
        return REF_DJS_PUBLIC.document(uid)
    }
    
    var REF_CURRENT_DJ_SESSIONS: CollectionReference {
        return REF_CURRENT_DJ_PUBLIC.collection("sessions")
    }
    
    var REF_REQUESTS: CollectionReference {
        return REF_CURRENT_USER_PRIVATE.collection("requests")
    }
    
    var REF_USER_CART: CollectionReference {
        return REF_CURRENT_USER_PRIVATE.collection("cart")
    }
    
    func createDj(uid: String, djData: Dictionary<String, Any>, completion: @escaping() -> Void) {
        
        //TODO: multi collection writes with a single callback
        REF_DJS_PRIVATE.document(uid).setData(djData, merge: true) { (error) in
            if error == nil {
                let pushManager = PushNotificationManager(userID: uid)
                pushManager.registerForPushNotifications(uid: uid)
                completion()
            } else {
                print(error!)
            }
        }
    }
    
    
    func getOnlineEvents(vc: UIViewController, completion: @escaping ([Session]?) -> ()) {
        FS_BASE.collection("sessions").whereField("onlineEvent", isEqualTo: true).whereField("endTime", isGreaterThan: Timestamp(date: Date())).whereField("ended", isEqualTo: false).getDocuments { (snap, err) in
            if err != nil {
                Alerts.errMessage(view: vc, message: err!.localizedDescription)
                return
            }
            
            guard snap?.documents.isEmpty != true else {
                completion([])
                return
            }
            
            var sessionTableData: [Session] = []
            
            for documents in snap!.documents {
                let sessionData = documents.data()
                let sessionObject = Session(data: sessionData)
                
//                if sessionObject.startTime.dateValue() < Date() {
//                    continue
//                }
                
                sessionTableData.append(sessionObject)
            }
            
            completion(sessionTableData)
        }
    }
    
    ///Returns nil unless there is an error
    func createUser(uid: String, userData: Dictionary<String, Any>, completion: @escaping (String?) -> Void) {
        let userUID = uid
        //TODO: multi collection writes with a single callback
        REF_USERS_PRIVATE.document(userUID).setData(userData, merge: true) { (error) in
            if error == nil {
                userService.shared.uid = userUID
                let pushManager = PushNotificationManager(userID: userUID)
                pushManager.registerForPushNotifications(uid: uid)
                completion(nil)
            } else {
                completion(error?.localizedDescription)
            }
        }
    }

    func checkForIdenticalRequest(songName: String, artistName: String, sessionID: String, completion: @escaping (Int?) -> ()) {
        let db = Firestore.firestore()
        db.collection("sessions").document(sessionID).collection("queue").whereField("songTitle", isEqualTo: songName).whereField("artistName", isEqualTo: artistName).getDocuments { (snap, err) in
            if err != nil {
                print("Error checking for duplicate song requests: \(err!.localizedDescription)")
                return
            }
            
            if snap?.documents == [] {
                return completion(nil)
            }
            
            for document in snap!.documents {
                guard let sessionArtistName = document.data()["artistName"] as? String else {
                    return
                }
                
                guard let sessionSongName = document.data()["songTitle"] as? String else {
                    return
                }
                
                if sessionArtistName == artistName &&  sessionSongName == songName {
                    completion(document.data()["queueStatus"] as? Int)
                    return
                }
            }
            
            completion(nil)
        }
    }
    
    func createSession(sessionUid: String, sessionData: Dictionary<String, Any>, completion: @escaping(Bool) -> Void) {
        
        REF_SESSIONS.document(sessionUid).setData(sessionData, merge: true) { (error) in
            if error == nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func addSessionReference(sessionUid: String, completion: @escaping(Bool) -> Void) {
        REF_CURRENT_DJ_SESSIONS.document(sessionUid).setData([:]) { (error) in
            guard error == nil else {return completion(false)}
            
            completion(true)
        }
    }
    
    func getSessionData(sessionUid: String, completion: @escaping([String: Any]?) -> Void) {
        FS_BASE.collection("sessions").document(sessionUid).getDocument { (snapshot, err) in
            if let snapshot = snapshot {
                if !snapshot.exists {
                    print("\(snapshot) does not exist")
                    completion(nil)
                }
            }
            
            if let data = snapshot?.data() {
                completion(data)
            } else if err != nil {
                print("ERROR is \(err!)")
            }
        }
    }
    
    func getAwaitingPaymentSessionsCount(completion: @escaping (Int) -> ()) {
        if userService.shared.currentSession?.sessionUid != nil {
            FS_BASE.collection("sessions").document(userService.shared.currentSession!.sessionUid).collection("queue").whereField("userUid", isEqualTo: userService.shared.uid).whereField("queueStatus", isEqualTo: 1).getDocuments { (snap, err) in
                if err != nil {
                    return completion(0)
                }
                
                guard snap != nil else {
                    return completion(0)
                }
                
                completion(snap!.documents.count)
            }
        }
    }
    
    //Delete from sessions collection and djs_public/{uid}/sessions
    func deleteSession(sessionUid: String) {
        //Delete from sessions collection
        REF_SESSIONS.document(sessionUid).delete()
        REF_CURRENT_DJ_SESSIONS.document(sessionUid).delete()
    }
    
    func addDjPublicData(_ data: [String: Any], completion: @escaping(Bool) -> Void) {
        REF_CURRENT_DJ_PUBLIC.setData(data, merge: true) { (error) in
            guard error == nil else {
                return completion(false)
            }
            completion(true)
        }
    }
    
    func getDjProfileData(completion: @escaping([String: Any]) -> Void) {
        REF_CURRENT_DJ_PUBLIC.getDocument { (snapshot, error) in
            guard error == nil else {return}
        }
    }
    
    func getDocumentData(ref: DocumentReference, completion: @escaping([String: Any]?) -> Void) {
        ref.getDocument { (snapshot, error) in
            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }
            completion(data)
        }
    }
    
    func setData(document: DocumentReference, data: [String:Any], completion: @escaping() -> Void) {
        document.setData(data, merge: true) { (error) in
            if error != nil {
                print("ERROR: \(error!.localizedDescription)")
                return
            }
            
            completion()
        }
    }
    
    func addTransaction(data: [String:Any], completion: @escaping(Bool) -> Void) {
        let uuid = NSUUID.init().uuidString.replacingOccurrences(of: "-", with: "")
        let sessionUID = data["sessionUid"] as! String
        let songs = data["songs"] as! [String]
        
        let doc = REF_TRANSACTIONS.document(uuid)
        doc.setData(data) { (error) in
            if error != nil {
                print("Error setting transaction")
                completion(false)
            }
            
            for song in songs {
                self.REF_SESSIONS.document(sessionUID).collection("queue").document(song).updateData(["Transaction" : data])
            }
            
            completion(true)
        }
    }
    
    func batchSetCartItemsReadyToPlay(cartItems: [QueueItem], sessionId: String, completion: @escaping(Bool) -> Void) {
        let batch = FS_BASE.batch()
        for item in cartItems {
            let doc = REF_SESSIONS.document(sessionId).collection("queue").document(item.id)
            batch.updateData(["queueStatus": QueueStatus.paid.rawValue], forDocument: doc)
        }
        
        batch.commit() { err in
            if let err = err {
                print("Batched write error: \(err)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    func getStripeID(viewController: UIViewController, uid: String, completion: @escaping (_ connectID: String?, _ error: String?) -> ()) {
        FS_BASE.collection("djs_private").document(uid).getDocument { (snap, err) in
            if err != nil {
                Alerts.shared.ok(viewController: viewController, title: "Error!", message: err!.localizedDescription)
                completion(nil, err!.localizedDescription)
                return
            }
            
            guard let connectID = snap?.data()?["connectID"] as? String else {
                let payAlert = UIAlertController(title: "CueBoom has a new way to pay!", message: "Let's get you setup for direct deposits before you continue.", preferredStyle: .alert)
                let no = UIAlertAction(title: "Maybe Later", style: .default) { (action) in
                    let storyboard = UIStoryboard(name: "Login", bundle: nil)
                    let newVC = storyboard.instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
                    newVC.modalPresentationStyle = .fullScreen
                    viewController.present(newVC, animated: true)
                }
                let yes = UIAlertAction(title: "Okay", style: .default) { (action) in
                    let storyboard = UIStoryboard(name: "DJSetup", bundle: nil)
                    let newVC = storyboard.instantiateViewController(withIdentifier: "stripeSetup") as! stripeSetupViewController
                    newVC.uid = uid
                    newVC.modalPresentationStyle = .fullScreen
                    viewController.present(newVC, animated: true)
                }
                
                payAlert.addAction(no)
                payAlert.addAction(yes)
                viewController.present(payAlert, animated: true)
                return
            }
             
            completion(connectID, nil)
        }
    }
   
    func getFavoriteDJs(vc: UIViewController, completion: @escaping ([DjProfile]) -> ()) {
        let db = Firestore.firestore()
        db.collection("users_private").document(userService.shared.uid).getDocument { (snap, err) in
            if err != nil {
                return
            }
            
            guard snap?.data()?["following"] as? [String] != nil else {
                return
            }
            
            guard let following = snap?.data()?["following"] as? [String] else { return }
            guard following.isEmpty != true else { return }
            
            var djObjects: [DjProfile] = []
            
            let group = DispatchGroup()
            
            for djs in following {
                group.enter()
                db.collection("djs_public").document(djs).getDocument { (snap, err) in
                    if err != nil {
                        print(err!.localizedDescription)
                        group.leave()
                        return
                    }
                    
                    guard snap?.data() != nil else { return }
                    
                    let djObject = DjProfile(profileData: snap!.data()!, uid: snap!.documentID)
                    djObjects.append(djObject)
                    group.leave()
                }
            }
            
            group.notify(queue: DispatchQueue.main) {
                completion(djObjects)
            }
        }
    }
    
    // MARK: Onboarding Check and Approved By Admin
    func checkCompletedOnboardingAndApprovedByAdmin(type: userType, userUID: String, completion: @escaping (Bool, Bool) -> ()) {
        
        let db = Firestore.firestore()
        var collection: CollectionReference
        
        if type == .dj {
            collection = db.collection("djs_private")
        } else {
            collection = db.collection("users_private")
        }

//        if type == .dj {
//            collection.getDocuments {(snap, err) in
//                guard snap != nil else { return }
//                for one in snap!.documents {
//                    collection.document(one.documentID).updateData(["approvedByAdmin" : true])
//                }
//            }
//        }
        
        collection.document(userUID).getDocument { (snap, err) in
            if err != nil {
                return completion(false, false)
            }
            
            guard snap != nil else { return }
            guard let onboardingComplete = snap?.data()?["onboardingComplete"] as? Bool else {
                completion(false, false)
                return
            }
            
            guard let approvedByAdmin = snap?.data()?["approvedByAdmin"] as? Bool else {
                completion(onboardingComplete, false)
                return
            }
            
            return completion(onboardingComplete, approvedByAdmin)
        }
    }
    
    func updateOnboardingComplete(type: userType, userUID: String, completion: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        var collection: CollectionReference
        
        if type == .dj {
            collection = db.collection("djs_private")
        } else {
            collection = db.collection("users_private")
        }
        
        collection.document(userUID).updateData(["onboardingComplete" : true]) { (err) in
            if err != nil {
                return completion(false)
            }
            
            completion(true)
        }
    }
    
    // Move this to different file
    enum userType {
        case dj
        case user
    }
}
